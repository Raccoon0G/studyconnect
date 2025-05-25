import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:study_connect/widgets/register_carousel.dart';
import 'package:study_connect/widgets/hoverable_text.dart';
import 'package:study_connect/widgets/widgets.dart' show CustomAppBar;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _acceptedTerms = true;
  bool _acceptedPrivacy = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms || !_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar todos los términos y condiciones'),
        ),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    try {
      //print("Creando usuario con Firebase Auth...");
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //print("Enviando verificación...");
      await userCredential.user!.sendEmailVerification();

      final uid = userCredential.user!.uid;

      await initializeDateFormatting('es_MX');
      //print("Guardando usuario en Firestore...");
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'Nombre': name,
        'Correo': email,
        'Telefono': phone,
        'rol': 'Estudiante',
        'id': uid,
        'FotoPerfil': '',
        'CalificacionEjercicios': 0.0,
        'CalificacionMateriales': 0.0,
        'EjerSubidos': 0,
        'MaterialesSubidos': 0,
        'Acerca de mi': '',
        'Config': {
          'ModoOscuro': true,
          'Notificaciones': true,
          'PerfilVisible': true,
        },
        'FechaRegistro': DateFormat.yMMMMd(
          'es_MX',
        ).add_jm().format(DateTime.now()),
      });

      if (!mounted) return;

      print("Mostrando diálogo de éxito...");
      mostrarDialogoExitosoConRedireccion(context);
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException: ${e.code} - ${e.message}");

      if (!mounted) return;
      String mensaje = 'Ocurrió un error inesperado.';

      if (e.code == 'email-already-in-use') {
        mensaje = 'El correo electrónico ya está en uso.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo electrónico no es válido.';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es demasiado débil.';
      } else {
        mensaje = '(${e.code}) ${e.message ?? mensaje}';
      }

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Error al registrarse'),
              content: Text(mensaje),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
      );
    } catch (e) {
      //print("Error inesperado: $e");
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Error'),
              content: Text('Ha ocurrido un error: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Aceptar'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      appBar: const CustomAppBar(showBack: true),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool esPantallaGrande = constraints.maxWidth >= 900;
          final double anchoFormulario =
              esPantallaGrande ? 400 : constraints.maxWidth * 0.9;

          return Row(
            children: [
              if (esPantallaGrande)
                Expanded(
                  flex: 3,
                  child: Container(
                    color: const Color(0xFF024D78),
                    padding: const EdgeInsets.all(32),
                    child:
                        const RegisterCarousel(), //  Carrusel sólo en pantallas grandes
                  ),
                ),
              Expanded(
                flex: esPantallaGrande ? 1 : 2, // Si es chica, que ocupe más
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(
                      16,
                    ), // Para que no se corte en móviles
                    child: Container(
                      width: anchoFormulario,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF48C9EF),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black, blurRadius: 12),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Registro',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildField(
                              _emailController,
                              'Correo',
                              validator: _validateEmail,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(320),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              _passwordController,
                              'Contraseña',
                              obscure: _obscurePassword,
                              validator: _validatePassword,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(24),
                              ],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildField(
                              _confirmPasswordController,
                              'Confirmar contraseña',
                              obscure: _obscureConfirmPassword,
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Las contraseñas no coinciden';
                                }
                                return null;
                              },
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(24),
                              ],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed:
                                    () => setState(
                                      () =>
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _checkboxWithInternalRoute(
                              value: _acceptedTerms,
                              label: 'Acepto Términos y condiciones',
                              onChanged:
                                  (val) => setState(
                                    () => _acceptedTerms = val ?? false,
                                  ),
                              routeName: '/terms',
                              context: context,
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Container(
                                width: 200,
                                height: 1,
                                color: Colors.white38,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _checkboxWithInternalRoute(
                              value: _acceptedPrivacy,
                              label: 'Acepto Aviso de privacidad',
                              onChanged:
                                  (val) => setState(
                                    () => _acceptedPrivacy = val ?? false,
                                  ),
                              routeName: '/privacy',
                              context: context,
                            ),
                            const SizedBox(height: 26),
                            Center(
                              child: Image.asset(
                                'assets/images/logo.png',
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text('Registrarse'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label :', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator:
              validator ??
              (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
        ),
      ],
    );
  }

  Widget _checkboxWithInternalRoute({
    required bool value,
    required String label,
    required Function(bool?) onChanged,
    required String routeName,
    required BuildContext context,
  }) {
    return Center(
      //  Ahora TODO el checkbox + texto estará centrado
      child: Row(
        mainAxisSize:
            MainAxisSize
                .min, //  Solo ocupa lo que necesita (no toda la pantalla)
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            visualDensity: const VisualDensity(
              horizontal: -4,
              vertical: -4,
            ), // más compacto
          ),
          Flexible(
            child: HoverableText(
              text: label,
              onTap: () => Navigator.pushNamed(context, routeName),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    final emailRegex = RegExp(
      r'^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@'
      r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|'
      r'(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
    );
    if (value == null || !emailRegex.hasMatch(value.trim())) {
      return 'Correo no válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final passRegex = RegExp(r'^[\x20-\x7F]{8,24}$');
    if (value == null || !passRegex.hasMatch(value)) {
      return 'Contraseña inválida (8-24 caracteres ASCII)';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Debe contener exactamente 10 dígitos';
    }
    return null;
  }

  void mostrarDialogoExitosoConRedireccion(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(seconds: 5), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
          Navigator.pushReplacementNamed(dialogContext, '/login');
        });

        return AlertDialog(
          title: const Text('Registro exitoso'),
          content: const Text(
            'Tu cuenta ha sido creada correctamente.\n\n'
            'Hemos enviado un correo de verificación. Por favor, revísalo antes de iniciar sesión.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.pushReplacementNamed(dialogContext, '/login');
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}
