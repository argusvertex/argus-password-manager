import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../src/rust/api/vault.dart' as rust;

class MoveToFolderScreen extends StatelessWidget {
  final List<rust.FolderDto> folders;
  final BigInt? currentFolderId;

  const MoveToFolderScreen({
    super.key,
    required this.folders,
    this.currentFolderId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ArgusColors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: ArgusColors.border),
      ),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'MOVE TO FOLDER',
                  style: TextStyle(
                    color: ArgusColors.white,
                    fontSize: 16,
                    letterSpacing: 3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  // ← ОТМЕНА возвращает маркер
                  onPressed: () => Navigator.pop(context, '__cancel__'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
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
            const SizedBox(height: 8),
            Container(height: 1, color: ArgusColors.green),
            const SizedBox(height: 16),

            _item(
              context,
              label: '// Without a folder',
              folderId: null,
              isCurrent: currentFolderId == null,
            ),

            if (folders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '// No folders yet',
                  style: TextStyle(color: ArgusColors.grey, fontSize: 13),
                ),
              )
            else
              ...folders.map((f) => _item(
                    context,
                    label: '*** ${f.name}',
                    folderId: f.id,
                    isCurrent: currentFolderId == f.id,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required String label,
    required BigInt? folderId,
    required bool isCurrent,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, folderId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isCurrent ? ArgusColors.white : ArgusColors.green,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (isCurrent)
              const Text(
                '// current',
                style: TextStyle(color: ArgusColors.grey, fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }
}