import '../core/constants/app_constants.dart';

/// Which category this movie belongs to when displayed in the Movies screen.
enum MovieCategory { trending, tamilTheatre, hollywoodOtt }

class Movie {
  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final String releaseDate;
  final double rating;
  final int voteCount;
  final List<int> genreIds;

  /// OTT platform name (e.g. "Netflix", "Prime Video") — null for theatre releases
  final String? ottPlatform;

  /// Category assigned when fetched — used for UI labelling
  final MovieCategory category;

  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    this.posterPath,
    this.backdropPath,
    required this.releaseDate,
    required this.rating,
    required this.voteCount,
    required this.genreIds,
    this.ottPlatform,
    this.category = MovieCategory.trending,
  });

  factory Movie.fromJson(
    Map<String, dynamic> json, {
    MovieCategory category = MovieCategory.trending,
    String? ottPlatform,
  }) {
    return Movie(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? 'Unknown',
      overview: json['overview'] as String? ?? 'No description available.',
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      releaseDate: json['release_date'] as String? ??
          json['first_air_date'] as String? ??
          '',
      rating: ((json['vote_average'] as num?) ?? 0.0).toDouble(),
      voteCount: json['vote_count'] as int? ?? 0,
      genreIds: (json['genre_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      category: category,
      ottPlatform: ottPlatform,
    );
  }

  String get posterUrl => posterPath != null
      ? '${AppConstants.tmdbImageBase}/${AppConstants.posterSize}$posterPath'
      : '';

  String get backdropUrl => backdropPath != null
      ? '${AppConstants.tmdbImageBase}/${AppConstants.backdropSize}$backdropPath'
      : '';

  String get thumbUrl => posterPath != null
      ? '${AppConstants.tmdbImageBase}/${AppConstants.thumbSize}$posterPath'
      : '';

  String get year =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : releaseDate;

  String get ratingText => rating.toStringAsFixed(1);
}
