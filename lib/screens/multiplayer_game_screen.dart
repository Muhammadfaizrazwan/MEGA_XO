import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'dart:async';
import '../services/pocketbase_service.dart';
import '../widgets/ultimate_ttt_board.dart';
import 'package:flutter/foundation.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final String roomId;
  final bool isPlayerX;

  const MultiplayerGameScreen({
    super.key,
    required this.roomId,
    required this.isPlayerX,
  });

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final pbService = PocketBaseService();

  // Convert to 3D board structure for compatibility with UltimateTTTBoard
  late List<List<List<String>>>
  board; // 3x3 papan besar, tiap elemen 9 kotak kecil
  late List<List<String>>
  bigBoardStatus; // status papan besar: "X", "O", "D" (draw), atau ""

  String currentPlayer = "X";
  int?
  activeBigRow; // papan besar aktif row (0..2) atau null = bebas main dimana saja
  int? activeBigCol;

  String? winner;
  String? opponentName;
  bool isGameLoaded = false;
  bool isProcessingMove = false;
  bool isWaitingRestart = false; // Flag for restart state
  int gameRound = 1; // Track game rounds
  String? restartRequestedBy; // Track who requested restart
  String? roomCreatorId; // Track room creator
  String userDisplayName = "Unknown User"; // User display name
  bool _isGameOverDialogShowing = false;
  bool _isRestartDialogShowing = false;

  // Simple player status tracking
  bool isOpponentInRoom = true;
  bool hasShownLeaveDialog = false;
  bool _hasLeftGame = false; // Track if current player has left

  // Timers and animations
  Timer? _gameTimer;
  int _totalSeconds = 0;
  Timer? _turnTimer;
  int _turnSeconds = 30;

  late AnimationController _turnIndicatorController;
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late AnimationController _restartController;
  late AnimationController _leaveController; // Animation for leave notification

  late Animation<double> _turnIndicatorAnimation;
  late Animation<double> _timerWarningAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _restartAnimation;
  late Animation<double> _leaveAnimation; // Leave notification animation

  // Realtime subscription management
  bool isSubscribed = false;
  UnsubscribeFunc? _unsubscribeFunc;

  @override
  void initState() {
    super.initState();
    print(
      "🎮 Ultimate Tic-Tac-Toe started - Room: ${widget.roomId}, IsPlayerX: ${widget.isPlayerX}",
    );
    print("👤 Current user: ${pbService.getCurrentUserInfo()}");

    // Initialize 3D board structure
    board = List.generate(
      3,
      (_) => List.generate(3, (_) => List.generate(9, (_) => "")),
    );
    bigBoardStatus = List.generate(3, (_) => List.generate(3, (_) => ""));

    activeBigRow = null; // awalnya bebas pilih papan kecil mana saja
    activeBigCol = null;

    // Add app lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    _initAnimations();
    _initializeGame();
    _loadUserInfo(); // Load user display name
    _markPlayerAsInRoom(); // Mark current player as in room
  }

  // Load user display name
  void _loadUserInfo() async {
    try {
      final userInfo = await pbService.getUserInfo();
      setState(() {
        userDisplayName =
            userInfo['name'] ??
            userInfo['email'] ??
            pbService.username ??
            "Unknown User";
      });
    } catch (e) {
      print("Error loading user info: $e");
    }
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    print("📱 App lifecycle changed to: $state");

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // App minimized/hidden - don't leave room, just mark as inactive
        break;
      case AppLifecycleState.resumed:
        // App resumed - mark as active again
        if (!_hasLeftGame) {
          _markPlayerAsInRoom();
        }
        break;
      case AppLifecycleState.detached:
        // App being destroyed - leave room
        _leaveRoom();
        break;
    }
  }

  // Mark current player as in room
  Future<void> _markPlayerAsInRoom() async {
    if (_hasLeftGame) return;

    try {
      final pocketbase = await pbService.pb;
      final updateData = <String, dynamic>{};

      if (widget.isPlayerX) {
        updateData['playerXInRoom'] = true;
        updateData['playerXLastSeen'] = DateTime.now().toIso8601String();
      } else {
        updateData['playerOInRoom'] = true;
        updateData['playerOLastSeen'] = DateTime.now().toIso8601String();
      }

      await pocketbase
          .collection('rooms')
          .update(widget.roomId, body: updateData);
      print("✅ Marked player as in room");
    } catch (e) {
      print("❌ Failed to mark player as in room: $e");
    }
  }

  // Leave room - mark player as left
  Future<void> _leaveRoom() async {
    if (_hasLeftGame) return; // Prevent duplicate calls

    _hasLeftGame = true;

    try {
      final pocketbase = await pbService.pb;
      final updateData = <String, dynamic>{};

      if (widget.isPlayerX) {
        updateData['playerXInRoom'] = false;
        updateData['playerXLeftAt'] = DateTime.now().toIso8601String();
      } else {
        updateData['playerOInRoom'] = false;
        updateData['playerOLeftAt'] = DateTime.now().toIso8601String();
      }

      await pocketbase
          .collection('rooms')
          .update(widget.roomId, body: updateData);
      print("🚪 Player left room");
    } catch (e) {
      print("❌ Failed to mark player as left: $e");
    }
  }

  void _initAnimations() {
    _turnIndicatorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _timerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _restartController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _leaveController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _turnIndicatorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _turnIndicatorController,
        curve: Curves.elasticOut,
      ),
    );

    _timerWarningAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _restartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _restartController, curve: Curves.bounceOut),
    );

    _leaveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _leaveController, curve: Curves.easeInOut),
    );

    _turnIndicatorController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _totalSeconds++;
        });
      }
    });
  }

  void _startTurnTimer() {
    _turnSeconds = 30;
    _turnTimer?.cancel();
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _turnSeconds--;
          if (_turnSeconds <= 10) {
            _timerController.repeat(reverse: true);
          }
          if (_turnSeconds <= 0) {
            _handleTimeOut();
          }
        });
      }
    });
  }

  void _handleTimeOut() {
    // In multiplayer, we might want to handle timeouts differently
    // For now, just reset the timer
    _startTurnTimer();
    _turnIndicatorController.reset();
    _turnIndicatorController.forward();
    _timerController.reset();
  }

  Future<void> _initializeGame() async {
    await _loadRoomData();
    await _setupRealtime();
    _startGameTimer();
    _startTurnTimer();
  }

  // Convert flat board index to 3D coordinates
  void _convertFlatTo3D(List<List<String>> smallBoards, List<String> bigBoard) {
    // Reset board
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        for (int k = 0; k < 9; k++) {
          board[i][j][k] = "";
        }
        bigBoardStatus[i][j] = "";
      }
    }

    // Convert flat structure to 3D
    for (int flatIndex = 0; flatIndex < 9; flatIndex++) {
      int bigRow = flatIndex ~/ 3;
      int bigCol = flatIndex % 3;

      // Set big board status
      bigBoardStatus[bigRow][bigCol] = bigBoard[flatIndex];

      // Set small board cells
      for (int cellIndex = 0; cellIndex < 9; cellIndex++) {
        board[bigRow][bigCol][cellIndex] = smallBoards[flatIndex][cellIndex];
      }
    }
  }

  // Convert 3D coordinates to flat index
  int _convert3DToFlat(int bigRow, int bigCol) {
    return bigRow * 3 + bigCol;
  }

  // Convert small row/col to cell index
  int _convertSmallCoords(int smallRow, int smallCol) {
    return smallRow * 3 + smallCol;
  }

  // Helper method to safely parse JSON arrays
  List<List<String>> _parseSmallBoards(dynamic data) {
    try {
      if (data == null || data.toString().isEmpty || data.toString() == '[]') {
        print("⚠️ SmallBoards data is null/empty, using empty board");
        return List.generate(9, (index) => List.filled(9, ''));
      }

      dynamic parsedData;
      if (data is String) {
        parsedData = jsonDecode(data);
      } else {
        parsedData = data;
      }

      if (parsedData is List) {
        final result = parsedData.map((board) {
          if (board is List) {
            return List<String>.from(
              board.map((cell) => cell?.toString() ?? ''),
            );
          } else {
            return List<String>.filled(9, '');
          }
        }).toList();

        // Ensure we have exactly 9 boards with 9 cells each
        while (result.length < 9) {
          result.add(List<String>.filled(9, ''));
        }

        for (int i = 0; i < result.length; i++) {
          while (result[i].length < 9) {
            result[i].add('');
          }
        }

        print("✅ Successfully parsed smallBoards with ${result.length} boards");
        return result;
      }
    } catch (e) {
      print("❌ Error parsing smallBoards: $e, data: $data");
    }

    return List.generate(9, (index) => List.filled(9, ''));
  }

  // Helper method to safely parse big board
  List<String> _parseBigBoard(dynamic data) {
    try {
      if (data == null || data.toString().isEmpty || data.toString() == '[]') {
        print("⚠️ BigBoard data is null/empty, using empty board");
        return List.filled(9, '');
      }

      dynamic parsedData;
      if (data is String) {
        parsedData = jsonDecode(data);
      } else {
        parsedData = data;
      }

      if (parsedData is List) {
        final result = List<String>.from(
          parsedData.map((cell) => cell?.toString() ?? ''),
        );

        // Ensure we have exactly 9 positions
        while (result.length < 9) {
          result.add('');
        }

        print("✅ Successfully parsed bigBoard with ${result.length} positions");
        return result;
      }
    } catch (e) {
      print("❌ Error parsing bigBoard: $e, data: $data");
    }

    return List.filled(9, '');
  }

  // Check if current user is room creator
  bool _isRoomCreator() {
    final myUserId = pbService.getCurrentUserId();
    return roomCreatorId == myUserId;
  }

  Future<void> _loadRoomData() async {
    try {
      print("🔄 Loading room data...");
      final pocketbase = await pbService.pb;
      final room = await pocketbase.collection('rooms').getOne(widget.roomId);

      print("=== 📊 LOADING ROOM DATA ===");
      print("Raw smallBoards: ${room.data['smallBoards']}");
      print("Raw bigBoard: ${room.data['bigBoard']}");
      print("Current turn: ${room.data['currentTurn']}");
      print("Active board: ${room.data['activeBoard']}");
      print("Game round: ${room.data['gameRound'] ?? 1}");
      print("Waiting restart: ${room.data['waitingRestart'] ?? false}");
      print("Restart requested by: ${room.data['restartRequestedBy']}");
      print("Created by: ${room.data['createdBy']}");
      print("Status: ${room.data['status']}");

      // Load room creator ID
      final newRoomCreatorId = room.data['createdBy']?.toString();

      // Check opponent room status
      bool opponentInRoom = true;
      if (widget.isPlayerX) {
        opponentInRoom = room.data['playerOInRoom'] ?? true;
      } else {
        opponentInRoom = room.data['playerXInRoom'] ?? true;
      }

      // Load small boards state with better parsing
      final newSmallBoards = _parseSmallBoards(room.data['smallBoards']);

      // Load big board state with better parsing
      final newBigBoard = _parseBigBoard(room.data['bigBoard']);

      // Load current turn
      final newCurrentTurn = room.data['currentTurn']?.toString() ?? 'X';

      // Load active board and convert to 3D coordinates
      final activeBoard = room.data['activeBoard'] ?? -1;
      int? newActiveBigRow;
      int? newActiveBigCol;

      if (activeBoard != -1) {
        newActiveBigRow = activeBoard ~/ 3;
        newActiveBigCol = activeBoard % 3;
      }

      // Load opponent name - use consistent naming with room screen
      String? newOpponentName;
      if (widget.isPlayerX) {
        newOpponentName = room.data['playerOName']?.toString() ?? 'Player O';
      } else {
        newOpponentName = room.data['playerXName']?.toString() ?? 'Player X';
      }

      // Load restart state
      final newIsWaitingRestart = room.data['waitingRestart'] ?? false;
      final newGameRound = room.data['gameRound'] ?? 1;
      final newRestartRequestedBy = room.data['restartRequestedBy']?.toString();

      // Convert and apply updates to state
      _convertFlatTo3D(newSmallBoards, newBigBoard);

      setState(() {
        currentPlayer = newCurrentTurn;
        activeBigRow = newActiveBigRow;
        activeBigCol = newActiveBigCol;
        opponentName = newOpponentName;
        isGameLoaded = true;
        isProcessingMove = false; // Reset processing flag
        isWaitingRestart = newIsWaitingRestart;
        gameRound = newGameRound;
        restartRequestedBy = newRestartRequestedBy;
        isOpponentInRoom = opponentInRoom;
        roomCreatorId = newRoomCreatorId;
      });

      _checkWinners();

      // Start restart animation if needed
      if (isWaitingRestart) {
        _restartController.forward();
      } else {
        _restartController.reset();
      }

      print("=== 📈 PARSED DATA ===");
      print("Current turn: $currentPlayer");
      print("Active board: $activeBigRow, $activeBigCol");
      print("Opponent: $opponentName");
      print("Game round: $gameRound");
      print("Waiting restart: $isWaitingRestart");
      print("Restart requested by: $restartRequestedBy");
      print("Opponent in room: $isOpponentInRoom");
      print("Room creator: $roomCreatorId");
      print("Am I creator: ${_isRoomCreator()}");
      print("=================");

      print("✅ Game loaded successfully");
    } catch (e) {
      print("❌ Failed to load room: $e");
      if (mounted) {
        _showMessage("Gagal memuat data room", isError: true);
      }
    }
  }

  Future<void> _setupRealtime() async {
    if (isSubscribed) {
      print("⚠️ Already subscribed to realtime updates");
      return;
    }

    try {
      print("🔌 Setting up realtime subscription for room: ${widget.roomId}");

      // Clean up any existing subscription first
      await _cleanupRealtime();

      // Add small delay to ensure clean state
      await Future.delayed(const Duration(milliseconds: 100));

      final pocketbase = await pbService.pb;

      _unsubscribeFunc = await pocketbase.collection('rooms').subscribe(
        widget.roomId,
        (e) async {
          if (!mounted) {
            print("⚠️ Widget not mounted, ignoring realtime update");
            return;
          }

          print("=== 📡 REALTIME UPDATE ===");
          print("Action: ${e.action}");
          print("Record ID: ${e.record?.id}");

          if (e.action == 'update' && e.record != null) {
            // Add small delay to prevent race conditions
            await Future.delayed(const Duration(milliseconds: 50));
            _handleRealtimeUpdate(e.record!.data);
          }
          print("=== 🔚 END REALTIME UPDATE ===");
        },
      );

      isSubscribed = true;
      print("✅ Realtime subscription established successfully");
    } catch (e) {
      print("❌ Error setting up realtime subscription: $e");
      isSubscribed = false;

      // Retry after delay
      if (mounted) {
        print("🔄 Retrying realtime setup in 2 seconds...");
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _setupRealtime();
          }
        });
      }
    }
  }

  Future<void> _cleanupRealtime() async {
    try {
      if (_unsubscribeFunc != null) {
        await _unsubscribeFunc!();
        _unsubscribeFunc = null;
        print("🧹 Cleaned up previous realtime subscription");
      }

      isSubscribed = false;
    } catch (e) {
      print("⚠️ Error during realtime cleanup: $e");
      // Ignore cleanup errors but ensure state is reset
      _unsubscribeFunc = null;
      isSubscribed = false;
    }
  }

  void _handleRealtimeUpdate(Map<String, dynamic> data) {
    try {
      print("=== 🔄 HANDLING REALTIME UPDATE ===");
      print("Received data keys: ${data.keys.toList()}");
      print("Current processing state: $isProcessingMove");

      bool hasChanges = false;

      // Parse small boards with better error handling
      final newSmallBoards = _parseSmallBoards(data['smallBoards']);
      final newBigBoard = _parseBigBoard(data['bigBoard']);

      // Update other fields
      final newTurn = data['currentTurn']?.toString() ?? 'X';
      final activeBoard = data['activeBoard'] ?? -1;

      int? newActiveBigRow;
      int? newActiveBigCol;

      if (activeBoard != -1) {
        newActiveBigRow = activeBoard ~/ 3;
        newActiveBigCol = activeBoard % 3;
      }

      // Check for restart state changes
      final newIsWaitingRestart = data['waitingRestart'] ?? false;
      final newGameRound = data['gameRound'] ?? gameRound;
      final newRestartRequestedBy = data['restartRequestedBy']?.toString();
      final newWinner = data['winner']; // Check if winner was reset

      // Update room creator if available
      final newRoomCreatorId = data['createdBy']?.toString() ?? roomCreatorId;

      // Check if opponent left room
      bool newOpponentInRoom = true;
      if (widget.isPlayerX) {
        newOpponentInRoom = data['playerOInRoom'] ?? true;
      } else {
        newOpponentInRoom = data['playerXInRoom'] ?? true;
      }

      // Handle opponent leaving room
      if (isOpponentInRoom && !newOpponentInRoom && !hasShownLeaveDialog) {
        print("🚪 Opponent left the room!");
        _handleOpponentLeft();
        hasChanges = true;
      } else if (!isOpponentInRoom && newOpponentInRoom) {
        print("🚪 Opponent returned to room!");
        _handleOpponentReturned();
        hasChanges = true;
      }

      if (newTurn != currentPlayer) {
        print("🔄 Turn changed from $currentPlayer to $newTurn");
        hasChanges = true;
      }

      if (newActiveBigRow != activeBigRow || newActiveBigCol != activeBigCol) {
        print(
          "🔄 ActiveBoard changed from $activeBigRow,$activeBigCol to $newActiveBigRow,$newActiveBigCol",
        );
        hasChanges = true;
      }

      // IMPORTANT: Handle game round changes (restart detection)
      if (newGameRound != gameRound) {
        print("🔄 Game round changed from $gameRound to $newGameRound");

        // If game round changed (restart happened), dismiss all dialogs and reset game state
        if (newGameRound > gameRound) {
          print("🔄 Game restarted! Resetting all states...");

          if (_isGameOverDialogShowing) {
            Navigator.of(context, rootNavigator: true).pop();
            _isGameOverDialogShowing = false;
          }
          if (_isRestartDialogShowing) {
            Navigator.of(context, rootNavigator: true).pop();
            _isRestartDialogShowing = false;
          }

          // Reset winner state since this is a new game
          winner = null;

          // Reset processing flags
          isProcessingMove = false;
          isWaitingRestart = false;
          restartRequestedBy = null;

          // Show success message
          _showMessage("🎮 Game baru dimulai! Round $newGameRound");

          // Restart timers
          _totalSeconds = 0;
          _startGameTimer();
          _startTurnTimer();

          // Reset animations
          _restartController.reset();
          _turnIndicatorController.reset();
          _turnIndicatorController.forward();
          _timerController.reset();
        }

        hasChanges = true;
      }

      // Handle restart state changes
      if (newIsWaitingRestart != isWaitingRestart) {
        print(
          "🔄 Restart state changed from $isWaitingRestart to $newIsWaitingRestart",
        );

        // If restart is no longer waiting, dismiss any open restart dialog
        if (!newIsWaitingRestart && _isRestartDialogShowing) {
          Navigator.of(context, rootNavigator: true).pop();
          _isRestartDialogShowing = false;
        }

        hasChanges = true;
      }

      if (newRestartRequestedBy != restartRequestedBy) {
        print(
          "🔄 Restart requester changed from $restartRequestedBy to $newRestartRequestedBy",
        );
        hasChanges = true;
      }

      if (newRoomCreatorId != roomCreatorId) {
        print("🔄 Room creator updated: $newRoomCreatorId");
        hasChanges = true;
      }

      // Update opponent name if needed
      String? newOpponentName = opponentName;
      if (widget.isPlayerX &&
          data['playerOName'] != null &&
          data['playerOName'] != opponentName) {
        newOpponentName = data['playerOName'].toString();
        hasChanges = true;
      } else if (!widget.isPlayerX &&
          data['playerXName'] != null &&
          data['playerXName'] != opponentName) {
        newOpponentName = data['playerXName'].toString();
        hasChanges = true;
      }

      if (hasChanges || isProcessingMove) {
        print("🔄 Applying realtime changes to UI...");
        print("🔄 Resetting processing flag from $isProcessingMove to false");

        // Convert flat to 3D structure
        _convertFlatTo3D(newSmallBoards, newBigBoard);

        setState(() {
          currentPlayer = newTurn;
          activeBigRow = newActiveBigRow;
          activeBigCol = newActiveBigCol;
          if (newOpponentName != null) {
            opponentName = newOpponentName;
          }
          isWaitingRestart = newIsWaitingRestart;
          gameRound = newGameRound;
          restartRequestedBy = newRestartRequestedBy;
          isOpponentInRoom = newOpponentInRoom;
          roomCreatorId = newRoomCreatorId;
          // IMPORTANT: Always reset processing flag on ANY realtime update
          isProcessingMove = false;
        });

        // Handle restart animation (only if still waiting)
        if (isWaitingRestart) {
          _restartController.forward();

          // Show restart request dialog only if room creator requested it and current user is not creator
          final myUserId = pbService.getCurrentUserId();
          if (newRestartRequestedBy != null &&
              newRestartRequestedBy != myUserId &&
              newRestartRequestedBy == roomCreatorId &&
              !_isRestartDialogShowing) {
            print("🔄 Room creator requested restart, showing dialog");
            _showRestartRequestDialog();
          }
        } else {
          _restartController.reset();
        }

        // Only check winners if this is not a fresh restart
        if (newGameRound <= gameRound || winner != null) {
          _checkWinners();
        }

        print("✅ UI updated via realtime! Processing flag reset.");

        // Reset timer animations only if not during restart
        if (newGameRound <= gameRound) {
          _startTurnTimer();
          _turnIndicatorController.reset();
          _turnIndicatorController.forward();
          _timerController.reset();
        }
      } else {
        print("ℹ️ No changes detected in realtime update");
      }

      print("=== 🔚 END HANDLING REALTIME UPDATE ===");
    } catch (parseError) {
      print("❌ Error parsing realtime data: $parseError");

      // Always reset processing flag on error
      setState(() {
        isProcessingMove = false;
      });

      // Fallback: reload data from server
      print("🔄 Falling back to reload from server...");
      _loadRoomData();
    }
  }

  // Handle when opponent leaves room
  void _handleOpponentLeft() {
    if (!mounted || hasShownLeaveDialog) return;

    setState(() {
      isOpponentInRoom = false;
    });

    _leaveController.forward();
    hasShownLeaveDialog = true;

    // Show notification
    _showMessage(
      "🚪 ${opponentName ?? 'Opponent'} telah keluar dari room",
      isError: true,
    );

    // Show dialog
    _showOpponentLeftDialog();
  }

  // Handle when opponent returns to room
  void _handleOpponentReturned() {
    if (!mounted) return;

    setState(() {
      isOpponentInRoom = true;
    });

    _leaveController.reverse();
    hasShownLeaveDialog = false;

    // Show notification
    _showMessage(
      "🚪 ${opponentName ?? 'Opponent'} kembali ke room!",
      isError: false,
    );
  }

  // Show dialog when opponent left
  void _showOpponentLeftDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D1B69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Player Left Room',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${opponentName ?? "Your opponent"} has left the room.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can wait for them to return or leave the room.',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _exitToMainMenu(); // Exit to main menu
              },
              child: const Text(
                'Leave Room',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Continue waiting
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A0DAD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Wait'),
            ),
          ],
        );
      },
    );
  }

  // Build leave status indicator
  Widget _buildLeaveStatus() {
    if (isOpponentInRoom) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _leaveAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _leaveAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.exit_to_app, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Player Left Room',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${opponentName ?? "Opponent"} has left the room',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.info_outline, color: Colors.orange, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  // Exit to main menu
  Future<void> _exitToMainMenu() async {
    await _leaveRoom();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Show restart request dialog when room creator requests restart
  void _showRestartRequestDialog() {
    if (!mounted || _isRestartDialogShowing) return;

    _isRestartDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D1B69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.refresh, color: const Color(0xFF4CAF50), size: 28),
              const SizedBox(width: 12),
              const Text(
                'Restart Game?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Room creator wants to start a new game.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Do you want to play another round?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _isRestartDialogShowing = false;
                Navigator.of(context).pop(); // Close dialog
                _rejectRestart();
              },
              child: const Text(
                'No, Thanks',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _isRestartDialogShowing = false;
                Navigator.of(context).pop(); // Close dialog
                _acceptRestart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Yes, Play Again!'),
            ),
          ],
        );
      },
    ).then((_) {
      _isRestartDialogShowing = false;
    });
  }

  // Enhanced draw detection system
  // Check if small board is full (for draw detection)
  bool _isSmallBoardFull(List<String> boardSection) {
    return boardSection.every((cell) => cell.isNotEmpty);
  }

  // Check if player wins in small board (list of 9 cells)
  bool _checkSmallBoardWin(List<String> boardSection, String player) {
    List<List<int>> winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6], // diagonals
    ];

    for (var pattern in winPatterns) {
      if (boardSection[pattern[0]] == player &&
          boardSection[pattern[1]] == player &&
          boardSection[pattern[2]] == player) {
        return true;
      }
    }
    return false;
  }

  // Check if small board is drawn
  bool _checkSmallBoardDraw(List<String> boardSection) {
    // Board is drawn if it's full and no player has won
    if (!_isSmallBoardFull(boardSection)) return false;

    return !_checkSmallBoardWin(boardSection, 'X') &&
        !_checkSmallBoardWin(boardSection, 'O');
  }

  // Check if player wins on the big board
  bool _checkBigBoardWin(List<List<String>> bigBoard, String player) {
    // Check rows
    for (int i = 0; i < 3; i++) {
      if (bigBoard[i][0] == player &&
          bigBoard[i][1] == player &&
          bigBoard[i][2] == player) {
        return true;
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (bigBoard[0][i] == player &&
          bigBoard[1][i] == player &&
          bigBoard[2][i] == player) {
        return true;
      }
    }

    // Check diagonals
    if (bigBoard[0][0] == player &&
        bigBoard[1][1] == player &&
        bigBoard[2][2] == player) {
      return true;
    }

    if (bigBoard[0][2] == player &&
        bigBoard[1][1] == player &&
        bigBoard[2][0] == player) {
      return true;
    }

    return false;
  }

  // Check if big board is drawn
  bool _checkBigBoardDraw() {
    // Check if all big board positions are filled (either won by someone or drawn)
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (bigBoardStatus[i][j].isEmpty) {
          return false; // Still has empty positions
        }
      }
    }

    // All positions filled, check if no one won the big board
    return !_checkBigBoardWin(bigBoardStatus, 'X') &&
        !_checkBigBoardWin(bigBoardStatus, 'O');
  }

  void _checkWinners() {
    // Check big board win for X
    if (_checkBigBoardWin(bigBoardStatus, 'X')) {
      if (winner != 'X') {
        winner = 'X';
        print("🏆 Winner found: X");
        if (mounted && !_isGameOverDialogShowing) {
          // Check dialog flag
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isGameOverDialogShowing) {
              // Double check
              _showGameOverDialog(
                winner == (widget.isPlayerX ? 'X' : 'O')
                    ? "🎉 Kamu Menang!"
                    : "😔 $opponentName Menang!",
              );
            }
          });
        }
      }
      return;
    }

    // Check big board win for O
    if (_checkBigBoardWin(bigBoardStatus, 'O')) {
      if (winner != 'O') {
        winner = 'O';
        print("🏆 Winner found: O");
        if (mounted && !_isGameOverDialogShowing) {
          // Check dialog flag
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isGameOverDialogShowing) {
              // Double check
              _showGameOverDialog(
                winner == (widget.isPlayerX ? 'X' : 'O')
                    ? "🎉 Kamu Menang!"
                    : "😔 $opponentName Menang!",
              );
            }
          });
        }
      }
      return;
    }

    // Check for big board draw
    if (winner == null && _checkBigBoardDraw()) {
      winner = 'Draw';
      print("🤝 Big board is a draw");
      if (mounted && !_isGameOverDialogShowing) {
        // Check dialog flag
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && !_isGameOverDialogShowing) {
            // Double check
            _showGameOverDialog("🤝 Permainan seri!");
          }
        });
      }
    }
  }

  void _handleMove(int bigRow, int bigCol, int smallRow, int smallCol) async {
    // Prevent duplicate moves
    if (isProcessingMove || isWaitingRestart) {
      print(
        "⚠️ Move blocked - Processing: $isProcessingMove, Waiting restart: $isWaitingRestart",
      );
      if (isWaitingRestart) {
        _showMessage("Game sedang menunggu restart", isError: true);
      } else {
        _showMessage("Sedang memproses move...", isError: true);
      }
      return;
    }

    // Check if opponent is in room
    if (!isOpponentInRoom) {
      _showMessage("Opponent telah keluar dari room", isError: true);
      return;
    }

    // Convert 3D coordinates to flat indices
    int boardIndex = _convert3DToFlat(bigRow, bigCol);
    int cellIndex = _convertSmallCoords(smallRow, smallCol);

    // Basic validations
    if (board[bigRow][bigCol][smallRow * 3 + smallCol].isNotEmpty ||
        bigBoardStatus[bigRow][bigCol].isNotEmpty ||
        winner != null ||
        !isGameLoaded) {
      print("⚠️ Move blocked - Cell occupied or board won or game over");
      return;
    }

    // Turn validation
    final mySymbol = widget.isPlayerX ? 'X' : 'O';
    if (currentPlayer != mySymbol) {
      print("⚠️ Not your turn - Current: $currentPlayer, My symbol: $mySymbol");
      _showMessage("Belum giliran kamu!", isError: true);
      return;
    }

    // Active board validation
    if (activeBigRow != null && activeBigCol != null) {
      if (bigRow != activeBigRow || bigCol != activeBigCol) {
        print(
          "⚠️ Wrong board - Active: $activeBigRow,$activeBigCol, Clicked: $bigRow,$bigCol",
        );
        _showMessage("Hanya bisa main di kotak yang aktif!", isError: true);
        return;
      }
    }

    // Set processing flag immediately with UI feedback
    if (mounted) {
      setState(() {
        isProcessingMove = true;
      });
    }

    print(
      "🎯 Making move at board $bigRow,$bigCol, cell $smallRow,$smallCol with symbol $mySymbol",
    );

    try {
      // Convert current 3D board back to flat structure for server
      List<List<String>> flatSmallBoards = [];
      List<String> flatBigBoard = [];

      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          flatSmallBoards.add(List<String>.from(board[i][j]));
          flatBigBoard.add(bigBoardStatus[i][j]);
        }
      }

      // Make the move on flat structure
      flatSmallBoards[boardIndex][cellIndex] = mySymbol;

      print("📝 After making move:");
      print("Board $boardIndex, Cell $cellIndex = $mySymbol");

      // Enhanced small board resolution with draw detection
      if (_checkSmallBoardWin(flatSmallBoards[boardIndex], mySymbol)) {
        // Player won this small board
        flatBigBoard[boardIndex] = mySymbol;
        // Fill entire small board with winner symbol for visual clarity
        flatSmallBoards[boardIndex] = List.generate(9, (_) => mySymbol);
        print("🏆 Small board $boardIndex won by $mySymbol");
      } else if (_checkSmallBoardDraw(flatSmallBoards[boardIndex])) {
        // Small board is drawn
        flatBigBoard[boardIndex] = 'D'; // D for Draw
        print("🤝 Small board $boardIndex is drawn");
      }

      // Determine next active board
      int newActiveBoard;
      if (flatBigBoard[cellIndex] != '') {
        // Target board is already resolved (won or drawn), so next player can play anywhere
        newActiveBoard = -1;
        print(
          "🎯 Next player can play anywhere (target board $cellIndex already resolved)",
        );
      } else {
        // Next player must play in the board corresponding to this cell
        newActiveBoard = cellIndex;
        print("🎯 Next player must play in board $newActiveBoard");
      }

      final newTurn = currentPlayer == 'X' ? 'O' : 'X';

      // Prepare data for server update - consistent with room screen structure
      final updateData = {
        'smallBoards': jsonEncode(flatSmallBoards),
        'bigBoard': jsonEncode(flatBigBoard),
        'currentTurn': newTurn,
        'activeBoard': newActiveBoard,
        'lastMove': DateTime.now().toIso8601String(),
        'lastMoveBy': pbService.getCurrentUserId(),
        // Keep status as 'playing' during game
        'status': 'playing',
      };

      print("📤 Sending to server:");
      print("Turn: $currentPlayer -> $newTurn");
      print(
        "Active Board: ${_convert3DToFlat(activeBigRow ?? -1, activeBigCol ?? -1)} -> $newActiveBoard",
      );
      print("Move by: ${updateData['lastMoveBy']}");
      print("Status: playing");

      // Update to server with timeout
      final pocketbase = await pbService.pb;
      final updatedRecord = await pocketbase
          .collection('rooms')
          .update(widget.roomId, body: updateData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: Server tidak merespons');
            },
          );

      print("✅ Move sent to server successfully");
      print("📄 Server response: ${updatedRecord.id}");

      // Don't reset processing flag here - let realtime handler do it
      print("⏳ Waiting for realtime confirmation...");

      // Add timeout fallback for realtime
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && isProcessingMove) {
          print("⚠️ Realtime timeout, forcing processing flag reset");
          setState(() {
            isProcessingMove = false;
          });
          _loadRoomData(); // Reload state from server
        }
      });
    } catch (e) {
      print("❌ Failed to send move to server: $e");

      // Reset processing flag on error immediately
      if (mounted) {
        setState(() {
          isProcessingMove = false;
        });
      }

      _showMessage("Gagal melakukan langkah: ${e.toString()}", isError: true);

      // Reload current state from server on error
      await _loadRoomData();
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 3 : 2),
        action: isError
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _loadRoomData(),
              )
            : null,
      ),
    );
  }

  // Modified game over dialog - only show restart option to room creator
  void _showGameOverDialog(String message) {
    if (_isGameOverDialogShowing) return; // Prevent duplicate dialogs

    _isGameOverDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              winner == 'Draw'
                  ? Icons.handshake
                  : (winner == (widget.isPlayerX ? 'X' : 'O')
                        ? Icons.celebration
                        : Icons.sentiment_dissatisfied),
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Game Over',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Round $gameRound completed!',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        widget.isPlayerX ? 'You' : (opponentName ?? 'Opponent'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'X',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Column(
                    children: [
                      Text(
                        widget.isPlayerX ? (opponentName ?? 'Opponent') : 'You',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'O',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Show creator info if current user is not creator
            if (!_isRoomCreator())
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only the room creator can start a new game',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              _isGameOverDialogShowing = false; // Reset flag
              Navigator.of(context).pop(); // Close dialog
              _exitToMainMenu(); // Exit to main menu
            },
            icon: const Icon(Icons.exit_to_app, color: Colors.grey, size: 20),
            label: const Text(
              'Leave Room',
              style: TextStyle(color: Colors.grey),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          // Only show "Play Again" button to room creator
          if (_isRoomCreator())
            ElevatedButton.icon(
              onPressed: () {
                _isGameOverDialogShowing = false; // Reset flag
                Navigator.of(context).pop(); // Close dialog
                _requestRestart();
              },
              icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
              label: const Text(
                'Play Again',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 5,
              ),
            ),
        ],
      ),
    ).then((_) {
      // Reset flag when dialog is dismissed
      _isGameOverDialogShowing = false;
    });
  }

  // Modified restart functionality - only room creator can request restart
  // Modified restart functionality - only room creator can request restart
  Future<void> _requestRestart() async {
    // Check if user is room creator
    if (!_isRoomCreator()) {
      print("❌ Restart blocked - User is not room creator");
      _showMessage(
        "Hanya pembuat room yang bisa memulai game baru",
        isError: true,
      );
      return;
    }

    if (isProcessingMove || isWaitingRestart) {
      print(
        "⚠️ Restart blocked - Processing: $isProcessingMove, Waiting: $isWaitingRestart",
      );
      _showMessage("Restart sudah dalam proses", isError: true);
      return;
    }

    setState(() {
      isProcessingMove = true;
    });

    try {
      print("🔄 Room creator requesting game restart...");

      final myUserId = pbService.getCurrentUserId();
      final pocketbase = await pbService.pb;

      // Check current room state
      final room = await pocketbase.collection('rooms').getOne(widget.roomId);
      final currentWaitingRestart = room.data['waitingRestart'] ?? false;
      final currentRestartRequestedBy = room.data['restartRequestedBy'];

      print(
        "Current restart state: waiting=$currentWaitingRestart, requestedBy=$currentRestartRequestedBy",
      );
      print("My user ID: $myUserId");

      // If already waiting for restart and I requested it, just show message
      if (currentWaitingRestart && currentRestartRequestedBy == myUserId) {
        print("⚠️ I already requested restart");
        _showMessage("Kamu sudah meminta restart, tunggu lawan", isError: true);
        setState(() {
          isProcessingMove = false;
        });
        return;
      }

      // If opponent already requested restart (shouldn't happen since only creator can request)
      // OR if both agreed, perform restart immediately
      if (currentWaitingRestart && currentRestartRequestedBy != myUserId) {
        print(
          "✅ Opponent somehow requested restart or both agreed, performing restart",
        );
        await _performRestart();
      } else {
        // Room creator making initial restart request
        print("📤 Room creator making initial restart request");
        await pocketbase
            .collection('rooms')
            .update(
              widget.roomId,
              body: {
                'waitingRestart': true,
                'restartRequestedBy': myUserId,
                'restartRequestTime': DateTime.now().toIso8601String(),
              },
            );

        _showMessage("🎮 Restart diminta! Menunggu ${opponentName}...");

        setState(() {
          isWaitingRestart = true;
          restartRequestedBy = myUserId;
          isProcessingMove = false;
        });

        _restartController.forward();
        print("✅ Restart request sent successfully");
      }
    } catch (e) {
      print("❌ Failed to request restart: $e");
      _showMessage("Gagal meminta restart: ${e.toString()}", isError: true);

      setState(() {
        isProcessingMove = false;
        isWaitingRestart = false;
      });
    }
  }

  Future<void> _acceptRestart() async {
    if (isProcessingMove) return;

    setState(() {
      isProcessingMove = true;
    });

    try {
      print("✅ Accepting restart request from room creator");
      await _performRestart();
    } catch (e) {
      print("❌ Failed to accept restart: $e");
      _showMessage("Gagal menerima restart", isError: true);

      setState(() {
        isProcessingMove = false;
      });
    }
  }

  Future<void> _rejectRestart() async {
    if (isProcessingMove) return;

    setState(() {
      isProcessingMove = true;
    });

    try {
      print("❌ Rejecting restart request");
      final pocketbase = await pbService.pb;
      await pocketbase
          .collection('rooms')
          .update(
            widget.roomId,
            body: {
              'waitingRestart': false,
              'restartRequestedBy': null,
              'restartRequestTime': null,
            },
          );

      _showMessage("Restart ditolak");

      setState(() {
        isWaitingRestart = false;
        restartRequestedBy = null;
        isProcessingMove = false;
      });

      _restartController.reset();
    } catch (e) {
      print("❌ Failed to reject restart: $e");
      _showMessage("Gagal menolak restart", isError: true);

      setState(() {
        isProcessingMove = false;
      });
    }
  }

  // Modified cancel restart - only room creator can cancel their own request
  Future<void> _cancelRestart() async {
    if (isProcessingMove) return;

    // Only room creator can cancel restart
    if (!_isRoomCreator()) {
      _showMessage(
        "Hanya pembuat room yang bisa membatalkan restart",
        isError: true,
      );
      return;
    }

    setState(() {
      isProcessingMove = true;
    });

    try {
      print("🚫 Room creator canceling restart request");
      final pocketbase = await pbService.pb;
      await pocketbase
          .collection('rooms')
          .update(
            widget.roomId,
            body: {
              'waitingRestart': false,
              'restartRequestedBy': null,
              'restartRequestTime': null,
            },
          );

      _showMessage("Restart request dibatalkan");

      setState(() {
        isWaitingRestart = false;
        restartRequestedBy = null;
        isProcessingMove = false;
      });

      _restartController.reset();
    } catch (e) {
      print("❌ Failed to cancel restart: $e");
      _showMessage("Gagal membatalkan restart", isError: true);

      setState(() {
        isProcessingMove = false;
      });
    }
  }

  Future<void> _performRestart() async {
    try {
      print("🔄 Performing game restart...");

      // Dismiss any open dialogs first
      if (_isGameOverDialogShowing && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _isGameOverDialogShowing = false;
      }
      if (_isRestartDialogShowing && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _isRestartDialogShowing = false;
      }

      final emptySmallBoards = List.generate(9, (index) => List.filled(9, ''));
      final emptyBigBoard = List.filled(9, '');

      final pocketbase = await pbService.pb;

      // IMPORTANT: Get current room state first to maintain consistency
      final currentRoom = await pocketbase
          .collection('rooms')
          .getOne(widget.roomId);
      final currentGameRound = currentRoom.data['gameRound'] ?? 1;
      final newGameRound = currentGameRound + 1;

      print("Current game round: $currentGameRound");
      print("New game round: $newGameRound");

      // Update room with restart data - make sure all fields are properly reset
      await pocketbase
          .collection('rooms')
          .update(
            widget.roomId,
            body: {
              'smallBoards': jsonEncode(emptySmallBoards),
              'bigBoard': jsonEncode(emptyBigBoard),
              'currentTurn': 'X', // Always start with X
              'activeBoard': -1, // Free choice initially
              'winner': null, // Clear winner
              'waitingRestart': false, // No longer waiting
              'restartRequestedBy': null, // Clear restart requester
              'restartRequestTime': null, // Clear restart time
              'gameRound': newGameRound, // Increment round
              'lastMove': DateTime.now().toIso8601String(),
              'gameRestartedAt': DateTime.now().toIso8601String(),
              'status': 'playing', // Ensure status is playing
              // Ensure both players are still marked as in room
              'playerXInRoom': true,
              'playerOInRoom': true,
              'playerXLastSeen': DateTime.now().toIso8601String(),
              'playerOLastSeen': DateTime.now().toIso8601String(),
            },
          );

      print("✅ Server updated successfully with restart data");

      // Reset ALL local state immediately - don't wait for realtime
      // Convert and apply updates to local state immediately
      _convertFlatTo3D(emptySmallBoards, emptyBigBoard);

      setState(() {
        // Game state
        winner = null;
        currentPlayer = 'X';
        activeBigRow = null;
        activeBigCol = null;

        // Restart state
        isWaitingRestart = false;
        restartRequestedBy = null;
        gameRound = newGameRound;

        // Processing flags
        isProcessingMove = false;

        // Timer state
        _totalSeconds = 0;

        // Dialog flags
        _isGameOverDialogShowing = false;
        _isRestartDialogShowing = false;

        // Reset leave state for new game
        hasShownLeaveDialog = false;
      });

      // Reset all animations
      _restartController.reset();
      _leaveController.reset();
      _turnIndicatorController.reset();
      _turnIndicatorController.forward();
      _timerController.reset();

      // Restart timers
      _startGameTimer();
      _startTurnTimer();

      _showMessage("🎮 Game baru dimulai! Round $newGameRound");

      print("✅ Game restarted successfully - Round $newGameRound");
      print("✅ Local state reset completed");
    } catch (e) {
      print("❌ Failed to perform restart: $e");
      _showMessage("Gagal restart game", isError: true);

      setState(() {
        isProcessingMove = false;
      });

      // Fallback: reload room data from server
      await _loadRoomData();
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A0DAD), Color(0xFF8A2BE2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _showExitDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white.withOpacity(0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Total: ${_formatTime(_totalSeconds)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Round $gameRound',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Room creator indicator
                    if (_isRoomCreator())
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.stars,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Host',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOpponentInRoom
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOpponentInRoom
                                      ? Icons.person
                                      : Icons.exit_to_app,
                                  color: isOpponentInRoom
                                      ? Colors.green
                                      : Colors.red,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isOpponentInRoom ? 'In Room' : 'Left',
                                  style: TextStyle(
                                    color: isOpponentInRoom
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 16),

                    if (isProcessingMove)
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white70,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Syncing...',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Multiplayer Game',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String player, String name, bool isActive) {
    // Simplified logic to determine if this player card should show the crown
    final isThisPlayerCreator = () {
      if (roomCreatorId == null) return false;

      final myUserId = pbService.getCurrentUserId();
      final isCurrentUserCreator = roomCreatorId == myUserId;

      // If this is "You" card
      if ((player == "X" && widget.isPlayerX) ||
          (player == "O" && !widget.isPlayerX)) {
        return isCurrentUserCreator;
      }

      // If this is opponent card
      if ((player == "X" && !widget.isPlayerX) ||
          (player == "O" && widget.isPlayerX)) {
        return !isCurrentUserCreator; // Opponent is creator if current user is not
      }

      return false;
    }();

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B69),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Icon(
                          player == "X" ? Icons.person : Icons.person_outline,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    // Crown icon for room creator
                    if (isThisPlayerCreator)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.stars,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Show "Host" label for room creator
                if (isThisPlayerCreator)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Host',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: player == "X"
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      player,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: player == "X" ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTurnIndicator() {
    return AnimatedBuilder(
      animation: _turnIndicatorAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _turnIndicatorAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPlayerCard(
                      "X",
                      widget.isPlayerX ? "You" : (opponentName ?? "Opponent"),
                      currentPlayer == "X",
                    ),
                    _buildPlayerCard(
                      "O",
                      widget.isPlayerX ? (opponentName ?? "Opponent") : "You",
                      currentPlayer == "O",
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getTurnText(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getStatusText(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _timerWarningAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _turnSeconds <= 10
                                ? _timerWarningAnimation.value
                                : 1.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _turnSeconds <= 10
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 16,
                                    color: _turnSeconds <= 10
                                        ? Colors.white
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_turnSeconds',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _turnSeconds <= 10
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getTurnText() {
    if (!isGameLoaded) {
      return 'Loading game...';
    }

    if (isWaitingRestart) {
      return 'Waiting for restart...';
    }

    if (isProcessingMove) {
      return 'Processing move...';
    }

    // Show leave status
    if (!isOpponentInRoom) {
      return 'Opponent left the room';
    }

    if (winner != null) {
      if (winner == 'Draw') {
        return 'Game Seri!';
      }

      final mySymbol = widget.isPlayerX ? 'X' : 'O';
      if (winner == mySymbol) {
        return 'You Win!';
      } else {
        return '${opponentName ?? "Opponent"} Wins!';
      }
    }

    final mySymbol = widget.isPlayerX ? 'X' : 'O';
    if (currentPlayer == mySymbol) {
      return "Your Turn ($mySymbol)";
    } else {
      return "${opponentName ?? "Opponent"}'s Turn ($currentPlayer)";
    }
  }

  String _getStatusText() {
    if (!isGameLoaded || isProcessingMove || winner != null) {
      return '';
    }

    if (isWaitingRestart) {
      // Show different messages based on creator status
      if (_isRoomCreator()) {
        return 'Waiting for opponent to accept restart';
      } else {
        return 'Room creator wants to restart game';
      }
    }

    // Show leave status
    if (!isOpponentInRoom) {
      return 'Game paused - waiting for player';
    }

    if (activeBigRow != null && activeBigCol != null) {
      return 'Must play in board ${activeBigRow! + 1}-${activeBigCol! + 1}';
    } else {
      return 'Free to choose any board';
    }
  }

  // Modified restart request panel - different UI for creator vs non-creator
  Widget _buildRestartRequestPanel() {
    if (!isWaitingRestart) return const SizedBox.shrink();

    final myUserId = pbService.getCurrentUserId();
    final isMyRequest = restartRequestedBy == myUserId;
    final isCreatorRequest = restartRequestedBy == roomCreatorId;

    return AnimatedBuilder(
      animation: _restartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _restartAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      color: const Color(0xFF4CAF50),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    // Crown icon if creator made request
                    if (isCreatorRequest)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.stars, color: Colors.amber, size: 16),
                      ),
                    Expanded(
                      child: Text(
                        isMyRequest
                            ? 'Restart Request Sent'
                            : 'Restart Game Request',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isMyRequest
                      ? 'Waiting for ${opponentName ?? "opponent"} to accept...'
                      : isCreatorRequest
                      ? 'Room creator wants to start a new game.'
                      : '${opponentName ?? "Opponent"} wants to start a new game.',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (isMyRequest && _isRoomCreator())
                  // Show cancel button for room creator who made request
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: isProcessingMove ? null : _cancelRestart,
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'Cancel Request',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  )
                else if (!isMyRequest && isCreatorRequest)
                  // Show accept/decline buttons for non-creator when creator requests
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: isProcessingMove ? null : _rejectRestart,
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text(
                            'Decline',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessingMove ? null : _acceptRestart,
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text(
                            'Accept',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  // If non-creator somehow made request, show info message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Only room creator can initiate restart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D1B69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Leave Multiplayer Room?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: Text(
            'You will leave the current multiplayer room${isWaitingRestart ? ' and cancel the restart request' : ''}. Your opponent will be notified.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[300])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exitToMainMenu();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A0DAD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    print("Disposing multiplayer game screen");
    _leaveRoom();

    _gameTimer?.cancel();
    _turnTimer?.cancel();
    _turnIndicatorController.dispose();
    _timerController.dispose();
    _pulseController.dispose();
    _restartController.dispose();
    _leaveController.dispose();

    // Clean up realtime subscription
    _cleanupRealtime();

    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5800FF), Color(0xFF330066), Color(0xFF1A0033)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildGameHeader(),
                  _buildTurnIndicator(),
                  _buildLeaveStatus(), // Leave status indicator
                  _buildRestartRequestPanel(), // Restart panel
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: UltimateTTTBoard(
                          board: board,
                          onMove: _handleMove,
                          activeBigRow: activeBigRow,
                          activeBigCol: activeBigCol,
                          bigBoardStatus: bigBoardStatus,
                        ),
                      ),
                    ),
                  ),
                  // Enhanced bottom action buttons - only show restart to creator
                  // Replace the existing bottom action buttons section (around line 1500+) with this fixed version:

                  // Enhanced bottom action buttons - only show restart to creator
                  if (winner != null)
                    Container(
                      margin: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        bottom: 20,
                      ),
                      child: Column(
                        children: [
                          // If waiting for restart
                          if (isWaitingRestart)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.orange,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    // Added Flexible to prevent overflow
                                    child: Text(
                                      _isRoomCreator()
                                          ? 'Waiting for opponent to accept restart...'
                                          : 'Room creator requested restart...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign:
                                          TextAlign.center, // Center align text
                                      overflow: TextOverflow
                                          .ellipsis, // Handle overflow gracefully
                                      maxLines:
                                          2, // Allow text to wrap to 2 lines if needed
                                    ),
                                  ),
                                ],
                              ),
                            )
                          // If game finished and not waiting for restart
                          else
                            Column(
                              // Changed from Row to Column for better layout
                              children: [
                                // Only show Play Again button to room creator
                                if (_isRoomCreator())
                                  Container(
                                    width: double.infinity, // Full width button
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ElevatedButton.icon(
                                      onPressed: isProcessingMove
                                          ? null
                                          : _requestRestart,
                                      icon: isProcessingMove
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white70),
                                              ),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.stars,
                                                  color: Colors.amber,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.refresh,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                      label: Text(
                                        isProcessingMove
                                            ? 'Requesting...'
                                            : 'Start New Game',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4CAF50,
                                        ),
                                        disabledBackgroundColor: const Color(
                                          0xFF4CAF50,
                                        ).withOpacity(0.6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 5,
                                      ),
                                    ),
                                  )
                                else
                                  // Show info message for non-creators - fixed layout
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      // Changed to Column for better text layout
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.blue,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.stars,
                                              color: Colors.amber,
                                              size: 14,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Waiting for host to start new game',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                // Leave Room button - now full width and separate
                                Container(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showExitDialog();
                                    },
                                    icon: const Icon(
                                      Icons.exit_to_app,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Leave Room',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red.withOpacity(
                                        0.8,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
