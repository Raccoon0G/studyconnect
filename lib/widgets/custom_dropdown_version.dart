import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomDropdownVersiones extends StatelessWidget {
  final String? versionSeleccionada;
  final List<Map<String, dynamic>> versiones;
  final ValueChanged<String> onChanged;

  const CustomDropdownVersiones({
    super.key,
    required this.versionSeleccionada,
    required this.versiones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // mejora fondo
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: DropdownButtonFormField<String>(
        value: versionSeleccionada,
        isExpanded: true,
        decoration: const InputDecoration.collapsed(
          hintText: 'Seleccionar versión',
        ),
        dropdownColor: Colors.white,
        items:
            versiones.map((ver) {
              final fecha = (ver['fecha'] as Timestamp?)?.toDate();
              final formattedFecha =
                  fecha != null
                      ? DateFormat('dd/MM/yyyy').format(fecha)
                      : 'Sin fecha';
              return DropdownMenuItem<String>(
                value: ver['id'],
                child: Center(
                  child: Text(
                    'Versión: ${ver['id']} - $formattedFecha',
                    style: GoogleFonts.ebGaramond(
                      fontSize: 20,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}
