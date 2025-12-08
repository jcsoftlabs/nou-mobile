import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/formation_module.dart';
import '../models/quiz.dart';

class ModuleViewScreen extends StatefulWidget {
  final FormationModule module;
  final String formationTitre;

  const ModuleViewScreen({
    super.key,
    required this.module,
    required this.formationTitre,
  });

  @override
  State<ModuleViewScreen> createState() => _ModuleViewScreenState();
}

class _ModuleViewScreenState extends State<ModuleViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.module.titre),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildContent(),
            if (widget.module.hasDownloadableFiles) _buildDownloadableFilesSection(),
            if (widget.module.hasQuizzes) _buildQuizzesSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              const Icon(Icons.school, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.formationTitre,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.module.titre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.module.description != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.module.description!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type de contenu badge
          if (widget.module.typeContenu != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getContentIcon(widget.module.typeContenu!),
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Contenu ${widget.module.typeContenu}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Image
          if (widget.module.hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.module.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Vidéo
          if (widget.module.hasVideo) ...[
            _buildVideoSection(),
            const SizedBox(height: 24),
          ],

          // Contenu texte
          if (widget.module.contenuTexte != null &&
              widget.module.contenuTexte!.isNotEmpty) ...[
            const Text(
              'Contenu du module',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.module.contenuTexte!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Vidéo du module',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => _launchVideo(widget.module.videoUrl!),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Ouvrir la vidéo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadableFilesSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fichiers à télécharger',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Documents et supports de cours',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // PDF principal
          if (widget.module.hasPdf)
            _buildFileCard(
              'Document PDF',
              widget.module.fichierPdfUrl!,
              Icons.picture_as_pdf,
              Colors.red,
            ),
          
          // PowerPoint principal
          if (widget.module.hasPpt)
            _buildFileCard(
              'Présentation PowerPoint',
              widget.module.fichierPptUrl!,
              Icons.slideshow,
              Colors.orange,
            ),
          
          // Fichiers supplémentaires
          if (widget.module.hasSupplementaryFiles)
            ...widget.module.fichiersSupplementaires!.map((file) {
              return _buildFileCard(
                file.nom,
                file.url,
                _getFileIcon(file.type),
                _getFileColor(file.type),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFileCard(String title, String url, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_rounded),
          color: Colors.blue,
          onPressed: () => _downloadFile(url, title),
          tooltip: 'Télécharger',
        ),
        onTap: () => _openFile(url),
      ),
    );
  }

  Widget _buildQuizzesSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz du module',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Testez vos connaissances',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.module.quizzes!.length,
            itemBuilder: (context, index) {
              return _buildQuizCard(widget.module.quizzes![index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Quiz quiz) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.quiz,
            color: Colors.red,
            size: 28,
          ),
        ),
        title: Text(
          quiz.titre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: quiz.description != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  quiz.description!,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: ElevatedButton(
          onPressed: quiz.isActive
              ? () {
                  // TODO: Navigation vers l'écran de quiz
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité de quiz à venir'),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Commencer'),
        ),
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

  Future<void> _launchVideo(String url) async {
    final Uri videoUri = Uri.parse(url);
    if (await canLaunchUrl(videoUri)) {
      await launchUrl(videoUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la vidéo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getFileIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'zip':
      case 'rar':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openFile(String url) async {
    final Uri fileUri = Uri.parse(url);
    if (await canLaunchUrl(fileUri)) {
      await launchUrl(fileUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir le fichier'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Téléchargement de "$fileName" en cours...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Ouvrir le fichier dans le navigateur/app externe pour téléchargement
      final Uri fileUri = Uri.parse(url);
      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('URL invalide');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
