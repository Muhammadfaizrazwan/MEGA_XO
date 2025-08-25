import 'package:flutter/material.dart';
import 'dart:math' as math;

// Language Service untuk mengelola terjemahan
class LanguageService extends ChangeNotifier {
  static LanguageService? _instance;
  static LanguageService get instance => _instance ??= LanguageService._();
  LanguageService._();
  
  String _currentLanguage = 'id';
  String get currentLanguage => _currentLanguage;
  
  void changeLanguage(String languageCode) {
    _currentLanguage = languageCode;
    notifyListeners();
  }
  
  static final Map<String, Map<String, String>> _translations = {
    'id': {
      'rules_title': 'ATURAN PERMAINAN',
      'game_subtitle': 'MEGA X/O',
      'app_bar_title': 'Aturan Game',
      'board_title': 'Papan Permainan',
      'board_desc': 'Papan besar 3×3, setiap kotak berisi papan kecil 3×3. Total 81 kotak untuk dimainkan!',
      'board_tip': 'Bayangkan seperti 9 papan tic-tac-toe dalam satu permainan besar!',
      'gameplay_title': 'Cara Bermain',
      'gameplay_desc': 'Pilih kotak di papan kecil. Posisi kotak menentukan papan mana yang harus dimainkan lawan.',
      'gameplay_tip': 'Setiap langkah Anda mengarahkan lawan ke papan tertentu!',
      'freedom_title': 'Kebebasan Memilih',
      'freedom_desc': 'Jika papan tujuan sudah penuh atau dimenangkan, pemain bebas memilih papan lain mana saja.',
      'freedom_tip': 'Kadang terjebak di papan penuh bisa jadi keuntungan!',
      'win_board_title': 'Memenangkan Papan',
      'win_board_desc': 'Papan kecil dimenangkan dengan aturan Tic Tac Toe biasa (3 berjajar). Simbol pemenang akan muncul besar.',
      'win_board_tip': 'Fokus menangkan papan kecil untuk menguasai papan besar!',
      'main_win_title': 'Kemenangan Utama',
      'main_win_desc': 'Menangkan 3 papan kecil berjajar (horizontal, vertikal, atau diagonal) untuk menjadi juara!',
      'main_win_tip': 'Strategi terbaik: kendalikan papan tengah dan pojok!',
      'start_title': 'Memulai Game',
      'start_desc': 'Pemain pertama (X) dapat memilih papan mana saja untuk langkah pembuka.',
      'start_tip': 'Langkah pertama di tengah biasanya memberikan kontrol terbaik!',
      'pro_tip': 'Pro Tip! 💡',
      'bottom_tip': 'Pikirkan strategi jangka panjang! Kadang mengorbankan papan kecil untuk mengendalikan posisi lawan lebih menguntungkan.',
      'language': 'Bahasa',
    },
    'en': {
      'rules_title': 'GAME RULES',
      'game_subtitle': 'MEGA X/O',
      'app_bar_title': 'Game Rules',
      'board_title': 'Game Board',
      'board_desc': 'Large 3×3 board, each cell contains a small 3×3 board. Total of 81 cells to play!',
      'board_tip': 'Imagine like 9 tic-tac-toe boards in one big game!',
      'gameplay_title': 'How to Play',
      'gameplay_desc': 'Choose a cell in the small board. The cell position determines which board the opponent must play.',
      'gameplay_tip': 'Every move you make directs your opponent to a specific board!',
      'freedom_title': 'Freedom to Choose',
      'freedom_desc': 'If the target board is already full or won, the player can freely choose any other board.',
      'freedom_tip': 'Sometimes being trapped in a full board can be an advantage!',
      'win_board_title': 'Winning a Board',
      'win_board_desc': 'Small boards are won with regular Tic Tac Toe rules (3 in a row). The winner symbol will appear large.',
      'win_board_tip': 'Focus on winning small boards to control the big board!',
      'main_win_title': 'Main Victory',
      'main_win_desc': 'Win 3 small boards in a row (horizontal, vertical, or diagonal) to become the champion!',
      'main_win_tip': 'Best strategy: control the center and corner boards!',
      'start_title': 'Starting the Game',
      'start_desc': 'First player (X) can choose any board for the opening move.',
      'start_tip': 'First move in the center usually gives the best control!',
      'pro_tip': 'Pro Tip! 💡',
      'bottom_tip': 'Think long-term strategy! Sometimes sacrificing a small board to control opponent\'s position is more profitable.',
      'language': 'Language',
    },
  };
  
  String translate(String key) {
    return _translations[_currentLanguage]?[key] ?? key;
  }
  
  List<Map<String, String>> get availableLanguages => [
    {'code': 'id', 'name': '🇮🇩 Indonesia', 'nativeName': 'Bahasa Indonesia'},
    {'code': 'en', 'name': '🇺🇸 English', 'nativeName': 'English'},
  ];
}

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardController;
  late AnimationController _backgroundController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;

  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;

  int _selectedRuleIndex = -1;
  final LanguageService _languageService = LanguageService.instance;

  List<RuleItem> get rules => [
    RuleItem(
      icon: Icons.grid_3x3,
      titleKey: "board_title",
      descriptionKey: "board_desc",
      color: const Color(0xFF6A0DAD),
      emoji: "🎯",
      tipKey: "board_tip",
    ),
    RuleItem(
      icon: Icons.touch_app,
      titleKey: "gameplay_title",
      descriptionKey: "gameplay_desc",
      color: const Color(0xFF8A2BE2),
      emoji: "👆",
      tipKey: "gameplay_tip",
    ),
    RuleItem(
      icon: Icons.free_breakfast,
      titleKey: "freedom_title",
      descriptionKey: "freedom_desc",
      color: const Color(0xFF9932CC),
      emoji: "🗽",
      tipKey: "freedom_tip",
    ),
    RuleItem(
      icon: Icons.emoji_events,
      titleKey: "win_board_title",
      descriptionKey: "win_board_desc",
      color: const Color(0xFFBA55D3),
      emoji: "🏆",
      tipKey: "win_board_tip",
    ),
    RuleItem(
      icon: Icons.military_tech,
      titleKey: "main_win_title",
      descriptionKey: "main_win_desc",
      color: const Color(0xFF9370DB),
      emoji: "👑",
      tipKey: "main_win_tip",
    ),
    RuleItem(
      icon: Icons.play_arrow,
      titleKey: "start_title",
      descriptionKey: "start_desc",
      color: const Color(0xFF7B68EE),
      emoji: "🚀",
      tipKey: "start_tip",
    ),
  ];

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _headerSlideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );

    _headerScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _cardSlideAnimation = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutExpo),
    );

    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _floatingAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      _cardController.forward();
    });
    _backgroundController.repeat();
    _floatingController.repeat();
    _pulseController.repeat(reverse: true);

    // Listen to language changes
    _languageService.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardController.dispose();
    _backgroundController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF5800FF),
              Color(0xFF3D0066),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    _languageService.translate('language'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._languageService.availableLanguages.map((lang) =>
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Text(
                          lang['name']!.split(' ')[0],
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          lang['nativeName']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: _languageService.currentLanguage == lang['code']
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: _languageService.currentLanguage == lang['code']
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.1),
                        onTap: () {
                          _languageService.changeLanguage(lang['code']!);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return AnimatedBuilder(
      animation: Listenable.merge([_headerController, _pulseController]),
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final isSmallScreen = screenWidth < 400;
        final isShortScreen = screenHeight < 700;
        
        return Transform.translate(
          offset: Offset(0, _headerSlideAnimation.value),
          child: Transform.scale(
            scale: _headerScaleAnimation.value,
            child: Container(
              padding: EdgeInsets.all(isSmallScreen ? 16 : 28),
              margin: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: isShortScreen ? 10 : 20,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700),
                    const Color(0xFFFFA500),
                    const Color(0xFFFF8C00),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: const [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.yellow.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: _pulseAnimation.value * 0.8,
                        child: Container(
                          width: isSmallScreen ? 60 : 80,
                          height: isSmallScreen ? 60 : 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Text(
                        "📖",
                        style: TextStyle(fontSize: isSmallScreen ? 32 : 44),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.white70],
                      ).createShader(bounds),
                      child: Text(
                        _languageService.translate('rules_title'),
                        style: TextStyle(
                          fontSize: math.min(26, screenWidth * 0.065),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: isSmallScreen ? 1.5 : 3,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: FittedBox(
                      child: Text(
                        _languageService.translate('game_subtitle'),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: isSmallScreen ? 1 : 2,
                        ),
                      ),
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

  Widget _buildEnhancedRuleCard(RuleItem rule, int index) {
    final isSelected = _selectedRuleIndex == index;
    
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 400;
        
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value * (index + 1) * 0.3),
          child: Opacity(
            opacity: _cardFadeAnimation.value,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRuleIndex = isSelected ? -1 : index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: 8,
                ),
                width: double.infinity,
                constraints: BoxConstraints(
                  maxWidth: math.min(screenWidth * 0.9, 600),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSelected 
                        ? [
                            rule.color,
                            rule.color.withOpacity(0.8),
                            rule.color.withOpacity(0.9),
                          ]
                        : [
                            rule.color.withOpacity(0.9),
                            rule.color.withOpacity(0.7),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: rule.color.withOpacity(isSelected ? 0.5 : 0.3),
                      blurRadius: isSelected ? 15 : 10,
                      spreadRadius: isSelected ? 3 : 1,
                      offset: Offset(0, isSelected ? 6 : 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(isSelected ? 0.4 : 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 0,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: isSmallScreen ? 50 : 70,
                                  height: isSmallScreen ? 50 : 70,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  rule.emoji,
                                  style: TextStyle(fontSize: isSmallScreen ? 24 : 32),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _languageService.translate(rule.titleKey),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 16 : 20,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                    AnimatedRotation(
                                      duration: const Duration(milliseconds: 300),
                                      turns: isSelected ? 0.25 : 0,
                                      child: Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.white.withOpacity(0.8),
                                        size: isSmallScreen ? 20 : 24,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 8 : 10),
                                Text(
                                  _languageService.translate(rule.descriptionKey),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: isSelected ? null : 0,
                        curve: Curves.easeInOutCubic,
                        child: isSelected
                            ? Container(
                                margin: EdgeInsets.only(top: isSmallScreen ? 12 : 16),
                                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.tips_and_updates,
                                      color: Colors.amber[200],
                                      size: isSmallScreen ? 20 : 24,
                                    ),
                                    SizedBox(width: isSmallScreen ? 8 : 12),
                                    Expanded(
                                      child: Text(
                                        _languageService.translate(rule.tipKey),
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 12 : 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.95),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
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

  Widget _buildEnhancedFloatingShapes() {
    return AnimatedBuilder(
      animation: Listenable.merge([_backgroundAnimation, _floatingAnimation]),
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        return Stack(
          children: [
            // Floating grid pattern - responsive positioning
            for (int i = 0; i < 5; i++)
              Positioned(
                top: (screenHeight * 0.15) + (i * screenHeight * 0.15) + (30 * math.sin(_backgroundAnimation.value + i)),
                left: math.max(20, screenWidth * 0.05) + (40 * math.cos(_floatingAnimation.value + i * 0.5)),
                child: Transform.rotate(
                  angle: _backgroundAnimation.value + (i * 0.3),
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03 + (i * 0.01)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            // Floating emojis - responsive positioning
            Positioned(
              top: screenHeight * 0.17 + (25 * math.sin(_floatingAnimation.value)),
              right: math.max(30, screenWidth * 0.08) + (20 * math.cos(_floatingAnimation.value * 0.8)),
              child: Transform.scale(
                scale: 0.8 + (0.3 * math.sin(_floatingAnimation.value * 2)),
                child: Text(
                  "🎮",
                  style: TextStyle(
                    fontSize: screenWidth < 400 ? 25 : 30,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.35 + (35 * math.cos(_floatingAnimation.value * 0.6)),
              left: math.max(40, screenWidth * 0.1) + (25 * math.sin(_floatingAnimation.value * 0.7)),
              child: Transform.rotate(
                angle: _floatingAnimation.value * 0.5,
                child: Text(
                  "⭐",
                  style: TextStyle(
                    fontSize: screenWidth < 400 ? 20 : 25,
                    shadows: [
                      Shadow(
                        color: Colors.yellow.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: screenHeight * 0.2 + (20 * math.sin(_floatingAnimation.value * 1.2)),
              right: math.max(50, screenWidth * 0.12) + (30 * math.cos(_floatingAnimation.value * 0.4)),
              child: Transform.scale(
                scale: 0.9 + (0.2 * math.cos(_floatingAnimation.value * 3)),
                child: Text(
                  "🏁",
                  style: TextStyle(fontSize: screenWidth < 400 ? 23 : 28),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEnhancedBottomTip() {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 400;
        
        return Transform.translate(
          offset: Offset(0, (1 - _cardFadeAnimation.value) * 50),
          child: Opacity(
            opacity: _cardFadeAnimation.value,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: 16,
              ),
              padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: math.min(screenWidth * 0.9, 600),
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    spreadRadius: 0,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isSmallScreen ? 40 : 50,
                    height: isSmallScreen ? 40 : 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[300]!, Colors.orange[300]!],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lightbulb,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _languageService.translate('pro_tip'),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber[300],
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 4 : 6),
                        Text(
                          _languageService.translate('bottom_tip'),
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.95),
                            height: 1.4,
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
    final screenHeight = MediaQuery.of(context).size.height;
    final isShortScreen = screenHeight < 700;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _languageService.translate('app_bar_title'),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white, size: 26),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.translate,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: _showLanguageSelector,
              tooltip: _languageService.translate('language'),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF5800FF),
              Color(0xFF3D0066),
              Color(0xFF2A0044),
              Color(0xFF1A0033),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            _buildEnhancedFloatingShapes(),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildEnhancedHeader(),
                    SizedBox(height: isShortScreen ? 5 : 10),
                    ...rules.asMap().entries.map(
                      (entry) => _buildEnhancedRuleCard(entry.value, entry.key),
                    ),
                    _buildEnhancedBottomTip(),
                    SizedBox(height: isShortScreen ? 20 : 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RuleItem {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final Color color;
  final String emoji;
  final String tipKey;

  RuleItem({
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.color,
    required this.emoji,
    required this.tipKey,
  });
}