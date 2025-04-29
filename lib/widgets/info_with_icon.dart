import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoWithIcon extends StatefulWidget {
  final IconData icon;
  final String text;
  final MainAxisAlignment alignment;
  final Alignment iconAlignment;
  final Color textColor;
  final double textSize;

  const InfoWithIcon({
    super.key,
    required this.icon,
    required this.text,
    this.alignment = MainAxisAlignment.start,
    this.iconAlignment = Alignment.center,
    this.textColor = Colors.white,
    this.textSize = 18,
  });

  @override
  State<InfoWithIcon> createState() => _InfoWithIconState();
}

class _InfoWithIconState extends State<InfoWithIcon>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  bool _startBlinking = false;
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.3,
      upperBound: 1.0,
    );

    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          _startBlinking = true;
        });
        _blinkController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth <= 800;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final double dynamicFontSize =
        isSmallScreen ? widget.textSize - 2 : widget.textSize;
    final double estimatedTextWidth =
        widget.text.length * (dynamicFontSize * 0.6);
    final bool needsEllipsis =
        estimatedTextWidth > (screenWidth * 0.4); // pequeño ajuste

    final Color normalColor = isDarkMode ? Colors.white54 : Colors.black54;
    final Color hoverColor =
        isDarkMode ? Colors.amberAccent : Colors.blueAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            mainAxisAlignment: widget.alignment,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: widget.iconAlignment,
                child: Icon(widget.icon, color: widget.textColor, size: 20),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: MouseRegion(
                        onEnter: (_) {
                          setState(() => _isHovering = true);
                        },
                        onExit: (_) {
                          setState(() => _isHovering = false);
                        },
                        child: GestureDetector(
                          onTap: () {
                            // No forzamos nada, Flutter maneja automáticamente el tooltip
                          },
                          child: Tooltip(
                            message: needsEllipsis ? widget.text : '',
                            waitDuration: const Duration(milliseconds: 300),
                            child: Text(
                              widget.text,
                              maxLines: isSmallScreen ? 1 : 2,
                              overflow:
                                  needsEllipsis
                                      ? TextOverflow.ellipsis
                                      : TextOverflow.visible,
                              softWrap: true,
                              textAlign: TextAlign.start,
                              style: GoogleFonts.ebGaramond(
                                color: widget.textColor,
                                fontSize: dynamicFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (needsEllipsis) const SizedBox(width: 6),
                    if (needsEllipsis)
                      AnimatedBuilder(
                        animation: _blinkController,
                        builder: (context, child) {
                          return Opacity(
                            opacity:
                                _startBlinking && !_isHovering
                                    ? _blinkController.value
                                    : 1,
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: _isHovering ? hoverColor : normalColor,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
