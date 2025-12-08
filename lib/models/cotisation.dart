class Cotisation {
  final int id;
  final int membreId;
  final double montant;
  final String statutPaiement; // 'En attente', 'Validé', 'Rejeté'
  final String? moyenPaiement; // 'MonCash', 'Espèces', 'Virement', etc.
  final String? recuUrl;
  final DateTime dateCreation;
  final DateTime? dateValidation;

  Cotisation({
    required this.id,
    required this.membreId,
    required this.montant,
    required this.statutPaiement,
    this.moyenPaiement,
    this.recuUrl,
    required this.dateCreation,
    this.dateValidation,
  });

  factory Cotisation.fromJson(Map<String, dynamic> json) {
    // Convertir les valeurs backend (en_attente, valide, rejete) vers format affichage
    String normalizeStatut(String? statut) {
      if (statut == null) return 'En attente';
      switch (statut.toLowerCase()) {
        case 'en_attente':
          return 'En attente';
        case 'valide':
          return 'Validé';
        case 'rejete':
          return 'Rejeté';
        default:
          return statut;
      }
    }

    return Cotisation(
      id: json['id'],
      membreId: json['membre_id'],
      montant: double.tryParse(json['montant']?.toString() ?? '0.0') ?? 0.0,
      statutPaiement: normalizeStatut(json['statut_paiement']),
      moyenPaiement: json['moyen_paiement'],
      recuUrl: json['url_recu'],
      dateCreation: DateTime.parse(json['date_paiement'] ?? json['date_creation'] ?? DateTime.now().toIso8601String()),
      dateValidation: json['date_verification'] != null
          ? DateTime.parse(json['date_verification'])
          : null,
    );
  }

  String get statutColor {
    switch (statutPaiement.toLowerCase()) {
      case 'validé':
      case 'valide':
        return 'green';
      case 'rejeté':
      case 'rejete':
        return 'red';
      default:
        return 'orange';
    }
  }

  String get formattedMontant => '${montant.toStringAsFixed(2)} HTG';
}

class CotisationRequest {
  final int membreId;
  final double montant;
  final String moyenPaiement;
  final String? recuPath; // Chemin local du fichier

  CotisationRequest({
    required this.membreId,
    required this.montant,
    required this.moyenPaiement,
    this.recuPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'membre_id': membreId,
      'montant': montant,
      'moyen_paiement': moyenPaiement,
    };
  }
}
