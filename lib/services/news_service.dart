import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../models/news_article.dart';

class NewsService {
  Future<List<NewsArticle>> fetchTopHeadlines({
    String country = 'us',
    int pageSize = 10,
  }) async {
    // If placeholder key, return mock data
    if (AppConstants.newsApiKey == 'YOUR_NEWS_API_KEY') {
      return _mockArticles();
    }

    final uri = Uri.parse(
      '${AppConstants.newsBaseUrl}/top-headlines'
      '?country=$country'
      '&pageSize=$pageSize'
      '&apiKey=${AppConstants.newsApiKey}',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final articles = (data['articles'] as List<dynamic>? ?? [])
            .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
            .where((a) => a.title.isNotEmpty && a.title != '[Removed]')
            .toList();
        return articles.isEmpty ? _mockArticles() : articles;
      }
      return _mockArticles();
    } catch (_) {
      return _mockArticles();
    }
  }

  static List<NewsArticle> _mockArticles() {
    final now = DateTime.now();
    return [
      NewsArticle(
        id: '1',
        title: 'Global AI Summit Reaches Historic Agreement on Safety Standards',
        summary:
            'World leaders and tech giants signed a landmark AI safety framework at the annual Global AI Summit, pledging to implement independent audits and shared risk protocols across frontier model development.',
        imageUrl: 'https://images.unsplash.com/photo-1677442135703-1787eea5ce01?w=800',
        source: 'TechCrunch',
        publishedAt: now.subtract(const Duration(hours: 1)).toIso8601String(),
        url: 'https://techcrunch.com',
        whyItMatters: 'AI governance frameworks will shape how the technology impacts jobs, security, and civil liberties globally.',
      ),
      NewsArticle(
        id: '2',
        title: 'Federal Reserve Signals Three Rate Cuts Ahead as Inflation Eases',
        summary:
            'The Federal Reserve indicated it expects three interest rate cuts in the coming year after new data showed inflation cooling to its lowest level in three years, boosting markets worldwide.',
        imageUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=800',
        source: 'Reuters',
        publishedAt: now.subtract(const Duration(hours: 2)).toIso8601String(),
        url: 'https://reuters.com',
        whyItMatters: 'Lower rates mean cheaper mortgages, loans, and business credit — directly benefiting households and small businesses.',
      ),
      NewsArticle(
        id: '3',
        title: 'NASA\'s Artemis Mission Successfully Lands Astronauts Near Lunar South Pole',
        summary:
            'NASA\'s Artemis program achieved a historic milestone as astronauts safely landed near the lunar south pole, marking the first crewed moon landing in over 50 years and opening the door to permanent lunar habitation.',
        imageUrl: 'https://images.unsplash.com/photo-1614728894747-a83421e2b9c9?w=800',
        source: 'NASA News',
        publishedAt: now.subtract(const Duration(hours: 3)).toIso8601String(),
        url: 'https://nasa.gov',
        whyItMatters: 'Lunar exploration advances science, inspires innovation, and could enable resources that support future deep-space missions to Mars.',
      ),
      NewsArticle(
        id: '4',
        title: 'Climate Scientists Warn Arctic Ice Loss Accelerating Faster Than Predicted',
        summary:
            'A new report from international climate researchers shows Arctic sea ice is disappearing 40% faster than models projected, with cascading effects on global weather patterns and coastal communities.',
        imageUrl: 'https://images.unsplash.com/photo-1562607635-4608ff48a859?w=800',
        source: 'The Guardian',
        publishedAt: now.subtract(const Duration(hours: 4)).toIso8601String(),
        url: 'https://theguardian.com',
        whyItMatters: 'Faster ice loss means rising sea levels and more extreme weather, affecting billions of people worldwide within decades.',
      ),
      NewsArticle(
        id: '5',
        title: 'Apple Unveils Vision Pro 2 with 8K Displays and All-Day Battery Life',
        summary:
            'Apple announced the second generation Vision Pro at its annual Worldwide Developers Conference, featuring dual 8K micro-OLED displays, a thinner form factor, and a claimed 12-hour battery life.',
        imageUrl: 'https://images.unsplash.com/photo-1491933382434-500287f9b54b?w=800',
        source: 'The Verge',
        publishedAt: now.subtract(const Duration(hours: 5)).toIso8601String(),
        url: 'https://theverge.com',
        whyItMatters: 'Improvements in spatial computing hardware accelerate mainstream adoption of AR/VR across work, health, and entertainment.',
      ),
      NewsArticle(
        id: '6',
        title: 'Breakthrough Cancer Therapy Shows 90% Remission Rate in Trial',
        summary:
            'A novel mRNA-based personalised cancer therapy demonstrated a 90% complete remission rate in a Phase III trial across multiple cancer types, offering hope for a transformative new treatment category.',
        imageUrl: 'https://images.unsplash.com/photo-1576671081837-49000212a370?w=800',
        source: 'Nature Medicine',
        publishedAt: now.subtract(const Duration(hours: 6)).toIso8601String(),
        url: 'https://nature.com',
        whyItMatters: 'Effective universal cancer therapies could save millions of lives annually and fundamentally change oncology treatment protocols.',
      ),
      NewsArticle(
        id: '7',
        title: 'India\'s Economy Surpasses Japan to Become World\'s Third Largest',
        summary:
            'International Monetary Fund data confirms India has overtaken Japan to become the world\'s third-largest economy by nominal GDP, driven by robust manufacturing growth and a surging services sector.',
        imageUrl: 'https://images.unsplash.com/photo-1532375810709-75b1da00537c?w=800',
        source: 'Bloomberg',
        publishedAt: now.subtract(const Duration(hours: 8)).toIso8601String(),
        url: 'https://bloomberg.com',
        whyItMatters: 'India\'s rise reshapes global trade flows, investment patterns, and geopolitical power dynamics for decades ahead.',
      ),
      NewsArticle(
        id: '8',
        title: 'OpenAI Launches GPT-5 with Real-Time Reasoning and Multimodal Capabilities',
        summary:
            'OpenAI released GPT-5 to the public, featuring enhanced logical reasoning, real-time internet access, and native video understanding — marking a major leap beyond previous language model benchmarks.',
        imageUrl: 'https://images.unsplash.com/photo-1668790516767-8d7e1200b434?w=800',
        source: 'Wired',
        publishedAt: now.subtract(const Duration(hours: 9)).toIso8601String(),
        url: 'https://wired.com',
        whyItMatters: 'Each new AI generation fundamentally shifts how people work, learn, and access information globally.',
      ),
      NewsArticle(
        id: '9',
        title: 'Self-Driving Trucks Now Operate on Major US Highways Without Safety Drivers',
        summary:
            'The NHTSA approved fully autonomous commercial trucking on interstate highways, with Waymo Via and Aurora deploying driverless freight trucks across Texas, Arizona, and California corridors.',
        imageUrl: 'https://images.unsplash.com/photo-1519003722824-194d4455a60c?w=800',
        source: 'Ars Technica',
        publishedAt: now.subtract(const Duration(hours: 11)).toIso8601String(),
        url: 'https://arstechnica.com',
        whyItMatters: 'Autonomous freight could slash logistics costs and reshape 3.5 million trucking jobs over the next decade.',
      ),
      NewsArticle(
        id: '10',
        title: 'WHO Declares End to Global Mpox Health Emergency',
        summary:
            'The World Health Organization officially declared the end of mpox as a Public Health Emergency of International Concern after sustained global vaccination efforts brought case counts to record lows.',
        imageUrl: 'https://images.unsplash.com/photo-1584467735815-f778f274e296?w=800',
        source: 'WHO',
        publishedAt: now.subtract(const Duration(hours: 12)).toIso8601String(),
        url: 'https://who.int',
        whyItMatters: 'Controlling infectious disease outbreaks protects global health security and enables economies to function without disruption.',
      ),
    ];
  }
}
