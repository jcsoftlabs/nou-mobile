import 'quiz.dart';

class SupplementaryFile {
  final String type;
  final String url;
  final String nom;

  SupplementaryFile({
    required this.type,
    required this.url,
    required this.nom,
  });

  factory SupplementaryFile.fromJson(Map<String, dynamic> json) {
    return SupplementaryFile(
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      nom: json['nom'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'url': url,
      'nom': nom,
    };
  }
}

class FormationModule {
  final int id;
  final int formationId;
  final String titre;
  final String? description;
  final int ordre;
  final String? typeContenu; // 'texte', 'video', 'image', 'mixte'
  final String? contenuTexte;
  final String? imageUrl;
  final String? videoUrl;
  final String? fichierPdfUrl;
  final String? fichierPptUrl;
  final List<SupplementaryFile>? fichiersSupplementaires;
  final List<Quiz>? quizzes;

  FormationModule({
    required this.id,
    required this.formationId,
    required this.titre,
    this.description,
    this.ordre = 0,
    this.typeContenu,
    this.contenuTexte,
    this.imageUrl,
    this.videoUrl,
    this.fichierPdfUrl,
    this.fichierPptUrl,
    this.fichiersSupplementaires,
    this.quizzes,
  });

  factory FormationModule.fromJson(Map<String, dynamic> json) {
    return FormationModule(
      id: json['id'] ?? 0,
      formationId: json['formation_id'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'],
      ordre: json['ordre'] ?? 0,
      typeContenu: json['type_contenu'],
      contenuTexte: json['contenu_texte'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      fichierPdfUrl: json['fichier_pdf_url'],
      fichierPptUrl: json['fichier_ppt_url'],
      fichiersSupplementaires: json['fichiers_supplementaires'] != null
          ? (json['fichiers_supplementaires'] as List)
              .map((f) => SupplementaryFile.fromJson(f))
              .toList()
          : null,
      quizzes: json['quizzes'] != null
          ? (json['quizzes'] as List)
              .map((q) => Quiz.fromJson(q))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'formation_id': formationId,
      'titre': titre,
      'description': description,
      'ordre': ordre,
      'type_contenu': typeContenu,
      'contenu_texte': contenuTexte,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'fichier_pdf_url': fichierPdfUrl,
      'fichier_ppt_url': fichierPptUrl,
      'fichiers_supplementaires': fichiersSupplementaires?.map((f) => f.toJson()).toList(),
      'quizzes': quizzes?.map((q) => q.toJson()).toList(),
    };
  }

  // Helper pour vérifier si le module a du contenu multimédia
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasPdf => fichierPdfUrl != null && fichierPdfUrl!.isNotEmpty;
  bool get hasPpt => fichierPptUrl != null && fichierPptUrl!.isNotEmpty;
  bool get hasSupplementaryFiles => fichiersSupplementaires != null && fichiersSupplementaires!.isNotEmpty;
  bool get hasQuizzes => quizzes != null && quizzes!.isNotEmpty;
  bool get hasDownloadableFiles => hasPdf || hasPpt || hasSupplementaryFiles;
}
