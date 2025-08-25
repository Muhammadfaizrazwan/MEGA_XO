import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'pvp_screen.dart';
import 'difficulty_selection_screen.dart';
import 'multiplayer_room_screen.dart';
import 'rules_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'package:audioplayers/audioplayers.dart';

// Background Music Class
class BackgroundMusic {
  final player = AudioPlayer();

  Future<void> playLoop() async {
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('audio/backsound.mp3'));
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> setVolume(double volume) async {
    await player.setVolume(volume);
  }

  Future<void> pause() async {
    await player.pause();
  }

  Future<void> resume() async {
    await player.resume();
  }
}

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _logoController;
  late AnimationController _buttonController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late AnimationController _waveController;

  late Animation<double> _logoAnimation;
  late Animation<double> _buttonSlideAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _waveAnimation;

  String _userEmail = '';
  String _userName = '';

  // Background Music
  final BackgroundMusic _backgroundMusic = BackgroundMusic();
  bool _isMusicEnabled = true;
  bool _isMusicPlaying = false;
  bool _isInitialized = false; // Add this flag to track initialization

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp(); // Change this to a single initialization method

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Button animation controller
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Background animation controller
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );

    // Wave animation controller
    _waveController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    // Logo animations
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    // Button animations
    _buttonSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
    );

    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    // Background animation
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    // Particle animation
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    // Wave animation
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _buttonController.forward();
    });
    _backgroundController.repeat();
    _particleController.repeat();
    _waveController.repeat();
  }

  // Combined initialization method to ensure proper order
  Future<void> _initializeApp() async {
    await _loadUserInfo();
    await _loadMusicSettings();
    await _initializeMusic();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userEmail = prefs.getString('userEmail') ?? '';
        _userName = prefs.getString('userName') ?? '';
      });
    }
  }

  // Load music settings from SharedPreferences
  Future<void> _loadMusicSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isMusicEnabled = prefs.getBool('musicEnabled') ?? true;
      });
    }
  }

  // Save music settings to SharedPreferences
  Future<void> _saveMusicSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', _isMusicEnabled);
  }

  // Initialize music based on loaded settings
  Future<void> _initializeMusic() async {
    if (_isMusicEnabled && !_isMusicPlaying) {
      await _startBackgroundMusic();
    } else {
      // Ensure music is stopped if disabled
      await _backgroundMusic.stop();
      setState(() {
        _isMusicPlaying = false;
      });
    }
  }

  // Start background music
  Future<void> _startBackgroundMusic() async {
    if (_isMusicEnabled && !_isMusicPlaying) {
      try {
        await _backgroundMusic.playLoop();
        await _backgroundMusic.setVolume(0.3); // Set volume to 30%
        if (mounted) {
          setState(() {
            _isMusicPlaying = true;
          });
        }
      } catch (e) {
        print('Error playing background music: $e');
      }
    }
  }

  // Toggle music on/off
  Future<void> _toggleMusic(bool enabled) async {
    setState(() {
      _isMusicEnabled = enabled;
    });

    if (_isMusicEnabled) {
      await _startBackgroundMusic();
    } else {
      await _backgroundMusic.stop();
      setState(() {
        _isMusicPlaying = false;
      });
    }

    await _saveMusicSettings();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_isInitialized)
      return; // Don't handle lifecycle changes until initialized

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        if (_isMusicPlaying) {
          _backgroundMusic.pause();
        }
        break;
      case AppLifecycleState.resumed:
        if (_isMusicEnabled && _isMusicPlaying) {
          _backgroundMusic.resume();
        } else if (_isMusicEnabled && !_isMusicPlaying) {
          // Restart music if it should be playing but isn't
          _startBackgroundMusic();
        }
        break;
      case AppLifecycleState.detached:
        _backgroundMusic.stop();
        break;
      case AppLifecycleState.hidden:
        // Handle hidden state if needed
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundMusic.stop(); // Stop music when disposing
    _logoController.dispose();
    _buttonController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveAnimation, _particleAnimation]),
      builder: (context, child) {
        return CustomPaint(
          painter: AnimatedBackgroundPainter(
            waveAnimation: _waveAnimation.value,
            particleAnimation: _particleAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildProfileButton() {
    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () async {
                // Stop music before navigating to profile
                if (_isMusicPlaying) {
                  await _backgroundMusic.pause();
                }

                final result = await Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ProfileScreen(
                          isMusicEnabled: _isMusicEnabled,
                          onMusicToggle: _toggleMusic,
                        ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return SlideTransition(
                            position: animation.drive(
                              Tween(
                                begin: const Offset(1.0, 0.0),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeInOut)),
                            ),
                            child: child,
                          );
                        },
                  ),
                );

                // Resume music when coming back from profile if needed
                if (_isMusicEnabled && _isMusicPlaying && mounted) {
                  await _backgroundMusic.resume();
                } else if (_isMusicEnabled && !_isMusicPlaying && mounted) {
                  // Restart music if settings changed
                  await _startBackgroundMusic();
                }

                // Check if user logged out
                if (result == 'logout') {
                  // User logged out from profile screen
                  return;
                }
              },
              icon: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 24,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              tooltip: 'Profile',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 40),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.3),
                        blurRadius: 50,
                        spreadRadius: 10,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.grid_3x3,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                      Color(0xFFFF6B35),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'MEGA',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const Text(
                  'X/O',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
    int index,
  ) {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _buttonSlideAnimation.value * (index + 1)),
          child: Opacity(
            opacity: _buttonFadeAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(16),
                shadowColor: Colors.deepPurple.withOpacity(0.4),
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(16),
                  splashColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6A0DAD).withOpacity(0.95),
                          const Color(0xFF8A2BE2).withOpacity(0.95),
                          const Color(0xFF9370DB).withOpacity(0.95),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 18,
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingShapes() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Grid pattern particles
            ...List.generate(6, (index) {
              double size = 20 + (index * 5);
              double opacity = 0.05 + (index * 0.01);
              double speed = 0.3 + (index * 0.1);

              return Positioned(
                top:
                    80 +
                    (index * 120) +
                    (40 * sin(_backgroundAnimation.value * speed * 2 * pi)),
                left:
                    20 +
                    (index * 60) +
                    (30 * cos(_backgroundAnimation.value * speed * 2 * pi)),
                child: Transform.rotate(
                  angle: _backgroundAnimation.value * speed * 2 * pi,
                  child: Icon(
                    Icons.grid_3x3_outlined,
                    size: size,
                    color: Colors.white.withOpacity(opacity),
                  ),
                ),
              );
            }),

            // Floating X and O shapes
            ...List.generate(8, (index) {
              bool isX = index % 2 == 0;
              double size = 25 + (index * 3);
              double opacity = 0.08 + (index * 0.005);
              double xOffset = (index * 80) % 300;
              double yOffset = (index * 100) % 600;
              double speed = 0.5 + (index * 0.1);

              return Positioned(
                top:
                    yOffset +
                    (50 *
                        sin(
                          _backgroundAnimation.value * speed * 2 * pi + index,
                        )),
                left:
                    xOffset +
                    (40 *
                        cos(
                          _backgroundAnimation.value * speed * 2 * pi + index,
                        )),
                child: Transform.rotate(
                  angle: _backgroundAnimation.value * speed * 2 * pi,
                  child: Text(
                    isX ? '×' : '○',
                    style: TextStyle(
                      fontSize: size,
                      color: isX
                          ? Colors.red.withOpacity(opacity)
                          : Colors.green.withOpacity(opacity),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          ],
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
            // Animated background with waves and particles
            _buildAnimatedBackground(),

            // Floating shapes
            _buildFloatingShapes(),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Profile button only
                  _buildProfileButton(),

                  // Main content with logo and buttons
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildLogo(),
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildAnimatedButton(
                                    context,
                                    "PvP (Offline)",
                                    Icons.people,
                                    () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => const PvPScreen(),
                                          transitionsBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                return SlideTransition(
                                                  position: animation.drive(
                                                    Tween(
                                                      begin: const Offset(
                                                        1.0,
                                                        0.0,
                                                      ),
                                                      end: Offset.zero,
                                                    ).chain(
                                                      CurveTween(
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                  ),
                                                  child: child,
                                                );
                                              },
                                        ),
                                      );
                                    },
                                    0,
                                  ),
                                  _buildAnimatedButton(
                                    context,
                                    "PvE (Bot)",
                                    Icons.smart_toy,
                                    () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) =>
                                                  const DifficultySelectionScreen(),
                                          transitionsBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                return SlideTransition(
                                                  position: animation.drive(
                                                    Tween(
                                                      begin: const Offset(
                                                        1.0,
                                                        0.0,
                                                      ),
                                                      end: Offset.zero,
                                                    ).chain(
                                                      CurveTween(
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                  ),
                                                  child: child,
                                                );
                                              },
                                        ),
                                      );
                                    },
                                    1,
                                  ),
                                  _buildAnimatedButton(
                                    context,
                                    "Multiplayer (Online)",
                                    Icons.wifi,
                                    () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) =>
                                                  const MultiplayerRoomScreen(),
                                          transitionsBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                return SlideTransition(
                                                  position: animation.drive(
                                                    Tween(
                                                      begin: const Offset(
                                                        1.0,
                                                        0.0,
                                                      ),
                                                      end: Offset.zero,
                                                    ).chain(
                                                      CurveTween(
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                  ),
                                                  child: child,
                                                );
                                              },
                                        ),
                                      );
                                    },
                                    2,
                                  ),
                                  _buildAnimatedButton(
                                    context,
                                    "Rules",
                                    Icons.help_outline,
                                    () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                              ) => const RulesScreen(),
                                          transitionsBuilder:
                                              (
                                                context,
                                                animation,
                                                secondaryAnimation,
                                                child,
                                              ) {
                                                return SlideTransition(
                                                  position: animation.drive(
                                                    Tween(
                                                      begin: const Offset(
                                                        1.0,
                                                        0.0,
                                                      ),
                                                      end: Offset.zero,
                                                    ).chain(
                                                      CurveTween(
                                                        curve: Curves.easeInOut,
                                                      ),
                                                    ),
                                                  ),
                                                  child: child,
                                                );
                                              },
                                        ),
                                      );
                                    },
                                    3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
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

class AnimatedBackgroundPainter extends CustomPainter {
  final double waveAnimation;
  final double particleAnimation;

  AnimatedBackgroundPainter({
    required this.waveAnimation,
    required this.particleAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create gradient waves
    final paint = Paint()..style = PaintingStyle.fill;

    // Wave 1 - Purple waves
    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x += 1) {
      double y =
          size.height * 0.7 +
          30 * sin((x / size.width * 4 * pi) + waveAnimation) +
          15 * sin((x / size.width * 8 * pi) + waveAnimation * 1.5);
      path1.lineTo(x, y);
    }

    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF6A0DAD).withOpacity(0.3),
        const Color(0xFF8A2BE2).withOpacity(0.2),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path1, paint);

    // Wave 2 - Lighter purple waves
    final path2 = Path();
    path2.moveTo(0, size.height * 0.8);

    for (double x = 0; x <= size.width; x += 1) {
      double y =
          size.height * 0.8 +
          20 * sin((x / size.width * 6 * pi) + waveAnimation * 0.8) +
          10 * sin((x / size.width * 12 * pi) + waveAnimation * 2);
      path2.lineTo(x, y);
    }

    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF9370DB).withOpacity(0.2),
        const Color(0xFFBA55D3).withOpacity(0.1),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path2, paint);

    // Particle effects
    paint.shader = null;
    for (int i = 0; i < 30; i++) {
      double x = (i * 47 + particleAnimation * 100) % size.width;
      double y = (i * 73 + particleAnimation * 80) % size.height;
      double opacity = (sin(particleAnimation * 2 * pi + i) + 1) / 2 * 0.1;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), 2, paint);
    }

    // Grid pattern overlay
    paint.color = Colors.white.withOpacity(0.03);
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;

    double gridSize = 50;
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
