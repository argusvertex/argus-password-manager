import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../src/rust/api/vault.dart' as rust;
import 'generator_screen.dart';

class EntryFormScreen extends StatefulWidget {
  final rust.EntryDto? entry;  // null → создать, иначе → редактировать

  const EntryFormScreen({super.key, this.entry});

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  late final TextEditingController _serviceController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _noteController;

  bool _showPassword = false;
  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _serviceController = TextEditingController(text: e?.service ?? '');
    _usernameController = TextEditingController(text: e?.username ?? '');
    _passwordController = TextEditingController(text: e?.password ?? '');
    _noteController = TextEditingController(text: e?.note ?? '');
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int _strengthScore(String p) {
    if (p.isEmpty) return 0;
    final len = p.length;
    final variety = [
      p.contains(RegExp(r'[a-z]')),
      p.contains(RegExp(r'[A-Z]')),
      p.contains(RegExp(r'[0-9]')),
      p.contains(RegExp(r'[^a-zA-Z0-9]')),
    ].where((x) => x).length;
    if (len >= 12 && variety >= 3) return 12;
    if (len >= 8 && variety >= 2) return 8;
    return 4;
  }

  String _strengthLabel(int s) {
    if (s >= 12) return 'Strong';
    if (s >= 8) return 'Medium';
    if (s > 0) return 'Weak';
    return 'Empty';
  }

  Future<void> _onSave() async {
    final service = _serviceController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final note = _noteController.text.trim();

    if (service.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Заполните сервис, логин и пароль');
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      if (_isEdit) {
        await rust.updateEntry(
          id: widget.entry!.id,
          service: service,
          username: username,
          password: password,
          note: note,
        );
      } else {
        await rust.addEntry(
          service: service,
          username: username,
          password: password,
          note: note,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _strengthScore(_passwordController.text);

    return Dialog(
      backgroundColor: ArgusColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ArgusColors.border),
      ),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _isEdit ? 'EDIT ENTRY' : 'NEW ENTRY',
                  style: const TextStyle(
                    color: ArgusColors.white,
                    fontSize: 18,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '<<CANCEL>>',
                    style: TextStyle(
                      color: ArgusColors.green,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: ArgusColors.green),
            const SizedBox(height: 20),

            _inlineField(
              icon: Icons.language,
              label: 'SERVICE',
              controller: _serviceController,
              hint: 'google.com',
            ),
            _inlineField(
              icon: Icons.person_outline,
              label: 'LOGIN',
              controller: _usernameController,
              hint: 'user@example.com',
            ),
            _inlineField(
              icon: Icons.lock_outline,
              label: 'PASSWORD',
              controller: _passwordController,
              obscure: !_showPassword,
              suffix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (_) => const GeneratorScreen(),
                      );
                      if (result != null && result.isNotEmpty) {
                        _passwordController.text = result;
                      }
                    },
                    child: const Icon(
                      Icons.casino,
                      color: ArgusColors.green,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () =>
                        setState(() => _showPassword = !_showPassword),
                    child: Icon(
                      _showPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: ArgusColors.green,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Text(
              'NOTE',
              style: TextStyle(
                color: ArgusColors.green,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: ArgusColors.background,
                border: Border.all(color: ArgusColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _noteController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(color: ArgusColors.grey, fontSize: 13),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 20),
            _strengthBar(score),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                '⚠ $_error',
                style: const TextStyle(color: ArgusColors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 20),
            Center(
              child: _saving
                  ? const CircularProgressIndicator(color: ArgusColors.green)
                  : TextButton(
                      onPressed: _onSave,
                      style: TextButton.styleFrom(
                        backgroundColor: ArgusColors.background,
                        foregroundColor: ArgusColors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'SAVE',
                        style: TextStyle(fontSize: 14, letterSpacing: 3),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: ArgusColors.green, size: 16),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(
                  color: ArgusColors.green,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: obscure,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: ArgusColors.grey,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: ArgusColors.grey.withOpacity(0.4),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: suffix,
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: ArgusColors.border),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _strengthBar(int score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(12, (i) {
            final filled = i < score;
            return Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(right: 2),
              color: filled ? ArgusColors.green : ArgusColors.red,
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '// Password Strength: ${_strengthLabel(score)}',
          style: const TextStyle(color: ArgusColors.grey, fontSize: 12),
        ),
      ],
    );
  }
}