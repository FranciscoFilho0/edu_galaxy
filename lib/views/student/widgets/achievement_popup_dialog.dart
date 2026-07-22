import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/achievement_model.dart';

/// Pop-up de "conquista desbloqueada", exibido sobre a tela de resultado
/// quando o aluno bate uma meta do `AchievementsEngine` pela primeira vez.
///
/// Este widget é só a parte visual: quem decide *quando* chamar [show] é a
/// `GameResultScreen`, que compara as conquistas antes/depois da partida.
class AchievementPopupDialog extends StatefulWidget {
  final AchievementModel achievement;

  const AchievementPopupDialog({super.key, required this.achievement});

  /// Mostra o pop-up centralizado sobre a tela atual, com animação de
  /// entrada em "salto" (scale + fade). O Future resolve quando o aluno
  /// fecha o pop-up (toque no botão ou fora dele), o que permite exibir
  /// vários pop-ups em fila, um de cada vez.
  static Future<void> show(BuildContext context, AchievementModel achievement) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Conquista desbloqueada',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, _, __) => AchievementPopupDialog(achievement: achievement),
      transitionBuilder: (context, animation, _, child) {
        final scale = Tween<double>(begin: 0.4, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.elasticOut),
        );
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: scale.value, child: child),
        );
      },
    );
  }

  @override
  State<AchievementPopupDialog> createState() => _AchievementPopupDialogState();
}

class _AchievementPopupDialogState extends State<AchievementPopupDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    // Brilho pulsante contínuo atrás do emoji enquanto o pop-up estiver
    // aberto — dá vida ao card sem precisar de nenhum pacote externo.
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievement = widget.achievement;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.galaxyMid, AppTheme.galaxyDeep],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.galaxyStar.withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.galaxyStar.withOpacity(0.25),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🏆 CONQUISTA DESBLOQUEADA!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.galaxyStar,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 20),
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                final glow = 0.35 + (_glowController.value * 0.35);
                return Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.galaxyStar.withOpacity(glow),
                        AppTheme.galaxyPurple.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Text(achievement.emoji, style: const TextStyle(fontSize: 52)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF89B4FA), fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.galaxyPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
