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

  // Animation controllers
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
      // Initialize PocketBase service if not already done
      if (!isInitialized) {
        await pbService.init();
        isInitialized = true;
      }

      // Check authentication status
      _checkAuth();
    } catch (e) {
      print("Error initializing service: $e");
      _showMessage("Error initializing service: $e", isError: true);
    }
  }

  void _checkAuth() async {
    try {
      // Check if user is logged in using the updated method
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

      // Get user info for display
      final userInfo = await pbService.getUserInfo();
      setState(() {
        userDisplayName = userInfo['name'] ?? userInfo['email'] ?? "Unknown User";
      });

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

    // Unsubscribe dari realtime jika masih aktif
    if (roomId != null) {
      try {
        pbService.pb.then((pb) => pb.collection('rooms').unsubscribe(roomId!));
      } catch (e) {
        print("Error unsubscribing: $e");
      }
    }

    super.dispose();
  }

  /// Buat room baru
  Future<void> createRoom() async {
    if (isWaiting) return;

    try {
      // Ensure we're authenticated before creating room
      final isLoggedIn = await pbService.isUserLoggedIn();
      if (!isLoggedIn) {
        throw Exception("Sesi login expired, silakan login ulang");
      }

      setState(() {
        isWaiting = true;
      });

      // Generate kode room 6 digit
      final code = (Random().nextInt(900000) + 100000).toString();

      print("Creating room with code: $code");
      print("Player X (Creator): ${pbService.getCurrentUserInfo()}");

      // Initialize with proper Ultimate Tic-Tac-Toe structure
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
        },
      );

      roomCode = code;
      roomId = room.id;

      print("Room created successfully: $roomId");

      // Dengarkan jika ada playerO join
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

  /// Tunggu lawan join (Realtime)
  void _listenForOpponent() async {
    if (roomId == null) return;

    print("Listening for opponent in room: $roomId");

    try {
      final pb = await pbService.pb;
      pb.collection('rooms').subscribe(roomId!, (e) {
        if (!mounted) return;

        print("Realtime event: ${e.action}");

        if (e.action == 'update') {
          final r = e.record;
          print("Room updated: ${r?.data}");

          if (r?.data['playerO'] != null && r?.data['playerO'] != '') {
            print("Opponent joined! PlayerO: ${r?.data['playerOName']}");

            // Unsubscribe sebelum navigate
            pb.collection('rooms').unsubscribe(roomId!);

            // Navigate ke game screen
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
        }
      });
    } catch (e) {
      print("Error listening for opponent: $e");
      _showMessage("Error listening for opponent: $e", isError: true);
    }
  }

  /// Join room berdasarkan roomCode
  Future<void> joinRoom(String code) async {
    if (isWaiting) return;

    try {
      // Ensure we're authenticated before joining room
      final isLoggedIn = await pbService.isUserLoggedIn();
      if (!isLoggedIn) {
        throw Exception("Sesi login expired, silakan login ulang");
      }

      // Validasi kode minimal 4 digit, maksimal 6
      if (code.length < 4) {
        throw Exception("Kode room minimal 4 digit");
      }

      setState(() {
        isWaiting = true;
      });

      print("Trying to join room with code: $code");
      print("Player O (Joiner): ${pbService.getCurrentUserInfo()}");

      // Use proper filter syntax
      final filterQuery = "roomCode='$code' && status='waiting'";

      print("Filter query: $filterQuery");

      final pb = await pbService.pb;
      // Cari room berdasarkan roomCode dan status waiting
      final rooms = await pb.collection('rooms').getList(filter: filterQuery, perPage: 1);

      print("Rooms found: ${rooms.items.length}");

      if (rooms.items.isEmpty) {
        // Coba cari room dengan kode yang sama tapi status berbeda
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

      // User tidak join room sendiri
      if (room.data['playerX'] == pbService.userId) {
        throw Exception("Kamu tidak bisa join room yang kamu buat sendiri");
      }

      // Room belum ada playerO
      final currentPlayerO = room.data['playerO'];
      if (currentPlayerO != null && currentPlayerO.toString().isNotEmpty) {
        throw Exception("Room sudah penuh");
      }

      print("Joining room: ${room.id}");

      // Update room dengan playerO
      await pb.collection('rooms').update(
        room.id,
        body: {
          'playerO': pbService.userId,
          'playerOName': pbService.username ?? userDisplayName,
          'status': 'playing',
        },
      );

      print("Successfully joined room");

      // Navigate ke game screen
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

      // Handle specific PocketBase errors
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
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
        // Delete room yang sedang menunggu
        final pb = await pbService.pb;
        await pb.collection('rooms').delete(roomId!).catchError((e) {
          print("Error deleting room: $e");
        });

        // Unsubscribe
        pb.collection('rooms').unsubscribe(roomId!);
      } catch (e) {
        print("Error canceling room: $e");
      }
    }

    setState(() {
      roomCode = null;
      roomId = null;
      isWaiting = false;
    });
  }

  Widget _buildFloatingElements() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: 100 + (20 * sin(_rotationAnimation.value)),
              left: 40,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Icon(
                  Icons.games_outlined,
                  color: Colors.white.withOpacity(0.1),
                  size: 30,
                ),
              ),
            ),
            Positioned(
              top: 200 - (15 * cos(_rotationAnimation.value)),
              right: 50,
              child: Transform.rotate(
                angle: -_rotationAnimation.value * 0.8,
                child: Icon(
                  Icons.sports_esports_outlined,
                  color: Colors.yellow.withOpacity(0.15),
                  size: 25,
                ),
              ),
            ),
            Positioned(
              bottom: 250 + (25 * sin(_rotationAnimation.value * 0.6)),
              left: 30,
              child: Transform.rotate(
                angle: _rotationAnimation.value * 1.5,
                child: Icon(
                  Icons.group_outlined,
                  color: Colors.white.withOpacity(0.08),
                  size: 28,
                ),
              ),
            ),
            Positioned(
              bottom: 350 - (20 * cos(_rotationAnimation.value * 1.2)),
              right: 40,
              child: Transform.rotate(
                angle: -_rotationAnimation.value * 0.5,
                child: Icon(
                  Icons.wifi_outlined,
                  color: Colors.purple.withOpacity(0.12),
                  size: 22,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWaitingScreen() {
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
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated icon
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA500),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.4),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.hourglass_empty,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Waiting for Opponent',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Share this code with your friend',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Room code display
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6A0DAD), Color(0xFF8A2BE2)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  roomCode!,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 4,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: _copyRoomCode,
                                  icon: const Icon(
                                    Icons.copy,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Loading indicator
                          AnimatedBuilder(
                            animation: _rotationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _rotationAnimation.value,
                                child: const SizedBox(
                                  width: 40,
                                  height: 40,
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
                          const SizedBox(height: 16),
                          Text(
                            'Waiting for player to join...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Cancel button
                          TextButton(
                            onPressed: _cancelWaiting,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
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

              // Back button
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  onPressed: _cancelWaiting,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
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
                      // Header
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          margin: const EdgeInsets.only(top: 60, bottom: 40),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFA500),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.4),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.group_add,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Multiplayer',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                'Create or join a room to play',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "Welcome $userDisplayName",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Main content
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Create Room Button
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6A0DAD),
                                      Color(0xFF8A2BE2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.deepPurple.withOpacity(0.4),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isWaiting ? null : createRoom,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: isWaiting
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add_circle_outline,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Create Room',
                                                  style: TextStyle(
                                                    fontSize: 18,
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

                              // Divider
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 24,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                      ),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontWeight: FontWeight.w500,
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

                              // Room Code Input
                              TextField(
                                controller: roomCodeController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  letterSpacing: 2,
                                ),
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                enabled: !isWaiting,
                                onChanged: (value) {
                                  // Trigger rebuild untuk update button state
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter Room Code',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFFFD700),
                                      width: 2,
                                    ),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18.0,
                                    horizontal: 20.0,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.tag,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  counterText: '',
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Join Room Button
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: roomCodeController,
                                builder: (context, value, child) {
                                  final canJoin =
                                      !isWaiting &&
                                      value.text.trim().length >= 4; 

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    height: 56,
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
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: canJoin
                                          ? [
                                              BoxShadow(
                                                color: Colors.green.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 15,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 6),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: canJoin
                                            ? () {
                                                final code = roomCodeController
                                                    .text
                                                    .trim();
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
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: isWaiting
                                              ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
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
                                                          : Colors
                                                                .grey
                                                                .shade400,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'Join Room',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: canJoin
                                                            ? Colors.white
                                                            : Colors
                                                                  .grey
                                                                  .shade400,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
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

              // Back button
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
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

    // Tampilan awal create/join room
    return _buildCreateJoinScreen();
  }
}