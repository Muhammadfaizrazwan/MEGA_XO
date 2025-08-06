import 'package:flutter/material.dart';
import '../widgets/ultimate_ttt_board.dart';
import 'dart:async';
import 'dart:math';

class PvEScreen extends StatefulWidget {
  const PvEScreen({super.key});

  @override
  State<PvEScreen> createState() => _PvEScreenState();
}

class _PvEScreenState extends State<PvEScreen> with TickerProviderStateMixin {
  late List<List<List<String>>> board;
  late List<List<String>> bigBoardStatus;
  String currentPlayer = "X";
  int? activeBigRow;
  int? activeBigCol;
  bool gameEnded = false; // Add game state flag

  // Timer variables
  Timer? _gameTimer;
  int _totalSeconds = 0;
  Timer? _turnTimer;
  int _turnSeconds = 30;

  // Bot status
  bool _botThinking = false;

  // Animation controllers
  late AnimationController _turnIndicatorController;
  late AnimationController _timerController;
  late AnimationController _pulseController;
  late AnimationController _botThinkingController;

  late Animation<double> _turnIndicatorAnimation;
  late Animation<double> _timerWarningAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _botThinkingAnimation;

  @override
  void initState() {
    super.initState();
    board = List.generate(
      3,
      (_) => List.generate(3, (_) => List.generate(9, (_) => "")),
    );

    // Initialize bigBoardStatus
    bigBoardStatus = List.generate(3, (_) => List.generate(3, (_) => ""));

    _initAnimations();
    _startGameTimer();
    _startTurnTimer();
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

    _botThinkingController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

    _botThinkingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _botThinkingController, curve: Curves.easeInOut),
    );

    _turnIndicatorController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !gameEnded) {
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
      if (mounted && !gameEnded) {
        setState(() {
          _turnSeconds--;
          if (_turnSeconds <= 10) {
            _timerController.repeat(reverse: true);
          }
          if (_turnSeconds <= 0 && currentPlayer == "X") {
            _handleTimeOut();
          }
        });
      }
    });
  }

  void _handleTimeOut() {
    // Auto pass turn when player times out
    setState(() {
      currentPlayer = "O";
    });
    _startTurnTimer();
    _turnIndicatorController.reset();
    _turnIndicatorController.forward();
    _timerController.reset();

    // Bot makes move
    Future.delayed(const Duration(milliseconds: 500), _botMove);
  }

  // Method to check mini board win
  String _checkMiniBoard(List<String> miniBoard) {
    // Check rows
    for (int i = 0; i < 3; i++) {
      if (miniBoard[i * 3] != "" &&
          miniBoard[i * 3] == miniBoard[i * 3 + 1] &&
          miniBoard[i * 3 + 1] == miniBoard[i * 3 + 2]) {
        return miniBoard[i * 3];
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (miniBoard[i] != "" &&
          miniBoard[i] == miniBoard[i + 3] &&
          miniBoard[i + 3] == miniBoard[i + 6]) {
        return miniBoard[i];
      }
    }

    // Check diagonals
    if (miniBoard[0] != "" &&
        miniBoard[0] == miniBoard[4] &&
        miniBoard[4] == miniBoard[8]) {
      return miniBoard[0];
    }

    if (miniBoard[2] != "" &&
        miniBoard[2] == miniBoard[4] &&
        miniBoard[4] == miniBoard[6]) {
      return miniBoard[2];
    }

    // Check if board is full (tie)
    if (miniBoard.every((cell) => cell != "")) {
      return "T"; // Tie
    }

    return ""; // No winner yet
  }

  // Method to check big board win
  String _checkBigBoard() {
    // Check rows
    for (int i = 0; i < 3; i++) {
      if (bigBoardStatus[i][0] != "" &&
          bigBoardStatus[i][0] != "T" &&
          bigBoardStatus[i][0] == bigBoardStatus[i][1] &&
          bigBoardStatus[i][1] == bigBoardStatus[i][2]) {
        return bigBoardStatus[i][0];
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (bigBoardStatus[0][i] != "" &&
          bigBoardStatus[0][i] != "T" &&
          bigBoardStatus[0][i] == bigBoardStatus[1][i] &&
          bigBoardStatus[1][i] == bigBoardStatus[2][i]) {
        return bigBoardStatus[0][i];
      }
    }

    // Check diagonals
    if (bigBoardStatus[0][0] != "" &&
        bigBoardStatus[0][0] != "T" &&
        bigBoardStatus[0][0] == bigBoardStatus[1][1] &&
        bigBoardStatus[1][1] == bigBoardStatus[2][2]) {
      return bigBoardStatus[0][0];
    }

    if (bigBoardStatus[0][2] != "" &&
        bigBoardStatus[0][2] != "T" &&
        bigBoardStatus[0][2] == bigBoardStatus[1][1] &&
        bigBoardStatus[1][1] == bigBoardStatus[2][0]) {
      return bigBoardStatus[0][2];
    }

    // Check if big board is full (tie)
    bool isFull = true;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (bigBoardStatus[i][j] == "") {
          isFull = false;
          break;
        }
      }
      if (!isFull) break;
    }

    if (isFull) {
      return "T"; // Tie
    }

    return ""; // No winner yet
  }

  // Method to show game end dialog
  void _showGameEndDialog(String winner) {
    String title, message;
    Color color;

    if (winner == "X") {
      title = "🎉 Selamat!";
      message = "Kamu berhasil mengalahkan Bot!";
      color = Colors.green;
    } else if (winner == "O") {
      title = "😔 Game Over";
      message = "Bot berhasil mengalahkanmu. Coba lagi!";
      color = Colors.red;
    } else {
      title = "🤝 Seri!";
      message = "Permainan berakhir seri. Pertarungan yang sengit!";
      color = Colors.orange;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D1B69),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
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
                'Waktu Total: ${_formatTime(_totalSeconds)}',
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Kembali ke menu utama
              },
              child: Text(
                'Menu Utama',
                style: TextStyle(color: Colors.grey[300]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Main Lagi'),
            ),
          ],
        );
      },
    );
  }

  // Method to restart game
  void _restartGame() {
    setState(() {
      board = List.generate(
        3,
        (_) => List.generate(3, (_) => List.generate(9, (_) => "")),
      );
      bigBoardStatus = List.generate(3, (_) => List.generate(3, (_) => ""));
      currentPlayer = "X";
      activeBigRow = null;
      activeBigCol = null;
      _totalSeconds = 0;
      _botThinking = false;
      gameEnded = false;
    });

    _gameTimer?.cancel();
    _turnTimer?.cancel();
    _startGameTimer();
    _startTurnTimer();
    _turnIndicatorController.reset();
    _turnIndicatorController.forward();
    _timerController.reset();
    _botThinkingController.reset();
  }

  void _handleMove(int bigRow, int bigCol, int smallRow, int smallCol) {
    if (_botThinking || gameEnded)
      return; // Prevent moves during bot thinking or after game ends

    setState(() {
      board[bigRow][bigCol][smallRow * 3 + smallCol] = currentPlayer;

      // Check if mini board is won
      bigBoardStatus[bigRow][bigCol] = _checkMiniBoard(board[bigRow][bigCol]);

      activeBigRow = smallRow;
      activeBigCol = smallCol;

      // If the target board is already won or full, player can choose any board
      if (bigBoardStatus[activeBigRow!][activeBigCol!] != "" ||
          board[activeBigRow!][activeBigCol!].every((c) => c.isNotEmpty)) {
        activeBigRow = null;
        activeBigCol = null;
      }
    });

    // Check if big board has a winner
    String bigBoardWinner = _checkBigBoard();
    if (bigBoardWinner != "") {
      setState(() {
        gameEnded = true;
      });
      _gameTimer?.cancel();
      _turnTimer?.cancel();
      _stopBotThinking();
      Future.delayed(const Duration(milliseconds: 500), () {
        _showGameEndDialog(bigBoardWinner);
      });
      return;
    }

    setState(() {
      currentPlayer = currentPlayer == "X" ? "O" : "X";
    });

    // Restart turn timer and animations
    _startTurnTimer();
    _turnIndicatorController.reset();
    _turnIndicatorController.forward();
    _timerController.reset();

    // If bot's turn
    if (currentPlayer == "O" && !gameEnded) {
      _startBotThinking();
      Future.delayed(
        Duration(milliseconds: 1000 + Random().nextInt(1500)),
        _botMove,
      );
    }
  }

  void _startBotThinking() {
    setState(() {
      _botThinking = true;
    });
    _botThinkingController.repeat(reverse: true);
  }

  void _stopBotThinking() {
    setState(() {
      _botThinking = false;
    });
    _botThinkingController.reset();
  }

  void _botMove() {
    if (!mounted || gameEnded) return;

    final rand = Random();
    List<Map<String, int>> availableMoves = [];

    for (int bigRow = 0; bigRow < 3; bigRow++) {
      for (int bigCol = 0; bigCol < 3; bigCol++) {
        // Skip if this big board is already won
        if (bigBoardStatus[bigRow][bigCol] != "") continue;

        // Skip if we must play in a specific board and this isn't it
        if (activeBigRow != null &&
            (bigRow != activeBigRow || bigCol != activeBigCol))
          continue;

        for (int i = 0; i < 9; i++) {
          if (board[bigRow][bigCol][i].isEmpty) {
            availableMoves.add({
              "bigRow": bigRow,
              "bigCol": bigCol,
              "smallRow": i ~/ 3,
              "smallCol": i % 3,
            });
          }
        }
      }
    }

    if (availableMoves.isEmpty) {
      _stopBotThinking();
      return;
    }

    final move = availableMoves[rand.nextInt(availableMoves.length)];
    _stopBotThinking();
    _handleMove(
      move["bigRow"]!,
      move["bigCol"]!,
      move["smallRow"]!,
      move["smallCol"]!,
    );
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
            // ignore: deprecated_member_use
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back Button
          Material(
            // ignore: deprecated_member_use
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _showExitDialog(),
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

          // Game Timer
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
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Player vs Bot',
                  style: const TextStyle(
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

  Widget _buildPlayerCard(
    String player,
    String name,
    bool isBot,
    bool isActive,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive && !gameEnded ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B69),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive && !gameEnded
                    ? Colors.white
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: isActive && !gameEnded
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
                // Avatar with bot thinking animation
                AnimatedBuilder(
                  animation: _botThinkingAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isBot
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF4ECDC4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            isBot ? Icons.smart_toy : Icons.person,
                            color: Colors.white,
                            size: 30,
                          ),
                          if (isBot && _botThinking)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Transform.scale(
                                scale: _botThinkingAnimation.value,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.yellow,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                // Player Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (isBot && _botThinking) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Thinking...',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.yellow[300],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Player Symbol
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
                // Player Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPlayerCard("X", "You", false, currentPlayer == "X"),
                    _buildPlayerCard("O", "Bot", true, currentPlayer == "O"),
                  ],
                ),
                const SizedBox(height: 16),

                // Game Status and Timer
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
                              gameEnded
                                  ? "Game Selesai!"
                                  : _botThinking
                                  ? "Bot is thinking..."
                                  : currentPlayer == "X"
                                  ? "Your Turn"
                                  : "Bot's Turn",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              gameEnded
                                  ? 'Permainan telah berakhir'
                                  : activeBigRow != null && activeBigCol != null
                                  ? 'Must play in board ${activeBigRow! + 1}-${activeBigCol! + 1}'
                                  : 'Free to choose any board',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Turn Timer (only for player)
                      if (currentPlayer == "X" && !_botThinking && !gameEnded)
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
                                      // ignore: deprecated_member_use
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
            'Keluar dari Game?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Progress game akan hilang. Yakin ingin kembali ke menu utama?',
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
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A0DAD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Keluar'),
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
    _botThinkingController.dispose();
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
            ],
          ),
        ),
      ),
    );
  }
}
