import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../src/rust/api/vault.dart' as rust;
import 'add_entry_screen.dart';
import 'unlock_screen.dart';
import '../widgets/folders_panel.dart';
import '../widgets/entries_list.dart';
import '../widgets/entry_details.dart';
import '../widgets/actions_panel.dart';
import 'new_folder_screen.dart';
import 'move_to_folder_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {


  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<rust.EntryDto> _entries = [];
  bool _loading = true;
  String? _error;
  BigInt? _selectedId;
  BigInt? _selectedFolder;
  List<rust.FolderDto> _folders = [];
  String _searchQuery = '';
  

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _loadEntries();
  }

    Future<void> _applySearch(String query) async {
    try {
      if (query.trim().isEmpty) {
        await _loadEntries();
        return;
      }
      final results = await rust.searchEntries(query: query);
      setState(() {
        _entries = results;
        if (_selectedId != null &&
            !results.any((e) => e.id == _selectedId)) {
          _selectedId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _onSettings() async {
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );
}

  Future<void> _loadEntries() async {
    try {
      final entries = await rust.listEntries();
      setState(() {
        _entries = entries;
        _loading = false;
        if (_selectedId != null &&
            !entries.any((e) => e.id == _selectedId)) {
          _selectedId = null;
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  rust.EntryDto? get _selectedEntry {
    if (_selectedId == null) return null;
    try {
      return _entries.firstWhere((e) => e.id == _selectedId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onAdd() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const EntryFormScreen(),
    );
    if (result == true) _loadEntries();
  }

  Future<void> _onEdit() async {
    final entry = _selectedEntry;
    if (entry == null) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EntryFormScreen(entry: entry),
    );
    if (result == true) _loadEntries();
  }

    Future<void> _loadFolders() async {
    try {
      final folders = await rust.listFolders();
      setState(() => _folders = folders);
    } catch (_) {}
  }

  Future<void> _onAddFolder() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const NewFolderScreen(),
    );
    if (name == null || name.isEmpty) return;
    try {
      await rust.addFolder(name: name);
      _loadFolders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _onMove() async {
    final entry = _selectedEntry;
    if (entry == null) return;

    final result = await showDialog<Object?>(
      context: context,
      builder: (_) => MoveToFolderScreen(
        folders: _folders,
        currentFolderId: entry.folderId,
      ),
    );

    // Отмена
    if (result == '__cancel__') return;

    // Определяем folderId
    BigInt? folderId;
    if (result == null) {
      folderId = null; // «без папки»
    } else if (result is BigInt) {
      folderId = result;
    } else {
      return; // что-то непонятное — ничего не делаем
    }

    try {
      await rust.moveEntryToFolder(
        entryId: entry.id,
        folderId: folderId,
      );
      _loadEntries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _onDeleteFolder() async {
    final id = _selectedFolder;
    if (id == null || id == BigInt.from(-1)) return;
    try {
      await rust.deleteFolder(id: id);
      setState(() => _selectedFolder = null);
      _loadFolders();
      _loadEntries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _filterByFolder(BigInt? folderId) async {
    setState(() => _selectedFolder = folderId);
    try {
      final List<rust.EntryDto> entries;
      if (folderId == null) {
        entries = await rust.listEntries();
      } else if (folderId == BigInt.from(-1)) {
        entries = await rust.listEntriesInFolder();
      } else {
        entries = await rust.listEntriesInFolder(folderId: folderId);
      }
      setState(() {
        _entries = entries;
        if (_selectedId != null &&
            !entries.any((e) => e.id == _selectedId)) {
          _selectedId = null;
        }
      });
    } catch (_) {}
  }

  Future<void> _onDelete() async {
    final id = _selectedId;
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ArgusColors.panel,
        title: const Text('Delete entry?',
            style: TextStyle(color: ArgusColors.white)),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: ArgusColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('<<NO>>',
                style: TextStyle(color: ArgusColors.green)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('<<YES>>',
                style: TextStyle(color: ArgusColors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await rust.deleteEntry(id: id);
      setState(() => _selectedId = null);
      _loadEntries();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _onExit() async {
    try {
      rust.lockSession();
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const UnlockScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_main.png',
              fit: BoxFit.cover,
            ),
          ),



          Column(
            children: [
              // Верхняя панель — 60px
              SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: _buildTopBar(),
                ),
              ),

              // Рабочая область
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 35, 19, 34),
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: ArgusColors.green),
                        )
                      : _error != null
                          ? Center(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                    color: ArgusColors.red),
                              ),
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Панель папок — 322px
                                SizedBox(
                                  width: 322,
                                  child: FoldersPanel(
                                    selectedFolder: _selectedFolder,
                                    folders: _folders,
                                    onSelect: _filterByFolder,
                                    onSearch: (q) async {
                                      setState(() => _searchQuery = q);
                                      await _applySearch(q);
                                    },
                                    onAddFolder: _onAddFolder,
                                    onDeleteFolder: _onDeleteFolder,
                                  ),
                                ),

                                // Окно 1 — 419px
                                SizedBox(
                                  width: 419,
                                  child: EntriesList(
                                    entries: _entries,
                                    selectedId: _selectedId,
                                    onSelect: (id) {
                                      setState(() => _selectedId = id);
                                    },
                                  ),
                                ),

                                const SizedBox(width: 20),

                                // Правая колонка — окна 2 и 3
                                Expanded(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 86,
                                        child: ActionsPanel(
                                          entry: _selectedEntry,
                                          onMove: _onMove,
                                          onDelete: _onDelete,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: EntryDetails(
                                          entry: _selectedEntry,
                                          onEdit: _onEdit,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Image.asset(
          'assets/images/logo_ar.png',
          width: 28,
          height: 28,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 12),
        const Text(
          'ARGUS v0.0.1',
          style: TextStyle(
            color: ArgusColors.white,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        _topButton('ADD', _onAdd),
        const SizedBox(width: 16),
        _topButton('SETTINGS', _onSettings),
        const SizedBox(width: 16),
        _topButton('EXIT', _onExit),
      ],
    );
  }

  Widget _topButton(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        '<<$label>>',
        style: const TextStyle(
          color: ArgusColors.green,
          fontSize: 14,
          letterSpacing: 2,
        ),
      ),
    );
  }
}