import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_theme.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B6E), Color(0xFF1A237E), Color(0xFF0A0E27)],
              ),
            ),
          ),
          // Stars decoration
          const Positioned.fill(child: _StarField()),
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo & title
                Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                        ),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.5), blurRadius: 20, spreadRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.rocket_launch, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text('EduGalaxy', style: TextStyle(
                      color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2,
                    )),
                    const Text('Aprender é uma aventura!', style: TextStyle(
                      color: Color(0xFF89B4FA), fontSize: 14, letterSpacing: 1,
                    )),
                  ],
                ),
                const SizedBox(height: 40),
                // Tab selector
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E3C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                      ),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF89B4FA),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: '👨‍🏫  Professor'),
                      Tab(text: '🚀  Aluno'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ProfessorLoginForm(emailCtrl: _emailCtrl, passwordCtrl: _passwordCtrl, obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                      _StudentLoginSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Professor login form ──────────────────────────────────────────────────────
class _ProfessorLoginForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscure;
  final VoidCallback onToggle;

  const _ProfessorLoginForm({
    required this.emailCtrl, required this.passwordCtrl,
    required this.obscure, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _GlassField(
            controller: emailCtrl,
            label: 'E-mail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _GlassField(
            controller: passwordCtrl,
            label: 'Senha',
            icon: Icons.lock_outline,
            obscure: obscure,
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF89B4FA)),
              onPressed: onToggle,
            ),
          ),
          if (auth.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEC4899), size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(auth.errorMessage!, style: const TextStyle(color: Color(0xFFEC4899), fontSize: 13))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : () async {
                final ok = await auth.loginProfessor(emailCtrl.text.trim(), passwordCtrl.text);
                if (ok && context.mounted) {
                  context.go(AppRoutes.professorDashboard);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ).copyWith(
                backgroundColor: WidgetStateProperty.all(Colors.transparent),
                overlayColor: WidgetStateProperty.all(Colors.white12),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF0288D1)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: auth.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Entrar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Student entry shortcut ────────────────────────────────────────────────────
class _StudentLoginSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1E3C),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text('🚀', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                const Text('Pronto para a missão?', style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 8),
                const Text(
                  'Seu professor te dará o código da turma. Use-o para entrar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF89B4FA), fontSize: 13),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.studentRoomEntry),
                    icon: const Icon(Icons.vpn_key_outlined),
                    label: const Text('Usar código da turma'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable glass text field ─────────────────────────────────────────────────
class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _GlassField({
    required this.controller, required this.label, required this.icon,
    this.obscure = false, this.keyboardType, this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF89B4FA)),
        prefixIcon: Icon(icon, color: const Color(0xFF7C3AED)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1A1E3C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
      ),
    );
  }
}

// ── Decorative star field ─────────────────────────────────────────────────────
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter());
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final positions = [
      Offset(size.width * 0.1, size.height * 0.05),
      Offset(size.width * 0.85, size.height * 0.08),
      Offset(size.width * 0.45, size.height * 0.03),
      Offset(size.width * 0.7, size.height * 0.15),
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.92, size.height * 0.3),
      Offset(size.width * 0.05, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.35, size.height * 0.55),
      Offset(size.width * 0.88, size.height * 0.6),
      Offset(size.width * 0.15, size.height * 0.7),
      Offset(size.width * 0.75, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.9),
      Offset(size.width * 0.25, size.height * 0.95),
    ];
    for (int i = 0; i < positions.length; i++) {
      paint.color = Colors.white.withOpacity(i % 3 == 0 ? 0.9 : 0.4);
      canvas.drawCircle(positions[i], i % 4 == 0 ? 2.5 : 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
