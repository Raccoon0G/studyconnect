import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterCarousel extends StatefulWidget {
  const RegisterCarousel({super.key});

  @override
  State<RegisterCarousel> createState() => _RegisterCarouselState();
}

class _RegisterCarouselState extends State<RegisterCarousel> {
  final PageController _pageController = PageController();
  late final Timer _autoScrollTimer;
  int _currentPage = 0;

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

    // _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
    //   if (_pageController.hasClients) {
    //     final nextPage = (_currentPage + 1) % _items.length;
    //     _pageController.animateToPage(
    //       nextPage,
    //       duration: const Duration(milliseconds: 600),
    //       curve: Curves.easeInOut,
    //     );
    //   }
    // });
    //tarda un poco mas la animacion pero es mas suave
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final isLastPage = _currentPage == _items.length - 1;
        final nextPage = isLastPage ? 0 : _currentPage + 1;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: isLastPage ? 1200 : 600),
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

  final List<_CarouselItem> _items = const [
    _CarouselItem(
      image: 'assets/images/slide1.webp',
      title: 'Aprende colaborando',
      description:
          'Comparte y resuelve ejercicios junto con otros estudiantes.',
    ),
    _CarouselItem(
      image: 'assets/images/slide2.webp',
      title: 'Explora contenido visual',
      description: 'Consulta soluciones paso a paso renderizadas con LaTeX.',
    ),
    _CarouselItem(
      image: 'assets/images/slide3.webp',
      title: 'Gana reconocimiento',
      description: 'Sube tus ejercicios y obtén puntos en el ranking.',
    ),
    _CarouselItem(
      image: 'assets/images/slide4.webp',
      title: 'Mejora tu rendimiento',
      description: 'Practica y supera tus propios registros académicos.',
    ),
    _CarouselItem(
      image: 'assets/images/slide5.webp',
      title: 'Conecta con estudiantes',
      description: 'Forma parte de la comunidad y comparte conocimientos.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final isCurrent = index == _currentPage;
                  return AnimatedOpacity(
                    opacity: isCurrent ? 1.0 : 0.5,
                    duration: const Duration(milliseconds: 400),
                    child: AnimatedScale(
                      scale: isCurrent ? 1.0 : 0.9,
                      duration: const Duration(milliseconds: 400),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              item.image,
                              height: constraints.maxHeight * 0.4,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              item.title,
                              style: GoogleFonts.montserrat(
                                // <--- Nueva fuente bonita
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.description,
                              style: GoogleFonts.montserrat(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _items.length,
                (index) => GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 1.0,
                      end: _currentPage == index ? 1.4 : 1.0,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color:
                                _currentPage == index
                                    ? Colors.white
                                    : Colors.white38,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
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
