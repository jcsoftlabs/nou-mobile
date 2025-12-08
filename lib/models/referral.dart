class Referral {
  final int id;
  final int filleulId;
  final int parrainId;
  final DateTime dateParrainage;
  final int pointsAttribues;
  final String? filleulNom;
  final String? filleulPrenom;
  final String? filleulUsername;
  final String? filleulCodeAdhesion;

  Referral({
    required this.id,
    required this.filleulId,
    required this.parrainId,
    required this.dateParrainage,
    this.pointsAttribues = 0,
    this.filleulNom,
    this.filleulPrenom,
    this.filleulUsername,
    this.filleulCodeAdhesion,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] ?? 0,
      filleulId: json['filleul_id'] ?? json['filleul']?['id'] ?? 0,
      parrainId: json['parrain_id'] ?? 0,
      // Le backend renvoie 'date_creation' pas 'date_parrainage'
      dateParrainage: json['date_parrainage'] != null
          ? DateTime.parse(json['date_parrainage'])
          : (json['date_creation'] != null
              ? DateTime.parse(json['date_creation'])
              : DateTime.now()),
      pointsAttribues: json['points_attribues'] ?? 0,
      filleulNom: json['filleul_nom'] ?? json['filleul']?['nom'],
      filleulPrenom: json['filleul_prenom'] ?? json['filleul']?['prenom'],
      filleulUsername: json['filleul_username'] ?? json['filleul']?['username'],
      filleulCodeAdhesion: json['filleul_code_adhesion'] ?? json['filleul']?['code_adhesion'],
    );
  }

  String get nomComplet {
    if (filleulNom != null && filleulPrenom != null) {
      return '$filleulPrenom $filleulNom';
    }
    return filleulUsername ?? 'Membre #$filleulId';
  }
}
