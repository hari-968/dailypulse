import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/movie.dart';
import '../../providers/movie_provider.dart';
import '../../widgets/bookmark_button.dart';

class MovieDetailScreen extends ConsumerStatefulWidget {
  final Movie movie;

  const MovieDetailScreen({super.key, required this.movie});

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _contentAnim;

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentAnim = CurvedAnimation(
        parent: _contentController, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _openTrailer(String key) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=$key');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final trailerAsync = ref.watch(trailerKeyProvider(movie.id));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // ── Backdrop header ──
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.surface,
            leading: _BackButton(),
            actions: [
              // ── Share Button ──
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.share_rounded, size: 22, color: Colors.white),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(
                      text: "Check out ${movie.title} (${movie.year}) on DailyPulse!",
                    ));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Title copied to clipboard!'),
                          backgroundColor: AppTheme.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              // ── Bookmark Button ──
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: BookmarkButton.movie(movieId: movie.id, size: 22),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Backdrop / fallback gradient
                  movie.backdropUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: movie.backdropUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const _GradientPlaceholder(),
                        )
                      : const _GradientPlaceholder(),

                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          AppTheme.background.withOpacity(0.7),
                          AppTheme.background,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // Rating badge bottom-left
                  Positioned(
                    bottom: 16,
                    left: 20,
                    child: _RatingBadge(rating: movie.ratingText),
                  ),
                ],
              ),
            ),
          ),

          // ── Content ──
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _contentAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(_contentAnim),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + year
                      Text(
                        movie.title,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              height: 1.3,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (movie.year.isNotEmpty) ...[
                            const Icon(Icons.calendar_today_rounded,
                                color: AppTheme.textMuted, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              movie.year,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.textMuted),
                            ),
                            const SizedBox(width: 14),
                          ],
                          const Icon(Icons.how_to_vote_rounded,
                              color: AppTheme.textMuted, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatVotes(movie.voteCount)} votes',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                      
                      // ── OTT Platform Badge (if any) ──
                      if (movie.ottPlatform != null && movie.ottPlatform!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.live_tv_rounded, 
                                  color: AppTheme.primaryLight, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Streaming on ${movie.ottPlatform}',
                                style: TextStyle(
                                  color: AppTheme.primaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),

                      // Divider
                      Divider(color: AppTheme.divider, height: 1),
                      const SizedBox(height: 22),

                      // Overview
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        movie.overview,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),

                      // Trailer button
                      trailerAsync.when(
                        loading: () => _OutlineButton(
                          icon: Icons.hourglass_empty_rounded,
                          label: 'Loading trailer…',
                          onTap: null,
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (key) => key != null
                            ? _TrailerButton(
                                onTap: () => _openTrailer(key))
                            : _OutlineButton(
                                icon: Icons.play_disabled_rounded,
                                label: 'Trailer unavailable',
                                onTap: null,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVotes(int votes) {
    if (votes >= 1000) return '${(votes / 1000).toStringAsFixed(1)}K';
    return votes.toString();
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 16),
        ),
      ),
    );
  }
}

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0533), Color(0xFF0D1144)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.movie_creation_outlined,
            color: AppTheme.textMuted, size: 64),
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final String rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.ratingGold.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded,
              color: AppTheme.ratingGold, size: 16),
          const SizedBox(width: 4),
          Text(
            rating,
            style: const TextStyle(
              color: AppTheme.ratingGold,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Text(
            '/10',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TrailerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.play_circle_filled_rounded, size: 22),
          label: const Text('Watch Trailer on YouTube'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textMuted,
          side: BorderSide(color: AppTheme.divider),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
