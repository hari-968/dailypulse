import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/movie.dart';

class VideoService {
  VideoService._();

  static Future<bool> openMovieTrailer(
    Movie movie, {
    String? trailerKey,
  }) async {
    final Uri uri = trailerKey != null && trailerKey.isNotEmpty
        ? Uri.parse('https://www.youtube.com/watch?v=$trailerKey')
        : Uri.parse(
            'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${movie.title} trailer')}',
          );

    try {
      return launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (error) {
      debugPrint('[VideoService] Failed to open trailer for ${movie.title}: $error');
      return false;
    }
  }
}