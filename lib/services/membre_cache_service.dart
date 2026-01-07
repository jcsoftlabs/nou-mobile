import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/membre.dart';

/// Service pour gérer le cache local des données du membre
/// Permet l'accès hors ligne aux données du profil
class MembreCacheService {
  static const String _keyMembreData = 'cached_membre_data';
  static const String _keyLastSync = 'last_sync_timestamp';

  /// Sauvegarder les données du membre dans le cache local
  Future<void> saveMembre(Membre membre) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convertir le membre en JSON
      final membreJson = {
        'id': membre.id,
        'username': membre.username,
        'code_adhesion': membre.codeAdhesion,
        'code_parrain': membre.codeParrain,
        'nom': membre.nom,
        'prenom': membre.prenom,
        'surnom': membre.surnom,
        'sexe': membre.sexe,
        'lieu_de_naissance': membre.lieuDeNaissance,
        'date_de_naissance': membre.dateDeNaissance.toIso8601String(),
        'nom_pere': membre.nomPere,
        'nom_mere': membre.nomMere,
        'nin': membre.nin,
        'nif': membre.nif,
        'situation_matrimoniale': membre.situationMatrimoniale,
        'nb_enfants': membre.nbEnfants,
        'nb_personnes_a_charge': membre.nbPersonnesACharge,
        'telephone_principal': membre.telephonePrincipal,
        'telephone_etranger': membre.telephoneEtranger,
        'email': membre.email,
        'adresse_complete': membre.adresseComplete,
        'profession': membre.profession,
        'occupation': membre.occupation,
        'departement': membre.departement,
        'commune': membre.commune,
        'section_communale': membre.sectionCommunale,
        'facebook': membre.facebook,
        'instagram': membre.instagram,
        'a_ete_membre_politique': membre.aEteMembrePolitique,
        'role_politique_precedent': membre.rolePolitiquePrecedent,
        'nom_parti_precedent': membre.nomPartiPrecedent,
        'a_ete_membre_organisation': membre.aEteMembreOrganisation,
        'role_organisation_precedent': membre.roleOrganisationPrecedent,
        'nom_organisation_precedente': membre.nomOrganisationPrecedente,
        'referent_nom': membre.referentNom,
        'referent_prenom': membre.referentPrenom,
        'referent_adresse': membre.referentAdresse,
        'referent_telephone': membre.referentTelephone,
        'relation_avec_referent': membre.relationAvecReferent,
        'a_ete_condamne': membre.aEteCondamne,
        'a_viole_loi_drogue': membre.aVioleLoiDrogue,
        'a_participe_activite_terroriste': membre.aParticipeActiviteTerroriste,
        'photo_profil_url': membre.photoProfilUrl,
        'role': membre.role,
        'statut': membre.statut,
        'date_inscription': membre.dateInscription.toIso8601String(),
        'rating': membre.rating,
      };
      
      // Sauvegarder en JSON string
      await prefs.setString(_keyMembreData, jsonEncode(membreJson));
      
      // Sauvegarder le timestamp de synchronisation
      await prefs.setInt(_keyLastSync, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Erreur lors de la sauvegarde du membre dans le cache: $e');
      rethrow;
    }
  }

  /// Récupérer les données du membre depuis le cache local
  Future<Membre?> getMembre() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membreJsonString = prefs.getString(_keyMembreData);
      
      if (membreJsonString == null) {
        return null;
      }
      
      // Décoder le JSON
      final membreJson = jsonDecode(membreJsonString) as Map<String, dynamic>;
      
      // Créer un objet Membre depuis le JSON
      return Membre.fromJson(membreJson);
    } catch (e) {
      print('Erreur lors de la récupération du membre depuis le cache: $e');
      return null;
    }
  }

  /// Supprimer les données du membre du cache local
  Future<void> clearMembre() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyMembreData);
      await prefs.remove(_keyLastSync);
    } catch (e) {
      print('Erreur lors de la suppression du membre du cache: $e');
    }
  }

  /// Vérifier si des données en cache existent
  Future<bool> hasCachedMembre() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyMembreData);
    } catch (e) {
      return false;
    }
  }

  /// Obtenir le timestamp de la dernière synchronisation
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_keyLastSync);
      
      if (timestamp == null) {
        return null;
      }
      
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }
}
