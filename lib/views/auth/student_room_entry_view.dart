import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../core/router/app_routes.dart';

class StudentRoomEntryView extends StatefulWidget {
  const StudentRoomEntryView({super.key});

  @override
  State<StudentRoomEntryView> createState() => _StudentRoomEntryViewState();
}

class _StudentRoomEntryViewState extends State<StudentRoomEntryView> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

 @override
Widget build(BuildContext context) {
  final auth = context.watch<AuthController>();

  return Scaffold(
    // Adicione esta linha para evitar que o teclado tente redimensionar o Scaffold
    resizeToAvoidBottomInset: true, 
    body: Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0E27), Color(0xFF1A0A3C), Color(0xFF0A0E27)],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView( // <-- Adicionado para permitir scroll
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => context.go(AppRoutes.login),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const SizedBox(height: 40), // Substituído o Expanded superior
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [Color(0xFF9B59B6), Color(0xFF1A1E3C)],
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.6), blurRadius: 30, spreadRadius: 8),
                          ],
                        ),
                        child: const Center(child: Text('🪐', style: TextStyle(fontSize: 56))),
                      ),
                      const SizedBox(height: 24),
                      const Text('Código da Turma', style: TextStyle(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold,
                      )),
                      const SizedBox(height: 8),
                      const Text(
                        'Digite o código que o seu professor forneceu',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF89B4FA), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _codeCtrl,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  ],
                  style: const TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    hintText: 'XXXXXX',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), letterSpacing: 8, fontSize: 28),
                    filled: true,
                    fillColor: const Color(0xFF1A1E3C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                    ),
                  ),
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(auth.errorMessage!, style: const TextStyle(color: Color(0xFFEC4899), fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : () async {
                      final ok = await auth.loginWithRoomCode(_codeCtrl.text.trim().toUpperCase());
                      if (ok && context.mounted) {
                        context.go(AppRoutes.studentProfileSetup);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Entrar na Galáxia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.rocket_launch),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24), // Substituído o Expanded inferior
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}
