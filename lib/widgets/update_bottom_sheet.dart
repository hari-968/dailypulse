// ─────────────────────────────────────────────────────────────────────────────
// update_bottom_sheet.dart
//
// A premium-looking modal bottom sheet that:
//   • Displays update version, message, and progress
//   • Downloads the APK on button tap with live progress bar
//   • Supports force-update mode (cannot be dismissed)
//   • Has a retry button on download failure
//   • Uses smooth animations throughout
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/update_service.dart';

// ── Public helper to show the bottom sheet ────────────────────────────────────
/// Call this from anywhere (e.g. main.dart after app launches).
/// If [info.forceUpdate] is true, the sheet cannot be dismissed by swiping
/// or tapping the "Later" button.
Future<void> showUpdateBottomSheet(
  BuildContext context,
  AppUpdateInfo info,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isDismissible: !info.forceUpdate,
    enableDrag: !info.forceUpdate,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UpdateBottomSheet(info: info),
  );
}

// ── Internal state ─────────────────────────────────────────────────────────────
enum _DownloadState { idle, downloading, success, failed }

// ── Bottom sheet widget ────────────────────────────────────────────────────────
class _UpdateBottomSheet extends StatefulWidget {
  final AppUpdateInfo info;

  const _UpdateBottomSheet({required this.info});

  @override
  State<_UpdateBottomSheet> createState() => _UpdateBottomSheetState();
}

class _UpdateBottomSheetState extends State<_UpdateBottomSheet>
    with SingleTickerProviderStateMixin {
  _DownloadState _state = _DownloadState.idle;
  double _progress = 0.0;
  File? _downloadedFile;
  String? _errorMessage;

  /// Dio cancel token — lets us cancel an in-progress download
  CancelToken _cancelToken = CancelToken();

  late AnimationController _entryController;
  late Animation<double> _entryAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _entryAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    // Cancel any ongoing download when sheet is closed
    if (!_cancelToken.isCancelled) _cancelToken.cancel('Sheet dismissed');
    super.dispose();
  }

  // ── Download & install flow  ──────────────────────────────────────────────
  Future<void> _startDownload() async {
    // Reset cancel token for potential retries
    _cancelToken = CancelToken();

    setState(() {
      _state = _DownloadState.downloading;
      _progress = 0.0;
      _errorMessage = null;
    });

    final file = await UpdateService.instance.downloadApk(
      widget.info.apkUrl,
      cancelToken: _cancelToken,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );

    if (!mounted) return;

    if (file == null) {
      setState(() {
        _state = _DownloadState.failed;
        _errorMessage = UpdateService.instance.lastError ??
            'Download failed. Check your connection and try again.';
      });
      return;
    }

    setState(() {
      _state = _DownloadState.success;
      _downloadedFile = file;
    });

    // Short pause so the user sees 100% before the installer opens
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final installed =
        await UpdateService.instance.installApk(_downloadedFile!);

    if (!installed && mounted) {
      setState(() {
        _state = _DownloadState.failed;
        _errorMessage = UpdateService.instance.lastError ??
            'Could not launch installer. Try enabling "Install unknown apps" in Settings.';
      });
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entryAnim,
      builder: (_, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_entryAnim),
        child: FadeTransition(opacity: _entryAnim, child: child),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ──
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Icon + title row ──
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Available',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Version ${widget.info.version}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                // Force-update badge
                if (widget.info.forceUpdate)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.error.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(color: AppTheme.divider, height: 1),
            const SizedBox(height: 20),

            // ── Update message ──
            Text(
              widget.info.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.6,
                  ),
            ),

            const SizedBox(height: 24),

            // ── Progress section (visible while downloading or success) ──
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: (_state == _DownloadState.downloading ||
                      _state == _DownloadState.success)
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _ProgressSection(
                progress: _progress,
                isDone: _state == _DownloadState.success,
              ),
            ),

            // ── Error section ──
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _state == _DownloadState.failed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: _ErrorSection(message: _errorMessage ?? ''),
            ),

            if (_state == _DownloadState.downloading ||
                _state == _DownloadState.success ||
                _state == _DownloadState.failed)
              const SizedBox(height: 20),

            // ── Action buttons ──
            _ActionButtons(
              state: _state,
              isForceUpdate: widget.info.forceUpdate,
              onUpdate: _startDownload,
              onRetry: _startDownload,
              onLater: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress section widget ───────────────────────────────────────────────────
class _ProgressSection extends StatelessWidget {
  final double progress;
  final bool isDone;

  const _ProgressSection({required this.progress, required this.isDone});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isDone ? '✅ Download complete' : 'Downloading update…',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDone ? AppTheme.success : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppTheme.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDone ? AppTheme.success : AppTheme.primaryLight,
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Error section widget ──────────────────────────────────────────────────────
class _ErrorSection extends StatelessWidget {
  final String message;

  const _ErrorSection({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppTheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action buttons widget ─────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  final _DownloadState state;
  final bool isForceUpdate;
  final VoidCallback onUpdate;
  final VoidCallback onRetry;
  final VoidCallback onLater;

  const _ActionButtons({
    required this.state,
    required this.isForceUpdate,
    required this.onUpdate,
    required this.onRetry,
    required this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Primary action button ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (state) {
            // Idle → "Update Now"
            _DownloadState.idle => _GradientButton(
                key: const ValueKey('update'),
                label: 'Update Now',
                icon: Icons.download_rounded,
                onTap: onUpdate,
              ),

            // Downloading → disabled spinner button
            _DownloadState.downloading => _LoadingButton(
                key: const ValueKey('loading'),
                label: 'Downloading…',
              ),

            // Success → "Installing…" (auto-triggered)
            _DownloadState.success => _GradientButton(
                key: const ValueKey('installing'),
                label: 'Installing…',
                icon: Icons.install_mobile_rounded,
                onTap: null,
              ),

            // Failed → "Retry"
            _DownloadState.failed => _GradientButton(
                key: const ValueKey('retry'),
                label: 'Retry Download',
                icon: Icons.refresh_rounded,
                onTap: onRetry,
                color: AppTheme.error,
              ),
          },
        ),

        // ── "Later" button (hidden for force updates and while downloading) ──
        if (!isForceUpdate &&
            state != _DownloadState.downloading &&
            state != _DownloadState.success) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: onLater,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Later',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Gradient button (reusable) ────────────────────────────────────────────────
class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const _GradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            gradient: color != null
                ? LinearGradient(colors: [
                    color!.withOpacity(0.8),
                    color!,
                  ])
                : AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDisabled
                ? []
                : [
                    BoxShadow(
                      color: (color ?? AppTheme.primary).withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading button (while downloading) ───────────────────────────────────────
class _LoadingButton extends StatelessWidget {
  final String label;

  const _LoadingButton({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.cardBgLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
