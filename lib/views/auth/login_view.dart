import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/router/app_routes.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B6E), Color(0xFF1A237E), Color(0xFF0A0E27)],
              ),
            ),
          ),
          const Positioned.fill(child: _StarField()),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 36),
                // Logo
                Column(
                  children: [
                    Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)]),
                        boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.5), blurRadius: 20, spreadRadius: 4)],
                      ),
                      child: const Icon(Icons.rocket_launch, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 14),
                    const Text('EduGalaxy', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const Text('Aprender é uma aventura!', style: TextStyle(color: Color(0xFF89B4FA), fontSize: 13, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 32),
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
                      gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)]),
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
                const SizedBox(height: 20),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      const _ProfessorSection(),
                      _StudentSection(),
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

// ── Seção professor: login / cadastro ────────────────────────────────────────
class _ProfessorSection extends StatefulWidget {
  const _ProfessorSection();

  @override
  State<_ProfessorSection> createState() => _ProfessorSectionState();
}

class _ProfessorSectionState extends State<_ProfessorSection> {
  int _mode = 0;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // Login / Cadastro toggle
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () { setState(() => _mode = 0); auth.clearError(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(
                        color: _mode == 0 ? const Color(0xFF7C3AED) : Colors.transparent, width: 2,
                      )),
                    ),
                    child: Text('Entrar', textAlign: TextAlign.center, style: TextStyle(
                      color: _mode == 0 ? Colors.white : const Color(0xFF89B4FA),
                      fontWeight: _mode == 0 ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () { setState(() => _mode = 1); auth.clearError(); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(
                        color: _mode == 1 ? const Color(0xFF7C3AED) : Colors.transparent, width: 2,
                      )),
                    ),
                    child: Text('Cadastrar', textAlign: TextAlign.center, style: TextStyle(
                      color: _mode == 1 ? Colors.white : const Color(0xFF89B4FA),
                      fontWeight: _mode == 1 ? FontWeight.bold : FontWeight.normal,
                    )),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Campos
          if (_mode == 1) ...[
            _GlassField(controller: _nameCtrl, label: 'Nome completo', icon: Icons.person_outline),
            const SizedBox(height: 14),
          ],
          _GlassField(controller: _emailCtrl, label: 'E-mail', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 14),
          _GlassField(
            controller: _passwordCtrl,
            label: 'Senha',
            icon: Icons.lock_outline,
            obscure: _obscure,
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF89B4FA)),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          if (_mode == 1) ...[
            const SizedBox(height: 14),
            _GlassField(
              controller: _confirmCtrl,
              label: 'Confirmar senha',
              icon: Icons.lock_outline,
              obscure: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: const Color(0xFF89B4FA)),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ],

          // Erro
          if (auth.errorMessage != null) ...[
            const SizedBox(height: 12),
            _ErrorBox(message: auth.errorMessage!),
          ],

          // Esqueci senha (apenas no login)
          if (_mode == 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showForgotPassword(context),
                child: const Text('Esqueci a senha', style: TextStyle(color: Color(0xFF89B4FA), fontSize: 12)),
              ),
            ),
          ] else const SizedBox(height: 16),

          // Botão principal
          _GradientButton(
            label: _mode == 0 ? 'Entrar' : 'Criar conta',
            isLoading: auth.isLoading,
            onTap: () async {
              if (_mode == 0) {
                final ok = await auth.loginProfessor(_emailCtrl.text, _passwordCtrl.text);
                if (ok && context.mounted) context.go(AppRoutes.professorDashboard);
              } else {
                if (_passwordCtrl.text != _confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('As senhas não coincidem.'), backgroundColor: Color(0xFFEC4899)),
                  );
                  return;
                }
                final ok = await auth.registerProfessor(_nameCtrl.text, _emailCtrl.text, _passwordCtrl.text);
                if (ok && context.mounted) context.go(AppRoutes.professorDashboard);
              }
            },
          ),

          const SizedBox(height: 18),

          // Divisor
          Row(children: [
            const Expanded(child: Divider(color: Color(0xFF2E3256))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('ou', style: TextStyle(color: Color(0xFF89B4FA), fontSize: 12)),
            ),
            const Expanded(child: Divider(color: Color(0xFF2E3256))),
          ]),

          const SizedBox(height: 18),

          // Botão Google
          _GoogleButton(
            isLoading: auth.isLoading,
            onTap: () async {
              final ok = await auth.loginWithGoogle();
              if (ok && context.mounted) context.go(AppRoutes.professorDashboard);
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController(text: _emailCtrl.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E3C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Redefinir senha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Digite seu e-mail e enviaremos um link para redefinir sua senha.',
              style: TextStyle(color: Color(0xFF89B4FA), fontSize: 13),
            ),
            const SizedBox(height: 14),
            _GlassField(controller: ctrl, label: 'E-mail', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Color(0xFF89B4FA)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
            onPressed: () async {
              final auth = context.read<AuthController>();
              final ok = await auth.sendPasswordReset(ctrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'E-mail de redefinição enviado!' : auth.errorMessage ?? 'Erro ao enviar.'),
                  backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEC4899),
                ));
              }
            },
            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Seção aluno ──────────────────────────────────────────────────────────────
class _StudentSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1E3C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🚀', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            const Text('Pronto para a missão?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
    );
  }
}

// ── Widgets reutilizáveis ────────────────────────────────────────────────────

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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.3))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2)),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const _GradientButton({required this.label, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Google em SVG inline via CustomPaint
              SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GoogleLogoPainter())),
              const SizedBox(width: 12),
              const Text('Continuar com Google', style: TextStyle(color: Color(0xFF3C4043), fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// Logo do Google desenhado manualmente (sem imagem/asset externo)
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    // Fundo branco
    paint.color = Colors.white;
    canvas.drawCircle(c, r, paint);

    // Quadrantes coloridos simplificados como arcos
    const colors = [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)];
    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.75),
        -3.14 / 2 + i * 3.14 / 2,
        3.14 / 2,
        true,
        paint,
      );
    }
    // Buraco central
    paint.color = Colors.white;
    canvas.drawCircle(c, r * 0.38, paint);

    // Barra horizontal (G)
    paint.color = const Color(0xFF4285F4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(c.dx, c.dy - r * 0.13, r * 0.78, r * 0.26), const Radius.circular(2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFEC4899), fontSize: 13))),
        ],
      ),
    );
  }
}

// ── Campo de estrelas decorativo ─────────────────────────────────────────────
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _StarPainter());
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final positions = [
      Offset(size.width * 0.1, size.height * 0.05), Offset(size.width * 0.85, size.height * 0.08),
      Offset(size.width * 0.45, size.height * 0.03), Offset(size.width * 0.7, size.height * 0.15),
      Offset(size.width * 0.2, size.height * 0.2),  Offset(size.width * 0.92, size.height * 0.3),
      Offset(size.width * 0.05, size.height * 0.4),  Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.35, size.height * 0.55), Offset(size.width * 0.88, size.height * 0.6),
      Offset(size.width * 0.15, size.height * 0.7),  Offset(size.width * 0.75, size.height * 0.8),
    ];
    for (int i = 0; i < positions.length; i++) {
      paint.color = Colors.white.withOpacity(i % 3 == 0 ? 0.9 : 0.4);
      canvas.drawCircle(positions[i], i % 4 == 0 ? 2.5 : 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
