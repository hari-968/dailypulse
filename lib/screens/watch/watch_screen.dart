import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../providers/movie_provider.dart';
import '../../services/video_service.dart';
import '../../widgets/shimmer_loader.dart';

class WatchScreen extends ConsumerWidget {
  const WatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingMoviesProvider);
    final nowPlayingAsync = ref.watch(nowPlayingMoviesProvider);
    final tamilAsync = ref.watch(tamilTheatreMoviesProvider);
    final ottAsync = ref.watch(ottMoviesProvider);

    final allMovies = [
      ...?trendingAsync.valueOrNull,
      ...?nowPlayingAsync.valueOrNull,
      ...?tamilAsync.valueOrNull,
      ...?ottAsync.valueOrNull,
    ];

    final seenIds = <int>{};
    final watchList = allMovies
        .where((movie) => seenIds.add(movie.id))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    final isLoading = trendingAsync.isLoading ||
        nowPlayingAsync.isLoading ||
        tamilAsync.isLoading ||
        ottAsync.isLoading;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppTheme.primaryLight,
        backgroundColor: AppTheme.cardBg,
        onRefresh: () async {
          await Future.wait([
            ref.read(trendingMoviesProvider.notifier).refresh(),
            ref.read(nowPlayingMoviesProvider.notifier).refresh(),
            ref.read(tamilTheatreMoviesProvider.notifier).refresh(),
            ref.read(ottMoviesProvider.notifier).refresh(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(bounds),
                      child: Text(
                        'Watch',
                        style: Theme.of(context)
                            .textTheme
                            .headlineLarge
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trailer picks pulled from the movie feed',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppTheme.cardGradient,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.smart_display_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tap any card to watch a trailer',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'If a direct trailer is not available, DailyPulse opens a YouTube search instead.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(
                      icon: Icons.play_circle_outline_rounded,
                      title: 'Featured trailers',
                      subtitle: 'Trending, theatre, and OTT picks',
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading && watchList.isEmpty)
              const SliverFillRemaining(
                child: ShimmerLoader(type: ShimmerType.movieCard, count: 4),
              )
            else if (watchList.isEmpty)
              SliverFillRemaining(
                child: _EmptyState(
                  onRetry: () async {
                    await Future.wait([
                      ref.read(trendingMoviesProvider.notifier).refresh(),
                      ref.read(nowPlayingMoviesProvider.notifier).refresh(),
                      ref.read(tamilTheatreMoviesProvider.notifier).refresh(),
                      ref.read(ottMoviesProvider.notifier).refresh(),
                    ]);
                  },
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList.separated(
                  itemCount: watchList.length.clamp(0, 12),
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final movie = watchList[index];
                    return _WatchTrailerCard(
                      movie: movie,
                      index: index,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _WatchTrailerCard extends ConsumerStatefulWidget {
  final Movie movie;
  final int index;

  const _WatchTrailerCard({
    required this.movie,
    required this.index,
  });

  @override
  ConsumerState<_WatchTrailerCard> createState() => _WatchTrailerCardState();
}

class _WatchTrailerCardState extends ConsumerState<_WatchTrailerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _isLaunching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 360 + widget.index * 40),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 55), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _watchTrailer() async {
    if (_isLaunching) return;
    setState(() => _isLaunching = true);

    final trailerAsync = ref.read(trailerKeyProvider(widget.movie.id));
    final launched = await VideoService.openMovieTrailer(
      widget.movie,
      trailerKey: trailerAsync.valueOrNull,
    );

    if (!mounted) return;
    setState(() => _isLaunching = false);

    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the video. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final trailerAsync = ref.watch(trailerKeyProvider(movie.id));
    final hasTrailerKey = trailerAsync.valueOrNull != null && trailerAsync.valueOrNull!.isNotEmpty;
    final accentColor = switch (movie.category) {
      MovieCategory.tamilTheatre => const Color(0xFFFF6B6B),
      MovieCategory.hollywoodOtt => const Color(0xFF06B6D4),
      MovieCategory.trending => AppTheme.warning,
    };

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: AppTheme.cardGradient,
            border: Border.all(
              color: accentColor.withOpacity(0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: movie.backdropUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: movie.backdropUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _posterFallback(),
                            )
                          : _posterFallback(),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.75),
                          ],
                          stops: const [0.35, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.72),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppTheme.ratingGold, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            movie.ratingText,
                            style: const TextStyle(
                              color: AppTheme.ratingGold,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: GestureDetector(
                      onTap: (_isLaunching || trailerAsync.isLoading) ? null : _watchTrailer,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isLaunching)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else if (trailerAsync.isLoading)
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Icon(
                                hasTrailerKey
                                    ? Icons.play_arrow_rounded
                                    : Icons.search_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              _isLaunching
                                  ? 'Opening'
                                  : trailerAsync.isLoading
                                      ? 'Loading'
                                      : hasTrailerKey
                                          ? 'Watch trailer'
                                          : 'Search trailer',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(height: 1.25),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      movie.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Tag(label: movie.year.isEmpty ? 'Now' : movie.year),
                        const SizedBox(width: 8),
                        _Tag(label: _categoryLabel(movie)),
                        const Spacer(),
                        Icon(
                          Icons.smart_display_rounded,
                          color: accentColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _posterFallback() {
    return Container(
      color: AppTheme.cardBgLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.smart_display_outlined,
        color: AppTheme.textMuted,
        size: 42,
      ),
    );
  }

  String _categoryLabel(Movie movie) {
    switch (movie.category) {
      case MovieCategory.trending:
        return 'Trending';
      case MovieCategory.tamilTheatre:
        return 'Theatre';
      case MovieCategory.hollywoodOtt:
        return movie.ottPlatform ?? 'OTT';
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBgLight,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.play_circle_outline_rounded,
              color: AppTheme.textMuted,
              size: 58,
            ),
            const SizedBox(height: 14),
            Text(
              'No videos found yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull to refresh or try again after the movie feed loads.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}