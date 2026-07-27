import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_theme.dart';

/// Configurações do aluno: volume da música de fundo, volume da voz que lê
/// as palavras/perguntas em voz alta, e o botão de sair da conta.
class StudentSettingsView extends StatelessWidget {
  const StudentSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final auth = context.read<AuthController>();

    return Scaffold(
      backgroundColor: AppTheme.galaxyDeep,
      appBar: AppBar(title: const Text('Configurações ⚙️')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionLabel('Som'),
            const SizedBox(height: 8),
            _VolumeCard(
              icon: Icons.music_note_rounded,
              title: 'Música de fundo',
              subtitle: 'Volume da música das telas e dos jogos',
              value: settings.musicVolume,
              onChanged: settings.setMusicVolume,
            ),
            const SizedBox(height: 14),
            _VolumeCard(
              icon: Icons.record_voice_over_rounded,
              title: 'Voz (texto falado)',
              subtitle: 'Volume de quando o app lê palavras e perguntas',
              value: settings.ttsVolume,
              onChanged: settings.setTtsVolume,
            ),
            const SizedBox(height: 32),
            _SectionLabel('Conta'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.galaxyMid,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.galaxyPurple.withOpacity(0.3)),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.logout, color: AppTheme.galaxyPink),
                title: const Text('Sair da conta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
      style: const TextStyle(color: AppTheme.galaxyCyan, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
    );
  }
}

class _VolumeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
      decoration: BoxDecoration(
        color: AppTheme.galaxyMid,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.galaxyPurple.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.galaxyViolet),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF89B4FA), fontSize: 11.5)),
                  ],
                ),
              ),
              Text('${(value * 100).round()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.volume_mute_rounded, color: Color(0xFF89B4FA), size: 18),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.galaxyPurple,
                    inactiveTrackColor: AppTheme.galaxyPurple.withOpacity(0.2),
                    thumbColor: AppTheme.galaxyViolet,
                    overlayColor: AppTheme.galaxyViolet.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 1,
                    onChanged: onChanged,
                  ),
                ),
              ),
              const Icon(Icons.volume_up_rounded, color: Color(0xFF89B4FA), size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
