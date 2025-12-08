import 'package:flutter/material.dart';
import '../models/formation.dart';
import '../services/api_service.dart';
import 'formation_detail_screen.dart';
import '../widgets/gradient_app_bar.dart';

class FormationsListScreen extends StatefulWidget {
  const FormationsListScreen({super.key});

  @override
  State<FormationsListScreen> createState() => _FormationsListScreenState();
}

class _FormationsListScreenState extends State<FormationsListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Formation> _formations = [];
  List<Formation> _filteredFormations = [];
  bool _isLoading = true;
  String? _selectedNiveau;

  final List<String> _niveaux = ['Tous', 'Débutant', 'Intermédiaire', 'Avancé'];

  @override
  void initState() {
    super.initState();
    _loadFormations();
    _searchController.addListener(_filterFormations);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFormations() async {
    setState(() => _isLoading = true);

    final result = await _apiService.getFormations();

    if (mounted) {
      setState(() {
        if (result['success']) {
          _formations = result['data'];
          _filteredFormations = _formations;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Erreur de chargement')),
          );
        }
        _isLoading = false;
      });
    }
  }

  void _filterFormations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFormations = _formations.where((formation) {
        final matchesSearch = formation.titre.toLowerCase().contains(query) ||
            (formation.description?.toLowerCase().contains(query) ?? false);
        
        final matchesNiveau = _selectedNiveau == null || 
            _selectedNiveau == 'Tous' ||
            formation.niveau?.toLowerCase() == _selectedNiveau?.toLowerCase();

        return matchesSearch && matchesNiveau;
      }).toList();
    });
  }

  void _onNiveauChanged(String? niveau) {
    setState(() {
      _selectedNiveau = niveau == 'Tous' ? null : niveau;
    });
    _filterFormations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: 'Formations',
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                // Barre de recherche
                Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une formation...',
                    prefixIcon: const Icon(Icons.search, color: Colors.red),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              // Filtres par niveau
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _niveaux.length,
                  itemBuilder: (context, index) {
                    final niveau = _niveaux[index];
                    final isSelected = (_selectedNiveau == null && niveau == 'Tous') ||
                        _selectedNiveau == niveau;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(niveau),
                        selected: isSelected,
                        onSelected: (selected) {
                          _onNiveauChanged(selected ? niveau : 'Tous');
                        },
                        backgroundColor: Colors.white,
                        selectedColor: Colors.red.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.red : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        checkmarkColor: Colors.red,
                      ),
                    );
                  },
                ),
              ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          // Liste des formations
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFormations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadFormations,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredFormations.length,
                          itemBuilder: (context, index) {
                            return _buildFormationCard(_filteredFormations[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'Aucune formation trouvée'
                : 'Aucune formation disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
              },
              child: const Text('Réinitialiser la recherche'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormationCard(Formation formation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FormationDetailScreen(
                formationId: formation.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de couverture
            if (formation.imageCouvertureUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  formation.imageCouvertureUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultImage(),
                ),
              )
            else
              _buildDefaultImage(),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge niveau
                  if (formation.niveau != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getNiveauColor(formation.niveau!),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        formation.niveau!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Titre
                  Text(
                    formation.titre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  if (formation.description != null)
                    Text(
                      formation.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 16),

                  // Statistiques
                  Row(
                    children: [
                      Icon(Icons.menu_book, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${formation.nombreModules} modules',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.quiz, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${formation.nombreQuizTotal} quiz',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
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

  Widget _buildDefaultImage() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: const Icon(
        Icons.school,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  Color _getNiveauColor(String niveau) {
    switch (niveau.toLowerCase()) {
      case 'débutant':
        return Colors.green;
      case 'intermédiaire':
        return Colors.orange;
      case 'avancé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
