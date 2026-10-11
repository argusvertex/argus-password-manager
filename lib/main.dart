import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/legacy.dart';
import 'src/rust/frb_generated.dart';
import 'theme/app_theme.dart';
import 'screens/unlock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(1200, 800),
    maximumSize: Size(1200, 800),
    center: true,
    title: 'ARGUS',
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
  });

  // Иконка в трее
  await trayManager.setIcon('assets/images/tray_icon.ico');

  // Меню
  final menu = Menu(
    items: [
      MenuItem(key: 'show', label: 'Show ARGUS'),
      MenuItem.separator(),
      MenuItem(key: 'exit', label: 'Exit'),
    ],
  );
  await trayManager.setContextMenu(menu);

  runApp(const ArgusApp());
}

class ArgusApp extends StatefulWidget {
  const ArgusApp({super.key});

  @override
  State<ArgusApp> createState() => _ArgusAppState();
}

class _ArgusAppState extends State<ArgusApp>
    with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  // Крестик → свернуть в трей
  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  // Левый клик по трею → показать окно
  @override
  void onTrayIconMouseDown() async {
    await windowManager.show();
    await windowManager.focus();
  }

  // Правый клик → показать меню
  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  // Пункт меню
  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'show') {
      await windowManager.show();
      await windowManager.focus();
    } else if (menuItem.key == 'exit') {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARGUS',
      debugShowCheckedModeBanner: false,
      theme: ArgusTheme.dark,
      home: const UnlockScreen(),
    );
  }
}