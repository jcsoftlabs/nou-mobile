class RegisterRequest {
  // Étape 1
  final String username;
  final String codeAdhesion;
  final String password;

  // Étape 2 - Informations personnelles
  final String nom;
  final String prenom;
  final String? surnom;
  final String sexe;
  final String lieuDeNaissance;
  final String dateDeNaissance;
  final String? nomPere;
  final String? nomMere;
  final String nin;
  final String? nif;
  final String? situationMatrimoniale;
  final int nbEnfants;
  final int nbPersonnesACharge;
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

  RegisterRequest({
    required this.username,
    required this.codeAdhesion,
    required this.password,
    required this.nom,
    required this.prenom,
    this.surnom,
    required this.sexe,
    required this.lieuDeNaissance,
    required this.dateDeNaissance,
    this.nomPere,
    this.nomMere,
    required this.nin,
    this.nif,
    this.situationMatrimoniale,
    required this.nbEnfants,
    required this.nbPersonnesACharge,
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
    required this.aEteMembrePolitique,
    this.rolePolitiquePrecedent,
    this.nomPartiPrecedent,
    required this.aEteMembreOrganisation,
    this.roleOrganisationPrecedent,
    this.nomOrganisationPrecedente,
    required this.referentNom,
    required this.referentPrenom,
    required this.referentAdresse,
    required this.referentTelephone,
    required this.relationAvecReferent,
    required this.aEteCondamne,
    required this.aVioleLoiDrogue,
    required this.aParticipeActiviteTerroriste,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'code_adhesion': codeAdhesion,
      'password': password,
      'nom': nom,
      'prenom': prenom,
      'surnom': surnom,
      'sexe': sexe,
      'lieu_de_naissance': lieuDeNaissance,
      'date_de_naissance': dateDeNaissance,
      'nom_pere': nomPere,
      'nom_mere': nomMere,
      'nin': nin,
      'nif': nif,
      'situation_matrimoniale': situationMatrimoniale,
      'nb_enfants': nbEnfants,
      'nb_personnes_a_charge': nbPersonnesACharge,
      'telephone_principal': telephonePrincipal,
      'telephone_etranger': telephoneEtranger,
      'email': email,
      'adresse_complete': adresseComplete,
      'profession': profession,
      'occupation': occupation,
      'departement': departement,
      'commune': commune,
      'section_communale': sectionCommunale,
      'facebook': facebook,
      'instagram': instagram,
      'a_ete_membre_politique': aEteMembrePolitique,
      'role_politique_precedent': rolePolitiquePrecedent,
      'nom_parti_precedent': nomPartiPrecedent,
      'a_ete_membre_organisation': aEteMembreOrganisation,
      'role_organisation_precedent': roleOrganisationPrecedent,
      'nom_organisation_precedente': nomOrganisationPrecedente,
      'referent_nom': referentNom,
      'referent_prenom': referentPrenom,
      'referent_adresse': referentAdresse,
      'referent_telephone': referentTelephone,
      'relation_avec_referent': relationAvecReferent,
      'a_ete_condamne': aEteCondamne,
      'a_viole_loi_drogue': aVioleLoiDrogue,
      'a_participe_activite_terroriste': aParticipeActiviteTerroriste,
    };
  }
}
