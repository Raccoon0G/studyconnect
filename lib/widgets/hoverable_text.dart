import 'package:flutter/material.dart';

class HoverableText extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final double fontSize;
  final Color color;
  final Color hoverColor;
  final TextAlign textAlign;
  final FontWeight fontWeight;

  const HoverableText({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.fontSize = 13,
    this.color = Colors.white,
    this.hoverColor = Colors.cyanAccent,
    this.textAlign = TextAlign.center,
    this.fontWeight = FontWeight.normal,
  });

  @override
  State<HoverableText> createState() => _HoverableTextState();
}

class _HoverableTextState extends State<HoverableText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, // 👈 Manita siempre
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            color: _isHovered ? widget.hoverColor : widget.color,
            decoration: TextDecoration.underline,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: widget.fontSize + 2,
                  color: _isHovered ? widget.hoverColor : widget.color,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.text,
                  textAlign: widget.textAlign,
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
