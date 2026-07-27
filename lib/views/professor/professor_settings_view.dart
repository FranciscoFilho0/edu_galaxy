import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_theme.dart';

/// Configurações do professor: modo noturno (tela mais escura, letras com
/// mais contraste) e o botão de sair da conta.
class ProfessorSettingsView extends StatelessWidget {
  const ProfessorSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final auth = context.read<AuthController>();

    return Scaffold(
      backgroundColor: AppTheme.profBackground,
      appBar: AppBar(title: const Text('Configurações')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionLabel('Aparência'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.profSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SwitchListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                secondary: Icon(Icons.dark_mode_rounded, color: AppTheme.profPrimary),
                title: Text('Modo noturno', style: TextStyle(color: AppTheme.profOnSurface, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Deixa a tela mais escura, com as letras em maior contraste',
                  style: TextStyle(color: AppTheme.profOnSurface.withOpacity(0.65), fontSize: 12.5),
                ),
                value: settings.professorDarkMode,
                activeColor: AppTheme.profPrimary,
                onChanged: settings.setProfessorDarkMode,
              ),
            ),
            const SizedBox(height: 32),
            _SectionLabel('Conta'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.profSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                leading: Icon(Icons.logout, color: AppTheme.profError),
                title: Text('Sair da conta', style: TextStyle(color: AppTheme.profOnSurface, fontWeight: FontWeight.w600)),
                onTap: () async {
                  await auth.logout();
                  if (context.mounted) context.go(AppRoutes.login);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(color: AppTheme.profPrimary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
    );
  }
}
