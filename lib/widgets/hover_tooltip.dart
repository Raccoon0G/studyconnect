import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//Sirve para mostrar un tooltip cuando el texto es muy largo y no cabe en la pantalla
// y el texto es muy largo, pero no se ve en la pantalla. El tooltip se muestra al pasar el mouse sobre el texto.

class HoverTooltip extends StatefulWidget {
  final String message;
  final String text;
  final Color textColor;
  final double textSize;
  final Duration waitDuration;
  final Duration showDuration;

  const HoverTooltip({
    super.key,
    required this.message,
    required this.text,
    this.textColor = Colors.white,
    this.textSize = 18,
    this.waitDuration = const Duration(milliseconds: 300),
    this.showDuration = const Duration(seconds: 3),
  });

  @override
  State<HoverTooltip> createState() => _HoverTooltipState();
}

class _HoverTooltipState extends State<HoverTooltip> {
  final GlobalKey _textKey = GlobalKey();
  bool _needsTooltip = false;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkIfNeedsTooltip());
  }

  void _checkIfNeedsTooltip() {
    final RenderBox? renderBox =
        _textKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final double textWidth = renderBox.size.width;
      final double availableWidth =
          (context.findRenderObject() as RenderBox?)?.constraints.maxWidth ??
          double.infinity;

      if (textWidth > availableWidth) {
        setState(() {
          _needsTooltip = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 800;

    final textWidget = Text(
      widget.text,
      key: _textKey,
      maxLines: isSmallScreen ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
      textAlign: TextAlign.start,
      style: GoogleFonts.ebGaramond(
        color: widget.textColor,
        fontSize: widget.textSize,
        fontWeight: FontWeight.w500,
      ),
    );

    if (!_needsTooltip) {
      // ❌ No necesita Tooltip, solo mostrar texto normal
      return textWidget;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Tooltip(
        message: widget.message,
        waitDuration: widget.waitDuration,
        showDuration: widget.showDuration,
        triggerMode:
            _isHovering ? TooltipTriggerMode.manual : TooltipTriggerMode.tap,
        preferBelow: false,
        verticalOffset: 20,
        child: textWidget,
      ),
    );
  }
}
