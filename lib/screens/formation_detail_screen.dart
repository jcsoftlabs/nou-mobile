import 'package:flutter/material.dart';
import '../models/formation.dart';
import '../models/formation_module.dart';
import '../services/api_service.dart';
import 'module_view_screen.dart';

class FormationDetailScreen extends StatefulWidget {
  final int formationId;

  const FormationDetailScreen({
    super.key,
    required this.formationId,
  });

  @override
  State<FormationDetailScreen> createState() => _FormationDetailScreenState();
}

class _FormationDetailScreenState extends State<FormationDetailScreen> {
  final ApiService _apiService = ApiService();

  Formation? _formation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormation();
  }

  Future<void> _loadFormation() async {
    setState(() => _isLoading = true);

    final result = await _apiService.getFormationById(widget.formationId);

    if (mounted) {
      setState(() {
        if (result['success']) {
          _formation = result['data'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Erreur de chargement')),
          );
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _formation == null
              ? _buildErrorState()
              : CustomScrollView(
                  slivers: [
                    _buildAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 24),
                            _buildModulesSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _formation!.titre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black54,
                blurRadius: 10,
              ),
            ],
          ),
        ),
        background: _formation!.imageCouvertureUrl != null
            ? Image.network(
                _formation!.imageCouvertureUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultBackground(),
              )
            : _buildDefaultBackground(),
      ),
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.school,
          size: 100,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge niveau
        if (_formation!.niveau != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getNiveauColor(_formation!.niveau!),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formation!.niveau!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Description
        if (_formation!.description != null)
          Text(
            _formation!.description!,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        const SizedBox(height: 16),

        // Statistiques
        Row(
          children: [
            _buildStat(
              Icons.menu_book,
              '${_formation!.nombreModules}',
              'Modules',
            ),
            const SizedBox(width: 32),
            _buildStat(
              Icons.quiz,
              '${_formation!.nombreQuizTotal}',
              'Quiz',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.red, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModulesSection() {
    if (_formation!.modules == null || _formation!.modules!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.layers_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun module disponible',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Trier les modules par ordre
    final sortedModules = List<FormationModule>.from(_formation!.modules!)
      ..sort((a, b) => a.ordre.compareTo(b.ordre));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Modules du cours',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedModules.length,
          itemBuilder: (context, index) {
            return _buildModuleCard(sortedModules[index], index + 1);
          },
        ),
      ],
    );
  }

  Widget _buildModuleCard(FormationModule module, int position) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ModuleViewScreen(
                module: module,
                formationTitre: _formation!.titre,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numéro du module
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (module.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        module.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Badges de contenu
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (module.typeContenu != null)
                          _buildContentBadge(
                            _getContentIcon(module.typeContenu!),
                            module.typeContenu!,
                          ),
                        if (module.hasVideo)
                          _buildContentBadge(Icons.play_circle, 'Vidéo'),
                        if (module.hasImage)
                          _buildContentBadge(Icons.image, 'Image'),
                        if (module.hasQuizzes)
                          _buildContentBadge(
                            Icons.quiz,
                            '${module.quizzes!.length} quiz',
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Icône flèche
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.red),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContentIcon(String typeContenu) {
    switch (typeContenu.toLowerCase()) {
      case 'video':
        return Icons.video_library;
      case 'image':
        return Icons.image;
      case 'texte':
        return Icons.article;
      case 'mixte':
        return Icons.auto_awesome;
      default:
        return Icons.description;
    }
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Formation introuvable',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }
}
