import 'dart:async';
import 'dart:ui'; // Para ImageFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExerciseCarousel extends StatefulWidget {
  const ExerciseCarousel({super.key});

  @override
  State<ExerciseCarousel> createState() => _ExerciseCarouselState();
}

class _ExerciseCarouselState extends State<ExerciseCarousel> {
  final PageController _pageController = PageController();
  Timer? _autoScrollTimer; // Hacerlo nullable para manejarlo mejor
  int _currentPage = 0;

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

    // Iniciar el PageController listener
    _pageController.addListener(() {
      if (_pageController.page != null) {
        // Verificar que page no sea null
        final page = _pageController.page!.round();
        if (page != _currentPage) {
          if (mounted) {
            // Verificar si el widget está montado antes de llamar a setState
            setState(() {
              _currentPage = page;
            });
          }
        }
      }
    });

    // Iniciar el timer solo si hay items
    if (_items.isNotEmpty) {
      _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_pageController.hasClients && mounted) {
          // Verificar mounted
          final nextPage = (_currentPage + 1) % _items.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel(); // Cancelar si no es null
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay items, muestra un placeholder o un mensaje
    if (_items.isEmpty) {
      return Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Text("No hay elementos en el carrusel"),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.expand, // Esto hace que el Stack llene el ConstrainedBox
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundColors[_currentPage % _backgroundColors.length]
                      .withAlpha(
                        // Usar modulo para _backgroundColors
                        (0.85 * 255).toInt(),
                      ),
                  Colors.black.withAlpha((0.3 * 255).toInt()),
                ],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
            ),
          ),
          Column(
            children: [
              Expanded(
                // PageView necesita estar en un padre con restricciones finitas de altura
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 8.0,
                          ), // Añadido vertical padding
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                // Usar Expanded en lugar de Flexible para que la imagen tome el espacio dado
                                flex: 6,
                                child: Image.asset(
                                  item.image,
                                  fit: BoxFit.scaleDown,
                                  //width: double.infinity, // QUITAMOS ESTO
                                  // El widget Expanded se encargará de las restricciones
                                ),
                              ),
                              const SizedBox(height: 12), // Reducido un poco
                              Text(
                                // Ya no es Flexible, dejamos que tome su altura natural
                                item.title,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.ebGaramond(
                                  fontSize: 22, // Ajustar si es necesario
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    // Sombra para mejorar legibilidad
                                    const Shadow(
                                      blurRadius: 2.0,
                                      color: Colors.black54,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6), // Reducido un poco
                              Padding(
                                // Padding alrededor de la descripción
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                ),
                                child: Text(
                                  // Ya no es Flexible
                                  item.description,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 15, // Ajustar si es necesario
                                    color: Colors.white.withOpacity(0.85),
                                    shadows: [
                                      // Sombra para mejorar legibilidad
                                      const Shadow(
                                        blurRadius: 1.0,
                                        color: Colors.black38,
                                        offset: Offset(1, 1),
                                      ),
                                    ],
                                  ),
                                  maxLines: 3, // Permitir más líneas
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(
                                flex: 1,
                              ), // Para empujar los dots un poco si hay espacio
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10), // Espacio antes de los dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_items.length, (index) {
                  return GestureDetector(
                    onTap: () {
                      if (_pageController.hasClients) {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
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
                                : Colors.white.withOpacity(
                                  0.4,
                                ), // Un poco más opaco el inactivo
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12), // Espacio después de los dots
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
