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
  late AnimationController _titleController;
  late AnimationController _formController;
  late AnimationController _backgroundController;
  late AnimationController _loadingController;
  late AnimationController _pulseController;

  late Animation<double> _titleScaleAnimation;
  late Animation<double> _titleOpacityAnimation;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formOpacityAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _loadingAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _checkIfAlreadyLoggedIn();
  }

  void _initAnimations() {
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _formController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _titleScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.elasticOut),
    );

    _titleOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _titleController, curve: Curves.easeIn));

    _formSlideAnimation = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutBack),
    );

    _formOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeIn));

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _titleController.forward();
    _backgroundController.repeat();
    _pulseController.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 800), () {
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
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? const Color(0xFF00C851) : const Color(0xFFFF3547),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isSuccess ? 2 : 3),
        elevation: 8,
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
    _titleController.dispose();
    _formController.dispose();
    _backgroundController.dispose();
    _loadingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildFloatingElements() {
    final screenSize = MediaQuery.of(context).size;
    
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Sharp geometric shapes floating with colors matching the purple theme
            Positioned(
              top: screenSize.height * 0.1 + (40 * _backgroundAnimation.value),
              left: screenSize.width * 0.05,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 2 * 3.14159,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFBBF24).withOpacity(0.3), // Gold/Yellow like your logo
                    border: Border.all(
                      color: const Color(0xFFFBBF24),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenSize.height * 0.3 - (30 * _backgroundAnimation.value),
              right: screenSize.width * 0.08,
              child: Transform.rotate(
                angle: -_backgroundAnimation.value * 1.5 * 3.14159,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFE879F9).withOpacity(0.25), // Light purple/pink
                    border: Border.all(
                      color: const Color(0xFFE879F9),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: screenSize.height * 0.25 + (35 * _backgroundAnimation.value),
              left: screenSize.width * 0.12,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 1.8 * 3.14159,
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFBBF24).withOpacity(0.2), // Gold matching logo
                    border: Border.all(
                      color: const Color(0xFFFBBF24),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: screenSize.height * 0.4 - (20 * _backgroundAnimation.value),
              right: screenSize.width * 0.15,
              child: Transform.rotate(
                angle: -_backgroundAnimation.value * 2.2 * 3.14159,
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFC084FC).withOpacity(0.3), // Light purple
                    border: Border.all(
                      color: const Color(0xFFC084FC),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            // Additional sharp geometric elements with purple theme
            Positioned(
              top: screenSize.height * 0.15 - (25 * _backgroundAnimation.value),
              right: screenSize.width * 0.25,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 3 * 3.14159,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA855F7).withOpacity(0.25), // Medium purple
                    border: Border.all(
                      color: const Color(0xFFA855F7),
                      width: 2,
                    ),
                  ),
                  transform: Matrix4.rotationZ(0.785398), // 45 degrees for diamond shape
                ),
              ),
            ),
            Positioned(
              bottom: screenSize.height * 0.15 + (45 * _backgroundAnimation.value),
              right: screenSize.width * 0.05,
              child: Transform.rotate(
                angle: -_backgroundAnimation.value * 1.2 * 3.14159,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF3E8FF).withOpacity(0.3), // Very light purple
                    border: Border.all(
                      color: const Color(0xFFF3E8FF),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTitleSection() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isLandscape = screenSize.width > screenSize.height;
    
    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _titleScaleAnimation.value,
          child: Opacity(
            opacity: _titleOpacityAnimation.value,
            child: Container(
              margin: EdgeInsets.only(
                top: isLandscape ? 20 : (isSmallScreen ? 30 : 50),
              ),
              child: Column(
                children: [
                  // Logo with pulse animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: isSmallScreen ? 80 : 100,
                          height: isSmallScreen ? 80 : 100,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFBBF24), // Yellow/Gold
                                Color(0xFFF59E0B), // Amber
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFBBF24).withOpacity(0.4),
                                blurRadius: 25,
                                spreadRadius: 3,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.grid_3x3_rounded,
                            size: isSmallScreen ? 40 : 50,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),
                  // App name
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFBBF24), // Gold
                        Color(0xFFF59E0B), // Amber
                        Color(0xFFEAB308), // Yellow
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'MEGA X/O',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 36 : 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  // Subtitle
                  Text(
                    'Ultimate Tic Tac Toe Experience',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),
                  // Welcome badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 20 : 24,
                      vertical: isSmallScreen ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Solid background instead of gradient
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.waving_hand_rounded,
                          size: isSmallScreen ? 16 : 18,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
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

  Widget _buildGoogleLoginButton() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    
    return Container(
      width: double.infinity,
      height: isSmallScreen ? 54 : 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4285F4), // Google Blue
            Color(0xFF1976D2), // Dark Blue
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4285F4).withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _loginWithGoogle,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
            child: _isLoading
                ? AnimatedBuilder(
                    animation: _loadingAnimation,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.rotate(
                            angle: _loadingAnimation.value * 2 * 3.14159,
                            child: SizedBox(
                              width: isSmallScreen ? 20 : 22,
                              height: isSmallScreen ? 20 : 22,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Signing In...',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Custom Google logo using path
                      Container(
                        width: isSmallScreen ? 24 : 28,
                        height: isSmallScreen ? 24 : 28,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4285F4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isLandscape = screenSize.width > screenSize.height;
    
    return AnimatedBuilder(
      animation: _formController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _formSlideAnimation.value),
          child: Opacity(
            opacity: _formOpacityAnimation.value,
            child: Container(
              margin: EdgeInsets.all(isSmallScreen ? 20 : 28),
              padding: EdgeInsets.all(isSmallScreen ? 28 : 36),
              constraints: BoxConstraints(
                maxWidth: isLandscape ? 420 : double.infinity,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15), // Solid background instead of gradient
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sign in title
                  Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 28 : 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Text(
                    'Sign in to access your game progress',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Divider
                  Container(
                    margin: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 24 : 32,
                    ),
                    height: 3,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBF24), // Solid color instead of gradient
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  // Google login button
                  _buildGoogleLoginButton(),
                  SizedBox(height: isSmallScreen ? 20 : 28),
                  // Privacy policy
                  TextButton(
                    onPressed: () => _launchURL('https://megaxo-dev.lightcodedigital.cloud'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 16 : 20,
                        vertical: isSmallScreen ? 8 : 12,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.1), // Solid background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          size: isSmallScreen ? 16 : 18,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLandscape = screenSize.width > screenSize.height;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4C1D95), // Dark Purple
              Color(0xFF312E81), // Deep Purple
              Color(0xFF1F2937), // Dark Gray
              Color(0xFF111827), // Very Dark Gray/Black
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
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
                  _buildFloatingElements(),
                  Column(
                    children: [
                      _buildTitleSection(),
                      const Spacer(),
                      _buildLoginForm(),
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          children: [
            _buildFloatingElements(),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: _buildTitleSection(),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: _buildLoginForm(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}