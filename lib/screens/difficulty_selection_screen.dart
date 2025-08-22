import 'package:flutter/material.dart';
import 'dart:math';
import 'pve_screen.dart';

class DifficultySelectionScreen extends StatefulWidget {
  const DifficultySelectionScreen({super.key});

  @override
  State<DifficultySelectionScreen> createState() => _DifficultySelectionScreenState();
}

class _DifficultySelectionScreenState extends State<DifficultySelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late AnimationController _titleController;
  
  late Animation<double> _backgroundAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _titleAnimation;

  @override
  void initState() {
    super.initState();
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _cardSlideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeInOut),
    );

    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.elasticOut),
    );

    // Start animations
    _backgroundController.repeat();
    _titleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: DifficultyBackgroundPainter(
            animation: _backgroundAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _titleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _titleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Material(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
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
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ).createShader(bounds),
                        child: const Text(
                          'Select Difficulty',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Text(
                        'Choose your challenge level',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
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

  Widget _buildDifficultyCard({
    required String title,
    required String subtitle,
    required String description,
    required String winRate,
    required Color color,
    required Color accentColor,
    required int stars,
    required String difficulty,
    required IconData icon,
    required int index,
    bool isSpecial = false,
  }) {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value * (index + 1) * 0.5),
          child: Opacity(
            opacity: _cardFadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Material(
                elevation: isSpecial ? 20 : 12,
                borderRadius: BorderRadius.circular(20),
                shadowColor: color.withOpacity(0.5),
                child: InkWell(
                  onTap: () => _startGame(difficulty),
                  borderRadius: BorderRadius.circular(20),
                  splashColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSpecial 
                          ? [
                              color.withOpacity(0.9),
                              accentColor.withOpacity(0.8),
                              Colors.black.withOpacity(0.9),
                            ]
                          : [
                              color.withOpacity(0.9),
                              accentColor.withOpacity(0.8),
                            ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSpecial 
                          ? Colors.white.withOpacity(0.5)
                          : Colors.white.withOpacity(0.2),
                        width: isSpecial ? 2 : 1,
                      ),
                      boxShadow: isSpecial ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 25,
                          spreadRadius: 3,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ] : [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Icon Section
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Content Section
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (isSpecial)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.8),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'SPECIAL',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white60,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Stats Section
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Star Rating
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (starIndex) {
                                  return Icon(
                                    starIndex < stars ? Icons.star : Icons.star_border,
                                    color: starIndex < stars 
                                      ? Colors.amber 
                                      : Colors.white.withOpacity(0.3),
                                    size: 16,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              // Win Rate
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Win: $winRate',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _startGame(String difficulty) {
    // Show loading animation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2D1B69),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  'Preparing ${difficulty.toUpperCase()} Bot...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Get ready for the challenge!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Navigate to game after delay
    Future.delayed(const Duration(milliseconds: 2000), () {
      Navigator.of(context).pop(); // Close loading dialog
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PvEScreen(difficulty: difficulty),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF5800FF),
              Color(0xFF330066),
              Color(0xFF1A0033),
              Color(0xFF0D001A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4, 0.8, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          
                          // Easy
                          _buildDifficultyCard(
                            title: 'EASY',
                            subtitle: 'Perfect for beginners',
                            description: 'Random moves with basic strategy',
                            winRate: '~85%',
                            color: Colors.green,
                            accentColor: Colors.lightGreen,
                            stars: 1,
                            difficulty: 'easy',
                            icon: Icons.sentiment_very_satisfied,
                            index: 0,
                          ),
                          
                          // Medium
                          _buildDifficultyCard(
                            title: 'MEDIUM',
                            subtitle: 'Balanced challenge',
                            description: 'Smart moves with tactical thinking',
                            winRate: '~65%',
                            color: Colors.orange,
                            accentColor: Colors.deepOrange,
                            stars: 2,
                            difficulty: 'medium',
                            icon: Icons.sentiment_satisfied,
                            index: 1,
                          ),
                          
                          // Hard
                          _buildDifficultyCard(
                            title: 'HARD',
                            subtitle: 'Advanced AI',
                            description: 'Minimax algorithm with lookahead',
                            winRate: '~35%',
                            color: Colors.red,
                            accentColor: Colors.redAccent,
                            stars: 3,
                            difficulty: 'hard',
                            icon: Icons.sentiment_neutral,
                            index: 2,
                          ),
                          
                          // Expert
                          _buildDifficultyCard(
                            title: 'EXPERT',
                            subtitle: 'Master level',
                            description: 'Alpha-beta pruning with deep analysis',
                            winRate: '~15%',
                            color: Colors.purple,
                            accentColor: Colors.deepPurple,
                            stars: 4,
                            difficulty: 'expert',
                            icon: Icons.sentiment_dissatisfied,
                            index: 3,
                          ),
                          
                          // Nightmare
                          _buildDifficultyCard(
                            title: 'NIGHTMARE',
                            subtitle: 'Nearly impossible',
                            description: 'Perfect play with maximum depth',
                            winRate: '~5%',
                            color: Colors.black,
                            accentColor: Colors.grey[800]!,
                            stars: 5,
                            difficulty: 'nightmare',
                            icon: Icons.sentiment_very_dissatisfied,
                            index: 4,
                            isSpecial: true,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Info text
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '💡 Tip: Start with Easy mode to learn the game mechanics, then gradually increase difficulty as you improve!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DifficultyBackgroundPainter extends CustomPainter {
  final double animation;

  DifficultyBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Animated gradient waves
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    
    for (double x = 0; x <= size.width; x += 1) {
      double y = size.height * 0.8 + 
                 25 * sin((x / size.width * 6 * pi) + animation * 2 * pi) +
                 15 * sin((x / size.width * 10 * pi) + animation * 3 * pi);
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF6A0DAD).withOpacity(0.3),
        const Color(0xFF8A2BE2).withOpacity(0.2),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawPath(path, paint);

    // Floating particles
    paint.shader = null;
    for (int i = 0; i < 20; i++) {
      double x = (i * 73 + animation * 50) % size.width;
      double y = (i * 97 + animation * 30) % size.height;
      double opacity = (sin(animation * 2 * pi + i) + 1) / 2 * 0.15;
      
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 3, paint);
    }

    // Grid overlay
    paint.color = Colors.white.withOpacity(0.02);
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;
    
    double gridSize = 60;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
