import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/movie.dart';
import '../providers/bookmark_provider.dart';

class BookmarkButton extends ConsumerStatefulWidget {
  final bool isNews;
  final String? newsId;
  final String? newsTitle;
  final int? movieId;
  final Movie? movie;
  final double size;

  const BookmarkButton.news({
    super.key,
    required String newsId,
    String? newsTitle,
    this.size = 20,
  })  : isNews = true,
        newsId = newsId,
        newsTitle = newsTitle,
        movieId = null,
        movie = null;

  const BookmarkButton.movie({
    super.key,
    required int movieId,
    Movie? movie,
    this.size = 20,
  })  : isNews = false,
        newsId = null,
        newsTitle = null,
        movieId = movieId,
        movie = movie;

  @override
  ConsumerState<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends ConsumerState<BookmarkButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward(from: 0);
    if (widget.isNews) {
      ref
          .read(bookmarkProvider.notifier)
          .toggleNews(widget.newsId!, articleTitle: widget.newsTitle);
    } else {
      ref
          .read(bookmarkProvider.notifier)
          .toggleMovie(widget.movieId!, movie: widget.movie);
    }
  }

  bool _isBookmarked(BookmarkState state) {
    if (widget.isNews) return state.isNewsBookmarked(widget.newsId!);
    return state.isMovieBookmarked(widget.movieId!);
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkState = ref.watch(bookmarkProvider);
    final isBookmarked = _isBookmarked(bookmarkState);

    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          width: widget.size + 16,
          height: widget.size + 16,
          decoration: BoxDecoration(
            color: isBookmarked
                ? AppTheme.primary.withOpacity(0.2)
                : Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            color: isBookmarked ? AppTheme.accent : AppTheme.textMuted,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
