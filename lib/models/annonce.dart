class Annonce {
  final int id;
  final String titre;
  final String message;
  final String priorite; // info, important, urgent
  final String statut; // brouillon, publie, archive
  final DateTime? datePublication;
  final DateTime? dateExpiration;
  final String? auteurNom;

  Annonce({
    required this.id,
    required this.titre,
    required this.message,
    required this.priorite,
    required this.statut,
    this.datePublication,
    this.dateExpiration,
    this.auteurNom,
  });

  factory Annonce.fromJson(Map<String, dynamic> json) {
    final auteur = json['auteur'];
    String? auteurNom;
    if (auteur != null) {
      final prenom = auteur['prenom'] ?? '';
      final nom = auteur['nom'] ?? '';
      auteurNom = ('$prenom $nom').trim();
      if (auteurNom.isEmpty) auteurNom = null;
    }

    return Annonce(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      priorite: json['priorite'] ?? 'info',
      statut: json['statut'] ?? 'brouillon',
      datePublication: json['date_publication'] != null
          ? DateTime.tryParse(json['date_publication'])
          : null,
      dateExpiration: json['date_expiration'] != null
          ? DateTime.tryParse(json['date_expiration'])
          : null,
      auteurNom: auteurNom,
    );
  }
}
