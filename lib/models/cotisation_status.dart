class CotisationStatus {
  final int annee;
  final double montantTotalAnnuel;
  final double montantVerse;
  final double montantRestant;
  final bool estComplet;
  final bool estPremierVersement;
  final double montantMinimumProchainVersement;

  CotisationStatus({
    required this.annee,
    required this.montantTotalAnnuel,
    required this.montantVerse,
    required this.montantRestant,
    required this.estComplet,
    required this.estPremierVersement,
    required this.montantMinimumProchainVersement,
  });

  /// Un membre est actif s'il a versé un montant > 0 pour l'année en cours.
  bool get estActif => montantVerse > 0;

  factory CotisationStatus.fromJson(Map<String, dynamic> json) {
    return CotisationStatus(
      annee: json['annee'] as int,
      montantTotalAnnuel: double.tryParse(json['montant_total_annuel']?.toString() ?? '0.0') ?? 0.0,
      montantVerse: double.tryParse(json['montant_verse']?.toString() ?? '0.0') ?? 0.0,
      montantRestant: double.tryParse(json['montant_restant']?.toString() ?? '0.0') ?? 0.0,
      estComplet: json['est_complet'] as bool,
      estPremierVersement: json['est_premier_versement'] as bool? ?? false,
      montantMinimumProchainVersement: double.tryParse(json['montant_minimum_prochain_versement']?.toString() ?? '1.0') ?? 1.0,
    );
  }
}
