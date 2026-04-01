import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../providers/movie_provider.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/bookmark_button.dart';
import 'movie_detail_screen.dart';

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(tamilTheatreMoviesProvider.notifier).refresh(),
      ref.read(ottMoviesProvider.notifier).refresh(),
      ref.read(trendingMoviesProvider.notifier).refresh(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppTheme.primaryGradient.createShader(bounds),
                  child: Text(
                    'Movies',
                    style:
                        Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: Colors.white,
                            ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tamil theatres · Hollywood OTT · Trending',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),

          // ── Tab Bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorPadding: const EdgeInsets.all(3),
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🎭', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 4),
                        Text('Tamil TN'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📺', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 4),
                        Text('OTT'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 4),
                        Text('Trending'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab Views ──
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryLight,
              backgroundColor: AppTheme.cardBg,
              onRefresh: _refreshAll,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TamilTheatreTab(),
                  _OttReleasesTab(),
                  _TrendingTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tamil Nadu Theatre Tab ─────────────────────────────────────────────────────
class _TamilTheatreTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(tamilTheatreMoviesProvider);

    return moviesAsync.when(
      loading: () => const ShimmerLoader(type: ShimmerType.movieCard, count: 4),
      error: (_, __) => _ErrorState(
        message: 'Could not load Tamil theatre releases',
        onRetry: () => ref.read(tamilTheatreMoviesProvider.notifier).refresh(),
      ),
      data: (movies) => CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Section banner ──
          SliverToBoxAdapter(
            child: _SectionBanner(
              icon: '🎭',
              title: 'Tamil Nadu Theatres',
              subtitle: 'Now playing in TN cinemas · Tamil & dubbed Hollywood',
              color: const Color(0xFFFF6B6B),
            ),
          ),

          // ── Movie list ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList.separated(
              itemCount: movies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final movie = movies[index];
                return _TheatreMovieCard(
                  movie: movie,
                  index: index,
                  onTap: () => Navigator.push(
                    context,
                    _fadeRoute(MovieDetailScreen(movie: movie)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── OTT Releases Tab ──────────────────────────────────────────────────────────
class _OttReleasesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(ottMoviesProvider);

    return moviesAsync.when(
      loading: () => const ShimmerLoader(type: ShimmerType.movieCard, count: 4),
      error: (_, __) => _ErrorState(
        message: 'Could not load OTT releases',
        onRetry: () => ref.read(ottMoviesProvider.notifier).refresh(),
      ),
      data: (movies) => CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Section banner ──
          SliverToBoxAdapter(
            child: _SectionBanner(
              icon: '📺',
              title: 'Hollywood OTT Releases',
              subtitle: 'Netflix · Prime · Disney+ · Apple TV+ and more',
              color: const Color(0xFF06B6D4),
            ),
          ),

          // ── Movie list ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList.separated(
              itemCount: movies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final movie = movies[index];
                return _OttMovieCard(
                  movie: movie,
                  index: index,
                  onTap: () => Navigator.push(
                    context,
                    _fadeRoute(MovieDetailScreen(movie: movie)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trending Tab ──────────────────────────────────────────────────────────────
class _TrendingTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingMoviesProvider);
    final nowPlayingAsync = ref.watch(nowPlayingMoviesProvider);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── Trending section ──
        SliverToBoxAdapter(
          child: _SectionBanner(
            icon: '🔥',
            title: 'Trending Worldwide',
            subtitle: 'Most popular movies right now globally',
            color: AppTheme.warning,
          ),
        ),

        trendingAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: SizedBox(
              height: 230,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryLight),
              ),
            ),
          ),
          error: (_, __) => const SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: Center(
                child: Text('Failed to load',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
          ),
          data: (movies) => SliverToBoxAdapter(
            child: SizedBox(
              height: 230,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: movies.length,
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: MovieTrendingCard(
                      movie: movie,
                      onTap: () => Navigator.push(
                        context,
                        _fadeRoute(MovieDetailScreen(movie: movie)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── Now Playing section ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: _SectionHeader(
              icon: Icons.play_circle_outline_rounded,
              title: 'Now Playing',
              color: AppTheme.secondary,
            ),
          ),
        ),

        nowPlayingAsync.when(
          loading: () => const SliverFillRemaining(
            child: ShimmerLoader(type: ShimmerType.movieCard, count: 4),
          ),
          error: (_, __) => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Failed to load',
                    style: TextStyle(color: AppTheme.textMuted)),
              ),
            ),
          ),
          data: (movies) => SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList.separated(
              itemCount: movies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final movie = movies[index];
                return MovieListCard(
                  movie: movie,
                  index: index,
                  onTap: () => Navigator.push(
                    context,
                    _fadeRoute(MovieDetailScreen(movie: movie)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// ── Theatre Movie Card (with Tamil badge) ────────────────────────────────────
class _TheatreMovieCard extends StatefulWidget {
  final Movie movie;
  final int index;
  final VoidCallback? onTap;

  const _TheatreMovieCard({
    required this.movie,
    required this.index,
    this.onTap,
  });

  @override
  State<_TheatreMovieCard> createState() => _TheatreMovieCardState();
}

class _TheatreMovieCardState extends State<_TheatreMovieCard>
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

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFF1C0E2E), Color(0xFF110A22)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Poster
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(20)),
                      child: SizedBox(
                        width: 90,
                        height: double.infinity,
                        child: movie.posterUrl.isNotEmpty
                            ? Image.network(
                                movie.posterUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _posterPlaceholder(movie.title),
                              )
                            : _posterPlaceholder(movie.title),
                      ),
                    ),
                    // Tamil badge
                    Positioned(
                      top: 8,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'TN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
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
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '🎭 Theatre',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFFF6B6B),
                                  fontWeight: FontWeight.w600,
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

  Widget _posterPlaceholder(String title) {
    return Container(
      color: AppTheme.cardBgLight,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_creation_outlined,
                color: AppTheme.textMuted, size: 28),
            const SizedBox(height: 4),
            Text(
              title.substring(0, title.length > 6 ? 6 : title.length),
              style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── OTT Movie Card (with platform badge) ─────────────────────────────────────
class _OttMovieCard extends StatefulWidget {
  final Movie movie;
  final int index;
  final VoidCallback? onTap;

  const _OttMovieCard({
    required this.movie,
    required this.index,
    this.onTap,
  });

  @override
  State<_OttMovieCard> createState() => _OttMovieCardState();
}

class _OttMovieCardState extends State<_OttMovieCard>
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

  Color get _platformColor {
    switch (widget.movie.ottPlatform) {
      case 'Netflix':
        return const Color(0xFFE50914);
      case 'Prime Video':
        return const Color(0xFF00A8E0);
      case 'Disney+':
        return const Color(0xFF113CCF);
      case 'Apple TV+':
        return const Color(0xFF555555);
      default:
        return AppTheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final platform = movie.ottPlatform ?? 'Streaming';
    final color = _platformColor;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.12),
                  const Color(0xFF0D0D22),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: color.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Poster
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(20)),
                      child: SizedBox(
                        width: 90,
                        height: double.infinity,
                        child: movie.posterUrl.isNotEmpty
                            ? Image.network(
                                movie.posterUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _posterPlaceholder(movie.title, color),
                              )
                            : _posterPlaceholder(movie.title, color),
                      ),
                    ),
                  ],
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
                            const SizedBox(width: 10),
                            // OTT platform badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '📺 $platform',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: color,
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

  Widget _posterPlaceholder(String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), AppTheme.cardBgLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline_rounded, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              title.substring(0, title.length > 6 ? 6 : title.length),
              style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 9,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Banner ───────────────────────────────────────────────────────────
class _SectionBanner extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SectionBanner({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.14),
              color.withOpacity(0.04),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color.withOpacity(0.85),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header (compact, for sub-sections) ────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

// ── Error state widget ────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
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
