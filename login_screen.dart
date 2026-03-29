import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/pocketbase_service.dart';
import 'main_menu_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final pbService = PocketBaseService();
  bool _isLoading = false;

  // Enhanced Animation controllers
  late AnimationController _titleController;
  late AnimationController _formController;
  late AnimationController _backgroundController;
  late AnimationController _loadingController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _boxGlowController;
  late AnimationController _orbitController;
  late AnimationController _waveController;

  late Animation<double> _titleScaleAnimation;
  late Animation<double> _titleOpacityAnimation;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formOpacityAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _boxGlowAnimation;
  late Animation<double> _orbitAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _checkIfAlreadyLoggedIn();
  }

  void _initAnimations() {
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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

    _particleController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _boxGlowController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    _orbitController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _titleScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.elasticOut),
    );

    _titleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeInOut));

    _formSlideAnimation = Tween<double>(begin: 120.0, end: 0.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );

    _formOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeInOut));

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _boxGlowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _boxGlowController, curve: Curves.easeInOut),
    );

    _orbitAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _orbitController, curve: Curves.linear),
    );

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _titleController.forward();
    _backgroundController.repeat();
    _particleController.repeat();
    _pulseController.repeat(reverse: true);
    _boxGlowController.repeat(reverse: true);
    _orbitController.repeat();
    _waveController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 600), () {
      _formController.forward();
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
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                  ),
                  child: child,
                ),
              );
            },
          ),
        );
        
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline, 
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Welcome back, $userName!",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: const Color(0xFF4CAF50),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.all(16),
                duration: const Duration(seconds: 3),
                elevation: 8,
              ),
            );
          }
        });
      }
    } catch (e) {
      print('Error checking authentication status: $e');
    }
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
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline, 
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Welcome, ${userData['name'] ?? 'User'}!",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            elevation: 8,
          ),
        );
        
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
                    Tween(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOutCubic)),
                  ),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.error_outline, 
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Login failed: ${e.toString().replaceFirst('Exception: ', '')}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
            elevation: 8,
          ),
        );
      }
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildPortraitLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Stack(
                children: [
                  _buildEnhancedFloatingElements(),
                  Column(
                    children: [
                      _buildEnhancedTitleSection(),
                      const Spacer(),
                      _buildPremiumLoginBox(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandscapeLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          children: [
            _buildEnhancedFloatingElements(),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildEnhancedTitleSection(),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: _buildPremiumLoginBox(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedFloatingElements() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_backgroundAnimation, _particleAnimation, _orbitAnimation, _waveAnimation]),
      builder: (context, child) {
        return Stack(
          children: [
            // Animated wave background
            ...List.generate(3, (index) {
              final delay = index * 0.3;
              final wavePhase = (_waveAnimation.value + delay) % 1.0;
              
              return Positioned.fill(
                child: CustomPaint(
                  painter: WavePainter(
                    wavePhase: wavePhase,
                    opacity: 0.05 + (index * 0.02),
                    color: [
                      const Color(0xFFFFD700),
                      const Color(0xFFFFA500),
                      const Color(0xFFFF69B4),
                    ][index],
                  ),
                ),
              );
            }),

            // Enhanced orbiting particles
            ...List.generate(12, (index) {
              final angle = (index * 30.0) + (_orbitAnimation.value * 360);
              final radius = 80.0 + (index * 15);
              final centerX = screenSize.width * 0.5;
              final centerY = screenSize.height * 0.35;
              final x = centerX + radius * math.cos(angle * math.pi / 180);
              final y = centerY + radius * math.sin(angle * math.pi / 180);
              
              return Positioned(
                left: x - 8,
                top: y - 8,
                child: Transform.rotate(
                  angle: angle * math.pi / 180,
                  child: Container(
                    width: 6 + (index % 3),
                    height: 6 + (index % 3),
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          [
                            const Color(0xFFFFD700),
                            const Color(0xFFFFA500),
                            const Color(0xFFFF69B4),
                            const Color(0xFF9C27B0),
                          ][index % 4],
                          Colors.transparent,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: [
                            const Color(0xFFFFD700),
                            const Color(0xFFFFA500),
                            const Color(0xFFFF69B4),
                            const Color(0xFF9C27B0),
                          ][index % 4].withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            
            // Enhanced floating symbols
            Positioned(
              top: (screenSize.height * 0.12) + (50 * math.sin(_backgroundAnimation.value * 2 * math.pi)),
              left: screenSize.width * 0.08,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 1.5 * math.pi,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD700).withOpacity(0.2),
                        const Color(0xFFFFA500).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    '×',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 32 : 40,
                      color: const Color(0xFFFFD700).withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            Positioned(
              top: (screenSize.height * 0.22) + (40 * math.cos(_backgroundAnimation.value * 1.8 * math.pi)),
              right: screenSize.width * 0.12,
              child: Transform.rotate(
                angle: -_backgroundAnimation.value * 2 * math.pi,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF69B4).withOpacity(0.25),
                        const Color(0xFF9C27B0).withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF69B4).withOpacity(0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF69B4).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    '○',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 36,
                      color: const Color(0xFFFF69B4).withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            // Additional mystical elements
            Positioned(
              bottom: (screenSize.height * 0.25) + (45 * math.sin(_backgroundAnimation.value * 2.5 * math.pi)),
              left: screenSize.width * 0.06,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 2.2 * math.pi,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00E5FF).withOpacity(0.3),
                        const Color(0xFF3F51B5).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: const Color(0xFF00E5FF).withOpacity(0.7),
                    size: isSmallScreen ? 24 : 32,
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: (screenSize.height * 0.35) + (30 * math.cos(_backgroundAnimation.value * 3 * math.pi)),
              right: screenSize.width * 0.1,
              child: Transform.rotate(
                angle: -_backgroundAnimation.value * 1.8 * math.pi,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE91E63).withOpacity(0.3),
                        const Color(0xFF673AB7).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.diamond_outlined,
                    color: const Color(0xFFE91E63).withOpacity(0.8),
                    size: isSmallScreen ? 20 : 28,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedTitleSection() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isLandscape = screenSize.width > screenSize.height;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_titleController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _titleScaleAnimation.value,
          child: Opacity(
            opacity: _titleOpacityAnimation.value,
            child: Container(
              margin: EdgeInsets.only(
                top: isLandscape ? 20 : (isSmallScreen ? 40 : 60),
              ),
              child: Column(
                children: [
                  // Enhanced logo with sophisticated animations
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: isSmallScreen ? 90 : 110,
                      height: isSmallScreen ? 90 : 110,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFFA500),
                            Color(0xFFFF8C00),
                            Color(0xFFFF69B4),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [0.0, 0.3, 0.7, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 15),
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFA500).withOpacity(0.4),
                            blurRadius: 60,
                            spreadRadius: 10,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF69B4).withOpacity(0.3),
                            blurRadius: 100,
                            spreadRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background glow effect
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(isSmallScreen ? 25 : 30),
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  Colors.white.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                          
                          // Main icon
                          Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.grid_3x3,
                              size: isSmallScreen ? 45 : 55,
                              color: Colors.white,
                            ),
                          ),
                          
                          // Top highlight
                          Positioned(
                            top: 8,
                            left: 8,
                            right: 8,
                            child: Container(
                              height: isSmallScreen ? 25 : 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.4),
                                    Colors.white.withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 20 : 28),
                  
                  // Enhanced title with sophisticated gradient
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: const [
                        Color(0xFFFFD700),
                        Color(0xFFFFA500),
                        Color(0xFFFF8C00),
                        Color(0xFFFF69B4),
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'MEGA',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 42 : 54,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: isSmallScreen ? 6 : 8,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(3, 3),
                            blurRadius: 8,
                          ),
                          Shadow(
                            color: const Color(0xFFFFD700).withOpacity(0.3),
                            offset: const Offset(-2, -2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Text(
                      'X / O',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(1, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: isSmallScreen ? 20 : 28),
                  
                  // Enhanced welcome badge with animations
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 24 : 28,
                      vertical: isSmallScreen ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFD700),
                                Color(0xFFFFA500),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.waving_hand,
                            color: Colors.white,
                            size: isSmallScreen ? 16 : 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            child: CustomPaint(
              painter: GoogleIconPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedGoogleLoginButton() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 68 : 76,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFF1976D2),
            Color(0xFF0D47A1),
            Color(0xFF1A237E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.4, 0.8, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF1976D2).withOpacity(0.4),
            blurRadius: 60,
            spreadRadius: 8,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 2,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _loginWithGoogle,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: _isLoading
                ? AnimatedBuilder(
                    animation: _loadingAnimation,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.rotate(
                            angle: _loadingAnimation.value * 2 * math.pi,
                            child: Container(
                              width: isSmallScreen ? 28 : 32,
                              height: isSmallScreen ? 28 : 32,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Text(
                            'Signing In...',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildGoogleIcon(),
                      const SizedBox(width: 24),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 20 : 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLoginBox() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isLandscape = screenSize.width > screenSize.height;
    
    return AnimatedBuilder(
      animation: Listenable.merge([_formController, _boxGlowController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _formSlideAnimation.value),
          child: Opacity(
            opacity: _formOpacityAnimation.value,
            child: Container(
              margin: EdgeInsets.all(isSmallScreen ? 24 : 32),
              constraints: BoxConstraints(
                maxWidth: isLandscape ? 520 : double.infinity,
              ),
              decoration: BoxDecoration(
                // Enhanced glass morphism
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  // Main depth shadow
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 50,
                    spreadRadius: 15,
                    offset: const Offset(0, 25),
                  ),
                  // Colored glow
                  BoxShadow(
                    color: const Color(0xFFFF69B4).withOpacity(0.4 * _boxGlowAnimation.value),
                    blurRadius: 100,
                    spreadRadius: 20,
                    offset: const Offset(0, 15),
                  ),
                  // Top highlight
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: -5,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    padding: EdgeInsets.all(isSmallScreen ? 36 : 44),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.08),
                          Colors.white.withOpacity(0.03),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Enhanced security badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.security,
                                  color: Colors.white,
                                  size: isSmallScreen ? 18 : 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Secure Login',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 28 : 36),
                        
                        // Enhanced title with better shadows
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 36 : 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(3, 3),
                                blurRadius: 12,
                              ),
                              Shadow(
                                color: const Color(0xFFFFD700).withOpacity(0.3),
                                offset: const Offset(-2, -2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        
                        Text(
                          'Sign in to continue your game',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 20,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        
                        // Enhanced divider with gradient
                        Container(
                          margin: EdgeInsets.only(
                            top: isSmallScreen ? 20 : 24,
                            bottom: isSmallScreen ? 36 : 44,
                          ),
                          height: 5,
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFD700),
                                Color(0xFFFFA500),
                                Color(0xFFFF8C00),
                                Color(0xFFFF69B4),
                              ],
                              stops: [0.0, 0.3, 0.7, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.8),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        
                        _buildEnhancedGoogleLoginButton(),
                        
                        SizedBox(height: isSmallScreen ? 28 : 36),
                        
                        // Enhanced privacy section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.privacy_tip_outlined,
                                  color: Colors.white.withOpacity(0.8),
                                  size: isSmallScreen ? 18 : 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _launchURL('https://megaxo-dev.lightcodedigital.cloud'),
                                child: Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    decoration: TextDecoration.underline,
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFF4A148C),
              Color(0xFF2E003E),
              Color(0xFF1A0033),
              Color(0xFF0D001A),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.3, 0.6, 0.85, 1.0],
          ),
        ),
        child: SafeArea(
          child: isLandscape
              ? _buildLandscapeLayout()
              : _buildPortraitLayout(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _formController.dispose();
    _backgroundController.dispose();
    _loadingController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _boxGlowController.dispose();
    _orbitController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}

// Custom wave painter for animated background waves
class WavePainter extends CustomPainter {
  final double wavePhase;
  final double opacity;
  final Color color;

  WavePainter({
    required this.wavePhase,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    final waveHeight = size.height * 0.1;
    final waveLength = size.width;
    
    path.moveTo(0, size.height);
    
    for (double x = 0; x <= size.width; x++) {
      final relativeX = x / waveLength;
      final sine = math.sin((relativeX * 2 * math.pi) + (wavePhase * 2 * math.pi));
      final y = size.height * 0.7 + (sine * waveHeight);
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
           oldDelegate.opacity != opacity ||
           oldDelegate.color != color;
  }
}

// Custom painter for Google icon
class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Google Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.2)
        ..lineTo(size.width * 0.8, size.height * 0.2)
        ..lineTo(size.width * 0.8, size.height * 0.4)
        ..lineTo(size.width * 0.6, size.height * 0.4)
        ..lineTo(size.width * 0.6, size.height * 0.6)
        ..lineTo(size.width * 0.8, size.height * 0.6)
        ..lineTo(size.width * 0.8, size.height * 0.8)
        ..lineTo(size.width * 0.5, size.height * 0.8)
        ..close(),
      paint,
    );
    
    // Google Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.2, size.height * 0.2)
        ..lineTo(size.width * 0.5, size.height * 0.2)
        ..lineTo(size.width * 0.5, size.height * 0.5)
        ..lineTo(size.width * 0.2, size.height * 0.5)
        ..close(),
      paint,
    );
    
    // Google Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.2, size.height * 0.5)
        ..lineTo(size.width * 0.5, size.height * 0.5)
        ..lineTo(size.width * 0.5, size.height * 0.8)
        ..lineTo(size.width * 0.2, size.height * 0.8)
        ..close(),
      paint,
    );
    
    // Google Green
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.5, size.height * 0.5)
        ..lineTo(size.width * 0.6, size.height * 0.5)
        ..lineTo(size.width * 0.6, size.height * 0.8)
        ..lineTo(size.width * 0.5, size.height * 0.8)
        ..close(),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}