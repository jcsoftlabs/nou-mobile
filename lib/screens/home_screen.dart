import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../data/providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/cotisation.dart';
import '../models/cotisation_status.dart';
import '../models/membre.dart';
import '../models/annonce.dart';
import '../constants/api_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  Cotisation? _derniereCotisation;
  CotisationStatus? _cotisationStatus;
  Membre? _parrain;
  Annonce? _topAnnonce;
  bool _isLoadingCotisation = true;
  bool _isLoadingParrain = true;
  bool _isLoadingAnnonces = true;
  bool _isAnnonceDismissed = false;
  bool _hasUnreadAnnonces = false;

  @override
  void initState() {
    super.initState();
    _loadCotisationInfo();
    _loadParrainInfo();
    _loadTopAnnonce();
  }

  Future<void> _loadCotisationInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final membre = authProvider.currentMembre;
    
    if (membre != null) {
      // Charger le statut annuel (pour savoir si actif cette année)
      final status = await _apiService.getCotisationStatus();
      // Charger aussi la dernière cotisation (pour affichage des détails)
      final cotisation = await _apiService.getLastCotisation(membre.id);
      
      setState(() {
        _cotisationStatus = status;
        _derniereCotisation = cotisation;
        _isLoadingCotisation = false;
      });
    }
  }

  Future<void> _loadParrainInfo() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final membre = authProvider.currentMembre;
    
    if (membre != null && membre.codeParrain != null) {
      final result = await _apiService.getParrainByCode(membre.codeParrain!);
      if (result['success'] == true) {
        setState(() {
          _parrain = result['data'];
          _isLoadingParrain = false;
        });
      } else {
        setState(() {
          _isLoadingParrain = false;
        });
      }
    } else {
      setState(() {
        _isLoadingParrain = false;
      });
    }
  }

  Future<void> _loadTopAnnonce() async {
    final result = await _apiService.getAnnoncesActives();

    if (!mounted) return;

    if (result['success'] == true) {
      final annonces = (result['data'] as List<Annonce>?) ?? <Annonce>[];
      await _updateAnnonceUnreadState(annonces);
      setState(() {
        _topAnnonce = _selectTopAnnonce(annonces);
        _isLoadingAnnonces = false;
      });
    } else {
      setState(() {
        _isLoadingAnnonces = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final membre = authProvider.currentMembre;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // Badge Statut membre
          if (membre != null)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                membre.statut,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          // Badge Actif/Inactif (basé sur cotisation de l'année en cours)
          if (!_isLoadingCotisation)
            Container(
              margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: (_cotisationStatus?.estActif == true)
                    ? Colors.white
                    : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: (_cotisationStatus?.estActif == true)
                          ? Colors.green.shade600
                          : Colors.grey.shade500,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    (_cotisationStatus?.estActif == true)
                        ? 'Actif'
                        : 'Inactif',
                    style: TextStyle(
                      color: (_cotisationStatus?.estActif == true)
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Déconnexion',
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
          ),
        ],
      ),
      body: membre == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec photo de profil
                  _buildProfileHeader(context, membre),

                  const SizedBox(height: 12),

                  // Bannière d'annonce (si disponible)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildAnnonceBanner(context),
                  ),

                  const SizedBox(height: 24),

                  // Cotisation
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildCotisationCard(context),
                  ),

                  const SizedBox(height: 24),
                  // Navigation rapide
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildQuickAccessGrid(context),
                  ),

                  const SizedBox(height: 32),

                  // Informations
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildInfoCard(
                      context,
                      'Code d\'adhésion',
                      membre.codeAdhesion,
                      Icons.qr_code,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Parrain
                  if (!_isLoadingParrain && _parrain != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildParrainInfo(context),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Annonce? _selectTopAnnonce(List<Annonce> annonces) {
    if (annonces.isEmpty) return null;

    final sorted = List<Annonce>.from(annonces);

    int _priorityValue(String priorite) {
      switch (priorite) {
        case 'urgent':
          return 3;
        case 'important':
          return 2;
        default:
          return 1;
      }
    }

    sorted.sort((a, b) {
      final pa = _priorityValue(a.priorite);
      final pb = _priorityValue(b.priorite);
      if (pa != pb) return pb - pa; // priorité décroissante

      final da = a.datePublication ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.datePublication ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da); // plus récent en premier
    });

    return sorted.first;
  }

  Future<void> _updateAnnonceUnreadState(List<Annonce> annonces) async {
    if (annonces.isEmpty) {
      setState(() {
        _hasUnreadAnnonces = false;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSeenId = prefs.getInt('last_seen_annonce_id');
    final latestId = annonces.map((a) => a.id).reduce(max);

    setState(() {
      _hasUnreadAnnonces = lastSeenId == null || latestId > lastSeenId;
    });
  }

  String _buildPhotoUrl(String photoUrl) {
    // Si l'URL commence par http, c'est déjà une URL complète (Cloudinary ou autre)
    if (photoUrl.startsWith('http')) {
      return photoUrl;
    }
    // Sinon, préfixer avec l'URL du backend
    return '${ApiConstants.baseUrl}$photoUrl';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _buildProfileHeader(BuildContext context, membre) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade600, Colors.red.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Row(
        children: [
          // Photo de profil avec placeholder selon le sexe
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              backgroundImage: membre.photoProfilUrl != null
                  ? NetworkImage(_buildPhotoUrl(membre.photoProfilUrl!))
                  : null,
              child: membre.photoProfilUrl == null
                  ? Icon(
                      membre.sexe == 'F' ? Icons.woman : Icons.man,
                      size: 50,
                      color: Colors.red.shade400,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 20),
          // Informations utilisateur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue,',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${membre.prenom} ${membre.nom}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                // Affichage du rating par étoiles
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < membre.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade300,
                      size: 18,
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnonceBanner(BuildContext context) {
    if (_isLoadingAnnonces || _topAnnonce == null || _isAnnonceDismissed) {
      return const SizedBox.shrink();
    }

    final annonce = _topAnnonce!;

    Color bgColor;
    Color textColor;
    IconData icon;

    switch (annonce.priorite) {
      case 'urgent':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        icon = Icons.report;
        break;
      case 'important':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        icon = Icons.priority_high;
        break;
      default:
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        icon = Icons.info_outline;
    }

    return Card
    (
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/annonces'),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: textColor, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            annonce.titre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                annonce.priorite.toUpperCase(),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: Colors.grey,
                              onPressed: () {
                                setState(() {
                                  _isAnnonceDismissed = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      annonce.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    if (annonce.datePublication != null || annonce.auteurNom != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            if (annonce.auteurNom != null) ...[
                              const Icon(Icons.person, size: 12, color: Colors.grey),
                              const SizedBox(width: 3),
                              Text(
                                annonce.auteurNom!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            if (annonce.auteurNom != null && annonce.datePublication != null)
                              const SizedBox(width: 8),
                            if (annonce.datePublication != null) ...[
                              const Icon(Icons.calendar_today,
                                  size: 12, color: Colors.grey),
                              const SizedBox(width: 3),
                              Text(
                                _formatDate(annonce.datePublication!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                context,
                'Podcasts',
                Icons.podcasts,
                () => context.go('/podcasts'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickAccessCard(
                context,
                'Formations',
                Icons.school,
                () => context.go('/formations'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                context,
                'Cotisation',
                Icons.payment,
                () => context.go('/cotisation'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickAccessCard(
                context,
                'Parrainage',
                Icons.people,
                () => context.go('/parrainage'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                context,
                'Actualités',
                Icons.article,
                () => context.go('/news'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickAccessCard(
                context,
'Annonces',
                Icons.campaign,
                () => context.go('/annonces'),
                showBadge: _hasUnreadAnnonces,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickAccessCard(
                context,
                'Faire un don',
                Icons.volunteer_activism,
                () async {
                  final result = await context.push('/don');
                  if (result == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Merci pour votre générosité !'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool showBadge = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 48, color: const Color(0xFFFF0000)),
                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: const Color(0xFFFF0000)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatutCard(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final membre = authProvider.currentMembre;
    
    if (membre == null) {
      return const SizedBox.shrink();
    }

    // Actif si a versé au moins 1 HTG pour l'année en cours
    final bool estActif = _cotisationStatus?.estActif == true;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: estActif 
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.grey.shade400, Colors.grey.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                estActif ? Icons.check_circle : Icons.person_outline,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Statut membre',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    membre.statut,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        estActif ? 'Actif' : 'Inactif',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCotisationCard(BuildContext context) {
    if (_isLoadingCotisation) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Actif/à jour si a versé au moins 1 HTG cette année ET cotisation complète
    final bool cotisationComplete = _cotisationStatus?.estComplet == true;
    final bool estActif = _cotisationStatus?.estActif == true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cotisationComplete 
                        ? Colors.green.shade50 
                        : (estActif ? Colors.orange.shade50 : Colors.red.shade50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    cotisationComplete ? Icons.check_circle : Icons.payment,
                    color: cotisationComplete 
                        ? Colors.green.shade600 
                        : (estActif ? Colors.orange.shade600 : Colors.red.shade600),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cotisation (période d\'adhésion)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cotisationComplete 
                            ? 'Complète' 
                            : (estActif ? 'En cours' : 'Non payée'),
                        style: TextStyle(
                          color: Colors.grey.shade900,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_cotisationStatus != null && !cotisationComplete) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_cotisationStatus!.montantVerse.toStringAsFixed(0)} / ${_cotisationStatus!.montantTotalAnnuel.toStringAsFixed(0)} HTG',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cotisationComplete 
                        ? Colors.green.shade50 
                        : (estActif ? Colors.orange.shade50 : Colors.red.shade50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cotisationComplete 
                        ? '✓ Payé' 
                        : '${((_cotisationStatus?.montantVerse ?? 0) / (_cotisationStatus?.montantTotalAnnuel ?? 1500) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: cotisationComplete 
                          ? Colors.green.shade700 
                          : (estActif ? Colors.orange.shade700 : Colors.red.shade700),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (!cotisationComplete) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => context.go('/cotisation'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.payment,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Payer ma cotisation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParrainInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person_pin_circle,
            color: Colors.red.shade400,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                children: [
                  const TextSpan(text: 'Parrainé par '),
                  TextSpan(
                    text: '${_parrain!.prenom} ${_parrain!.nom}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
