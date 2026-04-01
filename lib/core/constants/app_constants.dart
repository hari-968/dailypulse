// ignore_for_file: constant_identifier_names

class AppConstants {
  AppConstants._();

  static const String appName = 'DailyPulse';

  // ─── NewsAPI ────────────────────────────────────────────────────────────────
  // Get a free key at: https://newsapi.org
  static const String newsApiKey = 'YOUR_NEWS_API_KEY';
  static const String newsBaseUrl = 'https://newsapi.org/v2';

  // ─── TMDB ───────────────────────────────────────────────────────────────────
  // Get a free key at: https://www.themoviedb.org/settings/api
  static const String tmdbApiKey = 'YOUR_TMDB_API_KEY';
  static const String tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String tmdbImageBase = 'https://image.tmdb.org/t/p';

  // Image sizes
  static const String posterSize = 'w500';
  static const String backdropSize = 'w1280';
  static const String thumbSize = 'w200';

  // Notification IDs
  static const int morningNotificationId = 1001;
  static const int eveningNotificationId = 1002;
  static const int bookmarkNotificationId = 2001;

  // Notification channels
  static const String channelMorningNews = 'morning_news';
  static const String channelEveningMovies = 'evening_movies';
  static const String channelBookmarks = 'bookmark_alerts';

  // SharedPreferences keys
  static const String bookmarkedNewsKey = 'bookmarked_news';
  static const String bookmarkedMoviesKey = 'bookmarked_movies';
  static const String bookmarkedTamilMoviesKey = 'bookmarked_tamil_movies';
  static const String bookmarkedOttMoviesKey = 'bookmarked_ott_movies';
}
