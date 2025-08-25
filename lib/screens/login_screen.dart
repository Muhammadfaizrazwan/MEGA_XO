import 'package:flutter/material.dart';
import '../services/pocketbase_service.dart';
import 'main_menu_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final pbService = PocketBaseService();
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late AnimationController _loadingController;
  late AnimationController _logoController;
  late AnimationController _typewriterController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _typewriterAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonGlowAnimation;

  // Typewriter text
  final String _typewriterText = "Game On!";
  String _displayText = "";

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _checkIfAlreadyLoggedIn();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _typewriterController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _logoScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _logoRotationAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _typewriterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typewriterController, curve: Curves.easeInOut),
    );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _buttonGlowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Typewriter animation listener
    _typewriterAnimation.addListener(() {
      final progress = _typewriterAnimation.value;
      final targetLength = (_typewriterText.length * progress).round();
      setState(() {
        _displayText = _typewriterText.substring(0, targetLength);
      });
    });
  }

  void _startAnimations() {
    _fadeController.forward();
    _backgroundController.repeat();
    _logoController.repeat(reverse: true);
    _buttonController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 600), () {
      _slideController.forward();
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      _typewriterController.forward();
    });
  }

  Future<void> _checkIfAlreadyLoggedIn() async {
    try {
      await pbService.init();
      final isAuthenticated = await pbService.isUserLoggedIn();
      
      if (isAuthenticated && mounted) {
        final userInfo = await pbService.getUserInfo();
        final userName = userInfo['name'] ?? 'User';
        
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainMenuScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(0.0, -1.0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic)),
                ),
                child: child,
              );
            },
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showSnackBar("Welcome back, $userName!", isSuccess: true);
          }
        });
      }
    } catch (e) {
      print('Error checking authentication status: $e');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isSuccess 
            ? const Color(0xFF10B981) 
            : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
        duration: Duration(seconds: isSuccess ? 2 : 3),
        elevation: 12,
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    _loadingController.repeat();

    try {
      final userData = await pbService.loginWithGoogle();
      
      if (mounted) {
        _loadingController.stop();
        
        _showSnackBar("Welcome, ${userData['name'] ?? 'User'}!", isSuccess: true);
        
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainMenuScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeInOutCubic)),
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _loadingController.reset();
        
        _showSnackBar("Login failed: ${e.toString().replaceFirst('Exception: ', '')}");
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _loadingController.dispose();
    _logoController.dispose();
    _typewriterController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F0F23),
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                const Color(0xFF0F0F23),
              ],
              stops: [
                0.0 + (_backgroundAnimation.value * 0.1),
                0.3 + (_backgroundAnimation.value * 0.1),
                0.7 + (_backgroundAnimation.value * 0.1),
                1.0 + (_backgroundAnimation.value * 0.1),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Animated dots pattern
              ...List.generate(12, (index) {
                final double x = (index % 4) * 0.25 + 0.125;
                final double y = (index ~/ 4) * 0.33 + 0.16;
                final double delay = index * 0.5;
                
                return AnimatedBuilder(
                  animation: _backgroundAnimation,
                  builder: (context, child) {
                    final animValue = ((_backgroundAnimation.value + delay) % 2.0);
                    final opacity = (animValue < 1.0) 
                        ? animValue 
                        : 2.0 - animValue;
                    
                    return Positioned(
                      left: MediaQuery.of(context).size.width * x,
                      top: MediaQuery.of(context).size.height * y,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(opacity * 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                );
              }),
              // Gradient overlay for depth
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.3, -0.5),
                    radius: 1.2,
                    colors: [
                      const Color(0xFFFBBF24).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          child: Transform.rotate(
            angle: _logoRotationAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFBBF24), // Yellow/Gold
                    Color(0xFFF59E0B), // Amber
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFBBF24).withOpacity(0.4),
                    blurRadius: 32,
                    spreadRadius: 4,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/icon.png', // Ganti dengan path gambar logo Anda
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildLogo(),
          const SizedBox(height: 32),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFBBF24), // Gold
                Color(0xFFF59E0B), // Amber
                Color(0xFFEAB308), // Yellow
              ],
            ).createShader(bounds),
            child: const Text(
              'MEGA X/O',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Typewriter animation text
          SizedBox(
            height: 24,
            child: AnimatedBuilder(
              animation: _typewriterAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _displayText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    // Blinking cursor
                    if (_typewriterAnimation.value < 1.0 || 
                        (_typewriterAnimation.value == 1.0 && 
                         DateTime.now().millisecondsSinceEpoch % 1000 < 500))
                      Container(
                        width: 2,
                        height: 20,
                        margin: const EdgeInsets.only(left: 2),
                        color: const Color(0xFFFBBF24),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonScaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFFFFF),
                  const Color(0xFFF8FAFC),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                // Glowing effect
                BoxShadow(
                  color: const Color(0xFF4285F4).withOpacity(_buttonGlowAnimation.value * 0.3),
                  blurRadius: 32,
                  spreadRadius: 0,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : _loginWithGoogle,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _isLoading
                      ? AnimatedBuilder(
                          animation: _loadingAnimation,
                          builder: (context, child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(0xFF4285F4).withOpacity(0.8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Signing you in...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google Logo with correct colors
                            Container(
                              width: 32,
                              height: 32,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                size: const Size(20, 20),
                                painter: GoogleLogoPainter(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginCard() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 0,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFBBF24).withOpacity(0.2),
                      const Color(0xFFF59E0B).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFBBF24).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.rocket_launch_rounded,
                      size: 20,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Ready to Play?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to save your progress and compete with players worldwide',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildGoogleButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.width > size.height;
    
    return Scaffold(
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          SafeArea(
            child: isLandscape
                ? _buildLandscapeLayout()
                : _buildPortraitLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        const SizedBox(height: 60),
        _buildHeader(),
        const Spacer(),
        _buildLoginCard(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Center(child: _buildHeader()),
          ),
          Expanded(
            flex: 1,
            child: Center(child: _buildLoginCard()),
          ),
        ],
      ),
    );
  }
}

// Custom Painter untuk Google Logo dengan warna yang benar
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Google "G" path
    final path = Path();
    
    // Blue part (left)
    paint.color = const Color(0xFF4285F4);
    path.moveTo(size.width * 0.5, size.height * 0.1);
    path.lineTo(size.width * 0.9, size.height * 0.1);
    path.lineTo(size.width * 0.9, size.height * 0.4);
    path.lineTo(size.width * 0.6, size.height * 0.4);
    path.lineTo(size.width * 0.6, size.width * 0.6);
    path.lineTo(size.width * 0.9, size.height * 0.6);
    path.lineTo(size.width * 0.9, size.height * 0.9);
    path.lineTo(size.width * 0.5, size.height * 0.9);
    path.arcToPoint(
      Offset(size.width * 0.1, size.height * 0.5),
      radius: Radius.circular(size.width * 0.4),
      clockwise: false,
    );
    path.arcToPoint(
      Offset(size.width * 0.5, size.height * 0.1),
      radius: Radius.circular(size.width * 0.4),
      clockwise: false,
    );
    canvas.drawPath(path, paint);

    // Red part (top-right curve)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path();
    redPath.moveTo(size.width * 0.5, size.height * 0.1);
    redPath.arcToPoint(
      Offset(size.width * 0.85, size.height * 0.25),
      radius: Radius.circular(size.width * 0.4),
      clockwise: true,
    );
    redPath.lineTo(size.width * 0.75, size.height * 0.35);
    redPath.arcToPoint(
      Offset(size.width * 0.5, size.height * 0.25),
      radius: Radius.circular(size.width * 0.25),
      clockwise: false,
    );
    redPath.close();
    canvas.drawPath(redPath, paint);

    // Yellow part (bottom-left curve)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path();
    yellowPath.moveTo(size.width * 0.15, size.height * 0.75);
    yellowPath.arcToPoint(
      Offset(size.width * 0.5, size.height * 0.9),
      radius: Radius.circular(size.width * 0.4),
      clockwise: true,
    );
    yellowPath.lineTo(size.width * 0.5, size.height * 0.75);
    yellowPath.arcToPoint(
      Offset(size.width * 0.25, size.height * 0.65),
      radius: Radius.circular(size.width * 0.25),
      clockwise: false,
    );
    yellowPath.close();
    canvas.drawPath(yellowPath, paint);

    // Green part (bottom-right)
    paint.color = const Color(0xFF34A853);
    final greenRect = Rect.fromLTWH(
      size.width * 0.5, 
      size.height * 0.6, 
      size.width * 0.4, 
      size.height * 0.3
    );
    canvas.drawRect(greenRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}