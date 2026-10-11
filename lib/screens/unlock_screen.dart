import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../src/rust/api/vault.dart' as rust;
import 'main_screen.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _passwordController = TextEditingController();

  bool _vaultExists = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkVault();
  }

  Future<void> _checkVault() async {
    try {
      final exists = await rust.vaultExists();
      setState(() {
        _vaultExists = exists;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
        _loading = false;
      });
    }
  }

    Future<void> _onSubmit() async {
    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() => _error = 'Минимум 8 символов');
      return;
    }

    setState(() => _error = null);

    try {
      if (_vaultExists) {
        await rust.unlockVault(password: password);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainScreen(),
          ),
        );
      } else {
        await rust.createVault(password: password);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainScreen(),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_columns.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Container(
              width: 460,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: ArgusColors.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ArgusColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ArgusColors.green,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ARGUS v0.0.1',
                          style: TextStyle(
                            color: ArgusColors.white,
                            fontSize: 22,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 28),

                        _buildPasswordField(),
                        const SizedBox(height: 20),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                _vaultExists
                                    ? '// Enter your password.\n'
                                      '// Keep the password\n'
                                      'secret from prying eyes.'
                                    : '// Create a new storage.\n'
                                      '// Enter your master password.\n'
                                      '// It cannot be recovered!',
                                style: const TextStyle(
                                  color: ArgusColors.green,
                                  fontSize: 14,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            _buildDecorBlocks(),
                          ],
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '⚠ $_error',
                            style: const TextStyle(
                              color: ArgusColors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        Container(height: 2, color: ArgusColors.green),
                        const SizedBox(height: 28),

                        Center(
                          child: TextButton(
                            onPressed: _onSubmit,
                            style: TextButton.styleFrom(
                              backgroundColor: ArgusColors.background,
                              foregroundColor: ArgusColors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              _vaultExists
                                  ? 'UNLOCK'
                                  : 'CREATE A NEW STORAGE',
                              style: const TextStyle(
                                fontSize: 14,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: ArgusColors.background,
        border: Border.all(color: ArgusColors.green, width: 1),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: _passwordController,
        obscureText: true,
        textAlignVertical: TextAlignVertical.center,
        cursorColor: ArgusColors.green,
        cursorHeight: 24,
        cursorWidth: 2,
        onSubmitted: (_) => _onSubmit(),
        style: const TextStyle(
          color: ArgusColors.green,
          fontSize: 32,
          letterSpacing: 6,
        ),
        decoration: const InputDecoration(
          hintText: 'password . . .',
          hintStyle: TextStyle(
            color: ArgusColors.grey,
            fontSize: 16,
            letterSpacing: 1,
          ),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildDecorBlocks() {
    const pattern = [
      [1, 0, 1],
      [0, 1, 0],
      [1, 0, 1],
    ];

    Widget oneBlock() {
      return Padding(
        padding: const EdgeInsets.all(2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (r) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (c) {
                final filled = pattern[r][c] == 1;
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.all(1),
                  color: filled ? ArgusColors.white : Colors.transparent,
                );
              }),
            );
          }),
        ),
      );
    }

    Widget oneRow() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (_) => oneBlock()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        oneRow(),
        oneRow(),
      ],
    );
  }
}