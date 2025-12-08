class Membre {
  final int id;
  final String username;
  final String codeAdhesion;
  final String? codeParrain;
  final String nom;
  final String prenom;
  final String? surnom;
  final String sexe;
  final String lieuDeNaissance;
  final DateTime dateDeNaissance;
  final String? nomPere;
  final String? nomMere;
  final String? nin;
  final String? nif;
  final String? situationMatrimoniale;
  final int? nbEnfants;
  final int? nbPersonnesACharge;
  final String telephonePrincipal;
  final String? telephoneEtranger;
  final String email;
  final String adresseComplete;
  final String? profession;
  final String? occupation;
  final String departement;
  final String commune;
  final String? sectionCommunale;
  final String? facebook;
  final String? instagram;
  final bool aEteMembrePolitique;
  final String? rolePolitiquePrecedent;
  final String? nomPartiPrecedent;
  final bool aEteMembreOrganisation;
  final String? roleOrganisationPrecedent;
  final String? nomOrganisationPrecedente;
  final String referentNom;
  final String referentPrenom;
  final String referentAdresse;
  final String referentTelephone;
  final String relationAvecReferent;
  final bool aEteCondamne;
  final bool aVioleLoiDrogue;
  final bool aParticipeActiviteTerroriste;
  final String? photoProfilUrl;
  final String? role;
  final String statut;
  final DateTime dateInscription;
  final int rating;

  Membre({
    required this.id,
    required this.username,
    required this.codeAdhesion,
    this.codeParrain,
    required this.nom,
    required this.prenom,
    this.surnom,
    required this.sexe,
    required this.lieuDeNaissance,
    required this.dateDeNaissance,
    this.nomPere,
    this.nomMere,
    this.nin,
    this.nif,
    this.situationMatrimoniale,
    this.nbEnfants,
    this.nbPersonnesACharge,
    required this.telephonePrincipal,
    this.telephoneEtranger,
    required this.email,
    required this.adresseComplete,
    this.profession,
    this.occupation,
    required this.departement,
    required this.commune,
    this.sectionCommunale,
    this.facebook,
    this.instagram,
    this.aEteMembrePolitique = false,
    this.rolePolitiquePrecedent,
    this.nomPartiPrecedent,
    this.aEteMembreOrganisation = false,
    this.roleOrganisationPrecedent,
    this.nomOrganisationPrecedente,
    required this.referentNom,
    required this.referentPrenom,
    required this.referentAdresse,
    required this.referentTelephone,
    required this.relationAvecReferent,
    this.aEteCondamne = false,
    this.aVioleLoiDrogue = false,
    this.aParticipeActiviteTerroriste = false,
    this.photoProfilUrl,
    this.role,
    this.statut = 'Membre pré-adhérent',
    required this.dateInscription,
    this.rating = 0,
  });

  factory Membre.fromJson(Map<String, dynamic> json) {
    return Membre(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      codeAdhesion: json['code_adhesion'] ?? '',
      codeParrain: json['code_parrain'],
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      surnom: json['surnom'],
      sexe: json['sexe'] ?? '',
      lieuDeNaissance: json['lieu_de_naissance'] ?? '',
      dateDeNaissance: json['date_de_naissance'] != null
          ? DateTime.parse(json['date_de_naissance'])
          : DateTime.now(),
      nomPere: json['nom_pere'],
      nomMere: json['nom_mere'],
      nin: json['nin'],
      nif: json['nif'],
      situationMatrimoniale: json['situation_matrimoniale'],
      nbEnfants: json['nb_enfants'],
      nbPersonnesACharge: json['nb_personnes_a_charge'],
      telephonePrincipal: json['telephone_principal'] ?? '',
      telephoneEtranger: json['telephone_etranger'],
      email: json['email'] ?? '',
      adresseComplete: json['adresse_complete'] ?? '',
      profession: json['profession'],
      occupation: json['occupation'],
      departement: json['departement'] ?? '',
      commune: json['commune'] ?? '',
      sectionCommunale: json['section_communale'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      aEteMembrePolitique: json['a_ete_membre_politique'] ?? false,
      rolePolitiquePrecedent: json['role_politique_precedent'],
      nomPartiPrecedent: json['nom_parti_precedent'],
      aEteMembreOrganisation: json['a_ete_membre_organisation'] ?? false,
      roleOrganisationPrecedent: json['role_organisation_precedent'],
      nomOrganisationPrecedente: json['nom_organisation_precedente'],
      referentNom: json['referent_nom'] ?? '',
      referentPrenom: json['referent_prenom'] ?? '',
      referentAdresse: json['referent_adresse'] ?? '',
      referentTelephone: json['referent_telephone'] ?? '',
      relationAvecReferent: json['relation_avec_referent'] ?? '',
      aEteCondamne: json['a_ete_condamne'] ?? false,
      aVioleLoiDrogue: json['a_viole_loi_drogue'] ?? false,
      aParticipeActiviteTerroriste: json['a_participe_activite_terroriste'] ?? false,
      photoProfilUrl: json['photo_profil_url'],
      role: json['role'],
      statut: json['statut'] ?? json['Statuts'] ?? 'Membre pré-adhérent',
      dateInscription: json['date_inscription'] != null
          ? DateTime.parse(json['date_inscription'])
          : DateTime.now(),
      rating: json['rating'] ?? 0,
    );
  }

  String get nomComplet => '$prenom $nom';
  
  int get age {
    final now = DateTime.now();
    int age = now.year - dateDeNaissance.year;
    if (now.month < dateDeNaissance.month ||
        (now.month == dateDeNaissance.month && now.day < dateDeNaissance.day)) {
      age--;
    }
    return age;
  }
}
