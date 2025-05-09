import 'package:flutter/material.dart';

class CustomActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool reserveLoaderSpace;
  final bool animar;
  final bool girarIcono;

  const CustomActionButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF1A1A1A),
    this.foregroundColor = Colors.white,
    this.reserveLoaderSpace = false,
    this.animar = false,
    this.girarIcono = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorAnimada = animar ? Colors.blue.shade700 : backgroundColor;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      tween: Tween<double>(begin: 1.0, end: animar ? 1.04 : 1.0),
      builder: (context, scale, child) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 600),
          opacity: animar ? 0.9 : 1.0,
          child: Transform.scale(
            scale: scale,
            child: Semantics(
              label: text,
              button: true,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorAnimada,
                  foregroundColor: foregroundColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (girarIcono)
                      _RotatingIcon(icon)
                    else
                      Icon(icon, size: 20),
                    const SizedBox(width: 8),
                    Text(text),
                    if (reserveLoaderSpace) const SizedBox(width: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RotatingIcon extends StatefulWidget {
  final IconData icon;
  const _RotatingIcon(this.icon);

  @override
  State<_RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<_RotatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(); // Gira indefinidamente
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, size: 20),
    );
  }
}
