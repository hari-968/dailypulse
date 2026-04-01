import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/update_service.dart';
import 'widgets/update_bottom_sheet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize notifications (non-blocking — silently ignores denial)
  NotificationService.instance.initialize().catchError((_) {});

  runApp(
    const ProviderScope(
      child: DailyPulseApp(),
    ),
  );
}

class DailyPulseApp extends StatelessWidget {
  const DailyPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DailyPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // Use a builder so we have a valid Navigator context for the bottom sheet
      home: const _AppRoot(),
    );
  }
}

// ── AppRoot: mounts the home screen and triggers update check after first frame ──
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  @override
  void initState() {
    super.initState();
    // Wait until the first frame is drawn so we have a valid BuildContext
    // with a mounted Navigator before showing the bottom sheet.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    // Small delay so the home screen renders first — better UX
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    debugPrint('[main.dart] _checkForUpdate() — calling UpdateService...');

    final (result, info) = await UpdateService.instance.checkForUpdate();

    if (!mounted) return;

    switch (result) {
      case UpdateCheckResult.updateAvailable:
        debugPrint('[main.dart] ✅ Update available (${info?.version}). Showing bottom sheet.');
        await showUpdateBottomSheet(context, info!);

      case UpdateCheckResult.upToDate:
        debugPrint('[main.dart] ✔ App is already up to date. No popup shown.');

      case UpdateCheckResult.error:
        // Silently ignore in production — log in debug so we know what happened
        debugPrint(
          '[main.dart] ⚠️ Update check failed (network error or version.json not found). '
          'No popup shown. Check that the version.json URL is reachable and the file exists.',
        );
    }
  }

  @override
  Widget build(BuildContext context) => const HomeScreen();
}
