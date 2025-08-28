import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/ultimate_ttt_board.dart';

class PvPScreen extends StatefulWidget {
  const PvPScreen({super.key});

  @override
  State<PvPScreen> createState() => _PvPScreenState();
}

class _PvPScreenState extends State<PvPScreen> with TickerProviderStateMixin {
  late List<List<List<String>>> board;
  late List<List<String>> bigBoardStatus;
  String currentPlayer = "X";
  int? activeBigRow;
  int? activeBigCol;
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
  bool _gameEnded = false;
  String? _gameResult;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _initAnimations();
    _startGameTimer();
    _startTurnTimer();
  }

  void _initializeGame() {
    board = List.generate(
      3,
      (_) => List.generate(3, (_) => List.generate(9, (_) => "")),
    );
    bigBoardStatus = List.generate(3, (_) => List.generate(3, (_) => ""));
    activeBigRow = null;
    activeBigCol = null;
    currentPlayer = "X";
    _totalSeconds = 0;
    _gameEnded = false;
    _gameResult = null;
  }

  void _restartGame() {
    setState(() {
      _initializeGame();
    });
    
    _gameTimer?.cancel();
    _turnTimer?.cancel();
    _startGameTimer();
    _startTurnTimer();
    
    _turnIndicatorController.reset();
    _turnIndicatorController.forward();
    _timerController.reset();
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
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_gameEnded) {
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
      if (mounted && !_gameEnded) {
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
    if (!_gameEnded) {
      setState(() {
        currentPlayer = currentPlayer == "X" ? "O" : "X";
      });
      _startTurnTimer();
      _turnIndicatorController.reset();
      _turnIndicatorController.forward();
      _timerController.reset();
    }
  }

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

  bool checkDraw(List<String> boardSection) {
    return boardSection.every((cell) => cell.isNotEmpty) && 
           !checkWin(boardSection, "X") && 
           !checkWin(boardSection, "O");
  }

  bool checkBigBoardWin(List<List<String>> bigBoard, String player) {
    for (int i = 0; i < 3; i++) {
      if (bigBoard[i][0] == player &&
          bigBoard[i][1] == player &&
          bigBoard[i][2] == player)
        return true;
      if (bigBoard[0][i] == player &&
          bigBoard[1][i] == player &&
          bigBoard[2][i] == player)
        return true;
    }
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

  void _showGameOverDialog(String message) {
    setState(() {
      _gameEnded = true;
      _gameResult = message;
    });
    
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Total waktu: ${_formatTime(_totalSeconds)}',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _restartGame();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleMove(int bigRow, int bigCol, int smallRow, int smallCol) {
    if (_gameEnded) return;
    
    if (bigBoardStatus[bigRow][bigCol].isNotEmpty) return;
    if (board[bigRow][bigCol][smallRow * 3 + smallCol].isNotEmpty) return;
    if (activeBigRow != null && activeBigCol != null) {
      if (bigRow != activeBigRow || bigCol != activeBigCol) return;
    }
    setState(() {
      board[bigRow][bigCol][smallRow * 3 + smallCol] = currentPlayer;
      
      if (checkWin(board[bigRow][bigCol], currentPlayer)) {
        bigBoardStatus[bigRow][bigCol] = currentPlayer;
        board[bigRow][bigCol] = List.generate(9, (_) => currentPlayer);
      } else if (checkDraw(board[bigRow][bigCol])) {
        bigBoardStatus[bigRow][bigCol] = "D";
        board[bigRow][bigCol] = List.generate(9, (_) => "D");
      }
      
      if (checkBigBoardWin(bigBoardStatus, currentPlayer)) {
        String winner = currentPlayer == "X" ? "Player 1" : "Player 2";
        _showGameOverDialog('🎉 $winner Menang! 🎉');
        _turnTimer?.cancel();
        _gameTimer?.cancel();
        return;
      } else if (bigBoardStatus.expand((e) => e).every((c) => c.isNotEmpty)) {
        _showGameOverDialog('🤝 Permainan Seri! 🤝');
        _turnTimer?.cancel();
        _gameTimer?.cancel();
        return;
      }
      
      activeBigRow = smallRow;
      activeBigCol = smallCol;
      
      if (bigBoardStatus[activeBigRow!][activeBigCol!].isNotEmpty ||
          board[activeBigRow!][activeBigCol!].every((c) => c.isNotEmpty)) {
        activeBigRow = null;
        activeBigCol = null;
      }
      currentPlayer = currentPlayer == "X" ? "O" : "X";
    });
    _startTurnTimer();
    _turnIndicatorController.reset();
    _turnIndicatorController.forward();
    _timerController.reset();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildGameHeader(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04, 
        vertical: screenHeight * 0.02
      ),
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
                padding: EdgeInsets.all(screenWidth * 0.02),
                child: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: screenWidth * 0.06,
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Colors.white.withOpacity(0.8),
                      size: screenWidth * 0.04,
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      'Total: ${_formatTime(_totalSeconds)}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  'Player vs Player',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _showRestartDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                child: Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: screenWidth * 0.06,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(BuildContext context, String player, String name, bool isActive) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive && !_gameEnded ? _pulseAnimation.value : 1.0,
          child: Container(
            width: screenWidth * 0.35,
            padding: EdgeInsets.all(screenWidth * 0.03),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B69),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive && !_gameEnded ? Colors.white : Colors.transparent,
                width: 2,
              ),
              boxShadow: isActive && !_gameEnded
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
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4),
                    borderRadius: BorderRadius.circular(screenWidth * 0.075),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Icon(
                      player == "X" ? Icons.person : Icons.person_outline,
                      color: Colors.white,
                      size: screenWidth * 0.075,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenHeight * 0.008),
                Container(
                  width: screenWidth * 0.075,
                  height: screenWidth * 0.075,
                  decoration: BoxDecoration(
                    color: player == "X"
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenWidth * 0.0375),
                  ),
                  child: Center(
                    child: Text(
                      player,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
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

  Widget _buildTurnIndicator(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return AnimatedBuilder(
      animation: _turnIndicatorAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _turnIndicatorAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05, 
              vertical: screenHeight * 0.015
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPlayerCard(context, "X", "Player 1", currentPlayer == "X"),
                    _buildPlayerCard(context, "O", "Player 2", currentPlayer == "O"),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.015,
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
                              _gameEnded 
                                  ? (_gameResult ?? "Game Over")
                                  : (currentPlayer == "X"
                                      ? "Player 1's Turn"
                                      : "Player 2's Turn"),
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              _gameEnded 
                                  ? 'Game sudah berakhir'
                                  : (activeBigRow != null && activeBigCol != null
                                      ? 'Must play in board ${activeBigRow! + 1}-${activeBigCol! + 1}'
                                      : 'Free to choose any board'),
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_gameEnded)
                        AnimatedBuilder(
                          animation: _timerWarningAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _turnSeconds <= 10
                                  ? _timerWarningAnimation.value
                                  : 1.0,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.03,
                                  vertical: screenHeight * 0.01,
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
                                      size: screenWidth * 0.04,
                                      color: _turnSeconds <= 10
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                    SizedBox(width: screenWidth * 0.01),
                                    Text(
                                      '$_turnSeconds',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
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

  void _showRestartDialog() {
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
            'Restart Game?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Game akan dimulai dari awal. Progress saat ini akan hilang.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Batal', style: TextStyle(color: Colors.grey[300])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Restart'),
            ),
          ],
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
            'Quit the Game?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Game progress will be lost. Are you sure you want to return to the main menu?',
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
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _turnTimer?.cancel();
    _turnIndicatorController.dispose();
    _timerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
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
              _buildGameHeader(context),
              _buildTurnIndicator(context),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1.0, // Keeps the board square
                    child: Container(
                      margin: EdgeInsets.all(screenWidth * 0.05),
                      constraints: BoxConstraints(
                        maxWidth: screenWidth * 0.9,
                        maxHeight: screenHeight * 0.6, // Increased for better board size
                      ),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: EdgeInsets.all(screenWidth * 0.02), // Add some padding inside
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