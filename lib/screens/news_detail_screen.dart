import 'package:flutter/material.dart';
import '../models/news_article.dart';
import '../widgets/gradient_app_bar.dart';

class NewsDetailScreen extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(title: article.titre),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.imageUrl != null)
              Image.network(
                article.imageUrl!,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 220,
                  color: Colors.grey.shade200,
                  child:
                      const Icon(Icons.article, size: 60, color: Colors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.categorie != null && article.categorie!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        article.categorie!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    article.titre,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (article.auteurNom != null) ...[
                        const Icon(Icons.person, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          article.auteurNom!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (article.datePublication != null) ...[
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(article.datePublication!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (article.resume != null && article.resume!.isNotEmpty) ...[
                    Text(
                      article.resume!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    article.contenu,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
