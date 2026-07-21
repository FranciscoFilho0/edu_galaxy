import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/router/app_routes.dart';
import 'widgets/auth_shared_widgets.dart';

/// Tela de login/cadastro exclusiva do professor.
///
/// Antes, professor e aluno ficavam juntos em `LoginView` (com abas).
/// Essa página contém exatamente o que era a aba "Professor", só que
/// como uma tela própria, acessada a partir da tela de seleção de perfil.
class ProfessorLoginView extends StatefulWidget {
  const ProfessorLoginView({super.key});

  @override
  State<ProfessorLoginView> createState() => _ProfessorLoginViewState();
}

class _ProfessorLoginViewState extends State<ProfessorLoginView> {
  int _mode = 0; // 0 = entrar, 1 = cadastrar

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

    return Scaffold(
      body: Stack(
        children: [
          const AuthBackground(),
          SafeArea(
            child: Column(
              children: [
                _TopBar(onBack: () => context.go(AppRoutes.login)),
                const SizedBox(height: 12),
                const AuthLogo(subtitle: 'Portal do Professor'),
                const SizedBox(height: 28),
                Expanded(
                  child: SingleChildScrollView(
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
                          GlassField(controller: _nameCtrl, label: 'Nome completo', icon: Icons.person_outline),
                          const SizedBox(height: 14),
                        ],
                        GlassField(controller: _emailCtrl, label: 'E-mail', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 14),
                        GlassField(
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
                          GlassField(
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
                          ErrorBox(message: auth.errorMessage!),
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
                        GradientButton(
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
                        GoogleButton(
                          isLoading: auth.isLoading,
                          onTap: () async {
                            final ok = await auth.loginWithGoogle();
                            if (ok && context.mounted) context.go(AppRoutes.professorDashboard);
                          },
                        ),

                        const SizedBox(height: 20),
                      ],
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
            GlassField(controller: ctrl, label: 'E-mail', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
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

// Barra superior com botão de voltar para a tela de seleção de perfil.
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Voltar',
          ),
        ],
      ),
    );
  }
}
