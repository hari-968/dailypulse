import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_article.dart';
import '../services/news_service.dart';

// Service provider
final newsServiceProvider = Provider<NewsService>((ref) => NewsService());

// News list provider
final newsProvider =
    AsyncNotifierProvider<NewsNotifier, List<NewsArticle>>(NewsNotifier.new);

class NewsNotifier extends AsyncNotifier<List<NewsArticle>> {
  @override
  Future<List<NewsArticle>> build() async {
    return ref.read(newsServiceProvider).fetchTopHeadlines();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(newsServiceProvider).fetchTopHeadlines(),
    );
  }
}
