import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../src/rust/api/vault.dart' as rust;

class ActionsPanel extends StatelessWidget {
  final rust.EntryDto? entry;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const ActionsPanel({
    super.key,
    required this.entry,
    required this.onMove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = entry != null;

    return Container(
      height: 86,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/bg_panel_actions.png'),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment(0, -0.2),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _btn('COPY', enabled ? () => _copy(context) : null),
          _btn('MOVE', enabled ? onMove : null),
          _btn('DELETE', enabled ? onDelete : null),
        ],
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: entry!.password));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Пароль скопирован')),
    );
  }

  Widget _btn(String label, VoidCallback? onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        '<<$label>>',
        style: TextStyle(
          color: onTap == null
              ? ArgusColors.grey.withOpacity(0.4)
              : ArgusColors.green,
          fontSize: 14,
          letterSpacing: 2,
        ),
      ),
    );
  }
}