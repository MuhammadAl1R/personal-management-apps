import 'package:flutter/material.dart';
import 'package:task_management/money_screen.dart';
import 'task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final Color _primaryBlue = const Color(0xFF386BF6);

  // Daftar Halaman
  List<Widget> _buildPages() => [
    _buildHomeContent(),
    const TaskScreen(),
    const MoneyScreen(),
    const Center(child: Text("Halaman Schedule")),
    const Center(child: Text("Halaman Document")),
  ];

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'ZenDots',
                      color: Colors.black,
                      height: 0.0,
                    ),
                  ),
                  // const SizedBox(height: 1),
                  Text(
                    "Muhammad Ali R",
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'ZenDots',
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${DateTime.now().hour.toString().padLeft(2, '0')}.${DateTime.now().minute.toString().padLeft(2, "0")}",
                    style: TextStyle(
                      fontSize: 70,
                      fontFamily: "GE Jarida",
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double itemWidth = size.width / 5;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 246, 246, 246),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: _buildPages(),
      ),

      // Menggunakan Stack untuk menumpuk: Background Lukisan -> Label -> Lingkaran
      bottomNavigationBar: SizedBox(
        height: 80, // Tinggi total area
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none, // Izinkan lingkaran keluar area stack
          children: [
            // --- LAYER 1: BACKGROUND DENGAN CEKUNGAN BERGERAK ---
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: _selectedIndex.toDouble()),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              builder: (context, animatedIndex, child) {
                return CustomPaint(
                  size: Size(size.width, 70), // Tinggi navbar putih
                  painter: NavbarCurvePainter(
                    position: animatedIndex,
                    itemCount: 5,
                    // PERBAIKAN 1: Warna Background jadi Putih (sebelumnya Grey)
                    color: Colors.white,
                  ),
                );
              },
            ),

            // --- LAYER 2: LABEL & ICON INACTIVE ---
            SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: itemWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Beri jarak sedikit dari atas agar pas dengan cekungan
                          const SizedBox(height: 10),

                          // PERBAIKAN 2: Menambahkan Ikon Unselected
                          Icon(
                            _getIcon(index),
                            size: 24,
                            // Logika Warna: Transparan jika dipilih, Abu-abu jika tidak
                            color: _selectedIndex == index
                                ? Colors.transparent
                                : Colors.grey.shade400,
                          ),

                          const SizedBox(
                            height: 4,
                          ), // Jarak antara ikon dan teks
                          // Label
                          Text(
                            _getLabel(index),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              // Warna teks: Biru jika dipilih, Abu jika tidak
                              color: _selectedIndex == index
                                  ? _primaryBlue
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // --- LAYER 3: LINGKARAN BIRU MELAYANG ---
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              // Rumus posisi horizontal
              left: (_selectedIndex * itemWidth) + (itemWidth / 2) - 28,
              // PERBAIKAN 3: Posisi vertikal disesuaikan dengan kedalaman cekungan
              bottom: 40,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Container(
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      _getIcon(_selectedIndex),
                      color: _primaryBlue,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLabel(int index) {
    const labels = ['Home', 'Task', 'Money', 'Schedule', 'Doc'];
    return labels[index];
  }

  IconData _getIcon(int index) {
    const icons = [
      Icons.home_rounded,
      Icons.work_rounded,
      Icons.account_balance_wallet_rounded,
      Icons.calendar_month_rounded,
      Icons.description_rounded,
    ];
    return icons[index];
  }
}

// --- CLASS LUKISAN (THE PAINTER) ---
class NavbarCurvePainter extends CustomPainter {
  final double position;
  final int itemCount;
  final Color color;

  NavbarCurvePainter({
    required this.position,
    required this.itemCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    final itemWidth = size.width / itemCount;
    final center = (position * itemWidth) + (itemWidth / 2);

    // --- KONFIGURASI KEDALAMAN CEKUNGAN ---
    // PERBAIKAN 4: Diperdalam menjadi 40.0 (Sebelumnya 15.0)
    const double depth = 30.0;
    const double width =
        100.0; // Lebar cekungan sedikit ditambah agar proporsional

    path.moveTo(0, 20); // Mulai sedikit turun untuk rounded corner atas kiri
    path.quadraticBezierTo(0, 0, 20, 0);

    // Garis lurus kiri
    path.lineTo(center - (width / 2) - 10, 0);

    // MENGGAMBAR CEKUNGAN (Lebih Dalam)
    path.cubicTo(
      center - (width / 4),
      0, // Control Point 1
      center - (width / 4),
      depth, // Control Point 2 (Turun Dalam)
      center,
      depth, // Titik Dasar
    );
    path.cubicTo(
      center + (width / 4),
      depth, // Control Point 3 (Dasar Dalam)
      center + (width / 4),
      0, // Control Point 4 (Naik)
      center + (width / 2) + 10,
      0, // Selesai
    );

    // Garis lurus kanan
    path.lineTo(size.width - 20, 0);
    path.quadraticBezierTo(
      size.width,
      0,
      size.width,
      20,
    ); // Rounded corner atas kanan

    // Tutup kotak bawah
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant NavbarCurvePainter oldDelegate) {
    return oldDelegate.position != position;
  }
}
