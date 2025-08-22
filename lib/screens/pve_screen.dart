import 'package:flutter/material.dart';
import '../widgets/ultimate_ttt_board.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:math';

class PvEScreen extends StatefulWidget {
  final String difficulty;
  
  const PvEScreen({super.key, required this.difficulty});

  @override
  State<PvEScreen> createState() => _PvEScreenState();
}

class _PvEScreenState extends State<PvEScreen> with TickerProviderStateMixin {
  late List<List<List<String>>> board;
  late List<List<String>> bigBoardStatus;
  String currentPlayer = "X";
  int? activeBigRow;
  int? activeBigCol;
  bool gameEnded = false;
  String? gameResult;

  // Timer variables
  Timer? _gameTimer;
  int _totalSeconds = 0;
  Timer? _turnTimer;
  int _turnSeconds = 30;

  // Bot status
  bool _botThinking = false;
  late String botDifficulty;

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
    botDifficulty = widget.difficulty;
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
    currentPlayer = "X";
    activeBigRow = null;
    activeBigCol = null;
    gameEnded = false;
    gameResult = null;
    _totalSeconds = 0;
    _botThinking = false;
  }

  void _restartGame() {
    setState(() {
      _initializeGame();
    });

    // Cancel and restart timers
    _gameTimer?.cancel();
    _turnTimer?.cancel();
    _startGameTimer();
    _startTurnTimer();

    // Reset animations
    _turnIndicatorController.reset();
    _turnIndicatorController.forward();
    _timerController.reset();
    _botThinkingController.reset();
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
    if (!gameEnded) {
      setState(() {
        currentPlayer = "O";
      });
      _startTurnTimer();
      _turnIndicatorController.reset();
      _turnIndicatorController.forward();
      _timerController.reset();

      Future.delayed(const Duration(milliseconds: 500), _botMove);
    }
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

    // Check if board is full (draw)
    if (miniBoard.every((cell) => cell != "")) {
      return "D";
    }

    return "";
  }

  // Method to check big board win
  String _checkBigBoard() {
    // Check rows
    for (int i = 0; i < 3; i++) {
      if (bigBoardStatus[i][0] != "" &&
          bigBoardStatus[i][0] != "D" &&
          bigBoardStatus[i][0] == bigBoardStatus[i][1] &&
          bigBoardStatus[i][1] == bigBoardStatus[i][2]) {
        return bigBoardStatus[i][0];
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (bigBoardStatus[0][i] != "" &&
          bigBoardStatus[0][i] != "D" &&
          bigBoardStatus[0][i] == bigBoardStatus[1][i] &&
          bigBoardStatus[1][i] == bigBoardStatus[2][i]) {
        return bigBoardStatus[0][i];
      }
    }

    // Check diagonals
    if (bigBoardStatus[0][0] != "" &&
        bigBoardStatus[0][0] != "D" &&
        bigBoardStatus[0][0] == bigBoardStatus[1][1] &&
        bigBoardStatus[1][1] == bigBoardStatus[2][2]) {
      return bigBoardStatus[0][0];
    }

    if (bigBoardStatus[0][2] != "" &&
        bigBoardStatus[0][2] != "D" &&
        bigBoardStatus[0][2] == bigBoardStatus[1][1] &&
        bigBoardStatus[1][1] == bigBoardStatus[2][0]) {
      return bigBoardStatus[0][2];
    }

    // Check if big board is full (draw)
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
      return "D";
    }

    return "";
  }

  // Method to show game end dialog
  void _showGameEndDialog(String winner) {
    setState(() {
      gameEnded = true;
      gameResult = winner;
    });

    String title, message;
    Color color;

    if (winner == "X") {
      title = "🎉 Selamat!";
      message = "Kamu berhasil mengalahkan Bot ${botDifficulty.toUpperCase()}!";
      color = Colors.green;
    } else if (winner == "O") {
      title = "😔 Game Over";
      message = "Bot ${botDifficulty.toUpperCase()} berhasil mengalahkanmu!";
      color = Colors.red;
    } else {
      title = "🤝 Seri!";
      message = "Pertarungan sengit melawan Bot ${botDifficulty.toUpperCase()}!";
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
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Main Lagi',
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
                      'Menu Utama',
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
        );
      },
    );
  }

  void _handleMove(int bigRow, int bigCol, int smallRow, int smallCol) {
    if (_botThinking || gameEnded) return;

    setState(() {
      board[bigRow][bigCol][smallRow * 3 + smallCol] = currentPlayer;

      String miniResult = _checkMiniBoard(board[bigRow][bigCol]);
      if (miniResult != "") {
        bigBoardStatus[bigRow][bigCol] = miniResult;
        if (miniResult == "X" || miniResult == "O") {
          board[bigRow][bigCol] = List.generate(9, (_) => miniResult);
        } else if (miniResult == "D") {
          board[bigRow][bigCol] = List.generate(9, (_) => "D");
        }
      }

      activeBigRow = smallRow;
      activeBigCol = smallCol;

      if (bigBoardStatus[activeBigRow!][activeBigCol!] != "" ||
          board[activeBigRow!][activeBigCol!].every((c) => c.isNotEmpty)) {
        activeBigRow = null;
        activeBigCol = null;
      }
    });

    String bigBoardWinner = _checkBigBoard();
    if (bigBoardWinner != "") {
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

    _startTurnTimer();
    _turnIndicatorController.reset();
    _turnIndicatorController.forward();
    _timerController.reset();

    if (currentPlayer == "O" && !gameEnded) {
      _startBotThinking();
      
      // Different thinking times based on difficulty
      int thinkingTime = _getBotThinkingTime();
      
      Future.delayed(
        Duration(milliseconds: thinkingTime),
        _botMove,
      );
    }
  }

  int _getBotThinkingTime() {
    switch (botDifficulty) {
      case 'easy':
        return 500 + Random().nextInt(500); // 0.5-1s
      case 'medium':
        return 1000 + Random().nextInt(1000); // 1-2s
      case 'hard':
        return 1500 + Random().nextInt(1500); // 1.5-3s
      case 'expert':
        return 2000 + Random().nextInt(2000); // 2-4s
      case 'nightmare':
        return 3000 + Random().nextInt(2000); // 3-5s
      default:
        return 1000;
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

  // BOT AI SYSTEM
  void _botMove() {
    if (!mounted || gameEnded) return;

    Map<String, int>? bestMove;
    
    switch (botDifficulty) {
      case 'easy':
        bestMove = _getEasyMove();
        break;
      case 'medium':
        bestMove = _getMediumMove();
        break;
      case 'hard':
        bestMove = _getHardMove();
        break;
      case 'expert':
        bestMove = _getExpertMove();
        break;
      case 'nightmare':
        bestMove = _getNightmareMove();
        break;
      default:
        bestMove = _getMediumMove();
    }
    
    if (bestMove == null) {
      _stopBotThinking();
      return;
    }

    _stopBotThinking();
    _handleMove(
      bestMove["bigRow"]!,
      bestMove["bigCol"]!,
      bestMove["smallRow"]!,
      bestMove["smallCol"]!,
    );
  }

  // EASY AI - Random moves with 30% smart plays
  Map<String, int>? _getEasyMove() {
    List<Map<String, int>> availableMoves = _getAvailableMoves();
    if (availableMoves.isEmpty) return null;

    // 30% chance to make a smart move
    if (Random().nextDouble() < 0.3) {
      Map<String, int>? smartMove = _findMiniBoardWinMove(availableMoves) ??
                                   _findMiniBoardBlockMove(availableMoves);
      if (smartMove != null) return smartMove;
    }

    return availableMoves[Random().nextInt(availableMoves.length)];
  }

  // MEDIUM AI - Basic strategy
  Map<String, int>? _getMediumMove() {
    List<Map<String, int>> availableMoves = _getAvailableMoves();
    if (availableMoves.isEmpty) return null;

    // Priority: Win big board > Block big board > Win mini > Block mini > Strategic
    return _findBigBoardWinMove(availableMoves) ??
           _findBigBoardBlockMove(availableMoves) ??
           _findMiniBoardWinMove(availableMoves) ??
           _findMiniBoardBlockMove(availableMoves) ??
           _findStrategicMove(availableMoves) ??
           availableMoves[Random().nextInt(availableMoves.length)];
  }

  // HARD AI - Minimax with depth 2
  Map<String, int>? _getHardMove() {
    List<Map<String, int>> availableMoves = _getAvailableMoves();
    if (availableMoves.isEmpty) return null;

    return _minimaxMove(availableMoves, 2);
  }

  // EXPERT AI - Minimax with depth 3
  Map<String, int>? _getExpertMove() {
    List<Map<String, int>> availableMoves = _getAvailableMoves();
    if (availableMoves.isEmpty) return null;

    return _minimaxMove(availableMoves, 3);
  }

  // NIGHTMARE AI - Minimax with depth 4 + perfect evaluation
  Map<String, int>? _getNightmareMove() {
    List<Map<String, int>> availableMoves = _getAvailableMoves();
    if (availableMoves.isEmpty) return null;

    return _minimaxMove(availableMoves, 4);
  }

  // Minimax implementation
  Map<String, int>? _minimaxMove(List<Map<String, int>> moves, int depth) {
    Map<String, int>? bestMove;
    int bestScore = -10000;

    for (var move in moves) {
      GameState gameState = _simulateMove(move, 'O');
      int score = _minimax(gameState, depth - 1, false, -10000, 10000);
      
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }

    return bestMove ?? moves[Random().nextInt(moves.length)];
  }

  int _minimax(GameState state, int depth, bool isMaximizing, int alpha, int beta) {
    String winner = _evaluateGameState(state);
    if (winner == 'O') return 1000 + depth;
    if (winner == 'X') return -1000 - depth;
    if (winner == 'D') return 0;
    if (depth == 0) return _evaluatePosition(state);

    List<Map<String, int>> moves = _getAvailableMovesFromState(state);
    if (moves.isEmpty) return 0;

    if (isMaximizing) {
      int maxEval = -10000;
      for (var move in moves) {
        GameState newState = _simulateMove(move, 'O', state);
        int eval = _minimax(newState, depth - 1, false, alpha, beta);
        maxEval = math.max(maxEval, eval);
        alpha = math.max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 10000;
      for (var move in moves) {
        GameState newState = _simulateMove(move, 'X', state);
        int eval = _minimax(newState, depth - 1, true, alpha, beta);
        minEval = math.min(minEval, eval);
        beta = math.min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  int _evaluatePosition(GameState state) {
    int score = 0;
    
    // Evaluate big board position
    score += _evaluateBigBoard(state.bigBoardStatus) * 10;
    
    // Evaluate mini boards
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (state.bigBoardStatus[i][j] == '') {
          score += _evaluateMiniBoard(state.board[i][j]);
        }
      }
    }
    
    return score;
  }

  int _evaluateBigBoard(List<List<String>> bigBoard) {
    int score = 0;
    List<List<List<int>>> patterns = [
      [[0,0], [0,1], [0,2]], [[1,0], [1,1], [1,2]], [[2,0], [2,1], [2,2]], // Rows
      [[0,0], [1,0], [2,0]], [[0,1], [1,1], [2,1]], [[0,2], [1,2], [2,2]], // Columns
      [[0,0], [1,1], [2,2]], [[0,2], [1,1], [2,0]] // Diagonals
    ];

    for (var pattern in patterns) {
      int botCount = 0, playerCount = 0;
      
      for (var pos in pattern) {
        String cell = bigBoard[pos[0]][pos[1]];
        if (cell == 'O') botCount++;
        else if (cell == 'X') playerCount++;
      }
      
      if (playerCount == 0) {
        if (botCount == 3) score += 100;
        else if (botCount == 2) score += 10;
        else if (botCount == 1) score += 1;
      } else if (botCount == 0) {
        if (playerCount == 3) score -= 100;
        else if (playerCount == 2) score -= 10;
        else if (playerCount == 1) score -= 1;
      }
    }

    return score;
  }

  int _evaluateMiniBoard(List<String> miniBoard) {
    int score = 0;
    List<List<int>> patterns = [
      [0,1,2], [3,4,5], [6,7,8], // Rows
      [0,3,6], [1,4,7], [2,5,8], // Columns
      [0,4,8], [2,4,6] // Diagonals
    ];

    for (var pattern in patterns) {
      int botCount = 0, playerCount = 0;
      
      for (int pos in pattern) {
        if (miniBoard[pos] == 'O') botCount++;
        else if (miniBoard[pos] == 'X') playerCount++;
      }
      
      if (playerCount == 0) {
        if (botCount == 2) score += 5;
        else if (botCount == 1) score += 1;
      } else if (botCount == 0) {
        if (playerCount == 2) score -= 5;
        else if (playerCount == 1) score -= 1;
      }
    }

    return score;
  }

  // Helper methods
  List<Map<String, int>> _getAvailableMoves() {
    List<Map<String, int>> availableMoves = [];

    for (int bigRow = 0; bigRow < 3; bigRow++) {
      for (int bigCol = 0; bigCol < 3; bigCol++) {
        if (bigBoardStatus[bigRow][bigCol] != "") continue;

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

    return availableMoves;
  }

  List<Map<String, int>> _getAvailableMovesFromState(GameState state) {
    List<Map<String, int>> availableMoves = [];

    for (int bigRow = 0; bigRow < 3; bigRow++) {
      for (int bigCol = 0; bigCol < 3; bigCol++) {
        if (state.bigBoardStatus[bigRow][bigCol] != "") continue;

        if (state.activeBigRow != null &&
            (bigRow != state.activeBigRow || bigCol != state.activeBigCol))
          continue;

        for (int i = 0; i < 9; i++) {
          if (state.board[bigRow][bigCol][i].isEmpty) {
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

    return availableMoves;
  }

  GameState _simulateMove(Map<String, int> move, String player, [GameState? currentState]) {
    GameState state = currentState ?? GameState.fromCurrent(board, bigBoardStatus, activeBigRow, activeBigCol);

    int bigRow = move["bigRow"]!;
    int bigCol = move["bigCol"]!;
    int smallIndex = move["smallRow"]! * 3 + move["smallCol"]!;

    state.board[bigRow][bigCol][smallIndex] = player;

    String miniResult = _checkMiniBoard(state.board[bigRow][bigCol]);
    if (miniResult != "") {
      state.bigBoardStatus[bigRow][bigCol] = miniResult;
      if (miniResult == "X" || miniResult == "O") {
        state.board[bigRow][bigCol] = List.generate(9, (_) => miniResult);
      } else if (miniResult == "D") {
        state.board[bigRow][bigCol] = List.generate(9, (_) => "D");
      }
    }

    int nextBigRow = move["smallRow"]!;
    int nextBigCol = move["smallCol"]!;

    if (state.bigBoardStatus[nextBigRow][nextBigCol] != "" ||
        state.board[nextBigRow][nextBigCol].every((c) => c.isNotEmpty)) {
      state.activeBigRow = null;
      state.activeBigCol = null;
    } else {
      state.activeBigRow = nextBigRow;
      state.activeBigCol = nextBigCol;
    }

    return state;
  }

  String _evaluateGameState(GameState state) {
    return _checkBigBoardFromState(state.bigBoardStatus);
  }

  String _checkBigBoardFromState(List<List<String>> bigBoard) {
    // Check rows
    for (int i = 0; i < 3; i++) {
      if (bigBoard[i][0] != "" &&
          bigBoard[i][0] != "D" &&
          bigBoard[i][0] == bigBoard[i][1] &&
          bigBoard[i][1] == bigBoard[i][2]) {
        return bigBoard[i][0];
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (bigBoard[0][i] != "" &&
          bigBoard[0][i] != "D" &&
          bigBoard[0][i] == bigBoard[1][i] &&
          bigBoard[1][i] == bigBoard[2][i]) {
        return bigBoard[0][i];
      }
    }

    // Check diagonals
    if (bigBoard[0][0] != "" &&
        bigBoard[0][0] != "D" &&
        bigBoard[0][0] == bigBoard[1][1] &&
        bigBoard[1][1] == bigBoard[2][2]) {
      return bigBoard[0][0];
    }

    if (bigBoard[0][2] != "" &&
        bigBoard[0][2] != "D" &&
        bigBoard[0][2] == bigBoard[1][1] &&
        bigBoard[1][1] == bigBoard[2][0]) {
      return bigBoard[0][2];
    }

    // Check if full
    bool isFull = true;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (bigBoard[i][j] == "") {
          isFull = false;
          break;
        }
      }
      if (!isFull) break;
    }

    return isFull ? "D" : "";
  }

  // Simple move finders for easier difficulties
  Map<String, int>? _findBigBoardWinMove(List<Map<String, int>> moves) {
    for (var move in moves) {
      List<List<String>> tempBigBoard = List.generate(
        3, (i) => List.generate(3, (j) => bigBoardStatus[i][j])
      );
      
      List<String> tempMiniBoard = List.from(board[move["bigRow"]!][move["bigCol"]!]);
      tempMiniBoard[move["smallRow"]! * 3 + move["smallCol"]!] = "O";
      
      String miniResult = _checkMiniBoard(tempMiniBoard);
      if (miniResult == "O") {
        tempBigBoard[move["bigRow"]!][move["bigCol"]!] = "O";
        
        if (_checkBigBoardWin(tempBigBoard, "O")) {
          return move;
        }
      }
    }
    return null;
  }

  Map<String, int>? _findBigBoardBlockMove(List<Map<String, int>> moves) {
    for (var move in moves) {
      List<List<String>> tempBigBoard = List.generate(
        3, (i) => List.generate(3, (j) => bigBoardStatus[i][j])
      );
      
      List<String> tempMiniBoard = List.from(board[move["bigRow"]!][move["bigCol"]!]);
      tempMiniBoard[move["smallRow"]! * 3 + move["smallCol"]!] = "X";
      
      String miniResult = _checkMiniBoard(tempMiniBoard);
      if (miniResult == "X") {
        tempBigBoard[move["bigRow"]!][move["bigCol"]!] = "X";
        
        if (_checkBigBoardWin(tempBigBoard, "X")) {
          return move;
        }
      }
    }
    return null;
  }

  Map<String, int>? _findMiniBoardWinMove(List<Map<String, int>> moves) {
    for (var move in moves) {
      List<String> tempMiniBoard = List.from(board[move["bigRow"]!][move["bigCol"]!]);
      tempMiniBoard[move["smallRow"]! * 3 + move["smallCol"]!] = "O";
      
      if (_checkMiniBoard(tempMiniBoard) == "O") {
        return move;
      }
    }
    return null;
  }

  Map<String, int>? _findMiniBoardBlockMove(List<Map<String, int>> moves) {
    for (var move in moves) {
      List<String> tempMiniBoard = List.from(board[move["bigRow"]!][move["bigCol"]!]);
      tempMiniBoard[move["smallRow"]! * 3 + move["smallCol"]!] = "X";
      
      if (_checkMiniBoard(tempMiniBoard) == "X") {
        return move;
      }
    }
    return null;
  }

  Map<String, int>? _findStrategicMove(List<Map<String, int>> moves) {
    List<Map<String, int>> goodMoves = [];

    for (var move in moves) {
      int score = 0;
      int smallPos = move["smallRow"]! * 3 + move["smallCol"]!;
      
      // Prefer center positions
      if (smallPos == 4) score += 10;
      
      // Prefer corners
      if ([0, 2, 6, 8].contains(smallPos)) score += 5;
      
      if (score > 0) {
        goodMoves.add({...move, "score": score});
      }
    }

    if (goodMoves.isNotEmpty) {
      goodMoves.sort((a, b) => b["score"]!.compareTo(a["score"]!));
      return goodMoves.first;
    }

    return null;
  }

  bool _checkBigBoardWin(List<List<String>> tempBigBoard, String player) {
    // Check rows
    for (int i = 0; i < 3; i++) {
      if (tempBigBoard[i][0] == player &&
          tempBigBoard[i][1] == player &&
          tempBigBoard[i][2] == player) {
        return true;
      }
    }

    // Check columns
    for (int i = 0; i < 3; i++) {
      if (tempBigBoard[0][i] == player &&
          tempBigBoard[1][i] == player &&
          tempBigBoard[2][i] == player) {
        return true;
      }
    }

    // Check diagonals
    if (tempBigBoard[0][0] == player &&
        tempBigBoard[1][1] == player &&
        tempBigBoard[2][2] == player) {
      return true;
    }

    if (tempBigBoard[0][2] == player &&
        tempBigBoard[1][1] == player &&
        tempBigBoard[2][0] == player) {
      return true;
    }

    return false;
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getDifficultyColor() {
    switch (botDifficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'expert':
        return Colors.purple;
      case 'nightmare':
        return Colors.black;
      default:
        return Colors.orange;
    }
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
                Row(
                  children: [
                    Text(
                      'Player vs Bot',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor().withOpacity(0.8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        botDifficulty.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Restart button
          Material(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: _showRestartDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 24,
                ),
              ),
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
                AnimatedBuilder(
                  animation: _botThinkingAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isBot
                            ? _getDifficultyColor()
                            : const Color(0xFF4ECDC4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            isBot ? Icons.psychology : Icons.person,
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
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (isBot) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor().withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${botDifficulty.toUpperCase()} AI',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (isBot && _botThinking) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Analyzing...',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.yellow[300],
                    ),
                  ),
                ],
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
                // Player Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPlayerCard("X", "You", false, currentPlayer == "X"),
                    _buildPlayerCard("O", "${botDifficulty.toUpperCase()} Bot", true, currentPlayer == "O"),
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
                                  ? (gameResult == "X" ? "🎉 You Win!" : 
                                     gameResult == "O" ? "😔 Bot Wins!" : "🤝 Draw!")
                                  : _botThinking
                                  ? "Bot is analyzing..."
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
                                  ? 'Game sudah berakhir'
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
            ],
          ),
        ),
      ),
    );
  }
}

// Game state class for minimax algorithm
class GameState {
  List<List<List<String>>> board;
  List<List<String>> bigBoardStatus;
  int? activeBigRow;
  int? activeBigCol;
  
  GameState(this.board, this.bigBoardStatus, this.activeBigRow, this.activeBigCol);
  
  factory GameState.fromCurrent(List<List<List<String>>> currentBoard, 
                                List<List<String>> currentBigBoard,
                                int? currentActiveBigRow,
                                int? currentActiveBigCol) {
    return GameState(
      List.generate(3, (i) => List.generate(3, (j) => List.from(currentBoard[i][j]))),
      List.generate(3, (i) => List.from(currentBigBoard[i])),
      currentActiveBigRow,
      currentActiveBigCol,
    );
  }
}
