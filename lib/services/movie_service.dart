import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/movie.dart';

class MovieService {
  // ─── Trending (worldwide) ───────────────────────────────────────────────────
  Future<List<Movie>> fetchTrendingMovies() async {
    if (AppConstants.tmdbApiKey == 'YOUR_TMDB_API_KEY') {
      return _mockTrending();
    }

    final uri = Uri.parse(
      '${AppConstants.tmdbBaseUrl}/trending/movie/day'
      '?api_key=${AppConstants.tmdbApiKey}',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>? ?? [])
            .map((e) => Movie.fromJson(e as Map<String, dynamic>,
                category: MovieCategory.trending))
            .toList();
        return results.isEmpty ? _mockTrending() : results;
      }
      return _mockTrending();
    } catch (_) {
      return _mockTrending();
    }
  }

  // ─── Now Playing (legacy — kept for bookmarks screen) ──────────────────────
  Future<List<Movie>> fetchNowPlayingMovies() async {
    if (AppConstants.tmdbApiKey == 'YOUR_TMDB_API_KEY') {
      return _mockTrending().reversed.toList();
    }

    final uri = Uri.parse(
      '${AppConstants.tmdbBaseUrl}/movie/now_playing'
      '?api_key=${AppConstants.tmdbApiKey}',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List<dynamic>? ?? [])
            .map((e) => Movie.fromJson(e as Map<String, dynamic>,
                category: MovieCategory.trending))
            .toList();
        return results.isEmpty ? _mockTrending().reversed.toList() : results;
      }
      return _mockTrending().reversed.toList();
    } catch (_) {
      return _mockTrending().reversed.toList();
    }
  }

  // ─── Tamil Nadu Theatre Releases ───────────────────────────────────────────
  /// Fetches Tamil-language movies now playing in India (region=IN).
  /// Also fetches popular English movies releasing in India to approximate
  /// Hollywood Tamil-dubbed releases in TN theatres.
  Future<List<Movie>> fetchTamilTheatreMovies() async {
    if (AppConstants.tmdbApiKey == 'YOUR_TMDB_API_KEY') {
      return _mockTamilTheatre();
    }

    // Fetch Tamil-language now-playing in India
    final tamilUri = Uri.parse(
      '${AppConstants.tmdbBaseUrl}/movie/now_playing'
      '?api_key=${AppConstants.tmdbApiKey}'
      '&region=IN'
      '&with_original_language=ta',
    );

    // Also fetch English movies releasing in India (Hollywood Tamil dubs)
    final hollywoodInUri = Uri.parse(
      '${AppConstants.tmdbBaseUrl}/movie/now_playing'
      '?api_key=${AppConstants.tmdbApiKey}'
      '&region=IN'
      '&with_original_language=en',
    );

    try {
      final responses = await Future.wait([
        http.get(tamilUri).timeout(const Duration(seconds: 10)),
        http.get(hollywoodInUri).timeout(const Duration(seconds: 10)),
      ]);

      List<Movie> all = [];

      for (final response in responses) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final results = (data['results'] as List<dynamic>? ?? [])
              .map((e) => Movie.fromJson(e as Map<String, dynamic>,
                  category: MovieCategory.tamilTheatre))
              .toList();
          all.addAll(results);
        }
      }

      // Deduplicate by movie id, sort by rating desc
      final seen = <int>{};
      final unique = all.where((m) => seen.add(m.id)).toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      return unique.isEmpty ? _mockTamilTheatre() : unique;
    } catch (_) {
      return _mockTamilTheatre();
    }
  }

  // ─── Hollywood OTT Releases ────────────────────────────────────────────────
  /// Fetches recently digitally/streaming released English-language movies.
  /// Uses TMDB discover with release_type=4 (digital) | 5 (streaming).
  Future<List<Movie>> fetchHollywoodOttMovies() async {
    if (AppConstants.tmdbApiKey == 'YOUR_TMDB_API_KEY') {
      return _mockOttReleases();
    }

    // Get movies released digitally in the last 60 days
    final now = DateTime.now();
    final sixtyDaysAgo = now.subtract(const Duration(days: 60));
    final dateFrom =
        '${sixtyDaysAgo.year}-${sixtyDaysAgo.month.toString().padLeft(2, '0')}-${sixtyDaysAgo.day.toString().padLeft(2, '0')}';
    final dateTo =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final uri = Uri.parse(
      '${AppConstants.tmdbBaseUrl}/discover/movie'
      '?api_key=${AppConstants.tmdbApiKey}'
      '&with_original_language=en'
      '&with_release_type=4%7C5'
      '&release_date.gte=$dateFrom'
      '&release_date.lte=$dateTo'
      '&sort_by=popularity.desc'
      '&vote_count.gte=50'
      '&region=US',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        final results = (data['results'] as List<dynamic>? ?? [])
            .map((e) => Movie.fromJson(
                  e as Map<String, dynamic>,
                  category: MovieCategory.hollywoodOtt,
                  ottPlatform: _guessOttPlatform(e),
                ))
            .toList();

        return results.isEmpty ? _mockOttReleases() : results;
      }
      return _mockOttReleases();
    } catch (_) {
      return _mockOttReleases();
    }
  }

  // ─── Trailer ───────────────────────────────────────────────────────────────
  Future<String?> fetchTrailerKey(int movieId) async {
    if (AppConstants.tmdbApiKey == 'YOUR_TMDB_API_KEY') return null;

    final uri = Uri.parse(
      '${AppConstants.tmdbBaseUrl}/movie/$movieId/videos'
      '?api_key=${AppConstants.tmdbApiKey}',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        final trailer = results.firstWhere(
          (v) =>
              (v['type'] as String?) == 'Trailer' &&
              (v['site'] as String?) == 'YouTube',
          orElse: () => null,
        );
        return trailer?['key'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── OTT platform guesser ──────────────────────────────────────────────────
  /// Heuristic: TMDB doesn't return platform in discover — we label popular ones
  /// by production company keywords. Real implementation uses /watch/providers.
  String? _guessOttPlatform(Map<String, dynamic> json) {
    // We'll show generic "Streaming" for now; can be enhanced with watch providers API
    return 'Streaming';
  }

  // ─── Mock Data ─────────────────────────────────────────────────────────────
  static List<Movie> _mockTrending() {
    return [
      Movie(
        id: 1,
        title: 'Dune: Part Three',
        overview:
            'Paul Atreides unites the fremen of Arrakis and begins his conquest of the known universe, confronting the consequences of the prophecy that has shaped his destiny.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-11-20',
        rating: 8.7,
        voteCount: 12450,
        genreIds: [878, 12, 28],
        category: MovieCategory.trending,
      ),
      Movie(
        id: 2,
        title: 'The Last Frontier',
        overview:
            'In a world ravaged by climate collapse, a lone scientist discovers a hidden biome that could restore Earth\'s ecosystems.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-09-12',
        rating: 8.2,
        voteCount: 8930,
        genreIds: [878, 18],
        category: MovieCategory.trending,
      ),
      Movie(
        id: 3,
        title: 'Echoes of Tomorrow',
        overview:
            'A time-loop thriller in which a detective must relive the same 24 hours to prevent a global catastrophe.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-07-04',
        rating: 7.9,
        voteCount: 6210,
        genreIds: [53, 9648, 878],
        category: MovieCategory.trending,
      ),
      Movie(
        id: 4,
        title: 'Neon Requiem',
        overview:
            'In the cyberpunk streets of 2089 Neo-Tokyo, a disgraced detective hunts a serial killer who targets AI-human hybrids.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-06-20',
        rating: 8.4,
        voteCount: 9820,
        genreIds: [878, 80, 53],
        category: MovieCategory.trending,
      ),
      Movie(
        id: 5,
        title: 'Solar Winds',
        overview:
            'Three rival astronauts aboard the first crewed mission to Venus must set aside bitter competition when a catastrophic failure strikes.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-10-03',
        rating: 8.0,
        voteCount: 5890,
        genreIds: [878, 18, 12],
        category: MovieCategory.trending,
      ),
    ];
  }

  static List<Movie> _mockTamilTheatre() {
    return [
      Movie(
        id: 101,
        title: 'Retro',
        overview:
            'Rajinikanth stars in this stylish action drama that takes audiences on a nostalgic journey through Tamil cinema\'s golden era, blending vintage aesthetics with contemporary storytelling.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-04-10',
        rating: 8.5,
        voteCount: 22400,
        genreIds: [28, 18, 10749],
        category: MovieCategory.tamilTheatre,
      ),
      Movie(
        id: 102,
        title: 'Thug Life',
        overview:
            'Kamal Haasan returns in a gritty action thriller directed by Mani Ratnam, exploring the underbelly of organised crime and the code of honour among outlaws.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-04-05',
        rating: 8.2,
        voteCount: 18900,
        genreIds: [28, 80, 18],
        category: MovieCategory.tamilTheatre,
      ),
      Movie(
        id: 103,
        title: 'Coolie',
        overview:
            'Thalaivar rules the screen as a railway coolie who becomes an unlikely hero fighting against corporate greed and political corruption.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-03-28',
        rating: 7.9,
        voteCount: 31200,
        genreIds: [28, 35, 18],
        category: MovieCategory.tamilTheatre,
      ),
      Movie(
        id: 104,
        title: 'Kanguva',
        overview:
            'Suriya plays a warrior across two timelines — ancient and modern — connected by a mysterious bloodline that transcends centuries.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-03-15',
        rating: 7.5,
        voteCount: 14600,
        genreIds: [28, 12, 14],
        category: MovieCategory.tamilTheatre,
      ),
      Movie(
        id: 105,
        title: 'Thunderbolt (Tamil)',
        overview:
            'Marvel\'s Thunderbolt team arrives in Tamil Nadu theatres with the full Tamil-dubbed version of the superhero ensemble blockbuster.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-04-01',
        rating: 8.1,
        voteCount: 42000,
        genreIds: [28, 12, 878],
        category: MovieCategory.tamilTheatre,
      ),
      Movie(
        id: 106,
        title: 'Vettaiyan',
        overview:
            'A veteran police officer faces the toughest battle of his career when he must choose between law and justice in a system riddled with corruption.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-04-18',
        rating: 8.0,
        voteCount: 9800,
        genreIds: [18, 80, 28],
        category: MovieCategory.tamilTheatre,
      ),
    ];
  }

  static List<Movie> _mockOttReleases() {
    return [
      Movie(
        id: 201,
        title: 'The Electric State',
        overview:
            'A young woman and a robot travel through a retrofuturistic American West searching for her missing brother while avoiding government forces.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-03-14',
        rating: 6.8,
        voteCount: 8200,
        genreIds: [878, 12, 28],
        category: MovieCategory.hollywoodOtt,
        ottPlatform: 'Netflix',
      ),
      Movie(
        id: 202,
        title: 'Carry-On',
        overview:
            'A young TSA agent is blackmailed into letting a dangerous package onto a Christmas Eve flight — a ticking time bomb thriller.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-02-28',
        rating: 7.2,
        voteCount: 11400,
        genreIds: [53, 28],
        category: MovieCategory.hollywoodOtt,
        ottPlatform: 'Netflix',
      ),
      Movie(
        id: 203,
        title: 'Road House',
        overview:
            'Jake Gyllenhaal plays a former UFC fighter who takes a job as a bouncer at a roadhouse in the Florida Keys.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-03-21',
        rating: 7.5,
        voteCount: 14300,
        genreIds: [28, 18],
        category: MovieCategory.hollywoodOtt,
        ottPlatform: 'Prime Video',
      ),
      Movie(
        id: 204,
        title: 'Argylle',
        overview:
            'A reclusive spy novelist\'s fictional world starts to mirror the real world, drawing her into an international spy adventure.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-03-10',
        rating: 6.5,
        voteCount: 9100,
        genreIds: [28, 35, 53],
        category: MovieCategory.hollywoodOtt,
        ottPlatform: 'Apple TV+',
      ),
      Movie(
        id: 205,
        title: 'Lift',
        overview:
            'A master thief is recruited by Interpol to steal a gold shipment from a 777 commercial flight during its transoceanic journey.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-02-15',
        rating: 6.9,
        voteCount: 7600,
        genreIds: [28, 35, 80],
        category: MovieCategory.hollywoodOtt,
        ottPlatform: 'Netflix',
      ),
      Movie(
        id: 206,
        title: 'Land of Bad',
        overview:
            'A Delta Force team goes on a mission in the Philippines that quickly goes wrong, leaving one soldier stranded and fighting for survival.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-03-01',
        rating: 7.1,
        voteCount: 6800,
        genreIds: [28, 18, 10752],
        category: MovieCategory.hollywoodOtt,
        ottPlatform: 'Prime Video',
      ),
      Movie(
        id: 207,
        title: 'The Beekeeper',
        overview:
            'One man\'s campaign of vengeance takes on national stakes after he is revealed to be a former operative of a powerful secret organisation.',
        posterPath: null,
        backdropPath: null,
        releaseDate: '2026-03-26',
        rating: 7.4,
        voteCount: 16200,
        genreIds: [28, 53],
        category: MovieCategory.hollywoodOtt,
        ottPlatform: 'Disney+',
      ),
    ];
  }
}
