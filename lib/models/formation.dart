import 'formation_module.dart';

class Formation {
  final int id;
  final String titre;
  final String? description;
  final String? niveau;
  final String? imageCouvertureUrl;
  final bool estActive;
  final DateTime datePublication;
  final List<FormationModule>? modules;

  Formation({
    required this.id,
    required this.titre,
    this.description,
    this.niveau,
    this.imageCouvertureUrl,
    this.estActive = true,
    required this.datePublication,
    this.modules,
  });

  factory Formation.fromJson(Map<String, dynamic> json) {
    return Formation(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'],
      niveau: json['niveau'],
      imageCouvertureUrl: json['image_couverture_url'],
      estActive: json['est_active'] ?? true,
      datePublication: json['date_publication'] != null
          ? DateTime.parse(json['date_publication'])
          : DateTime.now(),
      modules: json['modules'] != null
          ? (json['modules'] as List)
              .map((m) => FormationModule.fromJson(m))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'niveau': niveau,
      'image_couverture_url': imageCouvertureUrl,
      'est_active': estActive,
      'date_publication': datePublication.toIso8601String(),
      'modules': modules?.map((m) => m.toJson()).toList(),
    };
  }

  // Helper pour compter les modules
  int get nombreModules => modules?.length ?? 0;

  // Helper pour compter les quiz totaux
  int get nombreQuizTotal {
    if (modules == null) return 0;
    return modules!.fold(0, (sum, module) => sum + (module.quizzes?.length ?? 0));
  }
}
