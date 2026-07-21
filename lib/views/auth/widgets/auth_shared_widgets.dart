import 'package:flutter/material.dart';

// ── Widgets reutilizáveis das telas de autenticação ─────────────────────────
//
// Este arquivo reúne os widgets visuais que eram usados dentro do antigo
// login_view.dart (quando professor e aluno dividiam a mesma tela com abas).
// Agora que cada perfil tem sua própria página, esses widgets ficaram aqui
// para poderem ser reaproveitados por:
//   - login_view.dart              (tela de seleção "Professor ou Aluno")
//   - professor_login_view.dart    (login/cadastro do professor)
//   - student_login_view.dart      (entrada do aluno)
//
// Nada do visual foi alterado, só movido para um lugar comum.

class GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const GlassField({
    super.key,
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

class GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  const GradientButton({super.key, required this.label, required this.isLoading, required this.onTap});

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

class GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const GoogleButton({super.key, required this.isLoading, required this.onTap});

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

class ErrorBox extends StatelessWidget {
  final String message;
  const ErrorBox({super.key, required this.message});

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
class StarField extends StatelessWidget {
  const StarField({super.key});

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

// ── Fundo padrão (gradiente + estrelas) usado em todas as telas de auth ─────
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
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
        const Positioned.fill(child: StarField()),
      ],
    );
  }
}

// ── Logo "EduGalaxy" padrão usado no topo das telas de auth ─────────────────
class AuthLogo extends StatelessWidget {
  final String subtitle;
  const AuthLogo({super.key, this.subtitle = 'Aprender é uma aventura!'});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Text(subtitle, style: const TextStyle(color: Color(0xFF89B4FA), fontSize: 13, letterSpacing: 1)),
      ],
    );
  }
}
