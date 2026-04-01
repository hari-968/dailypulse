import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../models/movie.dart';
import '../widgets/bookmark_button.dart';

// ── Vertical movie card (list view) ─────────────────────────────────────────
class MovieListCard extends StatefulWidget {
  final Movie movie;
  final int index;
  final VoidCallback? onTap;

  const MovieListCard({
    super.key,
    required this.movie,
    required this.index,
    this.onTap,
  });

  @override
  State<MovieListCard> createState() => _MovieListCardState();
}

class _MovieListCardState extends State<MovieListCard>
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

    Future.delayed(Duration(milliseconds: widget.index * 50), () {
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
                color: Colors.white.withOpacity(0.06),
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
                    child: widget.movie.posterUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.movie.posterUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppTheme.cardBgLight,
                              child: const Icon(Icons.movie_outlined,
                                  color: AppTheme.textMuted),
                            ),
                            errorWidget: (_, __, ___) => _posterPlaceholder(),
                          )
                        : _posterPlaceholder(),
                  ),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.movie.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(height: 1.3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            BookmarkButton.movie(movieId: widget.movie.id, movie: widget.movie),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded,
                                color: AppTheme.ratingGold, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              widget.movie.ratingText,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                      color: AppTheme.ratingGold,
                                      fontWeight: FontWeight.w700),
                            ),
                            if (widget.movie.year.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              const Icon(Icons.calendar_today_rounded,
                                  color: AppTheme.textMuted, size: 11),
                              const SizedBox(width: 3),
                              Text(
                                widget.movie.year,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.movie.overview,
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

  Widget _posterPlaceholder() {
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
              widget.movie.title.substring(
                  0, widget.movie.title.length > 6 ? 6 : widget.movie.title.length),
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

// ── Horizontal trending card (carousel) ────────────────────────────────────
class MovieTrendingCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  const MovieTrendingCard({
    super.key,
    required this.movie,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster image
              movie.posterUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: movie.posterUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: AppTheme.cardBgLight),
                      errorWidget: (_, __, ___) =>
                          _trendingPlaceholder(movie.title),
                    )
                  : _trendingPlaceholder(movie.title),

              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
              ),

              // Rating badge
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: AppTheme.ratingGold, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        movie.ratingText,
                        style: const TextStyle(
                          color: AppTheme.ratingGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title + year
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 0, 9, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          shadows: [
                            Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 1))
                          ],
                        ),
                      ),
                      if (movie.year.isNotEmpty)
                        Text(
                          movie.year,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trendingPlaceholder(String title) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.cardGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_creation_outlined,
                color: AppTheme.textMuted, size: 36),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
