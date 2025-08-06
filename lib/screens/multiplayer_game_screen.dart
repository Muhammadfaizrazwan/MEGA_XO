import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/pocketbase_service.dart';

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

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  final pbService = PocketBaseService();
  
  // Main board: 9 smaller grids, each with 9 cells
  List<List<String>> smallBoards = List.generate(9, (index) => List.filled(9, ''));
  
  // Winners of each small board (9 positions: '', 'X', 'O', 'Draw')
  List<String> bigBoard = List.filled(9, '');
  
  String currentTurn = 'X';
  String? winner;
  String? opponentName;
  bool isGameLoaded = false;
  bool isProcessingMove = false;
  
  // Active board index (-1 means all boards are active, 0-8 means specific board)
  int activeBoard = -1;

  @override
  void initState() {
    super.initState();
    print("Ultimate Tic-Tac-Toe started - Room: ${widget.roomId}, IsPlayerX: ${widget.isPlayerX}");
    print("Current user: ${pbService.getCurrentUserInfo()}");
    
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _loadRoomData();
    await _setupRealtime();
  }

  // Helper method to safely parse JSON arrays
  List<List<String>> _parseSmallBoards(dynamic data) {
    try {
      if (data == null || data.toString().isEmpty || data.toString() == '[]') {
        print("SmallBoards data is null/empty, using empty board");
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
        
        print("Successfully parsed smallBoards with ${result.length} boards");
        return result;
      }
    } catch (e) {
      print("Error parsing smallBoards: $e, data: $data");
    }
    
    return List.generate(9, (index) => List.filled(9, ''));
  }

  // Helper method to safely parse big board
  List<String> _parseBigBoard(dynamic data) {
    try {
      if (data == null || data.toString().isEmpty || data.toString() == '[]') {
        print("BigBoard data is null/empty, using empty board");
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
        
        print("Successfully parsed bigBoard with ${result.length} positions");
        return result;
      }
    } catch (e) {
      print("Error parsing bigBoard: $e, data: $data");
    }
    
    return List.filled(9, '');
  }

  Future<void> _loadRoomData() async {
    try {
      final room = await pbService.pb.collection('rooms').getOne(widget.roomId);
      
      print("=== LOADING ROOM DATA ===");
      print("Raw smallBoards: ${room.data['smallBoards']}");
      print("Raw bigBoard: ${room.data['bigBoard']}");
      print("Current turn: ${room.data['currentTurn']}");
      print("Active board: ${room.data['activeBoard']}");
      
      // Load small boards state with better parsing
      smallBoards = _parseSmallBoards(room.data['smallBoards']);
      
      // Load big board state with better parsing
      bigBoard = _parseBigBoard(room.data['bigBoard']);
      
      // Load current turn
      currentTurn = room.data['currentTurn']?.toString() ?? 'X';
      
      // Load active board
      activeBoard = room.data['activeBoard'] ?? -1;
      
      // Load opponent name
      if (widget.isPlayerX) {
        opponentName = room.data['playerOName']?.toString() ?? 'Player O';
      } else {
        opponentName = room.data['playerXName']?.toString() ?? 'Player X';
      }
      
      print("=== PARSED DATA ===");
      print("SmallBoards loaded with ${smallBoards.length} boards");
      print("BigBoard: $bigBoard");
      print("Current turn: $currentTurn");
      print("Active board: $activeBoard");
      print("=================");
      
      _checkWinners();
      
      if (mounted) {
        setState(() {
          isGameLoaded = true;
        });
      }
      
      print("Game loaded successfully");
    } catch (e) {
      print("Failed to load room: $e");
      if (mounted) {
        _showMessage("Gagal memuat data room", isError: true);
      }
    }
  }

  Future<void> _setupRealtime() async {
    try {
      print("Setting up realtime subscription for room: ${widget.roomId}");
      
      // Clean up any existing subscription first
      try {
        await pbService.pb.collection('rooms').unsubscribe(widget.roomId);
        pbService.stopPolling();
      } catch (e) {
        // Ignore if not subscribed yet
      }
      
      // Use improved SSE with polling fallback
      pbService.subscribeWithPollingFallback('rooms', widget.roomId).listen((data) {
        if (!mounted) {
          print("Widget not mounted, ignoring realtime update");
          return;
        }
        
        print("=== REALTIME UPDATE ===");
        print("Room data: $data");
        
        _handleRealtimeUpdate(data);
        print("=== END REALTIME UPDATE ===");
      }, onError: (error) {
        print("❌ Realtime subscription error: $error");
        if (mounted) {
          _showMessage("Koneksi realtime bermasalah, menggunakan polling", isError: true);
        }
      });
      
      print("✅ Realtime subscription with fallback established successfully");
      
    } catch (e) {
      print("❌ Error setting up realtime subscription: $e");
      if (mounted) {
        _showMessage("Koneksi realtime bermasalah", isError: true);
      }
    }
  }

  void _handleRealtimeUpdate(Map<String, dynamic> data) {
    try {
      print("=== HANDLING REALTIME UPDATE ===");
      bool hasChanges = false;
      
      // Parse small boards with better error handling
      final newSmallBoards = _parseSmallBoards(data['smallBoards']);
      if (_boardsAreDifferent(newSmallBoards, smallBoards)) {
        print("SmallBoards changed via realtime!");
        print("Old: ${smallBoards.map((b) => b.join(',')).join('|')}");
        print("New: ${newSmallBoards.map((b) => b.join(',')).join('|')}");
        smallBoards = newSmallBoards;
        hasChanges = true;
      }
      
      // Parse big board with better error handling
      final newBigBoard = _parseBigBoard(data['bigBoard']);
      if (newBigBoard.join(',') != bigBoard.join(',')) {
        print("BigBoard changed via realtime!");
        print("Old: ${bigBoard.join(',')}");
        print("New: ${newBigBoard.join(',')}");
        bigBoard = newBigBoard;
        hasChanges = true;
      }
      
      // Update other fields
      final newTurn = data['currentTurn']?.toString() ?? 'X';
      final newActiveBoard = data['activeBoard'] ?? -1;
      
      if (newTurn != currentTurn) {
        print("Turn changed from $currentTurn to $newTurn");
        currentTurn = newTurn;
        hasChanges = true;
      }
      
      if (newActiveBoard != activeBoard) {
        print("ActiveBoard changed from $activeBoard to $newActiveBoard");
        activeBoard = newActiveBoard;
        hasChanges = true;
      }
      
      // Update opponent name if needed
      if (widget.isPlayerX && data['playerOName'] != null && data['playerOName'] != opponentName) {
        opponentName = data['playerOName'].toString();
        hasChanges = true;
      } else if (!widget.isPlayerX && data['playerXName'] != null && data['playerXName'] != opponentName) {
        opponentName = data['playerXName'].toString();
        hasChanges = true;
      }
      
      if (hasChanges) {
        _checkWinners();
        
        if (mounted) {
          setState(() {
            // Reset processing flag when we receive server update
            isProcessingMove = false;
          });
          print(" UI updated via realtime!");
        }
      } else {
        print("No changes detected in realtime update");
      }
      
      print("=== END HANDLING REALTIME UPDATE ===");
      
    } catch (parseError) {
      print(" Error parsing realtime data: $parseError");
      // Fallback: reload data from server
      _loadRoomData();
    }
  }

  bool _boardsAreDifferent(List<List<String>> board1, List<List<String>> board2) {
    if (board1.length != board2.length) return true;
    
    for (int i = 0; i < board1.length; i++) {
      if (board1[i].length != board2[i].length) return true;
      for (int j = 0; j < board1[i].length; j++) {
        if (board1[i][j] != board2[i][j]) return true;
      }
    }
    return false;
  }

  void _makeMove(int boardIndex, int cellIndex) async {
    // Prevent duplicate moves
    if (isProcessingMove) {
      print(" Move already in progress");
      return;
    }

    // Basic validations
    if (smallBoards[boardIndex][cellIndex] != '' || 
        bigBoard[boardIndex] != '' || 
        winner != null || 
        !isGameLoaded) {
      print(" Move blocked - Cell occupied or board won or game over");
      return;
    }
    
    // Turn validation
    final mySymbol = widget.isPlayerX ? 'X' : 'O';
    if (currentTurn != mySymbol) {
      print(" Not your turn - Current: $currentTurn, My symbol: $mySymbol");
      _showMessage("Belum giliran kamu!", isError: true);
      return;
    }
    
    // Active board validation
    if (activeBoard != -1 && activeBoard != boardIndex) {
      print(" Wrong board - Active: $activeBoard, Clicked: $boardIndex");
      _showMessage("Hanya bisa main di kotak yang aktif!", isError: true);
      return;
    }

    // Set processing flag
    setState(() {
      isProcessingMove = true;
    });

    print(" Making move at board $boardIndex, cell $cellIndex with symbol $mySymbol");

    try {
      // Create deep copies for server update
      final newSmallBoards = smallBoards.map((board) => List<String>.from(board)).toList();
      final newBigBoard = List<String>.from(bigBoard);
      
      // Make the move
      newSmallBoards[boardIndex][cellIndex] = mySymbol;
      
      print(" After making move:");
      print("Board $boardIndex, Cell $cellIndex = $mySymbol");
      print("Board state: ${newSmallBoards[boardIndex].join(',')}");
      
      // Check if this small board is won
      final smallBoardWinner = _checkSmallBoardWinner(newSmallBoards[boardIndex]);
      if (smallBoardWinner != null) {
        newBigBoard[boardIndex] = smallBoardWinner;
        print(" Small board $boardIndex won by $smallBoardWinner");
      }
      
      // Determine next active board
      int newActiveBoard;
      if (newBigBoard[cellIndex] != '') {
        // Target board is already won, so next player can play anywhere
        newActiveBoard = -1;
        print(" Next player can play anywhere (target board $cellIndex already won)");
      } else {
        // Next player must play in the board corresponding to this cell
        newActiveBoard = cellIndex;
        print("Next player must play in board $newActiveBoard");
      }
      
      final newTurn = currentTurn == 'X' ? 'O' : 'X';
      
      // Prepare data for server update
      final updateData = {
        'smallBoards': jsonEncode(newSmallBoards),
        'bigBoard': jsonEncode(newBigBoard),
        'currentTurn': newTurn,
        'activeBoard': newActiveBoard,
        'lastMove': DateTime.now().toIso8601String(),
      };
      
      print("📤 Sending to server:");
      print("SmallBoards JSON: ${updateData['smallBoards']}");
      print("BigBoard JSON: ${updateData['bigBoard']}");
      print("Turn: ${updateData['currentTurn']}");
      print("Active Board: ${updateData['activeBoard']}");

      // Update to server
      await pbService.pb.collection('rooms').update(widget.roomId, body: updateData);
      
      print(" Move sent to server successfully");
      
      // Also do an optimistic UI update to avoid delays
      if (mounted) {
        setState(() {
          smallBoards = newSmallBoards;
          bigBoard = newBigBoard;
          currentTurn = newTurn;
          activeBoard = newActiveBoard;
          _checkWinners();
        });
        print(" Optimistic UI update applied");
      }
      
    } catch (e) {
      print("Failed to send move to server: $e");
      
      // Reset processing flag on error
      setState(() {
        isProcessingMove = false;
      });
      
      _showMessage("Gagal melakukan langkah, coba lagi", isError: true);
      
      // Reload current state from server on error
      await _loadRoomData();
    }
  }

  String? _checkSmallBoardWinner(List<String> board) {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6] // diagonals
    ];

    // Check for winner
    for (var pattern in winPatterns) {
      final a = board[pattern[0]];
      final b = board[pattern[1]];
      final c = board[pattern[2]];
      if (a != '' && a == b && b == c) {
        return a;
      }
    }

    // Check for draw
    if (!board.contains('')) {
      return 'Draw';
    }

    return null;
  }

  void _checkWinners() {
    const winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
      [0, 4, 8], [2, 4, 6] // diagonals
    ];

    // Check for winner in big board
    for (var pattern in winPatterns) {
      final a = bigBoard[pattern[0]];
      final b = bigBoard[pattern[1]];
      final c = bigBoard[pattern[2]];
      if (a != '' && a != 'Draw' && a == b && b == c) {
        winner = a;
        print("Winner found: $winner");
        return;
      }
    }

    // Check for draw (all big board positions filled)
    if (winner == null && !bigBoard.contains('')) {
      winner = 'Draw';
      print("Game is a draw");
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
        duration: const Duration(seconds: 2),
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
      
      _showMessage("Game direset!");
      
    } catch (e) {
      print("Gagal reset game: $e");
      _showMessage("Gagal reset game", isError: true);
      
      setState(() {
        isProcessingMove = false;
      });
    }
  }

  void _leaveGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Game"),
        content: const Text("Apakah kamu yakin ingin keluar dari game?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to previous screen
            },
            child: const Text("Leave"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print("Disposing multiplayer game screen");
    try {
      pbService.pb.collection('rooms').unsubscribe(widget.roomId);
      pbService.stopPolling();
      print("Successfully cleaned up connections for room: ${widget.roomId}");
    } catch (e) {
      print("Error cleaning up connections: $e");
    }
    super.dispose();
  }

  String _getStatusText() {
    if (!isGameLoaded) {
      return 'Loading...';
    }
    
    if (isProcessingMove) {
      return 'Processing move...';
    }
    
    if (winner != null) {
      if (winner == 'Draw') {
        return 'Game Seri!';
      }
      
      final mySymbol = widget.isPlayerX ? 'X' : 'O';
      if (winner == mySymbol) {
        return 'Kamu Menang! 🎉';
      } else {
        return '$opponentName Menang!';
      }
    }
    
    final mySymbol = widget.isPlayerX ? 'X' : 'O';
    if (currentTurn == mySymbol) {
      if (activeBoard == -1) {
        return 'Giliran Kamu ($mySymbol) - Pilih kotak mana saja';
      } else {
        return 'Giliran Kamu ($mySymbol) - Main di kotak hijau';
      }
    } else {
      if (activeBoard == -1) {
        return 'Giliran $opponentName ($currentTurn) - Bisa pilih kotak mana saja';
      } else {
        return 'Giliran $opponentName ($currentTurn)';
      }
    }
  }

  Color _getStatusColor() {
    if (isProcessingMove) return Colors.orange;
    
    if (winner != null) {
      if (winner == 'Draw') return Colors.orange;
      
      final mySymbol = widget.isPlayerX ? 'X' : 'O';
      return winner == mySymbol ? Colors.green : Colors.red;
    }
    
    final mySymbol = widget.isPlayerX ? 'X' : 'O';
    return currentTurn == mySymbol ? Colors.blue : Colors.grey;
  }

  Widget _buildSmallBoard(int boardIndex) {
    final isActive = activeBoard == -1 || activeBoard == boardIndex;
    final isWon = bigBoard[boardIndex] != '';
    final mySymbol = widget.isPlayerX ? 'X' : 'O';
    final canPlay = isActive && !isWon && currentTurn == mySymbol && winner == null && !isProcessingMove;
    
    return Container(
      decoration: BoxDecoration(
        color: isWon 
            ? Colors.black.withOpacity(0.7)
            : (isActive 
                ? Colors.green.withOpacity(0.1) 
                : Colors.black.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive && !isWon
              ? Colors.green
              : Colors.white.withOpacity(0.2),
          width: isActive && !isWon ? 3 : 1,
        ),
      ),
      child: isWon 
          ? Center(
              child: bigBoard[boardIndex] == 'Draw'
                  ? Icon(
                      Icons.remove,
                      size: 40,
                      color: Colors.orange,
                    )
                  : Text(
                      bigBoard[boardIndex],
                      style: TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: bigBoard[boardIndex] == 'X' 
                            ? Colors.blue[300]
                            : Colors.red[300],
                      ),
                    ),
            )
          : GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: 9,
              itemBuilder: (context, cellIndex) {
                final cellValue = smallBoards[boardIndex][cellIndex];
                final canMoveHere = canPlay && cellValue == '';
                
                return GestureDetector(
                  onTap: canMoveHere ? () => _makeMove(boardIndex, cellIndex) : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: canMoveHere 
                          ? Colors.white.withOpacity(0.1)
                          : Colors.grey.shade800.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: canMoveHere 
                            ? Colors.blue.withOpacity(0.5)
                            : Colors.white.withOpacity(0.1),
                        width: canMoveHere ? 1 : 0.5,
                      ),
                    ),
                    child: Center(
                      child: cellValue.isEmpty
                          ? (canMoveHere 
                              ? Icon(
                                  Icons.add,
                                  color: Colors.blue.withOpacity(0.6),
                                  size: 16,
                                )
                              : const SizedBox.shrink())
                          : Text(
                              cellValue,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: cellValue == 'X' 
                                    ? Colors.blue[300]
                                    : Colors.red[300],
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0033),
      appBar: AppBar(
        title: Text(
          "Ultimate Tic-Tac-Toe",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF330066),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leaveGame,
        ),
        actions: [
          if (winner != null && !isProcessingMove)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _resetGame,
              tooltip: 'Reset Game',
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF5800FF),
              Color(0xFF330066),
              Color(0xFF1A0033),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Status container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusColor().withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!isGameLoaded || isProcessingMove) ...[
                      const SizedBox(height: 8),
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Game board
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          return _buildSmallBoard(index);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              
              // Bottom info
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Kamu',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.isPlayerX ? 'X' : 'O',
                          style: TextStyle(
                            color: widget.isPlayerX ? Colors.blue[300] : Colors.red[300],
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          opponentName ?? 'Opponent',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          widget.isPlayerX ? 'O' : 'X',
                          style: TextStyle(
                            color: widget.isPlayerX ? Colors.red[300] : Colors.blue[300],
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}