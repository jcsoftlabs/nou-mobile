class Don {
  final int id;
  final int membreId;
  final String montant;
  final String? recuUrl;
  final String statutDon; // en_attente, approuve, rejete
  final DateTime dateDon;
  final DateTime? dateVerification;
  final int? adminVerificateurId;
  final String? commentaireVerification;
  final String? description;

  Don({
    required this.id,
    required this.membreId,
    required this.montant,
    this.recuUrl,
    required this.statutDon,
    required this.dateDon,
    this.dateVerification,
    this.adminVerificateurId,
    this.commentaireVerification,
    this.description,
  });

  factory Don.fromJson(Map<String, dynamic> json) {
    return Don(
      id: json['id'] ?? 0,
      membreId: json['membre_id'] ?? 0,
      montant: json['montant']?.toString() ?? '0.00',
      recuUrl: json['recu_url'],
      statutDon: json['statut_don'] ?? 'en_attente',
      dateDon: json['date_don'] != null
          ? DateTime.parse(json['date_don'])
          : DateTime.now(),
      dateVerification: json['date_verification'] != null
          ? DateTime.parse(json['date_verification'])
          : null,
      adminVerificateurId: json['admin_verificateur_id'],
      commentaireVerification: json['commentaire_verification'],
      description: json['description'],
    );
  }

  bool get isApprouve => statutDon == 'approuve';
  bool get isEnAttente => statutDon == 'en_attente';
  bool get isRejete => statutDon == 'rejete';
}

class DonRequest {
  final double montant;
  final String? description;

  DonRequest({
    required this.montant,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'montant': montant,
      'description': description,
    };
  }
}
