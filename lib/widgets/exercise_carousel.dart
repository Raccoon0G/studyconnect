import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExerciseCarousel extends StatefulWidget {
  const ExerciseCarousel({super.key});

  @override
  State<ExerciseCarousel> createState() => _ExerciseCarouselState();
}

class _ExerciseCarouselState extends State<ExerciseCarousel> {
  final PageController _pageController = PageController();
  late final Timer _autoScrollTimer;
  int _currentPage = 0;

  final List<_CarouselItem> _items = const [
    _CarouselItem(
      image: 'assets/images/slide1.png',
      title: 'Aprende colaborando',
      description:
          'Comparte y resuelve ejercicios junto con otros estudiantes.',
    ),
    _CarouselItem(
      image: 'assets/images/slide2.png',
      title: 'Explora contenido visual',
      description: 'Consulta soluciones paso a paso renderizadas con LaTeX.',
    ),
    _CarouselItem(
      image: 'assets/images/slide3.png',
      title: 'Gana reconocimiento',
      description: 'Sube tus ejercicios y obtén puntos en el ranking.',
    ),
    _CarouselItem(
      image: 'assets/images/slide4.png',
      title: 'Mejora tu rendimiento',
      description: 'Practica y supera tus propios registros académicos.',
    ),
    _CarouselItem(
      image: 'assets/images/slide5.png',
      title: 'Conecta con estudiantes',
      description: 'Forma parte de la comunidad y comparte conocimientos.',
    ),
  ];

  final List<Color> _backgroundColors = [
    const Color(0xFF0D47A1), // azul profundo
    const Color(0xFF1565C0), // azul intermedio
    const Color(0xFF1E88E5), // azul cielo
    const Color(0xFF5E35B1), // morado elegante
    const Color(0xFF3949AB), // azul violeta
  ];

  @override
  void initState() {
    super.initState();

    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _items.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo dinámico según el slide
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundColors[_currentPage].withAlpha(
                    (0.85 * 255).toInt(),
                  ),
                  Colors.black.withAlpha((0.3 * 255).toInt()),
                ],
              ),
            ),
          ),

          // Efecto de blur en el fondo
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
            ),
          ),
          // Contenido principal
          Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isCurrent = index == _currentPage;
                    return AnimatedOpacity(
                      opacity: isCurrent ? 1.0 : 0.6,
                      duration: const Duration(milliseconds: 400),
                      child: AnimatedScale(
                        scale: isCurrent ? 1.0 : 0.9,
                        duration: const Duration(milliseconds: 400),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                flex: 6,
                                child: Image.asset(
                                  item.image,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Flexible(
                                flex: 2,
                                child: Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Flexible(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    item.description,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.ebGaramond(
                                      fontSize: 16,
                                      color: Colors.white70,
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
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_items.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 12 : 8,
                      height: _currentPage == index ? 12 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index
                                ? Colors.white
                                : Colors.white30,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class _CarouselItem {
  final String image;
  final String title;
  final String description;

  const _CarouselItem({
    required this.image,
    required this.title,
    required this.description,
  });
}
