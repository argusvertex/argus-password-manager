import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../src/rust/api/vault.dart' as rust;

class EntryDetails extends StatefulWidget {
  final rust.EntryDto? entry;
  final VoidCallback onEdit;

  const EntryDetails({
    super.key,
    required this.entry,
    required this.onEdit,
  });

  @override
  State<EntryDetails> createState() => _EntryDetailsState();
}

class _EntryDetailsState extends State<EntryDetails> {
  bool _showPassword = false;

  int _strengthScore(String p) {
    if (p.isEmpty) return 0;
    final len = p.length;
    final variety = [
      p.contains(RegExp(r'[a-z]')),
      p.contains(RegExp(r'[A-Z]')),
      p.contains(RegExp(r'[0-9]')),
      p.contains(RegExp(r'[^a-zA-Z0-9]')),
    ].where((x) => x).length;
    if (len >= 12 && variety >= 3) return 16;
    if (len >= 8 && variety >= 2) return 10;
    return 6;
  }

  String _strengthLabel(int s) {
    if (s >= 14) return 'Strong';
    if (s >= 8) return 'Medium';
    if (s > 0) return 'Weak';
    return 'Empty';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/bg_panel_details.png'),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 40, 22),  // ← правый 30
      child: widget.entry == null
          ? const Center(
              child: Text(
                '// Select an entry',
                style: TextStyle(color: ArgusColors.grey, fontSize: 14),
              ),
            )
          : _buildContent(widget.entry!),
    );
  }

  Widget _buildContent(rust.EntryDto e) {
    final score = _strengthScore(e.password);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ArgusColors.green),
                ),
                alignment: Alignment.center,
                child: Text(
                  e.service.isNotEmpty ? e.service[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: ArgusColors.green, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.service,
                  style: const TextStyle(
                    color: ArgusColors.green,
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                ),
              ),
              TextButton(
                onPressed: widget.onEdit,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '<<EDIT>>',
                  style: TextStyle(color: ArgusColors.green, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: ArgusColors.border),
          const SizedBox(height: 16),

          _row('LINK', e.service, copyable: false),
          const SizedBox(height: 12),
          _row('LOGIN', e.username),
          const SizedBox(height: 12),
          _passwordRow(e.password),
          const SizedBox(height: 20),

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
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 100),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: ArgusColors.green),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              e.note.isEmpty ? '—' : e.note,
              style: const TextStyle(
                  color: ArgusColors.green, fontSize: 13),
            ),
          ),
          const SizedBox(height: 20),

          _buildStrengthBar(score),
        ],
      ),
    );
  }

  /// Индикатор — 8 X-блоков в 2 ряда. Заполняется колонками.
  Widget _buildStrengthBar(int score) {
    const int cols = 8;
    const int rows = 2;
    const pattern = [
      [1, 0, 1],
      [0, 1, 0],
      [1, 0, 1],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: List.generate(rows, (row) {
            return Row(
              children: List.generate(cols, (col) {
                final idx = col * rows + row;   // ← КОЛОНКАМИ
                final filled = idx < score;
                final color = filled ? ArgusColors.green : ArgusColors.red;

                return Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (r) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(3, (c) {
                          final on = pattern[r][c] == 1;
                          return Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.all(0.5),
                            color: on ? color : Colors.transparent,
                          );
                        }),
                      );
                    }),
                  ),
                );
              }),
            );
          }),
        ),
        const SizedBox(height: 10),
        Text(
          '// Password Strength: ${_strengthLabel(score)}',
          style: const TextStyle(
            color: ArgusColors.green,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
  
  Widget _row(String label, String value, {bool copyable = true}) {
    return Row(
      children: [
        const Icon(Icons.lock_outline, color: ArgusColors.green, size: 14),
        const SizedBox(width: 6),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: ArgusColors.green,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ArgusColors.grey, fontSize: 13),
          ),
        ),
        if (copyable) ...[
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Скопировано')),
              );
            },
            child: const Icon(Icons.copy,
                color: ArgusColors.green, size: 14),
          ),
        ],
      ],
    );
  }

  Widget _passwordRow(String password) {
    return Row(
      children: [
        const Icon(Icons.lock_outline, color: ArgusColors.green, size: 14),
        const SizedBox(width: 6),
        const SizedBox(
          width: 80,
          child: Text(
            'PASSWORD',
            style: TextStyle(
              color: ArgusColors.green,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Text(
            _showPassword ? password : '★' * password.length,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: ArgusColors.grey, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => setState(() => _showPassword = !_showPassword),
          child: Icon(
            _showPassword ? Icons.visibility_off : Icons.visibility,
            color: ArgusColors.green,
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: password));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Пароль скопирован')),
            );
          },
          child: const Icon(Icons.copy,
              color: ArgusColors.green, size: 14),
        ),
      ],
    );
  }
}