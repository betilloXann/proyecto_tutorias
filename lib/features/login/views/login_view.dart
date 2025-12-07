import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/text_input_field.dart';
import '../viewmodels/login_viewmodel.dart';
import '../../../core/widgets/responsive_container.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController emailCtrl;
  late final TextEditingController passwordCtrl;
  late final FocusNode _emailFocusNode;
  late final FocusNode _passwordFocusNode;

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    emailCtrl = TextEditingController();
    passwordCtrl = TextEditingController();
    _emailFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    final vm = context.read<LoginViewModel>();
    FocusScope.of(context).unfocus();

    final success = await vm.login(
      emailCtrl.text.trim(),
      passwordCtrl.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage ?? "Error desconocido"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<LoginViewModel>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9EB8D1).withValues(alpha: 0.25),
                offset: const Offset(2, 3),
                blurRadius: 8,
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2F5A93)),
            onPressed: () => Navigator.pushNamed(context, "/welcome"),
          ),
        ),
      ),

      // FONDO GRADIENTE
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFEBF3FF),
              Color(0xFFD6E7FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 120, 24, 24 + bottomPadding),

            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),

              child: Column(
                children: [
                  SvgPicture.asset("assets/images/image2.svg", height: 150, width: 160),

                  const SizedBox(height: 24),

                  Text(
                    "Iniciar Sesión",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2F5A93),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  TextInputField(
                    key: const Key('login_email_input'), // <--- AGREGA ESTO
                    label: "Correo Personal",
                    controller: emailCtrl,
                    focusNode: _emailFocusNode,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  TextInputField(
                    key: const Key('login_password_input'), // <--- AGREGA ESTO
                    label: "Contraseña",
                    controller: passwordCtrl,
                    focusNode: _passwordFocusNode,
                    icon: Icons.lock_outline,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submitLogin(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, "/recover"),
                      child: Text(
                        "¿Olvidaste tu contraseña?",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2F5A93),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: vm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : PrimaryButton(
                      key: const Key('login_button'), // <--- AGREGA ESTO TAMBIÉN
                      text: "Ingresar",
                      onPressed: _submitLogin,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, "/activation"),
                    child: Text(
                      "¿Eres nuevo? Activa tu cuenta aquí",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF2F5A93),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
