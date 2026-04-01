import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';

// ── Service provider ──────────────────────────────────────────────────────────
final movieServiceProvider = Provider<MovieService>((ref) => MovieService());

// ── Trending movies ───────────────────────────────────────────────────────────
final trendingMoviesProvider =
    AsyncNotifierProvider<TrendingMoviesNotifier, List<Movie>>(
        TrendingMoviesNotifier.new);

class TrendingMoviesNotifier extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() async {
    return ref.read(movieServiceProvider).fetchTrendingMovies();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(movieServiceProvider).fetchTrendingMovies(),
    );
  }
}

// ── Now Playing (legacy — used in bookmarks) ──────────────────────────────────
final nowPlayingMoviesProvider =
    AsyncNotifierProvider<NowPlayingMoviesNotifier, List<Movie>>(
        NowPlayingMoviesNotifier.new);

class NowPlayingMoviesNotifier extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() async {
    return ref.read(movieServiceProvider).fetchNowPlayingMovies();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(movieServiceProvider).fetchNowPlayingMovies(),
    );
  }
}

// ── Tamil Nadu Theatre Releases ───────────────────────────────────────────────
final tamilTheatreMoviesProvider =
    AsyncNotifierProvider<TamilTheatreMoviesNotifier, List<Movie>>(
        TamilTheatreMoviesNotifier.new);

class TamilTheatreMoviesNotifier extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() async {
    return ref.read(movieServiceProvider).fetchTamilTheatreMovies();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(movieServiceProvider).fetchTamilTheatreMovies(),
    );
  }
}

// ── Hollywood OTT Releases ────────────────────────────────────────────────────
final ottMoviesProvider =
    AsyncNotifierProvider<OttMoviesNotifier, List<Movie>>(
        OttMoviesNotifier.new);

class OttMoviesNotifier extends AsyncNotifier<List<Movie>> {
  @override
  Future<List<Movie>> build() async {
    return ref.read(movieServiceProvider).fetchHollywoodOttMovies();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(movieServiceProvider).fetchHollywoodOttMovies(),
    );
  }
}

// ── Trailer key (family — per movie id) ──────────────────────────────────────
final trailerKeyProvider =
    FutureProvider.family<String?, int>((ref, movieId) async {
  return ref.read(movieServiceProvider).fetchTrailerKey(movieId);
});
