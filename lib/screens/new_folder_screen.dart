import 'package:flutter/material.dart';
import '../theme/colors.dart';

class NewFolderScreen extends StatefulWidget {
  const NewFolderScreen({super.key});

  @override
  State<NewFolderScreen> createState() => _NewFolderScreenState();
}

class _NewFolderScreenState extends State<NewFolderScreen> {
  final _nameController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Введите имя папки');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ArgusColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ArgusColors.border),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NEW FOLDER',
              style: TextStyle(
                color: ArgusColors.white,
                fontSize: 16,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: ArgusColors.green),
            const SizedBox(height: 20),

            Container(
              decoration: BoxDecoration(
                color: ArgusColors.background,
                border: Border.all(color: ArgusColors.green),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _nameController,
                autofocus: true,
                onSubmitted: (_) => _onSave(),
                style: const TextStyle(
                  color: ArgusColors.green,
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  hintText: 'folder name',
                  hintStyle: TextStyle(color: ArgusColors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                '⚠ $_error',
                style: const TextStyle(color: ArgusColors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _onSave,
                    child: const Text(
                      '<<SAVE>>',
                      style: TextStyle(
                        color: ArgusColors.green,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '<<CANCEL>>',
                      style: TextStyle(
                        color: ArgusColors.green,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}