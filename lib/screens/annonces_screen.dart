import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/annonce.dart';
import '../services/api_service.dart';
import '../widgets/gradient_app_bar.dart';

class AnnoncesScreen extends StatefulWidget {
  const AnnoncesScreen({super.key});

  @override
  State<AnnoncesScreen> createState() => _AnnoncesScreenState();
}

class _AnnoncesScreenState extends State<AnnoncesScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Annonce> _annonces = [];

  @override
  void initState() {
    super.initState();
    _loadAnnonces();
  }

  Future<void> _loadAnnonces() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getAnnoncesActives();

    if (!mounted) return;

    if (result['success'] == true) {
      final annonces = (result['data'] as List<Annonce>?) ?? <Annonce>[];
      setState(() {
        _annonces = annonces;
        _isLoading = false;
      });

      // Marquer les annonces comme lues (dernière vue)
      if (annonces.isNotEmpty) {
        final latestId = annonces.map((a) => a.id).reduce(max);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_seen_annonce_id', latestId);
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur de chargement des annonces')),
      );
    }
  }

  Color _priorityColor(String priorite) {
    switch (priorite) {
      case 'urgent':
        return Colors.red.shade600;
      case 'important':
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Annonces',
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnnonces,
              child: _annonces.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'Aucune annonce active pour le moment',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _annonces.length,
                      itemBuilder: (context, index) {
                        final annonce = _annonces[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        annonce.titre,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _priorityColor(annonce.priorite)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        annonce.priorite.toUpperCase(),
                                        style: TextStyle(
                                          color: _priorityColor(annonce.priorite),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  annonce.message,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (annonce.auteurNom != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.person,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            annonce.auteurNom!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (annonce.datePublication != null)
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today,
                                              size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(annonce.datePublication!),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
