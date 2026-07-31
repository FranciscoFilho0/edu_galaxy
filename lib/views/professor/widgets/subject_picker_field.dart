import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/subjects.dart';

/// Botão de seleção de matéria usado nos formulários de pergunta/palavra do
/// professor. Em vez de digitar a matéria livremente, o professor toca no
/// campo e escolhe entre as matérias cadastradas (currículo do Fundamental 1),
/// garantindo que os resultados fiquem sempre agrupados de forma consistente.
class SubjectPickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const SubjectPickerField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.profSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Selecione a matéria',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: AppSubjects.all.length,
                  itemBuilder: (context, i) {
                    final subject = AppSubjects.all[i];
                    final isSelected = subject == value;
                    return ListTile(
                      leading: Icon(
                        Icons.subject,
                        color: isSelected ? AppTheme.profPrimary : Colors.grey.shade500,
                      ),
                      title: Text(
                        subject,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          color: isSelected ? AppTheme.profPrimary : null,
                        ),
                      ),
                      trailing: isSelected ? Icon(Icons.check, color: AppTheme.profPrimary) : null,
                      onTap: () => Navigator.pop(ctx, subject),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Matéria',
          prefixIcon: Icon(Icons.subject),
          suffixIcon: Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value.isEmpty ? 'Selecione a matéria' : value,
          style: TextStyle(color: value.isEmpty ? Colors.grey.shade500 : null),
        ),
      ),
    );
  }
}
