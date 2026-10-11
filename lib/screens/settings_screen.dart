import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../src/rust/api/vault.dart' as rust;
import 'package:file_picker/file_picker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_settings.png',
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 300, child: _buildMenu()),
                const SizedBox(width: 40),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== МЕНЮ ====================

  Widget _buildMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SECURITY',
          style: TextStyle(
            color: ArgusColors.white,
            fontSize: 16,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        _menuItem('CHANGING THE MASTER PASSWORD', 'change_master'),
        _menuItem('DURESS >> DELETE / INSTALL', 'duress'),

        const SizedBox(height: 24),
        const Text(
          'DATA',
          style: TextStyle(
            color: ArgusColors.white,
            fontSize: 16,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        _menuItem('EXPORT (JSON / CSV)', 'export'),
        _menuItem('IMPORT (JSON)', 'import'),

        const SizedBox(height: 24),
        const Text(
          'LEGAL',
          style: TextStyle(
            color: ArgusColors.white,
            fontSize: 16,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        _menuItem('TERMS OF SERVICE', 'legal_terms'),
        _menuItem('PRIVACY POLICY', 'legal_privacy'),
        _menuItem('EULA', 'legal_eula'),

        const SizedBox(height: 32),
        _menuItem('BACK', 'back'),
      ],
    );
  }

  Widget _menuItem(String label, String key) {
    final isActive = _section == key;
    return InkWell(
      onTap: () => _onSelect(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? ArgusColors.white : ArgusColors.green,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // ==================== КОНТЕНТ ====================

  Widget _buildContent() {
    switch (_section) {
      case 'change_master':
        return _buildChangeMasterForm();
      case 'duress':
        return _buildDuressForm();
      case 'export':
        return _buildExportForm();
      case 'import':
        return _buildImportForm();
      case 'legal_terms':
        return _buildLegalInfo(
          'Terms of Service',
          'assets/docs/terms.txt',
        );
      case 'legal_privacy':
        return _buildLegalInfo(
          'Privacy Policy',
          'assets/docs/privacy.txt',
        );
      case 'legal_eula':
        return _buildLegalInfo(
          'EULA',
          'assets/docs/eula.txt',
        );
      default:
        return const Center(
          child: Text(
            '// Select a section',
            style: TextStyle(color: ArgusColors.grey, fontSize: 14),
          ),
        );
    }
  }

  Widget _buildLegalInfo(String title, String path) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArgusColors.background.withOpacity(0.7),
        border: Border.all(color: ArgusColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: ArgusColors.white,
              fontSize: 16,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: ArgusColors.green),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<String>(
              future: DefaultAssetBundle.of(context).loadString(path),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Ошибка загрузки: ${snapshot.error}',
                    style: const TextStyle(
                      color: ArgusColors.red,
                      fontSize: 13,
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: ArgusColors.green,
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: SelectableText(
                    snapshot.data!,
                    style: const TextStyle(
                      color: ArgusColors.green,
                      fontSize: 13,
                      height: 1.6,
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

  // ==================== CHANGE MASTER ====================

  final _oldPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _newPwd2Ctrl = TextEditingController();

  Widget _buildChangeMasterForm() {
    return _buildForm(
      title: 'CHANGING THE MASTER PASSWORD',
      children: [
        _field('OLD PASSWORD', _oldPwdCtrl, obscure: true),
        const SizedBox(height: 12),
        _field('NEW PASSWORD', _newPwdCtrl, obscure: true),
        const SizedBox(height: 12),
        _field('REPEAT NEW', _newPwd2Ctrl, obscure: true),
        const SizedBox(height: 24),
        _actionButton('SAVE', _onChangeMaster),
      ],
    );
  }

  Future<void> _onChangeMaster() async {
    final oldP = _oldPwdCtrl.text;
    final newP = _newPwdCtrl.text;
    final newP2 = _newPwd2Ctrl.text;

    if (newP != newP2) {
      _showMsg('Пароли не совпадают');
      return;
    }
    if (newP.length < 8) {
      _showMsg('Минимум 8 символов');
      return;
    }

    try {
      await rust.changeMasterPassword(
        oldPassword: oldP,
        newPassword: newP,
      );
      _oldPwdCtrl.clear();
      _newPwdCtrl.clear();
      _newPwd2Ctrl.clear();
      _showMsg('Мастер-пароль изменён');
    } catch (e) {
      _showMsg(e.toString());
    }
  }

  // ==================== DURESS ====================

  final _duressPwdCtrl = TextEditingController();
  final _duressPwd2Ctrl = TextEditingController();

  Widget _buildDuressForm() {
    return FutureBuilder<bool>(
      future: Future.value(rust.hasDuressPassword()),
      builder: (context, snapshot) {
        final has = snapshot.data ?? false;

        return _buildForm(
          title: 'DURESS PASSWORD',
          children: [
            Text(
              has
                  ? '// Duress-пароль установлен.\n// Ввод этого пароля открывает пустое хранилище.'
                  : '// Duress-пароль не установлен.\n// Установите его для защиты.',
              style: const TextStyle(
                color: ArgusColors.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            if (has)
              _actionButton(
                'DELETE',
                _onRemoveDuress,
                color: ArgusColors.red,
              )
            else ...[
              _field('NEW DURESS PASSWORD', _duressPwdCtrl, obscure: true),
              const SizedBox(height: 12),
              _field('REPEAT', _duressPwd2Ctrl, obscure: true),
              const SizedBox(height: 24),
              _actionButton('INSTALL', _onInstallDuress),
            ],
          ],
        );
      },
    );
  }

  Future<void> _onInstallDuress() async {
    final p1 = _duressPwdCtrl.text;
    final p2 = _duressPwd2Ctrl.text;

    if (p1 != p2) {
      _showMsg('Пароли не совпадают');
      return;
    }
    if (p1.length < 8) {
      _showMsg('Минимум 8 символов');
      return;
    }

    try {
      await rust.setDuressPassword(password: p1);
      _duressPwdCtrl.clear();
      _duressPwd2Ctrl.clear();
      _showMsg('Duress-пароль установлен');
      setState(() {});
    } catch (e) {
      _showMsg(e.toString());
    }
  }

  Future<void> _onRemoveDuress() async {
    try {
      await rust.removeDuressPassword();
      _showMsg('Duress-пароль удалён');
      setState(() {});
    } catch (e) {
      _showMsg(e.toString());
    }
  }

  // ==================== EXPORT ====================

  Widget _buildExportForm() {
    return _buildForm(
      title: 'EXPORT',
      children: [
        const Text(
          '// Выберите формат и место сохранения.',
          style: TextStyle(
            color: ArgusColors.grey,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _actionButton('JSON', _onExportJson),
            const SizedBox(width: 16),
            _actionButton('CSV', _onExportCsv),
          ],
        ),
      ],
    );
  }

  Future<void> _onExportJson() async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Куда сохранить JSON?',
        fileName: 'passwords.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (path == null) return;
      await rust.exportToJson(path: path);
      _showMsg('Экспортировано: $path');
    } catch (e) {
      _showMsg(e.toString());
    }
  }

  Future<void> _onExportCsv() async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Куда сохранить CSV?',
        fileName: 'passwords.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (path == null) return;
      await rust.exportToCsv(path: path);
      _showMsg('Экспортировано: $path');
    } catch (e) {
      _showMsg(e.toString());
    }
  }

  // ==================== IMPORT ====================

  Widget _buildImportForm() {
    return _buildForm(
      title: 'IMPORT',
      children: [
        const Text(
          '// Выберите файл для импорта.\n'
          '// Поддерживаются: JSON (любой формат) и CSV.',
          style: TextStyle(
            color: ArgusColors.grey,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        _actionButton('CHOOSE FILE', _onImportFile),
      ],
    );
  }

  Future<void> _onImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Выберите файл для импорта',
        type: FileType.custom,
        allowedExtensions: ['json', 'csv', 'txt'],
      );
      if (result == null || result.files.single.path == null) return;
      final path = result.files.single.path!;
      final count = await rust.importFromFile(path: path);
      _showMsg('Импортировано записей: $count');
    } catch (e) {
      _showMsg(e.toString());
    }
  }

  // ==================== ХЕЛПЕРЫ ====================

  Widget _buildForm({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArgusColors.background.withOpacity(0.7),
        border: Border.all(color: ArgusColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: ArgusColors.white,
                fontSize: 16,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Container(height: 1, color: ArgusColors.green),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// $label',
          style: const TextStyle(color: ArgusColors.grey, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: ArgusColors.background,
            border: Border.all(color: ArgusColors.green),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(
              color: ArgusColors.green,
              fontSize: 14,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String label, VoidCallback onTap, {Color? color}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: ArgusColors.background,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(
        '<<$label>>',
        style: TextStyle(
          color: color ?? ArgusColors.green,
          fontSize: 13,
          letterSpacing: 2,
        ),
      ),
    );
  }

  void _showMsg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    _oldPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _newPwd2Ctrl.dispose();
    _duressPwdCtrl.dispose();
    _duressPwd2Ctrl.dispose();
    super.dispose();
  }

  
  // ==================== ЛОГИКА ====================

  void _onSelect(String key) {
    if (key == 'back') {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _section = key);
  }
}