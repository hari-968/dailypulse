class NewsArticle {
  final String id;
  final String title;
  final String summary;
  final String? imageUrl;
  final String source;
  final String publishedAt;
  final String url;
  final String whyItMatters;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.summary,
    this.imageUrl,
    required this.source,
    required this.publishedAt,
    required this.url,
    required this.whyItMatters,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as String?)?.trim() ?? 'No Title';
    final description = (json['description'] as String?)?.trim() ??
        (json['content'] as String?)?.trim() ??
        'No summary available.';

    return NewsArticle(
      id: json['url'] as String? ?? DateTime.now().toString(),
      title: title,
      summary: description.length > 200
          ? '${description.substring(0, 200)}…'
          : description,
      imageUrl: json['urlToImage'] as String?,
      source: (json['source'] as Map<String, dynamic>?)?['name'] as String? ??
          'Unknown Source',
      publishedAt: json['publishedAt'] as String? ?? '',
      url: json['url'] as String? ?? '',
      whyItMatters: _generateWhyItMatters(title, description),
    );
  }

  static String _generateWhyItMatters(String title, String description) {
    final lower = title.toLowerCase();
    if (lower.contains('economy') || lower.contains('gdp') || lower.contains('market')) {
      return 'Economic shifts affect jobs, prices, and financial stability worldwide.';
    } else if (lower.contains('climate') || lower.contains('environment') || lower.contains('carbon')) {
      return 'Climate decisions made today shape the planet future generations will inherit.';
    } else if (lower.contains('ai') || lower.contains('tech') || lower.contains('artificial')) {
      return 'Rapid AI advances are redefining industries, privacy, and how we work.';
    } else if (lower.contains('health') || lower.contains('covid') || lower.contains('disease')) {
      return 'Public health developments directly impact communities and healthcare systems.';
    } else if (lower.contains('election') || lower.contains('politi') || lower.contains('govern')) {
      return 'Political decisions shape policies that affect millions of lives.';
    } else {
      return 'Staying informed on key events helps you make better personal and professional decisions.';
    }
  }

  NewsArticle copyWith({bool? isBookmarked}) => NewsArticle(
        id: id,
        title: title,
        summary: summary,
        imageUrl: imageUrl,
        source: source,
        publishedAt: publishedAt,
        url: url,
        whyItMatters: whyItMatters,
      );
}
