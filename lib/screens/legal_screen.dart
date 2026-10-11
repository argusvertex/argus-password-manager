import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../theme/colors.dart';

class LegalScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const LegalScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  String _text = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await rootBundle.loadString(widget.assetPath);
    if (!mounted) return;
    setState(() {
      _text = t;
      _loading = false;
    });
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
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.title.toUpperCase(),
                  style: const TextStyle(
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
                    '<<CLOSE>>',
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
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: ArgusColors.green),
                    )
                  : SingleChildScrollView(
                      child: SelectableText(
                        _text,
                        style: const TextStyle(
                          color: ArgusColors.green,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
