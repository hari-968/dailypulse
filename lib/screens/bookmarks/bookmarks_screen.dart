import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/movie_provider.dart';
import '../../widgets/bookmark_button.dart';
import '../movies/movie_detail_screen.dart';

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen> {
  @override
  Widget build(BuildContext context) {
    final bookmarks = ref.watch(bookmarkProvider);

    // Merge ALL movie sources (trending + now playing + Tamil + OTT) and deduplicate
    final trendingAsync = ref.watch(trendingMoviesProvider);
    final nowPlayingAsync = ref.watch(nowPlayingMoviesProvider);
    final tamilAsync = ref.watch(tamilTheatreMoviesProvider);
    final ottAsync = ref.watch(ottMoviesProvider);

    final allMovies = [
      ...?trendingAsync.value,
      ...?nowPlayingAsync.value,
      ...?tamilAsync.value,
      ...?ottAsync.value,
    ];
    final seenIds = <int>{};
    final uniqueMovies = allMovies
        .where((m) => seenIds.add(m.id))
        .where((m) => bookmarks.isMovieBookmarked(m.id))
        .toList();

    final moviesCount = uniqueMovies.length;

    final isLoadingMovies = trendingAsync.isLoading ||
        nowPlayingAsync.isLoading ||
        tamilAsync.isLoading ||
        ottAsync.isLoading;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppTheme.primaryGradient.createShader(bounds),
                        child: Text(
                          'Bookmarks',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your saved movies',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                // Total count badge
                if (moviesCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$moviesCount saved',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Movies bookmarks view ──
          Expanded(
            child: _MoviesBookmarksList(
              movies: uniqueMovies,
              isLoading: isLoadingMovies,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Counter badge ──────────────────────────────────────────────────────────────
// ── Movies bookmarks list ──────────────────────────────────────────────────────
class _MoviesBookmarksList extends ConsumerWidget {
  final List<Movie> movies;
  final bool isLoading;

  const _MoviesBookmarksList({
    required this.movies,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryLight),
      );
    }

    if (movies.isEmpty) {
      return _EmptyState(
        icon: Icons.movie_filter_outlined,
        title: 'No saved movies',
        subtitle:
            'Tap the bookmark icon on any movie\nto add it to your watchlist.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: movies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final movie = movies[index];
        return _BookmarkedMovieCard(
          movie: movie,
          index: index,
          onTap: () => Navigator.push(
            context,
            _fadeRoute(MovieDetailScreen(movie: movie)),
          ),
        );
      },
    );
  }
}

// ── Bookmarked Movie Card (shows category badge) ───────────────────────────────
class _BookmarkedMovieCard extends StatefulWidget {
  final Movie movie;
  final int index;
  final VoidCallback? onTap;

  const _BookmarkedMovieCard({
    required this.movie,
    required this.index,
    this.onTap,
  });

  @override
  State<_BookmarkedMovieCard> createState() => _BookmarkedMovieCardState();
}

class _BookmarkedMovieCardState extends State<_BookmarkedMovieCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 50),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Returns label + color for the movie's category
  (String, Color) get _categoryBadge {
    switch (widget.movie.category) {
      case MovieCategory.tamilTheatre:
        return ('🎭 Tamil TN', const Color(0xFFFF6B6B));
      case MovieCategory.hollywoodOtt:
        return ('📺 ${widget.movie.ottPlatform ?? "OTT"}',
            const Color(0xFF06B6D4));
      case MovieCategory.trending:
        return ('🔥 Trending', AppTheme.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final (label, badgeColor) = _categoryBadge;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 125,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: AppTheme.cardGradient,
              border: Border.all(
                color: badgeColor.withOpacity(0.18),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Poster
                ClipRRect(
                  borderRadius:
                      const BorderRadius.horizontal(left: Radius.circular(20)),
                  child: SizedBox(
                    width: 88,
                    height: double.infinity,
                    child: movie.posterUrl.isNotEmpty
                        ? Image.network(
                            movie.posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(badgeColor),
                          )
                        : _placeholder(badgeColor),
                  ),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                movie.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(height: 1.3),
                              ),
                            ),
                            const SizedBox(width: 4),
                            BookmarkButton.movie(
                                movieId: movie.id, movie: movie),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppTheme.ratingGold, size: 13),
                            const SizedBox(width: 3),
                            Text(
                              movie.ratingText,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppTheme.ratingGold,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            // Category badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: badgeColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          movie.overview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.25), AppTheme.cardBgLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Icon(Icons.movie_creation_outlined, color: color, size: 28),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────
class _EmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _anim,
        child: ScaleTransition(
          scale: _anim,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withOpacity(0.2),
                        AppTheme.secondary.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppTheme.primary.withOpacity(0.7),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Route helper ──────────────────────────────────────────────────────────────
PageRoute _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );
    },
  );
}
