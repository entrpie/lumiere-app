// main.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart'; // Solución para la fuente Montserrat
import 'firebase_options.dart';
import 'inventario.dart'; // Redirección al iniciar sesión

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumière & Co. - Acceso',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Aplicamos Montserrat de forma global y automática
        fontFamily: GoogleFonts.montserrat().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8C6239),
          primary: const Color(0xFF8C6239),
          surface: const Color(0xFFFAF8F5),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicio de sesión exitoso'),
          backgroundColor: Color(0xFF556B2F),
        ),
      );

      // Redirecciona al Inventario eliminando el Login de la pila
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const InventarioPage()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Error al iniciar sesión';
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Correo o contraseña incorrectos';
      } else if (e.code == 'invalid-email') {
        message = 'El correo no es válido';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFC97A7A),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 1000,
            maxHeight: 620, // Altura máxima estática libre de scrollbars
          ),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C6239).withOpacity(0.06),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === LADO IZQUIERDO: CONTENEDOR DE IMAGEN ===
              const Expanded(
                flex: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                  child: VelasLogIn(),
                ),
              ),

              // === LADO DERECHO: FORMULARIO DE INGRESO ===
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 44.0,
                    vertical: 36.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Isotipo Minimalista
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2B28B),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'LUMIÈRE & CO.',
                              style: TextStyle(
                                letterSpacing: 2,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8C6239),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ¡Bienvenido de vuelta! con FontWeight en negrita (bold)
                        const Text(
                          '¡Bienvenido de vuelta!',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight:
                                FontWeight.bold, // <-- Cambiado a negritas aquí
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          'Panel de acceso exclusivo para el personal de Lumière & Co.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E8E8E),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // --- Campo de Correo ---
                        _buildInputLabel('Tu correo corporativo'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D2D2D),
                          ),
                          decoration: _buildInputDecoration(
                            'ejemplo@lumiere.com',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu correo';
                            }
                            if (!value.contains('@')) {
                              return 'Ingresa un correo válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // --- Campo de Contraseña ---
                        _buildInputLabel('Tu contraseña'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2D2D2D),
                          ),
                          decoration: _buildInputDecoration('••••••••••••••••')
                              .copyWith(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(
                                      0xFF8C6239,
                                    ).withOpacity(0.6),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // --- Botón de "Iniciar Sesión" ---
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8C6239),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Iniciar sesión',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- Línea divisoria ---
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Color(0xFFECE6DF),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'o continuar con',
                                style: TextStyle(
                                  color: const Color(
                                    0xFF8E8E8E,
                                  ).withOpacity(0.8),
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Color(0xFFECE6DF),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // --- Botones de Login Social ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialLoginButton(
                              Icons.g_mobiledata,
                              () => print('Login con Google'),
                            ),
                            const SizedBox(width: 16),
                            _socialLoginButton(
                              Icons.apple,
                              () => print('Login con Apple'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8C6239),
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: const Color(0xFF8E8E8E).withOpacity(0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFFAF8F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFAF8F5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2B28B), width: 1.5),
      ),
    );
  }

  Widget _socialLoginButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 50,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFECE6DF)),
      ),
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF8C6239), size: 22),
        onPressed: onPressed,
      ),
    );
  }
}

class VelasLogIn extends StatelessWidget {
  const VelasLogIn({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/img/vela_login.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.12),
                    padding: const EdgeInsets.all(20.0),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lumière & Co.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Creadas con amor, encendidas con intención.',
                          style: TextStyle(
                            color: Color(0xFFF0EFEF),
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w300,
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
      ),
    );
  }
}
