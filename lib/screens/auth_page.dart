import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (!mounted || user == null) return;

      if (!user.emailVerified) {
        await _auth.signOut();
        _showAlert(
          'Correo no verificado',
          'Debes verificar tu correo electrónico antes de iniciar sesión.',
        );
        setState(() => _isLoading = false);
        return;
      }

      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .get();
      final data = doc.data();
      final perfilCompleto =
          data != null && (data['Nombre'] ?? '').toString().trim().isNotEmpty;

      setState(() => _isLoading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          Future.delayed(const Duration(seconds: 2), () {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
            Navigator.pushReplacementNamed(
              context,
              perfilCompleto ? '/' : '/edit_profile',
            );
          });

          return AlertDialog(
            title: Text(
              perfilCompleto ? '¡Bienvenido de nuevo!' : 'Bienvenido',
            ),
            content: Text(
              perfilCompleto
                  ? 'Inicio de sesión exitoso. Serás redirigido al inicio.'
                  : 'Inicio de sesión exitoso. Completa tu perfil para continuar.',
            ),
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _emailError = null;
        _passwordError = null;
      });

      String mensaje = 'Error desconocido';

      if (e.code == 'user-not-found') {
        _emailError = 'No se encontró un usuario con ese correo';
      } else if (e.code == 'wrong-password') {
        _passwordError = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        mensaje = 'Correo inválido. Verifica el formato.';
      } else if (e.code == 'invalid-credential') {
        mensaje = 'Credenciales incorrectas o expiradas.';
      } else {
        mensaje = e.message ?? mensaje;
      }

      _formKey.currentState!.validate();

      if (_emailError == null && _passwordError == null) {
        _showAlert('Error al iniciar sesión', mensaje);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !_validateEmailFormat(email)) {
      _showAlert(
        'Correo no válido',
        'Ingresa un correo electrónico válido para restablecer tu contraseña.',
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _emailController.clear();
      _showAlert(
        'Correo enviado',
        'Se ha enviado un correo para restablecer tu contraseña. Revisa tu bandeja de entrada.',
      );
    } catch (e) {
      _showAlert('Error', 'No se pudo enviar el correo: $e');
    }
  }

  void _showAlert(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(titulo),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aceptar'),
              ),
            ],
          ),
    );
  }

  bool _validateEmailFormat(String email) {
    final emailRegex = RegExp(
      r'^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@'
      r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|'
      r'(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
    );
    return emailRegex.hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF036799),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF024D78),
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Accede para comenzar a compartir y resolver ejercicios.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF48C9EF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInputField(
                        label: 'Correo electrónico',
                        controller: _emailController,
                        errorText: _emailError,
                        isValid:
                            _emailError == null &&
                            _emailController.text.isNotEmpty,
                      ),
                      _buildInputField(
                        label: 'Contraseña',
                        controller: _passwordController,
                        obscure: _obscurePassword,
                        errorText: _passwordError,
                        isValid:
                            _passwordError == null &&
                            _passwordController.text.isNotEmpty,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Ingresar'),
                          ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed:
                            () => Navigator.pushNamed(context, '/register'),
                        child: const Text(
                          '¿No tienes cuenta? Regístrate',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    String? errorText,
    Widget? suffixIcon,
    bool isValid = false,
  }) {
    Icon? statusIcon;
    if (controller.text.isNotEmpty) {
      statusIcon = Icon(
        errorText != null ? Icons.close : Icons.check,
        color: errorText != null ? Colors.red : Colors.green,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label :', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon ?? statusIcon,
            errorText: errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
