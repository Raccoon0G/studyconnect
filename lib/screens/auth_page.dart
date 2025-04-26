import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:study_connect/widgets/login_carousel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _emailController.addListener(_actualizarEstado);
    _passwordController.addListener(_actualizarEstado);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 24,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _actualizarEstado() {
    setState(() {}); // fuerza actualización del botón
  }

  bool _intentoFallido = false;

  bool _sacudiendoPassword = false;

  bool get _formularioValido {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final emailValido = _validateEmailFormat(email);
    final passwordValida = password.length >= 6 && password.length <= 20;
    return emailValido && passwordValida;
  }

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _intentoFallido = true); // Marca el intento fallido
      return;
    }

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
        _intentoFallido = true;
        _sacudiendoPassword = true;
        _shakeController.forward(from: 0).then((_) {
          _shakeController.reverse(); // 🔁 Esto regresa la animación a 0
          setState(() {
            _sacudiendoPassword = false;
            _emailError = null;
            _passwordError = null;
          });
        });
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
            flex: 3,
            child: Container(
              color: const Color(0xFF024D78),
              padding: const EdgeInsets.all(32),
              child: const LoginCarousel(), // 👈 el nuevo widget
            ),
          ),

          Expanded(
            flex: 1,
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
                        hintText: 'ejemplo@dominio.com',
                        helperText: 'Debe tener un formato válido de correo.',
                      ),

                      // _buildInputField(
                      //   label: 'Contraseña',
                      //   controller: _passwordController,
                      //   obscure: _obscurePassword,
                      //   errorText: _passwordError,
                      //   isValid:
                      //       _passwordError == null &&
                      //       _passwordController.text.isNotEmpty,
                      //   hintText: 'Mínimo 6 caracteres',
                      //   helperText:
                      //       'Debe contener al menos 6 caracteres. \n Y maximo 20 caracteres.',
                      //   suffixIcon: IconButton(
                      //     icon: Icon(
                      //       _obscurePassword
                      //           ? Icons.visibility_off
                      //           : Icons.visibility,
                      //     ),
                      //     onPressed: () {
                      //       setState(() {
                      //         _obscurePassword = !_obscurePassword;
                      //       });
                      //     },
                      //   ),
                      // ),
                      AnimatedBuilder(
                        animation: _shakeController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: child,
                          );
                        },
                        child: _buildInputField(
                          label: 'Contraseña',
                          controller: _passwordController,
                          obscure: _obscurePassword,
                          errorText: _passwordError,
                          isValid:
                              _passwordError == null &&
                              _passwordController.text.isNotEmpty,
                          hintText: 'Mínimo 8 caracteres',
                          helperText:
                              'Debe contener al menos 8 caracteres. \n Y máximo 24 caracteres.',
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
                      // _isLoading
                      //     ? const CircularProgressIndicator(color: Colors.white)
                      //     : ElevatedButton(
                      //       onPressed: _isLoading ? null : _login,
                      //       style: ElevatedButton.styleFrom(
                      //         backgroundColor: Colors.white,
                      //         foregroundColor: Colors.black,
                      //         padding: const EdgeInsets.symmetric(
                      //           horizontal: 32,
                      //           vertical: 12,
                      //         ),
                      //         shape: RoundedRectangleBorder(
                      //           borderRadius: BorderRadius.circular(30),
                      //         ),
                      //       ),
                      //       child: const Text('Ingresar'),
                      //     ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          onPressed:
                              (_isLoading ||
                                      (_intentoFallido && !_formularioValido))
                                  ? null
                                  : _login,

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
                          child:
                              _isLoading
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Ingresando...'),
                                    ],
                                  )
                                  : const Text('Ingresar'),
                        ),
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
    String? hintText,
    String? helperText,
  }) {
    Icon? statusIcon;
    final isEmailField = label.contains('Correo');
    final isPasswordField = label.contains('Contraseña');

    if (controller.text.isNotEmpty) {
      final isValidEmail =
          isEmailField && _validateEmailFormat(controller.text);
      final isValidPassword =
          isPasswordField &&
          controller.text.length >= 6 &&
          controller.text.length <= 20;

      final isValid = isEmailField ? isValidEmail : isValidPassword;

      statusIcon = Icon(
        isValid ? Icons.check : Icons.close,
        color: isValid ? Colors.green : Colors.red,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: Colors.black),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Este campo es obligatorio.';
              }
              if (label.contains('Correo') && !_validateEmailFormat(value)) {
                return 'Ingresa un correo válido. Ej: ejemplo@dominio.com';
              }
              if (label.contains('Contraseña') && value.length < 6) {
                return 'La contraseña debe tener mínimo 6 caracteres.';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.black45),
              helperText: helperText,
              helperStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white,
              errorText:
                  errorText ??
                  (_sacudiendoPassword && isPasswordField ? '' : null),
              suffixIcon: suffixIcon ?? statusIcon,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.cyan, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
