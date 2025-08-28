import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/pocketbase_service.dart';
import 'multiplayer_game_screen.dart';

class MultiplayerRoomScreen extends StatefulWidget {
  const MultiplayerRoomScreen({super.key});

  @override
  State<MultiplayerRoomScreen> createState() => _MultiplayerRoomScreenState();
}

class _MultiplayerRoomScreenState extends State<MultiplayerRoomScreen>
    with TickerProviderStateMixin {
  final pbService = PocketBaseService();
  final roomCodeController = TextEditingController();
  String? roomCode;
  String? roomId;
  bool isWaiting = false;
  bool isInitialized = false;
  String userDisplayName = "USER";
  bool _hasNavigated = false;

  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeService();
  }

  void _initializeService() async {
    try {
      if (!isInitialized) {
        await pbService.init();
        isInitialized = true;
      }
      _checkAuth();
    } catch (e) {
      print("Error initializing service: $e");
      _showMessage("Error initializing service: $e", isError: true);
    }
  }

  void _checkAuth() async {
    try {
      final isLoggedIn = await pbService.isUserLoggedIn();
      if (!isLoggedIn) {
        _showMessage("Sesi login expired, silakan login ulang", isError: true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
        return;
      }

      final userInfo = await pbService.getUserInfo();
      if (mounted) {
        setState(() {
          userDisplayName = userInfo['name'] ?? userInfo['email'] ?? "Unknown User";
        });
      }

      print("Current user: ${pbService.getCurrentUserInfo()}");
    } catch (e) {
      print("Error checking auth: $e");
      _showMessage("Error checking authentication: $e", isError: true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    roomCodeController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();

    if (roomId != null) {
      try {
        pbService.pb.then((pb) => pb.collection('rooms').unsubscribe(roomId!));
      } catch (e) {
        print("Error unsubscribing: $e");
      }
    }

    super.dispose();
  }

  Future<void> createRoom() async {
    if (isWaiting) return;

    try {
      final isLoggedIn = await pbService.isUserLoggedIn();
      if (!isLoggedIn) {
        throw Exception("Sesi login expired, silakan login ulang");
      }

      setState(() {
        isWaiting = true;
      });

      final code = (Random().nextInt(900000) + 100000).toString();

      print("Creating room with code: $code");
      print("Player X (Creator): ${pbService.getCurrentUserInfo()}");

      final emptySmallBoards = List.generate(9, (index) => List.filled(9, ''));
      final emptyBigBoard = List.filled(9, '');

      final pb = await pbService.pb;
      final room = await pb.collection('rooms').create(
        body: {
          'roomCode': code,
          'playerX': pbService.userId,
          'playerXName': pbService.username ?? userDisplayName,
          'playerO': null,
          'playerOName': null,
          'status': 'waiting',
          'smallBoards': jsonEncode(emptySmallBoards),
          'bigBoard': jsonEncode(emptyBigBoard),
          'currentTurn': 'X',
          'activeBoard': -1,
          'createdBy': pbService.userId,
          'playerXInRoom': true,
          'playerOInRoom': false,
          'playerXLastSeen': DateTime.now().toIso8601String(),
          'playerOLastSeen': null,
          'playerXLeftAt': null,
          'playerOLeftAt': null,
        },
      );

      roomCode = code;
      roomId = room.id;

      print("Room created successfully: $roomId");
      print("- playerXInRoom: true");
      print("- playerOInRoom: false");
      print("- playerXLastSeen: ${DateTime.now().toIso8601String()}");

      _listenForOpponent();

      setState(() {});
    } catch (e) {
      print("Error creating room: $e");
      setState(() {
        isWaiting = false;
      });
      _showMessage("Gagal membuat room: ${e.toString().replaceFirst('Exception: ', '')}", isError: true);
    }
  }

  void _listenForOpponent() async {
    if (roomId == null) return;

    print("Listening for opponent in room: $roomId");

    try {
      final pb = await pbService.pb;
      pb.collection('rooms').subscribe(roomId!, (e) {
        if (!mounted || _hasNavigated) return;

        print("Realtime event: ${e.action}");

        if (e.action == 'update') {
          final r = e.record;
          print("Room updated: ${r?.data}");

          if (r?.data['playerO'] != null && 
              r?.data['playerO'] != '' && 
              !_hasNavigated) {
            print("Opponent joined! PlayerO: ${r?.data['playerOName']}");
            
            _hasNavigated = true;

            pb.collection('rooms').unsubscribe(roomId!);

            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        MultiplayerGameScreen(roomId: roomId!, isPlayerX: true),
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
              }
            });
          }
        }
      });
    } catch (e) {
      print("Error listening for opponent: $e");
      _showMessage("Error listening for opponent: $e", isError: true);
    }
  }

  Future<void> joinRoom(String code) async {
    if (isWaiting) return;

    try {
      final isLoggedIn = await pbService.isUserLoggedIn();
      if (!isLoggedIn) {
        throw Exception("Sesi login expired, silakan login ulang");
      }

      if (code.length < 4) {
        throw Exception("Kode room minimal 4 digit");
      }

      setState(() {
        isWaiting = true;
      });

      print("Trying to join room with code: $code");
      print("Player O (Joiner): ${pbService.getCurrentUserInfo()}");

      final filterQuery = "roomCode='$code' && status='waiting'";

      print("Filter query: $filterQuery");

      final pb = await pbService.pb;
      final rooms = await pb.collection('rooms').getList(filter: filterQuery, perPage: 1);

      print("Rooms found: ${rooms.items.length}");

      if (rooms.items.isEmpty) {
        print("No waiting rooms found, checking for any rooms with this code...");

        final allRoomsQuery = "roomCode='$code'";
        final allRooms = await pb.collection('rooms').getList(filter: allRoomsQuery, perPage: 1);

        if (allRooms.items.isEmpty) {
          throw Exception("Room dengan kode $code tidak ditemukan");
        } else {
          final room = allRooms.items.first;
          final status = room.data['status'] as String?;
          print("Found room with status: $status");

          switch (status) {
            case 'playing':
              throw Exception("Room sudah dimulai");
            case 'finished':
              throw Exception("Room sudah selesai");
            default:
              throw Exception("Room tidak dalam status waiting (status: $status)");
          }
        }
      }

      final room = rooms.items.first;
      print("Found waiting room: ${room.id}");

      if (room.data['playerX'] == pbService.userId) {
        throw Exception("Kamu tidak bisa join room yang kamu buat sendiri");
      }

      final currentPlayerO = room.data['playerO'];
      if (currentPlayerO != null && currentPlayerO.toString().isNotEmpty) {
        throw Exception("Room sudah penuh");
      }

      print("Joining room: ${room.id}");

      await pb.collection('rooms').update(
        room.id,
        body: {
          'playerO': pbService.userId,
          'playerOName': pbService.username ?? userDisplayName,
          'status': 'playing',
          'playerOInRoom': true,
          'playerOLastSeen': DateTime.now().toIso8601String(),
          'playerOLeftAt': null,
        },
      );

      print("Successfully joined room");
      print("- playerOInRoom: true");
      print("- playerOLastSeen: ${DateTime.now().toIso8601String()}");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                MultiplayerGameScreen(roomId: room.id, isPlayerX: false),
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
      }
    } on Exception catch (e) {
      print("Exception joining room: $e");
      setState(() {
        isWaiting = false;
      });
      _showMessage(
        "Gagal join room: ${e.toString().replaceFirst('Exception: ', '')}",
        isError: true,
      );
    } catch (e) {
      print("Error joining room: $e");
      setState(() {
        isWaiting = false;
      });

      String errorMessage = "Gagal join room";
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('network') || errorStr.contains('connection')) {
        errorMessage = "Koneksi bermasalah, cek internet kamu";
      } else if (errorStr.contains('404')) {
        errorMessage = "Room tidak ditemukan";
      } else if (errorStr.contains('400')) {
        errorMessage = "Kode room tidak valid";
      } else if (errorStr.contains('timeout')) {
        errorMessage = "Koneksi timeout, coba lagi";
      }

      _showMessage(errorMessage, isError: true);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;

    final screenWidth = MediaQuery.of(context).size.width;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.025)),
        margin: EdgeInsets.all(screenWidth * 0.04),
      ),
    );
  }

  void _copyRoomCode() {
    if (roomCode != null) {
      Clipboard.setData(ClipboardData(text: roomCode!));
      _showMessage("Kode room berhasil disalin!");
    }
  }

  void _cancelWaiting() async {
    if (roomId != null) {
      try {
        _hasNavigated = true;
        final pb = await pbService.pb;
        await pb.collection('rooms').delete(roomId!).catchError((e) {
          print("Error deleting room: $e");
        });
        pb.collection('rooms').unsubscribe(roomId!);
      } catch (e) {
        print("Error canceling room: $e");
      }
    }

    if (mounted) {
      setState(() {
        roomCode = null;
        roomId = null;
        isWaiting = false;
        _hasNavigated = false;
      });
    }
  }

  Widget _buildFloatingElements() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: screenHeight * 0.125 + (screenHeight * 0.025 * sin(_rotationAnimation.value)),
              left: screenWidth * 0.1,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Icon(
                  Icons.games_outlined,
                  color: Colors.white.withOpacity(0.1),
                  size: screenWidth * 0.075,
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.25 - (screenHeight * 0.01875 * cos(_rotationAnimation.value)),
              right: screenWidth * 0.125,
              child: Transform.rotate(
                angle: -_rotationAnimation.value * 0.8,
                child: Icon(
                  Icons.sports_esports_outlined,
                  color: Colors.yellow.withOpacity(0.15),
                  size: screenWidth * 0.0625,
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.3125 + (screenHeight * 0.03125 * sin(_rotationAnimation.value * 0.6)),
              left: screenWidth * 0.075,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 1.5,
                child: Icon(
                  Icons.group_outlined,
                  color: Colors.white.withOpacity(0.08),
                  size: screenWidth * 0.07,
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.4375 - (screenHeight * 0.025 * cos(_rotationAnimation.value * 1.2)),
              right: screenWidth * 0.1,
              child: Transform.rotate(
                angle: -_rotationAnimation.value * 0.5,
                child: Icon(
                  Icons.wifi_outlined,
                  color: Colors.purple.withOpacity(0.12),
                  size: screenWidth * 0.055,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaitingScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5800FF), Color(0xFF330066), Color(0xFF1A0033)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildFloatingElements(),
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      margin: EdgeInsets.all(screenWidth * 0.06),
                      padding: EdgeInsets.all(screenWidth * 0.08),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(screenWidth * 0.06),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: screenWidth * 0.05,
                            spreadRadius: screenWidth * 0.0125,
                            offset: Offset(0, screenWidth * 0.025),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: screenWidth * 0.2,
                                  height: screenWidth * 0.2,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA500),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(screenWidth * 0.05),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.4),
                                        blurRadius: screenWidth * 0.05,
                                        spreadRadius: screenWidth * 0.005,
                                        offset: Offset(0, screenWidth * 0.02),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.hourglass_empty,
                                    size: screenWidth * 0.1,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: screenWidth * 0.06),
                          Text(
                            'Waiting for Opponent',
                            style: TextStyle(
                              fontSize: screenWidth * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.02),
                          Text(
                            'Share this code with your friend',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.08),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.06,
                              vertical: screenWidth * 0.04,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6A0DAD), Color(0xFF8A2BE2)],
                              ),
                              borderRadius: BorderRadius.circular(screenWidth * 0.04),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.4),
                                  blurRadius: screenWidth * 0.0375,
                                  spreadRadius: screenWidth * 0.0025,
                                  offset: Offset(0, screenWidth * 0.015),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  roomCode!,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.08,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 4,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.04),
                                IconButton(
                                  onPressed: _copyRoomCode,
                                  icon: Icon(
                                    Icons.copy,
                                    color: Colors.white,
                                    size: screenWidth * 0.06,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.08),
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationAnimation.value,
                                child: SizedBox(
                                  width: screenWidth * 0.1,
                                  height: screenWidth * 0.1,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFFD700),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: screenWidth * 0.04),
                          Text(
                            'Waiting for player to join...',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.06),
                          TextButton(
                            onPressed: _cancelWaiting,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                                vertical: screenWidth * 0.025,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: screenWidth * 0.04,
                left: screenWidth * 0.04,
                child: IconButton(
                  onPressed: _cancelWaiting,
                  icon: Container(
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: screenWidth * 0.06,
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

  Widget _buildCreateJoinScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5800FF), Color(0xFF330066), Color(0xFF1A0033)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildFloatingElements(),
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: EdgeInsets.only(
                            top: screenWidth * 0.15,
                            bottom: screenWidth * 0.1,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: screenWidth * 0.2,
                                height: screenWidth * 0.2,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFA500),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.05),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.4),
                                      blurRadius: screenWidth * 0.05,
                                      spreadRadius: screenWidth * 0.005,
                                      offset: Offset(0, screenWidth * 0.02),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.group_add,
                                  size: screenWidth * 0.1,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.05),
                              Text(
                                'Multiplayer',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.08,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                'Create or join a room to play',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.02),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.03,
                                  vertical: screenWidth * 0.015,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                ),
                                child: Text(
                                  "Welcome, $userDisplayName",
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.03,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          margin: EdgeInsets.all(screenWidth * 0.06),
                          padding: EdgeInsets.all(screenWidth * 0.08),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(screenWidth * 0.06),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: screenWidth * 0.05,
                                spreadRadius: screenWidth * 0.0125,
                                offset: Offset(0, screenWidth * 0.025),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: double.infinity,
                                height: screenWidth * 0.14,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6A0DAD),
                                      Color(0xFF8A2BE2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.deepPurple.withOpacity(0.4),
                                      blurRadius: screenWidth * 0.0375,
                                      spreadRadius: screenWidth * 0.0025,
                                      offset: Offset(0, screenWidth * 0.015),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isWaiting ? null : createRoom,
                                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: isWaiting
                                          ? SizedBox(
                                              width: screenWidth * 0.06,
                                              height: screenWidth * 0.06,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_circle_outline,
                                                  color: Colors.white,
                                                  size: screenWidth * 0.06,
                                                ),
                                                SizedBox(width: screenWidth * 0.03),
                                                Text(
                                                  'Create Room',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.045,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(
                                  vertical: screenWidth * 0.06,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.04,
                                      ),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
                                          fontSize: screenWidth * 0.04,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextField(
                                controller: roomCodeController,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.04,
                                  letterSpacing: 2,
                                ),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                enabled: !isWaiting,
                                onChanged: (value) {
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter Room Code',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: screenWidth * 0.04,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFD700),
                                      width: 2,
                                    ),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: screenWidth * 0.045,
                                    horizontal: screenWidth * 0.05,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.tag,
                                    color: Colors.white.withOpacity(0.7),
                                    size: screenWidth * 0.06,
                                  ),
                                  counterText: '',
                                ),
                              ),
                              SizedBox(height: screenWidth * 0.04),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: roomCodeController,
                                builder: (context, value, child) {
                                  final canJoin =
                                      !isWaiting &&
                                      value.text.trim().length >= 4;

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    height: screenWidth * 0.14,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: canJoin
                                            ? [
                                                const Color(0xFF2E8B57),
                                                const Color(0xFF3CB371),
                                              ]
                                            : [
                                                Colors.grey.shade700,
                                                Colors.grey.shade600,
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                      boxShadow: canJoin
                                          ? [
                                              BoxShadow(
                                                color: Colors.green.withOpacity(0.3),
                                                blurRadius: screenWidth * 0.0375,
                                                spreadRadius: screenWidth * 0.0025,
                                                offset: Offset(0, screenWidth * 0.015),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: canJoin
                                            ? () {
                                                final code = roomCodeController.text.trim();
                                                if (code.isNotEmpty) {
                                                  joinRoom(code);
                                                } else {
                                                  _showMessage(
                                                    "Masukkan kode room",
                                                    isError: true,
                                                  );
                                                }
                                              }
                                            : null,
                                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: isWaiting
                                              ? SizedBox(
                                                  width: screenWidth * 0.06,
                                                  height: screenWidth * 0.06,
                                                  child: const CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<Color>(
                                                      Colors.white,
                                                    ),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.login,
                                                      color: canJoin
                                                          ? Colors.white
                                                          : Colors.grey.shade400,
                                                      size: screenWidth * 0.06,
                                                    ),
                                                    SizedBox(width: screenWidth * 0.03),
                                                    Text(
                                                      'Join Room',
                                                      style: TextStyle(
                                                        fontSize: screenWidth * 0.045,
                                                        fontWeight: FontWeight.bold,
                                                        color: canJoin
                                                            ? Colors.white
                                                            : Colors.grey.shade400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                      ),
                                    ),
                                  )
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: screenWidth * 0.04,
                left: screenWidth * 0.04,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: screenWidth * 0.06,
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

  @override
  Widget build(BuildContext context) {
    if (roomCode != null && isWaiting) {
      return _buildWaitingScreen();
    }
    return _buildCreateJoinScreen();
  }
}