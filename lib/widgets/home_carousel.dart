import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeCarousel extends StatefulWidget {
  const HomeCarousel({super.key});

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  final PageController _pageController = PageController();
  late final Timer _autoScrollTimer;
  int _currentPage = 0;

  final List<_CarouselItem> _items = const [
    _CarouselItem(
      image: 'assets/images/slide_calculo.png',
      title: 'Dominio de Cálculo',
      description:
          'Aprende y domina los conceptos clave de cálculo diferencial e integral con ejercicios guiados y materiales actualizados.',
    ),
    _CarouselItem(
      image: 'assets/images/slide_colaborativo.png',
      title: 'Colaboración en tiempo real',
      description:
          'Interactúa con otros estudiantes y tutores, comparte dudas y resuelve problemas en grupo desde cualquier lugar.',
    ),
    _CarouselItem(
      image: 'assets/images/slide_gamificacion.png',
      title: 'Motívate y gana recompensas',
      description:
          'Suma puntos, sube de nivel y recibe reconocimientos por tu participación en el sistema y en el ranking general.',
    ),
    _CarouselItem(
      image: 'assets/images/slide_compartir.png',
      title: 'Comparte en Facebook',
      description:
          'Publica tus ejercicios y logros fácilmente en Facebook para motivar a más estudiantes a aprender contigo.',
    ),
    _CarouselItem(
      image: 'assets/images/slide_escom.png',
      title: 'Desarrollado en ESCOM-IPN',
      description:
          'Un proyecto innovador creado por estudiantes para estudiantes, integrando tecnología y educación de calidad.',
    ),
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 560,
      child: Stack(
        children: [
          // Carousel principal
          Positioned.fill(
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
                    scale: isCurrent ? 1.0 : 0.97,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      width: double.infinity,
                      height: 560,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.transparent,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          height: 560,
                          color: Colors.black.withOpacity(0.14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Image.asset(
                                  item.image,
                                  width: double.infinity,
                                  height: 400,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                item.title,
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  item.description,
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Logo IPN (izquierda superior)
          Positioned(
            top: 18,
            left: 24,
            child: Image.asset(
              'assets/images/IPN-Logo.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              color: Colors.white.withOpacity(
                0.93,
              ), // Sutil, puedes bajar opacidad si lo quieres más suave
              colorBlendMode: BlendMode.modulate,
            ),
          ),
          // Logo ESCOM (derecha superior)
          Positioned(
            top: 18,
            right: 24,
            child: Image.asset(
              'assets/images/escudoESCOM.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              color: Colors.white.withOpacity(0.93),
              colorBlendMode: BlendMode.modulate,
            ),
          ),
          // Indicadores (dots)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
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
                          width: 12,
                          height: 12,
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
