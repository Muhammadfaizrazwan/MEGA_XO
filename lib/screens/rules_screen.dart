import 'package:flutter/material.dart';

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

  late Animation<double> _headerAnimation;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<double> _backgroundAnimation;

  final List<RuleItem> rules = [
    RuleItem(
      icon: Icons.grid_3x3,
      title: "Papan Permainan",
      description:
          "Papan besar 3×3, setiap kotak berisi papan kecil 3×3. Total 81 kotak untuk dimainkan!",
      color: const Color(0xFF6A0DAD),
    ),
    RuleItem(
      icon: Icons.touch_app,
      title: "Cara Bermain",
      description:
          "Pilih kotak di papan kecil. Posisi kotak menentukan papan mana yang harus dimainkan lawan.",
      color: const Color(0xFF8A2BE2),
    ),
    RuleItem(
      icon: Icons.free_breakfast,
      title: "Kebebasan Memilih",
      description:
          "Jika papan tujuan sudah penuh atau dimenangkan, pemain bebas memilih papan lain mana saja.",
      color: const Color(0xFF9932CC),
    ),
    RuleItem(
      icon: Icons.emoji_events,
      title: "Memenangkan Papan",
      description:
          "Papan kecil dimenangkan dengan aturan Tic Tac Toe biasa (3 berjajar). Simbol pemenang akan muncul besar.",
      color: const Color(0xFFBA55D3),
    ),
    RuleItem(
      icon: Icons.military_tech,
      title: "Kemenangan Utama",
      description:
          "Menangkan 3 papan kecil berjajar (horizontal, vertikal, atau diagonal) untuk menjadi juara!",
      color: const Color(0xFF9370DB),
    ),
    RuleItem(
      icon: Icons.play_arrow,
      title: "Memulai Game",
      description:
          "Pemain pertama (X) dapat memilih papan mana saja untuk langkah pembuka.",
      color: const Color(0xFF7B68EE),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );

    _cardSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
    );

    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    // Start animations
    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _cardController.forward();
    });
    _backgroundController.repeat();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _cardController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _headerAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.menu_book, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'ATURAN PERMAINAN',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mega X/0',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRuleCard(RuleItem rule, int index) {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _cardSlideAnimation.value * (index + 1) * 0.5),
          child: Opacity(
            opacity: _cardFadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    rule.color.withOpacity(0.9),
                    rule.color.withOpacity(0.7),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: rule.color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(rule.icon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            rule.description,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
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
            Positioned(
              top: 80 + (20 * _backgroundAnimation.value),
              left: 30,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 2 * 3.14159,
                child: Icon(
                  Icons.grid_3x3,
                  size: 40,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              top: 150 - (15 * _backgroundAnimation.value),
              right: 40,
              child: Transform.rotate(
                angle: -_backgroundAnimation.value * 1.5 * 3.14159,
                child: Icon(
                  Icons.emoji_events,
                  size: 35,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: 200 + (25 * _backgroundAnimation.value),
              left: 50,
              child: Transform.rotate(
                angle: _backgroundAnimation.value * 1.8 * 3.14159,
                child: Icon(
                  Icons.touch_app,
                  size: 30,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Positioned(
              bottom: 300 - (18 * _backgroundAnimation.value),
              right: 30,
              child: Transform.rotate(
                angle: -_backgroundAnimation.value * 2.2 * 3.14159,
                child: Icon(
                  Icons.military_tech,
                  size: 45,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomTip() {
    return AnimatedBuilder(
      animation: _cardController,
      builder: (context, child) {
        return Opacity(
          opacity: _cardFadeAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.yellow[300],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tips: Pikirkan strategi jangka panjang! Kadang mengorbankan papan kecil untuk mengendalikan posisi lawan lebih menguntungkan.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Aturan Game",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
            _buildFloatingShapes(),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    ...rules.asMap().entries.map(
                      (entry) => AnimatedBuilder(
                        animation: _cardController,
                        builder: (context, child) {
                          return AnimatedContainer(
                            duration: Duration(
                              milliseconds: 200 + (entry.key * 100),
                            ),
                            curve: Curves.easeOutBack,
                            child: _buildRuleCard(entry.value, entry.key),
                          );
                        },
                      ),
                    ),
                    _buildBottomTip(),
                    const SizedBox(height: 20),
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
  final String title;
  final String description;
  final Color color;

  RuleItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
