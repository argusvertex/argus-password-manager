import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../src/rust/api/vault.dart' as rust;

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  int _length = 16;
  bool _useSymbols = true;
  String _password = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final pwd = await rust.generatePassword(
        length: _length,
        useSymbols: _useSymbols,
      );
      setState(() {
        _password = pwd;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
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
        width: 480,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'PASSWORD GENERATOR',
                  style: TextStyle(
                    color: ArgusColors.white,
                    fontSize: 16,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '<<BACK>>',
                    style: TextStyle(
                      color: ArgusColors.green,
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: ArgusColors.green),
            const SizedBox(height: 20),

            // Длина
            Row(
              children: [
                const Text(
                  'LENGTH',
                  style: TextStyle(
                    color: ArgusColors.green,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_length',
                  style: const TextStyle(
                    color: ArgusColors.green,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Slider(
              value: _length.toDouble(),
              min: 8,
              max: 64,
              divisions: 56,
              activeColor: ArgusColors.green,
              inactiveColor: ArgusColors.border,
              onChanged: (v) {
                setState(() => _length = v.toInt());
              },
              onChangeEnd: (_) => _generate(),
            ),

            // Чекбоксы
            _checkbox('A-Z', _useSymbols, (_) {}),  // заглушка
            _checkbox('a-z', true, (_) {}),          // всегда
            _checkbox('0-9', true, (_) {}),          // всегда
            _checkbox('!@#\$', _useSymbols, (v) {
              setState(() => _useSymbols = v ?? false);
              _generate();
            }),

            const SizedBox(height: 16),

            // Поле пароля
            Container(
              decoration: BoxDecoration(
                color: ArgusColors.background,
                border: Border.all(color: ArgusColors.green),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _loading ? '...' : _password,
                      style: const TextStyle(
                        color: ArgusColors.green,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _password));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Скопировано')),
                      );
                    },
                    child: const Icon(Icons.copy,
                        color: ArgusColors.green, size: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Кнопки
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _generate,
                    child: const Text(
                      '<<REFRESH>>',
                      style: TextStyle(
                        color: ArgusColors.green,
                        fontSize: 13,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _password),
                    child: const Text(
                      '<<USE>>',
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

  Widget _checkbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: ArgusColors.green,
            checkColor: ArgusColors.background,
            side: const BorderSide(color: ArgusColors.green),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '[X] $label',
          style: const TextStyle(
            color: ArgusColors.green,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}