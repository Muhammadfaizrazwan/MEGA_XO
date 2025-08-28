import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isMusicEnabled;
  final Function(bool) onMusicToggle;

  const ProfileScreen({
    super.key,
    required this.isMusicEnabled,
    required this.onMusicToggle,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _userEmail = '';
  String _userName = '';
  bool _localMusicState = false;

  @override
  void initState() {
    super.initState();
    _localMusicState = widget.isMusicEnabled;
    _loadUserInfo();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _fadeController.forward();
    _slideController.forward();
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

  void _handleMusicToggle(bool value) {
    if (mounted) {
      setState(() {
        _localMusicState = value;
      });
    }
    widget.onMusicToggle(value);
  }

  Future<void> _logout() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A1810),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            side: BorderSide(
              color: Colors.orange.withOpacity(0.3),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: screenWidth * 0.06,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Flexible(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              color: Colors.white70,
              fontSize: screenWidth * 0.04,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenWidth * 0.02,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: screenWidth * 0.035),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFE74C3C)],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenWidth * 0.02,
                  ),
                ),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(
                    begin: const Offset(-1.0, 0.0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeInOut)),
                ),
                child: child,
              );
            },
          ),
          (route) => false,
        );
      }
    }
  }

  Widget _buildProfileHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final avatarSize = screenWidth < 360 ? screenWidth * 0.167 : screenWidth * 0.2;
        final titleFontSize = screenWidth < 360 ? screenWidth * 0.055 : screenWidth * 0.06;
        final emailFontSize = screenWidth < 360 ? screenWidth * 0.038 : screenWidth * 0.04;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(screenWidth * 0.05),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A0DAD), Color(0xFF8A2BE2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: screenWidth * 0.04,
                offset: Offset(0, screenWidth * 0.013),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: screenWidth * 0.04,
                      spreadRadius: screenWidth * 0.005,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: avatarSize * 0.5,
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              if (_userName.isNotEmpty)
                Text(
                  _userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              SizedBox(height: screenWidth * 0.02),
              if (_userEmail.isNotEmpty)
                Text(
                  _userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: emailFontSize,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final padding = screenWidth * 0.05;
        final titleFontSize = screenWidth < 360 ? screenWidth * 0.05 : screenWidth * 0.055;
        final itemFontSize = screenWidth < 360 ? screenWidth * 0.038 : screenWidth * 0.04;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: screenWidth * 0.05),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.025),
                      decoration: BoxDecoration(
                        color: _localMusicState
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(screenWidth * 0.025),
                      ),
                      child: Icon(
                        _localMusicState ? Icons.music_note : Icons.music_off,
                        color: _localMusicState ? Colors.green : Colors.red,
                        size: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Background Music',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: itemFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _localMusicState ? 'Music is ON' : 'Music is OFF',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: itemFontSize * 0.875,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _localMusicState,
                      onChanged: _handleMusicToggle,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      activeTrackColor: Colors.green.withOpacity(0.3),
                      inactiveTrackColor: Colors.red.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final buttonHeight = screenWidth < 360 ? screenWidth * 0.138 : screenWidth * 0.15;
        final fontSize = screenWidth < 360 ? screenWidth * 0.044 : screenWidth * 0.045;
        final iconSize = screenWidth < 360 ? screenWidth * 0.055 : screenWidth * 0.06;

        return Container(
          width: double.infinity,
          height: buttonHeight,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
          child: Material(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B6B), Color(0xFFE74C3C)],
                  ),
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: screenWidth * 0.04,
                      offset: Offset(0, screenWidth * 0.013),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.white, size: iconSize),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.of(context).size.height -
                              MediaQuery.of(context).padding.top -
                              MediaQuery.of(context).padding.bottom -
                              (screenWidth * 0.3),
                        ),
                        child: Column(
                          children: [
                            _buildProfileHeader(),
                            SizedBox(height: screenWidth * 0.075),
                            _buildSettingsCard(),
                            SizedBox(height: screenWidth * 0.1),
                            _buildLogoutButton(),
                            SizedBox(height: screenWidth * 0.05),
                          ],
                        ),
                      ),
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