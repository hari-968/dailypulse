import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../core/constants/app_constants.dart';
import '../models/movie.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(initSettings);
    await _requestPermissions();
    await _scheduleRecurringNotifications();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _scheduleRecurringNotifications() async {
    try {
      await _scheduleMorningNews();
      await _scheduleEveningMovies();
    } catch (e) {
      if (kDebugMode) debugPrint('Notification scheduling error: $e');
    }
  }

  // ─── Scheduled: Morning News Digest ────────────────────────────────────────
  Future<void> _scheduleMorningNews() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 8, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      AppConstants.channelMorningNews,
      'Morning News Digest',
      channelDescription: 'Daily morning news summary at 8 AM.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF7C3AED),
      styleInformation: const BigTextStyleInformation(
        'Your curated morning digest is ready. Tap to read today\'s top stories and stay ahead.',
      ),
    );
    const iosDetails =
        DarwinNotificationDetails(categoryIdentifier: 'morning_news');
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      AppConstants.morningNotificationId,
      '☀️ Good Morning — Daily Digest Ready',
      'Your top stories for today are waiting. Stay informed!',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─── Scheduled: Evening Movie Picks ────────────────────────────────────────
  Future<void> _scheduleEveningMovies() async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 19, 0);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      AppConstants.channelEveningMovies,
      'Evening Movie Picks',
      channelDescription: 'Daily evening Tamil & OTT movie recommendations.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF6366F1),
      styleInformation: const BigTextStyleInformation(
        'New Tamil theatre releases & Hollywood OTT drops are available. Check what\'s on tonight!',
      ),
    );
    const iosDetails =
        DarwinNotificationDetails(categoryIdentifier: 'evening_movies');
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      AppConstants.eveningNotificationId,
      '🎬 Tonight\'s Watch List',
      'New Tamil theatre & OTT releases are live — tap to explore!',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ─── Instant: Movie Bookmarked ─────────────────────────────────────────────
  Future<void> showBookmarkMovieNotification(Movie movie) async {
    if (!_initialized) await initialize();

    final suffix = movie.ottPlatform != null
        ? ' is available on ${movie.ottPlatform}.'
        : ' is in your watchlist.';

    final tag = movie.category == MovieCategory.tamilTheatre
        ? '🎭 Tamil Theatre'
        : movie.category == MovieCategory.hollywoodOtt
            ? '📺 OTT Release'
            : '🔥 Trending';

    final androidDetails = AndroidNotificationDetails(
      AppConstants.channelBookmarks,
      'Bookmark Alerts',
      channelDescription: 'Notifies when you bookmark a movie.',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF9F67FA),
      styleInformation: BigTextStyleInformation(
        '[$tag] "${movie.title}"$suffix\nRating: ⭐ ${movie.ratingText} | Released: ${movie.year}',
      ),
    );
    const iosDetails =
        DarwinNotificationDetails(categoryIdentifier: 'bookmark_alerts');
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Use a unique ID per movie so multiple bookmarks each show
    final notifId = AppConstants.bookmarkNotificationId + movie.id;

    await _plugin.show(
      notifId,
      '🔖 Added to Watchlist — ${movie.title}',
      '${movie.category == MovieCategory.tamilTheatre ? 'Tamil Theatre Release' : movie.ottPlatform ?? 'Movie'} · ⭐ ${movie.ratingText}',
      details,
    );
  }

  // ─── Instant: News Bookmarked ──────────────────────────────────────────────
  Future<void> showBookmarkNewsNotification(String title) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      AppConstants.channelBookmarks,
      'Bookmark Alerts',
      channelDescription: 'Notifies when you bookmark an article.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF9F67FA),
    );
    const iosDetails =
        DarwinNotificationDetails(categoryIdentifier: 'bookmark_alerts');
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      AppConstants.bookmarkNotificationId,
      '📰 Article Saved',
      title,
      details,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
