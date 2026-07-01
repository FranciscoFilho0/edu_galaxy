import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/student_model.dart';
import '../../core/router/app_routes.dart';

class StudentProfileSetupView extends StatefulWidget {
  final String roomCode;
  const StudentProfileSetupView({super.key, required this.roomCode});

  @override
  State<StudentProfileSetupView> createState() => _StudentProfileSetupViewState();
}

class _StudentProfileSetupViewState extends State<StudentProfileSetupView> {
  final _nameCtrl = TextEditingController();
  int _selectedAvatar = 0;

  static const List<Map<String, String>> _avatars = [
    {'emoji': '🧑‍🚀', 'name': 'Astronauta'},
    {'emoji': '👾', 'name': 'Alienígena'},
    {'emoji': '🤖', 'name': 'Robô'},
    {'emoji': '🧙', 'name': 'Mago'},
    {'emoji': '🦸', 'name': 'Herói'},
    {'emoji': '🐉', 'name': 'Dragão'},
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E27), Color(0xFF0A1A3C)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                const Text('Crie seu Perfil!', style: TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
                )),
                const SizedBox(height: 4),
                Text('Turma: ${widget.roomCode}', style: const TextStyle(
                  color: Color(0xFF7C3AED), fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 2,
                )),
                const SizedBox(height: 32),
                // Avatar grid
                const Text('Escolha seu avatar:', style: TextStyle(
                  color: Color(0xFF89B4FA), fontSize: 16, fontWeight: FontWeight.w600,
                )),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  ),
                  itemCount: _avatars.length,
                  itemBuilder: (context, i) {
                    final selected = _selectedAvatar == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: selected ? const Color(0xFF7C3AED).withOpacity(0.3) : const Color(0xFF1A1E3C),
                          border: Border.all(
                            color: selected ? const Color(0xFF7C3AED) : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: selected ? [
                            BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 12, spreadRadius: 2),
                          ] : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_avatars[i]['emoji']!, style: const TextStyle(fontSize: 40)),
                            const SizedBox(height: 4),
                            Text(_avatars[i]['name']!, style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF89B4FA),
                              fontSize: 11, fontWeight: FontWeight.w500,
                            )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                // Name field
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Seu nome de piloto:', style: TextStyle(
                    color: Color(0xFF89B4FA), fontSize: 16, fontWeight: FontWeight.w600,
                  )),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Ex: João Astronauta',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    prefixIcon: Text(
                      _avatars[_selectedAvatar]['emoji']!,
                      style: const TextStyle(fontSize: 22),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                    filled: true,
                    fillColor: const Color(0xFF1A1E3C),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Digite seu nome de piloto!'), backgroundColor: Color(0xFFEC4899)),
                        );
                        return;
                      }
                      final student = StudentModel(
                        id: 'stu_${DateTime.now().millisecondsSinceEpoch}',
                        name: _nameCtrl.text.trim(),
                        roomCode: widget.roomCode,
                        avatarIndex: '$_selectedAvatar',
                      );
                      auth.setStudentProfile(student);
                      context.go(AppRoutes.studentHome);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Iniciar Missão!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
