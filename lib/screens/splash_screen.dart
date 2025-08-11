import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/pocketbase_service.dart';
import 'login_screen.dart';
import 'main_menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  final pbService = PocketBaseService();
  
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;

  String _statusText = "Initializing...";

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Logo animations
    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    // Text animations
    _textSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Background animation
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    // Particle animation
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );

    // Start animations sequence
    _logoController.forward();
    _backgroundController.repeat();
    _particleController.repeat();

    Future.delayed(const Duration(milliseconds: 800), () {
      _textController.forward();
    });

    // Initialize and check authentication
    _initializeAndCheckAuth();
  }

  Future<void> _initializeAndCheckAuth() async {
    try {
      // Update status
      setState(() {
        _statusText = "Initializing services...";
      });

      // Initialize PocketBase service
      await pbService.init();

      // Update status
      setState(() {
        _statusText = "Checking authentication...";
      });

      // Wait for splash animation
      await Future.delayed(const Duration(milliseconds: 2500));
      
      if (!mounted) return;

      // Check if user is logged in
      final isLoggedIn = await pbService.isUserLoggedIn();
      
      if (isLoggedIn) {
        // Update status
        setState(() {
          _statusText = "Welcome back!";
        });
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          // User is logged in, go to main menu
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainMenuScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      } else {
        // Update status
        setState(() {
          _statusText = "Redirecting to login...";
        });
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          // User is not logged in, go to login screen
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const LoginScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      }
    } catch (e) {
      print("Error during initialization: $e");
      
      // Update status with error
      setState(() {
        _statusText = "Connection error, redirecting...";
      });
      
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        // Error occurred, go to login screen
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Widget _buildFloatingSymbols() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Floating X symbols
            Positioned(
              top: 80 + (30 * _backgroundAnimation.value),
              left: 30,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 2 * 3.14159,
                child: Text(
                  '×',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white.withOpacity(0.1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 150 - (20 * _backgroundAnimation.value),
              right: 50,
              child: Transform.rotate(
                angle: -_backgroundAnimation.value * 1.5 * 3.14159,
                child: Text(
                  '○',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white.withOpacity(0.08),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200 + (25 * _backgroundAnimation.value),
              left: 60,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 1.8 * 3.14159,
                child: Text(
                  '×',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white.withOpacity(0.06),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 120 - (15 * _backgroundAnimation.value),
              right: 40,
              child: Transform.rotate(
                angle: -_backgroundAnimation.value * 2.2 * 3.14159,
                child: Text(
                  '○',
                  style: TextStyle(
                    fontSize: 36,
                    color: Colors.white.withOpacity(0.07),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Additional floating symbols
            Positioned(
              top: 300 + (20 * _backgroundAnimation.value),
              right: 80,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 1.2 * 3.14159,
                child: Text(
                  '×',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.05),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 300 + (35 * _backgroundAnimation.value),
              left: 40,
              child: Transform.rotate(
                angle: -_backgroundAnimation.value * 1.7 * 3.14159,
                child: Text(
                  '○',
                  style: TextStyle(
                    fontSize: 26,
                    color: Colors.white.withOpacity(0.06),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildParticleEffects() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(8, (index) {
            double delay = index * 0.1;
            double progress = (_particleAnimation.value - delay).clamp(
              0.0,
              1.0,
            );

            return Positioned(
              top: 100 + (index * 60) + (progress * 50),
              left: 20 + (index * 40) + (progress * 30),
              child: Opacity(
                opacity: (1.0 - progress) * 0.3,
                child: Container(
                  width: 4 + (progress * 2),
                  height: 4 + (progress * 2),
                  decoration: BoxDecoration(
                    color: Colors.yellow[300],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Opacity(
            opacity: _logoOpacityAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFFFA500),
                    Color(0xFFFF8C00),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.6),
                    blurRadius: 25,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CustomPaint(painter: ModernTicTacToePainter()),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _textSlideAnimation.value),
          child: Opacity(
            opacity: _textOpacityAnimation.value,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                      Color(0xFFFF8C00),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'MEGA',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 8,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'X / O ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 3,
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

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                  ),
                  child: Transform.rotate(
                    angle: _backgroundAnimation.value * 2 * 3.14159,
                    child: const Icon(
                      Icons.sync,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _statusText,
                    key: ValueKey(_statusText),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5800FF), Color(0xFF330066), Color(0xFF1A0033)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            _buildFloatingSymbols(),
            _buildParticleEffects(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildTitle(),
                ],
              ),
            ),
            _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }
}

class ModernTicTacToePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final double cellSize = size.width / 3;

    // Draw grid lines with rounded corners
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(i * cellSize, 10),
        Offset(i * cellSize, size.height - 10),
        linePaint,
      );
      canvas.drawLine(
        Offset(10, i * cellSize),
        Offset(size.width - 10, i * cellSize),
        linePaint,
      );
    }

    // Draw X and O symbols with modern styling
    final symbolPaint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw X in center
    symbolPaint.color = Colors.red[300]!;
    double centerX = cellSize + cellSize / 2;
    double centerY = cellSize + cellSize / 2;
    double symbolSize = cellSize * 0.3;

    canvas.drawLine(
      Offset(centerX - symbolSize, centerY - symbolSize),
      Offset(centerX + symbolSize, centerY + symbolSize),
      symbolPaint,
    );
    canvas.drawLine(
      Offset(centerX + symbolSize, centerY - symbolSize),
      Offset(centerX - symbolSize, centerY + symbolSize),
      symbolPaint,
    );

    // Draw O symbols
    symbolPaint.color = Colors.blue[300]!;
    symbolPaint.style = PaintingStyle.stroke;

    // O in top-left
    canvas.drawCircle(
      Offset(cellSize / 2, cellSize / 2),
      symbolSize,
      symbolPaint,
    );

    // O in bottom-right
    canvas.drawCircle(
      Offset(cellSize * 2.5, cellSize * 2.5),
      symbolSize,
      symbolPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}