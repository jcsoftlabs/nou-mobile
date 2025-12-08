import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../models/podcast.dart';
import '../services/api_service.dart';
import '../services/audio_player_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../constants/api_constants.dart';

class PodcastScreen extends StatefulWidget {
  const PodcastScreen({super.key});

  @override
  State<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  final ApiService _apiService = ApiService();
  
  List<Podcast> _podcasts = [];
  List<int> _favoritePodcastIds = [];
  List<int> _downloadedPodcastIds = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
    _loadFavorites();
    _loadDownloaded();
  }

  Future<void> _loadPodcasts() async {
    setState(() => _isLoading = true);
    
    final result = await _apiService.getPodcasts();
    
    if (mounted) {
      setState(() {
        if (result['success']) {
          _podcasts = result['data'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Erreur de chargement')),
          );
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString('favorite_podcasts');
    if (favoritesJson != null) {
      setState(() {
        _favoritePodcastIds = List<int>.from(jsonDecode(favoritesJson));
      });
    }
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorite_podcasts', jsonEncode(_favoritePodcastIds));
  }

  Future<void> _loadDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    final downloadedJson = prefs.getString('downloaded_podcasts');
    if (downloadedJson != null) {
      setState(() {
        _downloadedPodcastIds = List<int>.from(jsonDecode(downloadedJson));
      });
    }
  }

  Future<void> _saveDownloaded() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('downloaded_podcasts', jsonEncode(_downloadedPodcastIds));
  }

  void _toggleFavorite(int podcastId) {
    setState(() {
      if (_favoritePodcastIds.contains(podcastId)) {
        _favoritePodcastIds.remove(podcastId);
      } else {
        _favoritePodcastIds.add(podcastId);
      }
    });
    _saveFavorites();
  }

  Future<void> _downloadPodcast(Podcast podcast) async {
    // Simuler un téléchargement
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Téléchargement de "${podcast.titre}" en cours...'),
        duration: const Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      if (!_downloadedPodcastIds.contains(podcast.id)) {
        _downloadedPodcastIds.add(podcast.id);
      }
    });
    _saveDownloaded();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${podcast.titre}" téléchargé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _playPodcast(Podcast podcast) async {
    try {
      // Gestion des lives: si URL live (souvent YouTube), on ouvre dans le navigateur/app
      if (podcast.estEnDirect && (podcast.liveUrl != null && podcast.liveUrl!.isNotEmpty)) {
        final uri = Uri.tryParse(podcast.liveUrl!);
        if (uri != null) {
          final can = await canLaunchUrl(uri);
          if (can) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            return;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Impossible d'ouvrir le live.")),
          );
        }
        return;
      }

      // Utiliser le service audio global
      final audioService = Provider.of<AudioPlayerService>(context, listen: false);
      await audioService.playPodcast(podcast);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de lecture: $e')),
        );
      }
    }
  }

  Widget _buildLiveSection() {
    final livePodcast = _podcasts.firstWhere(
      (p) => p.estEnDirect,
      orElse: () => _podcasts.isEmpty ? Podcast(
        id: 0,
        titre: '',
        description: '',
        audioUrl: '',
        duree: '',
        datePublication: DateTime.now(),
      ) : _podcasts.first,
    );

    if (!livePodcast.estEnDirect) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.red, Colors.redAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'EN DIRECT',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  livePodcast.titre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  livePodcast.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Consumer<AudioPlayerService>(
                  builder: (context, audioService, _) {
                    final isPlaying = audioService.currentPodcast?.id == livePodcast.id && audioService.isPlaying;
                    return ElevatedButton.icon(
                      onPressed: () => _playPodcast(livePodcast),
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                      label: Text(isPlaying ? 'Pause' : 'Écouter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodcastList() {
    final regularPodcasts = _podcasts.where((p) => !p.estEnDirect).toList();

    if (regularPodcasts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'Aucun épisode disponible',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: regularPodcasts.length,
      itemBuilder: (context, index) {
        final podcast = regularPodcasts[index];
        final isFavorite = _favoritePodcastIds.contains(podcast.id);
        final isDownloaded = _downloadedPodcastIds.contains(podcast.id);

        return Consumer<AudioPlayerService>(
          builder: (context, audioService, _) {
            final isCurrentlyPlaying = audioService.currentPodcast?.id == podcast.id;
            final isPlaying = isCurrentlyPlaying && audioService.isPlaying;

            return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isCurrentlyPlaying
                ? const BorderSide(color: Colors.red, width: 2)
                : BorderSide.none,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: podcast.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      podcast.imageUrl!.startsWith('/')
                          ? ApiConstants.baseUrl + podcast.imageUrl!
                          : podcast.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultPodcastImage(),
                    ),
                  )
                : _buildDefaultPodcastImage(),
            title: Text(
              podcast.titre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  podcast.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      podcast.duree,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (podcast.auteur != null) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.person, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          podcast.auteur!,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: () => _toggleFavorite(podcast.id),
                ),
                IconButton(
                  icon: Icon(
                    isDownloaded ? Icons.download_done : Icons.download,
                    color: isDownloaded ? Colors.green : Colors.grey,
                  ),
                  onPressed: isDownloaded
                      ? null
                      : () => _downloadPodcast(podcast),
                ),
                IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle
                        : Icons.play_circle,
                    color: Colors.red,
                    size: 32,
                  ),
                  onPressed: () => _playPodcast(podcast),
                ),
              ],
            ),
          ),
            );
          },
        );
      },
    );
  }

  Widget _buildDefaultPodcastImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.mic,
        color: Colors.red,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Podcasts',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Action pour filtrer (favoris, téléchargés, etc.)
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.favorite, color: Colors.red),
                        title: const Text('Voir les favoris'),
                        onTap: () {
                          Navigator.pop(context);
                          // Implémenter le filtre des favoris
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.download, color: Colors.green),
                        title: const Text('Voir les téléchargements'),
                        onTap: () {
                          Navigator.pop(context);
                          // Implémenter le filtre des téléchargements
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPodcasts,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLiveSection(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Tous les épisodes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildPodcastList(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
