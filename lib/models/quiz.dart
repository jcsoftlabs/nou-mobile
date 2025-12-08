class Quiz {
  final int id;
  final String titre;
  final String? description;
  final DateTime? datePublication;
  final DateTime? dateExpiration;
  final int? moduleId;

  Quiz({
    required this.id,
    required this.titre,
    this.description,
    this.datePublication,
    this.dateExpiration,
    this.moduleId,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'],
      datePublication: json['date_publication'] != null
          ? DateTime.parse(json['date_publication'])
          : null,
      dateExpiration: json['date_expiration'] != null
          ? DateTime.parse(json['date_expiration'])
          : null,
      moduleId: json['module_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'date_publication': datePublication?.toIso8601String(),
      'date_expiration': dateExpiration?.toIso8601String(),
      'module_id': moduleId,
    };
  }

  // Helper pour vérifier si le quiz est actif
  bool get isActive {
    final now = DateTime.now();
    if (dateExpiration == null) return true;
    return dateExpiration!.isAfter(now);
  }
}
