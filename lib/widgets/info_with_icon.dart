import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoWithIcon extends StatelessWidget {
  final IconData icon;
  final String text;
  final MainAxisAlignment alignment;
  final Color textColor;
  final double textSize;

  const InfoWithIcon({
    super.key,
    required this.icon,
    required this.text,
    this.alignment = MainAxisAlignment.start,
    this.textColor = Colors.white,
    this.textSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.ebGaramond(
              color: textColor,
              fontSize: textSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
