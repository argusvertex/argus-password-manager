import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../src/rust/api/vault.dart' as rust;

class EntriesList extends StatelessWidget {
  final List<rust.EntryDto> entries;
  final BigInt? selectedId;
  final ValueChanged<BigInt> onSelect;

  const EntriesList({
    super.key,
    required this.entries,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/bg_panel_entries.png'),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KEYS',
            style: TextStyle(
              color: ArgusColors.green,
              fontSize: 16,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'USER PASSWORDS',
            style: TextStyle(
              color: ArgusColors.grey,
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text(
                      '// No entries yet.\n// Press ADD to create one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ArgusColors.green,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final selected = e.id == selectedId;

                      return InkWell(
                        onTap: () => onSelect(e.id),
                        child: Container(
                          margin: const EdgeInsets.only(
                            left: 8,
                            right: 26,
                            bottom: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: selected
                                    ? ArgusColors.green
                                    : ArgusColors.border,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: ArgusColors.green),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  e.service.isNotEmpty
                                      ? e.service[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: ArgusColors.green,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  e.service,
                                  style: const TextStyle(
                                    color: ArgusColors.green,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}