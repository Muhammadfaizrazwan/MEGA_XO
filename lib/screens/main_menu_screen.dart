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

  final BackgroundMusic _backgroundMusic = BackgroundMusic();
  bool _isMusicEnabled = true;
  bool _isMusicPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _buttonSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
    );

    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _buttonController.forward();
    });
    _backgroundController.repeat();
    _particleController.repeat();
    _waveController.repeat();
  }

  Future<void> _initializeApp() async {
    await _loadUserInfo();
    await _loadMusicSettings();
    await _initializeMusic();
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
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

  Future<void> _loadMusicSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isMusicEnabled = prefs.getBool('musicEnabled') ?? true;
      });
    }
  }

  Future<void> _saveMusicSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('musicEnabled', _isMusicEnabled);
  }

  Future<void> _initializeMusic() async {
    if (_isMusicEnabled && !_isMusicPlaying) {
      await _startBackgroundMusic();
    } else {
      await _backgroundMusic.stop();
      if (mounted) {
        setState(() {
          _isMusicPlaying = false;
        });
      }
    }
  }

  Future<void> _startBackgroundMusic() async {
    if (_isMusicEnabled && !_isMusicPlaying) {
      try {
        await _backgroundMusic.playLoop();
        await _backgroundMusic.setVolume(0.3);
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

  Future<void> _toggleMusic(bool enabled) async {
    if (mounted) {
      setState(() {
        _isMusicEnabled = enabled;
      });
    }

    if (_isMusicEnabled) {
      await _startBackgroundMusic();
    } else {
      await _backgroundMusic.stop();
      if (mounted) {
        setState(() {
          _isMusicPlaying = false;
        });
      }
    }

    await _saveMusicSettings();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_isInitialized) return;

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
          _startBackgroundMusic();
        }
        break;
      case AppLifecycleState.detached:
        _backgroundMusic.stop();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _backgroundMusic.stop();
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
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(
        top: screenWidth * 0.05,
        left: screenWidth * 0.05,
        right: screenWidth * 0.05,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () async {
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

                if (_isMusicEnabled && _isMusicPlaying && mounted) {
                  await _backgroundMusic.resume();
                } else if (_isMusicEnabled && !_isMusicPlaying && mounted) {
                  await _startBackgroundMusic();
                }

                if (result == 'logout') {
                  return;
                }
              },
              icon: Icon(
                Icons.person_outline,
                color: Colors.white,
                size: screenWidth * 0.06,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
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
    final screenWidth = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoAnimation.value,
          child: Container(
            margin: EdgeInsets.only(bottom: screenWidth * 0.1),
            child: Column(
              children: [
                Container(
                  width: screenWidth * 0.3,
                  height: screenWidth * 0.3,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.06),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.6),
                        blurRadius: screenWidth * 0.075,
                        spreadRadius: screenWidth * 0.012,
                        offset: Offset(0, screenWidth * 0.025),
                      ),
                      BoxShadow(
                        color: Colors.yellow.withOpacity(0.3),
                        blurRadius: screenWidth * 0.125,
                        spreadRadius: screenWidth * 0.025,
                        offset: Offset(0, screenWidth * 0.037),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.grid_3x3,
                    size: screenWidth * 0.15,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: screenWidth * 0.05),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                      Color(0xFFFF6B35),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'MEGA',
                    style: TextStyle(
                      fontSize: screenWidth * 0.12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                Text(
                  'X/O',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
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
    final screenWidth = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _buttonSlideAnimation.value * (index + 1)),
          child: Opacity(
            opacity: _buttonFadeAnimation.value,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
              child: Material(
                elevation: 12,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                shadowColor: Colors.deepPurple.withOpacity(0.4),
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  splashColor: Colors.white.withOpacity(0.3),
                  highlightColor: Colors.white.withOpacity(0.1),
                  child: Container(
                    width: double.infinity,
                    height: screenWidth * 0.16,
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
                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: screenWidth * 0.04,
                          offset: Offset(0, screenWidth * 0.013),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.white, size: screenWidth * 0.06),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Grid pattern particles
            ...List.generate(6, (index) {
              double size = screenWidth * 0.05 + (index * screenWidth * 0.012);
              double opacity = 0.05 + (index * 0.01);
              double speed = 0.3 + (index * 0.1);

              return Positioned(
                top: screenHeight * 0.1 +
                    (index * screenHeight * 0.15) +
                    (screenHeight * 0.05 *
                        sin(_backgroundAnimation.value * speed * 2 * pi)),
                left: screenWidth * 0.05 +
                    (index * screenWidth * 0.15) +
                    (screenWidth * 0.075 *
                        cos(_backgroundAnimation.value * speed * 2 * pi)),
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
              double size = screenWidth * 0.06 + (index * screenWidth * 0.007);
              double opacity = 0.08 + (index * 0.005);
              double xOffset = (index * screenWidth * 0.2) % (screenWidth * 0.75);
              double yOffset = (index * screenHeight * 0.125) % (screenHeight * 0.75);
              double speed = 0.5 + (index * 0.1);

              return Positioned(
                top: yOffset +
                    (screenHeight * 0.0625 *
                        sin(_backgroundAnimation.value * speed * 2 * pi + index)),
                left: xOffset +
                    (screenWidth * 0.1 *
                        cos(_backgroundAnimation.value * speed * 2 * pi + index)),
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
    final screenWidth = MediaQuery.of(context).size.width;
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
            _buildAnimatedBackground(),
            _buildFloatingShapes(),
            SafeArea(
              child: Column(
                children: [
                  _buildProfileButton(),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                      child: Column(
                        children: [
                          SizedBox(height: screenWidth * 0.1),
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
                                              (context, animation, secondaryAnimation) =>
                                                  const PvPScreen(),
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
                                              (context, animation, secondaryAnimation) =>
                                                  const DifficultySelectionScreen(),
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
                                              (context, animation, secondaryAnimation) =>
                                                  const MultiplayerRoomScreen(),
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
                                              (context, animation, secondaryAnimation) =>
                                                  const RulesScreen(),
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
                                    },
                                    3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.1),
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
    final paint = Paint()..style = PaintingStyle.fill;

    // Wave 1 - Purple waves
    final path1 = Path();
    path1.moveTo(0, size.height * 0.7);

    for (double x = 0; x <= size.width; x += 1) {
      double y = size.height * 0.7 +
          (size.height * 0.0375) * sin((x / size.width * 4 * pi) + waveAnimation) +
          (size.height * 0.01875) * sin((x / size.width * 8 * pi) + waveAnimation * 1.5);
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
      double y = size.height * 0.8 +
          (size.height * 0.025) * sin((x / size.width * 6 * pi) + waveAnimation * 0.8) +
          (size.height * 0.0125) * sin((x / size.width * 12 * pi) + waveAnimation * 2);
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
      double x = (i * size.width * 0.1175 + particleAnimation * size.width * 0.25) % size.width;
      double y = (i * size.height * 0.09125 + particleAnimation * size.height * 0.1) % size.height;
      double opacity = (sin(particleAnimation * 2 * pi + i) + 1) / 2 * 0.1;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), size.width * 0.005, paint);
    }

    // Grid pattern overlay
    paint.color = Colors.white.withOpacity(0.03);
    paint.strokeWidth = 1;
    paint.style = PaintingStyle.stroke;

    double gridSize = size.width * 0.125;
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