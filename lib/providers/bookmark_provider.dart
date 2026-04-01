import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/movie.dart';
import '../services/notification_service.dart';

class BookmarkState {
  final Set<String> newsIds;
  final Set<int> movieIds;

  const BookmarkState({
    this.newsIds = const {},
    this.movieIds = const {},
  });

  BookmarkState copyWith({Set<String>? newsIds, Set<int>? movieIds}) {
    return BookmarkState(
      newsIds: newsIds ?? this.newsIds,
      movieIds: movieIds ?? this.movieIds,
    );
  }

  bool isNewsBookmarked(String id) => newsIds.contains(id);
  bool isMovieBookmarked(int id) => movieIds.contains(id);
}

final bookmarkProvider =
    StateNotifierProvider<BookmarkNotifier, BookmarkState>((ref) {
  return BookmarkNotifier()..loadFromPrefs();
});

class BookmarkNotifier extends StateNotifier<BookmarkState> {
  BookmarkNotifier() : super(const BookmarkState());

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final newsJson = prefs.getString(AppConstants.bookmarkedNewsKey);
    final moviesJson = prefs.getString(AppConstants.bookmarkedMoviesKey);

    Set<String> newsIds = {};
    Set<int> movieIds = {};

    if (newsJson != null) {
      final list = json.decode(newsJson) as List<dynamic>;
      newsIds = list.cast<String>().toSet();
    }
    if (moviesJson != null) {
      final list = json.decode(moviesJson) as List<dynamic>;
      movieIds = list.cast<int>().toSet();
    }

    state = state.copyWith(newsIds: newsIds, movieIds: movieIds);
  }

  /// Toggle news bookmark. Optionally shows a notification when saving.
  Future<void> toggleNews(String id, {String? articleTitle}) async {
    final updated = Set<String>.from(state.newsIds);
    final isAdding = !updated.contains(id);
    if (isAdding) {
      updated.add(id);
    } else {
      updated.remove(id);
    }
    state = state.copyWith(newsIds: updated);
    await _persistNews(updated);

    // Notify only when adding
    if (isAdding && articleTitle != null) {
      NotificationService.instance
          .showBookmarkNewsNotification(articleTitle)
          .catchError((_) {});
    }
  }

  /// Toggle movie bookmark. Fires an instant notification when adding.
  Future<void> toggleMovie(int id, {Movie? movie}) async {
    final updated = Set<int>.from(state.movieIds);
    final isAdding = !updated.contains(id);
    if (isAdding) {
      updated.add(id);
    } else {
      updated.remove(id);
    }
    state = state.copyWith(movieIds: updated);
    await _persistMovies(updated);

    // Fire notification on add (not on remove)
    if (isAdding && movie != null) {
      NotificationService.instance
          .showBookmarkMovieNotification(movie)
          .catchError((_) {});
    }
  }

  Future<void> _persistNews(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.bookmarkedNewsKey, json.encode(ids.toList()));
  }

  Future<void> _persistMovies(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        AppConstants.bookmarkedMoviesKey, json.encode(ids.toList()));
  }
}
