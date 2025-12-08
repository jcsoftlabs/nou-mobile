class Podcast {
  final int id;
  final String titre;
  final String description;
  final String audioUrl;
  final String? imageUrl;
  final String duree;
  final DateTime datePublication;
  final bool estEnDirect;
  final String? auteur;
  final int? nombreEcoutes;
  final String? liveUrl;

  Podcast({
    required this.id,
    required this.titre,
    required this.description,
    required this.audioUrl,
    this.imageUrl,
    required this.duree,
    required this.datePublication,
    this.estEnDirect = false,
    this.auteur,
    this.nombreEcoutes,
    this.liveUrl,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    // Le backend peut renvoyer soit `audio_url`, soit `url_audio`, et pour l'image
    // soit `image_url`, soit `img_couverture_url`. Les lives utilisent `url_live`.
    final audio = (json['audio_url'] ?? json['url_audio'] ?? '').toString();
    final image = (json['image_url'] ?? json['img_couverture_url']);
    final live = json['url_live']?.toString();

    // Convertir duree_en_secondes en format HH:MM:SS ou MM:SS
    String formatDuree(int? seconds) {
      if (seconds == null || seconds == 0) return '00:00';
      final duration = Duration(seconds: seconds);
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final secs = duration.inSeconds.remainder(60);
      
      if (hours > 0) {
        return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
      }
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return Podcast(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      audioUrl: audio,
      imageUrl: image,
      duree: json['duree'] ?? formatDuree(json['duree_en_secondes']),
      datePublication: json['date_publication'] != null
          ? DateTime.parse(json['date_publication'])
          : DateTime.now(),
      estEnDirect: json['est_en_direct'] ?? false,
      auteur: json['auteur'],
      nombreEcoutes: json['nombre_ecoutes'],
      liveUrl: live,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      // on renvoie avec les clés attendues côté API moderne
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'duree': duree,
      'date_publication': datePublication.toIso8601String(),
      'est_en_direct': estEnDirect,
      'auteur': auteur,
      'nombre_ecoutes': nombreEcoutes,
      'url_live': liveUrl,
    };
  }
}
