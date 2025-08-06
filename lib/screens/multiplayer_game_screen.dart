import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/pocketbase_service.dart';
import '../widgets/ultimate_ttt_board.dart';

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

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> with TickerProviderStateMixin {
  final pbService = PocketBaseService();
  
  // Convert to 3D board structure for compatibility with UltimateTTTBoard
  late List<List<List<String>>> board; // 3x3 papan besar, tiap elemen 9 kotak kecil
  late List<List<String>> bigBoardStatus; // status papan besar: "X", "O", atau ""
  
  String currentPlayer = "X";
  int? activeBigRow; // papan besar aktif row (0..2) atau null = bebas main dimana saja
  int? activeBigCol;
  
  String? winner;
  String? opponentName;
  bool isGameLoaded = false;
  bool isProcessingMove = false;
  
  // Timers and animations (similar to PvP)
  Timer? _gameTimer;
  int _totalSeconds = 0;
  Timer? _turnTimer;
  int _turnSeconds = 30;

  late AnimationController _turnIndicatorController;
  late AnimationController _timerController;
  late AnimationController _pulseController;

  late Animation<double> _turnIndicatorAnimation;
  late Animation<double> _timerWarningAnimation;
  late Animation<double> _pulseAnimation;
  
  // Add subscription management
  bool isSubscribed = false;

  @override
  void initState() {
    super.initState();
    print("🎮 Ultimate Tic-Tac-Toe started - Room: ${widget.roomId}, IsPlayerX: ${widget.isPlayerX}");
    print("👤 Current user: ${pbService.getCurrentUserInfo()}");
    
    // Initialize 3D board structure
    board = List.generate(
      3,
      (_) => List.generate(3, (_) => List.generate(9, (_) => "")),
    );
    bigBoardStatus = List.generate(3, (_) => List.generate(3, (_) => ""));
    
    activeBigRow = null; // awalnya bebas pilih papan kecil mana saja
    activeBigCol = null;

    _initAnimations();
    _initializeGame();
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
            return List<String>.from(board.map((cell) => cell?.toString() ?? ''));
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
        final result = List<String>.from(parsedData.map((cell) => cell?.toString() ?? ''));
        
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

  Future<void> _loadRoomData() async {
    try {
      print("🔄 Loading room data...");
      final room = await pbService.pb.collection('rooms').getOne(widget.roomId);
      
      print("=== 📊 LOADING ROOM DATA ===");
      print("Raw smallBoards: ${room.data['smallBoards']}");
      print("Raw bigBoard: ${room.data['bigBoard']}");
      print("Current turn: ${room.data['currentTurn']}");
      print("Active board: ${room.data['activeBoard']}");
      
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
      
      // Load opponent name
      String? newOpponentName;
      if (widget.isPlayerX) {
        newOpponentName = room.data['playerOName']?.toString() ?? 'Player O';
      } else {
        newOpponentName = room.data['playerXName']?.toString() ?? 'Player X';
      }
      
      // Convert and apply updates to state
      _convertFlatTo3D(newSmallBoards, newBigBoard);
      
      setState(() {
        currentPlayer = newCurrentTurn;
        activeBigRow = newActiveBigRow;
        activeBigCol = newActiveBigCol;
        opponentName = newOpponentName;
        isGameLoaded = true;
        isProcessingMove = false; // Reset processing flag
      });
      
      _checkWinners();
      
      print("=== 📈 PARSED DATA ===");
      print("Current turn: $currentPlayer");
      print("Active board: $activeBigRow, $activeBigCol");
      print("Opponent: $opponentName");
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
      try {
        await pbService.pb.collection('rooms').unsubscribe();
      } catch (e) {
        // Ignore if not subscribed yet
      }
      
      // Add small delay to ensure clean state
      await Future.delayed(Duration(milliseconds: 100));
      
      await pbService.pb.collection('rooms').subscribe(widget.roomId, (e) async {
        if (!mounted) {
          print("⚠️ Widget not mounted, ignoring realtime update");
          return;
        }
        
        print("=== 📡 REALTIME UPDATE ===");
        print("Action: ${e.action}");
        print("Record ID: ${e.record?.id}");
        
        if (e.action == 'update' && e.record != null) {
          // Add small delay to prevent race conditions
          await Future.delayed(Duration(milliseconds: 50));
          _handleRealtimeUpdate(e.record!.data);
        }
        print("=== 🔚 END REALTIME UPDATE ===");
      });
      
      isSubscribed = true;
      print("✅ Realtime subscription established successfully");
      
    } catch (e) {
      print("❌ Error setting up realtime subscription: $e");
      isSubscribed = false;
      
      // Retry after delay
      if (mounted) {
        print("🔄 Retrying realtime setup in 2 seconds...");
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _setupRealtime();
          }
        });
      }
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
      
      if (newTurn != currentPlayer) {
        print("🔄 Turn changed from $currentPlayer to $newTurn");
        hasChanges = true;
      }
      
      if (newActiveBigRow != activeBigRow || newActiveBigCol != activeBigCol) {
        print("🔄 ActiveBoard changed from $activeBigRow,$activeBigCol to $newActiveBigRow,$newActiveBigCol");
        hasChanges = true;
      }
      
      // Update opponent name if needed
      String? newOpponentName = opponentName;
      if (widget.isPlayerX && data['playerOName'] != null && data['playerOName'] != opponentName) {
        newOpponentName = data['playerOName'].toString();
        hasChanges = true;
      } else if (!widget.isPlayerX && data['playerXName'] != null && data['playerXName'] != opponentName) {
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
          // IMPORTANT: Always reset processing flag on ANY realtime update
          isProcessingMove = false;
        });
        
        _checkWinners();
        print("✅ UI updated via realtime! Processing flag reset.");
        
        // Reset timer animations
        _startTurnTimer();
        _turnIndicatorController.reset();
        _turnIndicatorController.forward();
        _timerController.reset();
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

  // Cek apakah player menang di papan kecil (list 9 kotak string)
  bool checkWin(List<String> boardSection, String player) {
    List<List<int>> wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // baris
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // kolom
      [0, 4, 8], [2, 4, 6], // diagonal
    ];
    for (var pat in wins) {
      if (boardSection[pat[0]] == player &&
          boardSection[pat[1]] == player &&
          boardSection[pat[2]] == player) {
        return true;
      }
    }
    return false;
  }

  // Cek apakah player menang di papan besar
  bool checkBigBoardWin(List<List<String>> bigBoard, String player) {
    for (int i = 0; i < 3; i++) {
      // baris
      if (bigBoard[i][0] == player &&
          bigBoard[i][1] == player &&
          bigBoard[i][2] == player)
        return true;
      // kolom
      if (bigBoard[0][i] == player &&
          bigBoard[1][i] == player &&
          bigBoard[2][i] == player)
        return true;
    }
    // diagonal
    if (bigBoard[0][0] == player &&
        bigBoard[1][1] == player &&
        bigBoard[2][2] == player)
      return true;
    if (bigBoard[0][2] == player &&
        bigBoard[1][1] == player &&
        bigBoard[2][0] == player)
      return true;

    return false;
  }

  void _checkWinners() {
    // Check big board win
    if (checkBigBoardWin(bigBoardStatus, currentPlayer == "X" ? "O" : "X")) {
      String winnerPlayer = currentPlayer == "X" ? "O" : "X";
      if (winner != winnerPlayer) {
        winner = winnerPlayer;
        print("🏆 Winner found: $winner");
        if (mounted) {
          Future.delayed(Duration(milliseconds: 500), () {
            _showGameOverDialog(winner == (widget.isPlayerX ? 'X' : 'O') 
                ? "🎉 Kamu Menang!" 
                : "😔 $opponentName Menang!");
          });
        }
      }
      return;
    }

    // Check for draw (all big board positions filled)
    if (winner == null && bigBoardStatus.expand((e) => e).every((c) => c.isNotEmpty)) {
      winner = 'Draw';
      print("🤝 Game is a draw");
      if (mounted) {
        Future.delayed(Duration(milliseconds: 500), () {
          _showGameOverDialog("🤝 Permainan seri!");
        });
      }
    }
  }

  void _handleMove(int bigRow, int bigCol, int smallRow, int smallCol) async {
    // Prevent duplicate moves
    if (isProcessingMove) {
      print("⚠️ Move already in progress, ignoring");
      _showMessage("Sedang memproses move...", isError: true);
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
        print("⚠️ Wrong board - Active: $activeBigRow,$activeBigCol, Clicked: $bigRow,$bigCol");
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

    print("🎯 Making move at board $bigRow,$bigCol, cell $smallRow,$smallCol with symbol $mySymbol");

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
      
      // Check if this small board is won
      if (checkWin(flatSmallBoards[boardIndex], mySymbol)) {
        flatBigBoard[boardIndex] = mySymbol;
        // Fill entire small board with winner symbol
        flatSmallBoards[boardIndex] = List.generate(9, (_) => mySymbol);
        print("🏆 Small board $boardIndex won by $mySymbol");
      }
      
      // Determine next active board
      int newActiveBoard;
      if (flatBigBoard[cellIndex] != '') {
        // Target board is already won, so next player can play anywhere
        newActiveBoard = -1;
        print("🎯 Next player can play anywhere (target board $cellIndex already won)");
      } else {
        // Next player must play in the board corresponding to this cell
        newActiveBoard = cellIndex;
        print("🎯 Next player must play in board $newActiveBoard");
      }
      
      final newTurn = currentPlayer == 'X' ? 'O' : 'X';
      
      // Prepare data for server update
      final updateData = {
        'smallBoards': jsonEncode(flatSmallBoards),
        'bigBoard': jsonEncode(flatBigBoard),
        'currentTurn': newTurn,
        'activeBoard': newActiveBoard,
        'lastMove': DateTime.now().toIso8601String(),
        'lastMoveBy': pbService.getCurrentUserId(), // Track who made the last move
      };
      
      print("📤 Sending to server:");
      print("Turn: $currentPlayer -> $newTurn");
      print("Active Board: ${_convert3DToFlat(activeBigRow ?? -1, activeBigCol ?? -1)} -> $newActiveBoard");
      print("Move by: ${updateData['lastMoveBy']}");

      // Update to server with timeout
      final updatedRecord = await pbService.pb.collection('rooms').update(
        widget.roomId, 
        body: updateData
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: Server tidak merespons');
        },
      );
      
      print("✅ Move sent to server successfully");
      print("📄 Server response: ${updatedRecord.id}");
      
      // Don't reset processing flag here - let realtime handler do it
      print("⏳ Waiting for realtime confirmation...");
      
      // Add timeout fallback for realtime
      Future.delayed(Duration(seconds: 5), () {
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  void _showGameOverDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Game Over',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetGame() async {
    if (isProcessingMove) return;
    
    setState(() {
      isProcessingMove = true;
    });

    try {
      final emptySmallBoards = List.generate(9, (index) => List.filled(9, ''));
      final emptyBigBoard = List.filled(9, '');
      
      await pbService.pb.collection('rooms').update(widget.roomId, body: {
        'smallBoards': jsonEncode(emptySmallBoards),
        'bigBoard': jsonEncode(emptyBigBoard),
        'currentTurn': 'X',
        'activeBoard': -1,
        'winner': null,
        'lastMove': DateTime.now().toIso8601String(),
      });
      
      // Reset local state
      setState(() {
        winner = null;
        _totalSeconds = 0;
      });
      
      _showMessage("🔄 Game direset!");
      
    } catch (e) {
      print("❌ Gagal reset game: $e");
      _showMessage("Gagal reset game", isError: true);
      
      setState(() {
        isProcessingMove = false;
      });
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
                    if (isProcessingMove)
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
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
                      currentPlayer == "X"
                    ),
                    _buildPlayerCard(
                      "O", 
                      widget.isPlayerX ? (opponentName ?? "Opponent") : "You", 
                      currentPlayer == "O"
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
      return '🔄 Loading game...';
    }
    
    if (isProcessingMove) {
      return '⏳ Processing move...';
    }
    
    if (winner != null) {
      if (winner == 'Draw') {
        return '🤝 Game Seri!';
      }
      
      final mySymbol = widget.isPlayerX ? 'X' : 'O';
      if (winner == mySymbol) {
        return '🎉 You Win!';
      } else {
        return '😔 ${opponentName ?? "Opponent"} Wins!';
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
    
    if (activeBigRow != null && activeBigCol != null) {
      return 'Must play in board ${activeBigRow! + 1}-${activeBigCol! + 1}';
    } else {
      return 'Free to choose any board';
    }
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
            'Leave Multiplayer Game?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'You will leave the current multiplayer session. Your opponent will be notified.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[300])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
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
    print("🔌 Disposing multiplayer game screen");
    _gameTimer?.cancel();
    _turnTimer?.cancel();
    _turnIndicatorController.dispose();
    _timerController.dispose();
    _pulseController.dispose();
    
    try {
      if (isSubscribed) {
        pbService.pb.collection('rooms').unsubscribe();
        print("✅ Successfully unsubscribed from realtime");
        isSubscribed = false;
      }
    } catch (e) {
      print("❌ Error unsubscribing: $e");
    }
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
          child: Column(
            children: [
              _buildGameHeader(),
              _buildTurnIndicator(),
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
              // Add reset button at bottom if game is over
              if (winner != null && !isProcessingMove)
                Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: ElevatedButton.icon(
                    onPressed: _resetGame,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Play Again',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A0DAD),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}