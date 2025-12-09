import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/membre.dart';
import '../models/cotisation.dart';
import '../models/cotisation_status.dart';
import '../services/api_service.dart';
import '../widgets/gradient_app_bar.dart';
import '../data/providers/auth_provider.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final int membreId;

  const ProfileScreen({
    super.key,
    required this.membreId,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  Membre? _membre;
  Cotisation? _derniereCotisation;
  CotisationStatus? _cotisationStatus;
  List<Cotisation> _historiqueCotisations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Charger les informations du membre
      final membreResult = await _apiService.getMembreById(widget.membreId);
      // Charger le statut de cotisation annuel
      final cotisationStatus = await _apiService.getCotisationStatus();
      // Charger la dernière cotisation
      final derniereCotisation = await _apiService.getLastCotisation(widget.membreId);
      // Charger l'historique des cotisations
      final cotisationsResult = await _apiService.getCotisations(widget.membreId);

      if (mounted) {
        setState(() {
          if (membreResult['success']) {
            _membre = membreResult['data'];
          }
          _cotisationStatus = cotisationStatus;
          _derniereCotisation = derniereCotisation;
          if (cotisationsResult['success']) {
            _historiqueCotisations = cotisationsResult['data'];
          } else {
            // Endpoint non disponible, liste vide
            _historiqueCotisations = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // Gérer les erreurs de connexion
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      if (!mounted) return;
      setState(() => _isLoading = true);

      final result = await _apiService.updatePhotoProfile(
        widget.membreId,
        image.path,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Recharger les données du membre localement ET dans l'AuthProvider
        await _reloadMembre();
        // Mettre à jour aussi l'AuthProvider pour rafraîchir le HomeScreen
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          await authProvider.updateMembre();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _reloadMembre() async {
    try {
      final membreResult = await _apiService.getMembreById(widget.membreId);
      if (mounted && membreResult['success']) {
        setState(() {
          _membre = membreResult['data'];
        });
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Mon Profil',
      ),
      body: _isLoading || _membre == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildCotisationStatus(),
                    _buildPersonalInfo(),
                    _buildContactInfo(),
                    _buildLocationInfo(),
                    _buildSocialMediaInfo(),
                    _buildPoliticalHistory(),
                    _buildReferentInfo(),
                    _buildHistoriqueCotisations(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  String _buildPhotoUrl(String photoUrl) {
    // Si l'URL commence par http, c'est déjà une URL complète
    if (photoUrl.startsWith('http')) {
      return photoUrl;
    }
    // Sinon, ajouter le baseUrl
    return 'http://localhost:4000$photoUrl';
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                backgroundImage: _membre!.photoProfilUrl != null
                    ? NetworkImage(_buildPhotoUrl(_membre!.photoProfilUrl!))
                    : null,
                child: _membre!.photoProfilUrl == null
                    ? Text(
                        _membre!.prenom.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 48,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _updatePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _membre!.nomComplet,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${_membre!.username}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '#${_membre!.codeAdhesion}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildStatusBadge(
                _membre!.statut,
                Colors.blue,
              ),
              // Badge Actif basé sur le statut de la période d'adhésion
              _buildStatusBadge(
                _cotisationStatus?.estActif == true ? 'Actif' : 'Inactif',
                _cotisationStatus?.estActif == true ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCotisationStatus() {
    // Utiliser le statut actuel basé sur la période d'adhésion
    if (_cotisationStatus == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Aucune cotisation enregistrée',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    // Déterminer le statut et le montant basé sur la période actuelle
    final bool estActif = _cotisationStatus!.estActif;
    final String statutText = estActif ? 'À jour' : 'Non à jour';
    final Color color = estActif ? Colors.green : Colors.red;
    final IconData icon = estActif ? Icons.check_circle : Icons.warning;
    final String montantText = '${_cotisationStatus!.montantVerse.toStringAsFixed(2)} HTG';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cotisation (période actuelle)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      statutText,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                montantText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo() {
    return _buildSection(
      'Informations personnelles',
      [
        _buildInfoRow('Nom complet', _membre!.nomComplet),
        if (_membre!.surnom != null) _buildInfoRow('Surnom', _membre!.surnom!),
        _buildInfoRow('Sexe', _membre!.sexe),
        _buildInfoRow('Date de naissance',
            '${_membre!.dateDeNaissance.day}/${_membre!.dateDeNaissance.month}/${_membre!.dateDeNaissance.year} (${_membre!.age} ans)'),
        _buildInfoRow('Lieu de naissance', _membre!.lieuDeNaissance),
        if (_membre!.nomPere != null) _buildInfoRow('Nom du père', _membre!.nomPere!),
        if (_membre!.nomMere != null) _buildInfoRow('Nom de la mère', _membre!.nomMere!),
        if (_membre!.nin != null) _buildInfoRow('NIN', _membre!.nin!),
        if (_membre!.nif != null) _buildInfoRow('NIF', _membre!.nif!),
        if (_membre!.situationMatrimoniale != null)
          _buildInfoRow('Situation matrimoniale', _membre!.situationMatrimoniale!),
        if (_membre!.nbEnfants != null)
          _buildInfoRow('Nombre d\'enfants', '${_membre!.nbEnfants}'),
        if (_membre!.nbPersonnesACharge != null)
          _buildInfoRow('Personnes à charge', '${_membre!.nbPersonnesACharge}'),
      ],
    );
  }

  Widget _buildContactInfo() {
    return _buildSection(
      'Contact',
      [
        _buildInfoRow('Téléphone principal', _membre!.telephonePrincipal),
        if (_membre!.telephoneEtranger != null)
          _buildInfoRow('Téléphone étranger', _membre!.telephoneEtranger!),
        _buildInfoRow('Email', _membre!.email),
        _buildInfoRow('Adresse', _membre!.adresseComplete),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return _buildSection(
      'Localisation et profession',
      [
        _buildInfoRow('Département', _membre!.departement),
        _buildInfoRow('Commune', _membre!.commune),
        if (_membre!.sectionCommunale != null)
          _buildInfoRow('Section communale', _membre!.sectionCommunale!),
        if (_membre!.profession != null) _buildInfoRow('Profession', _membre!.profession!),
        if (_membre!.occupation != null) _buildInfoRow('Occupation', _membre!.occupation!),
      ],
    );
  }

  Widget _buildSocialMediaInfo() {
    if (_membre!.facebook == null && _membre!.instagram == null) {
      return const SizedBox.shrink();
    }

    return _buildSection(
      'Réseaux sociaux',
      [
        if (_membre!.facebook != null) _buildInfoRow('Facebook', _membre!.facebook!),
        if (_membre!.instagram != null) _buildInfoRow('Instagram', _membre!.instagram!),
      ],
    );
  }

  Widget _buildPoliticalHistory() {
    if (!_membre!.aEteMembrePolitique && !_membre!.aEteMembreOrganisation) {
      return const SizedBox.shrink();
    }

    List<Widget> items = [];
    
    if (_membre!.aEteMembrePolitique) {
      items.add(_buildInfoRow('Membre politique', 'Oui'));
      if (_membre!.rolePolitiquePrecedent != null)
        items.add(_buildInfoRow('Rôle politique', _membre!.rolePolitiquePrecedent!));
      if (_membre!.nomPartiPrecedent != null)
        items.add(_buildInfoRow('Parti', _membre!.nomPartiPrecedent!));
    }

    if (_membre!.aEteMembreOrganisation) {
      items.add(_buildInfoRow('Membre organisation', 'Oui'));
      if (_membre!.roleOrganisationPrecedent != null)
        items.add(_buildInfoRow('Rôle organisation', _membre!.roleOrganisationPrecedent!));
      if (_membre!.nomOrganisationPrecedente != null)
        items.add(_buildInfoRow('Organisation', _membre!.nomOrganisationPrecedente!));
    }

    return _buildSection('Historique', items);
  }

  Widget _buildReferentInfo() {
    return _buildSection(
      'En cas d\'urgence',
      [
        _buildInfoRow('Nom', '${_membre!.referentPrenom} ${_membre!.referentNom}'),
        _buildInfoRow('Téléphone', _membre!.referentTelephone),
        _buildInfoRow('Adresse', _membre!.referentAdresse),
        _buildInfoRow('Relation', _membre!.relationAvecReferent),
      ],
    );
  }

  Widget _buildHistoriqueCotisations() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historique des paiements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          if (_historiqueCotisations.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Aucun historique',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _historiqueCotisations.length,
              itemBuilder: (context, index) {
                final cotisation = _historiqueCotisations[index];
                final color = _getStatutColor(cotisation.statutPaiement);
                final borderColor = _getBorderColor(cotisation.statutPaiement);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: borderColor,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icône à gauche
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: borderColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.receipt,
                            color: borderColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Montant et date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cotisation.formattedMontant,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${cotisation.dateCreation.day.toString().padLeft(2, '0')}/${cotisation.dateCreation.month.toString().padLeft(2, '0')}/${cotisation.dateCreation.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Statut à droite
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getStatutLabel(cotisation.statutPaiement),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'validé':
      case 'valide':
        return Colors.green;
      case 'rejeté':
      case 'rejete':
        return Colors.red;
      default:
        return const Color(0xFFFFB74D); // Orange pour en attente
    }
  }

  Color _getBorderColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'validé':
      case 'valide':
        return Colors.green;
      case 'rejeté':
      case 'rejete':
        return Colors.red;
      default:
        return const Color(0xFFFFB74D); // Orange pour en attente
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut.toLowerCase()) {
      case 'validé':
      case 'valide':
        return 'Validé';
      case 'rejeté':
      case 'rejete':
        return 'Rejeté';
      default:
        return 'En attente';
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut.toLowerCase()) {
      case 'validé':
      case 'valide':
        return Icons.check_circle;
      case 'rejeté':
      case 'rejete':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }
}
