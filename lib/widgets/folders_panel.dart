import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../src/rust/api/vault.dart' as rust;

class FoldersPanel extends StatelessWidget {
  final BigInt? selectedFolder;
  final ValueChanged<BigInt?> onSelect;
  final ValueChanged<String> onSearch;
  final List<rust.FolderDto> folders;
  final VoidCallback onAddFolder;
  final VoidCallback onDeleteFolder;

  const FoldersPanel({
    super.key,
    required this.selectedFolder,
    required this.onSelect,
    required this.onSearch,
    required this.folders,
    required this.onAddFolder,
    required this.onDeleteFolder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 322,
      padding: const EdgeInsets.fromLTRB(28, 24, 40, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          Container(
            width: 230,
            height: 32,
            decoration: BoxDecoration(
              color: ArgusColors.background,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(Icons.search, color: ArgusColors.grey, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: onSearch,
                    style: const TextStyle(
                      color: ArgusColors.green,
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'search',
                      hintStyle:
                          TextStyle(color: ArgusColors.grey, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _item('// All records', null),
          _item('// Without a folder', BigInt.from(-1)),

          const SizedBox(height: 16),
          const Text(
            '// List of folders',
            style: TextStyle(color: ArgusColors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),

          // Список папок
          if (folders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '// (empty)',
                style: TextStyle(color: ArgusColors.grey, fontSize: 12),
              ),
            )
          else
            ...folders.map((f) => _folderItem(f)),

          const SizedBox(height: 16),
          InkWell(
            onTap: onAddFolder,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '// Add a folder',
                style: TextStyle(
                  color: ArgusColors.green,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(String label, BigInt? key) {
    final isSelected = selectedFolder == key;
    return InkWell(
      onTap: () => onSelect(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? ArgusColors.white : ArgusColors.green,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _folderItem(rust.FolderDto f) {
    final isSelected = selectedFolder == f.id;
    return InkWell(
      onTap: () => onSelect(f.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '*** ${f.name}',
                style: TextStyle(
                  color:
                      isSelected ? ArgusColors.white : ArgusColors.green,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
            ),
            InkWell(
              onTap: onDeleteFolder,
              child: Icon(
                Icons.close,
                size: 14,
                color: isSelected
                    ? ArgusColors.red
                    : ArgusColors.red.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}