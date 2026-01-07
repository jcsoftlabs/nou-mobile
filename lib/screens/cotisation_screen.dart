import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/cotisation.dart';
import '../models/cotisation_status.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../data/providers/auth_provider.dart';
import '../widgets/gradient_app_bar.dart';
import 'payment_screen.dart';

class CotisationScreen extends StatefulWidget {
  final int membreId;

  const CotisationScreen({
    super.key,
    required this.membreId,
  });

  @override
  State<CotisationScreen> createState() => _CotisationScreenState();
}

class _CotisationScreenState extends State<CotisationScreen> {
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();
  final _montantController = TextEditingController();

  Cotisation? _derniereCotisation;
  CotisationStatus? _cotisationStatus;
  List<Cotisation> _historique = [];
  bool _isLoading = false;
  bool _showHistory = false;
  double? _montantSaisi;
  Timer? _pendingPaymentTimer;

  @override
  void initState() {
    super.initState();
    _loadCotisationStatus();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _pendingPaymentTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCotisationStatus() async {
    setState(() => _isLoading = true);

    try {
      // Charger le statut annuel
      final status = await _apiService.getCotisationStatus();
      
      // Charger la dernière cotisation
      final derniere = await _apiService.getLastCotisation(widget.membreId);
      
      // Charger l'historique
      final result = await _apiService.getCotisations(widget.membreId);
      
      if (mounted) {
        setState(() {
          _cotisationStatus = status;
          _derniereCotisation = derniere;
          if (result['success']) {
            _historique = result['data'] as List<Cotisation>;
          } else {
            // Endpoint non disponible, liste vide
            _historique = [];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      // Gérer les erreurs de connexion
      if (mounted) {
        setState(() {
          _historique = [];
          _isLoading = false;
        });
      }
    }
  }

  String? _validateMontant() {
    if (_cotisationStatus == null || _montantSaisi == null) {
      return 'Veuillez entrer un montant';
    }
    
    final status = _cotisationStatus!;
    
    // Vérifier le minimum
    if (_montantSaisi! < status.montantMinimumProchainVersement) {
      if (status.estPremierVersement) {
        return 'Le premier versement doit être d\'au moins ${status.montantMinimumProchainVersement.toStringAsFixed(0)} HTG';
      }
      return 'Le montant minimum est de ${status.montantMinimumProchainVersement.toStringAsFixed(0)} HTG';
    }
    
    // Vérifier le maximum
    if (_montantSaisi! > status.montantRestant) {
      return 'Le montant dépasse le solde restant (${status.montantRestant.toStringAsFixed(0)} HTG)';
    }
    
    // Cotisation déjà complète
    if (status.estComplet) {
      return 'Votre cotisation pour cette période d\'adhésion est déjà complète';
    }
    
    return null; // Valide
  }

  void _startPendingPaymentCheck(String referenceId) {
    _pendingPaymentTimer?.cancel();
    
    _pendingPaymentTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        timer.cancel();
        return;
      }
      
      try {
        final result = await PaymentService().checkPaymentStatus(
          token: token,
          referenceId: referenceId,
        );
        
        if (result['success']) {
          final status = result['data']['status'];
          
          if (status == 'completed') {
            timer.cancel();
            
            // Afficher notification
            await NotificationService.showPaymentConfirmed(
              result['data']['montant'] ?? 0.0,
              'cotisation',
            );
            
            // Rafraîchir
            await _loadCotisationStatus();
            
            // Afficher snackbar
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Votre paiement a été confirmé !'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          } else if (status == 'failed') {
            timer.cancel();
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Votre paiement a échoué.'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 5),
                ),
              );
            }
          }
        }
      } catch (e) {
        // Ignorer les erreurs de vérification
      }
    });
  }

  Future<void> _payWithMonCash() async {
    // Valider le montant
    final error = _validateMontant();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    // Simulation du flow MonCash
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paiement MonCash'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Montant : ${_montantSaisi!.toStringAsFixed(0)} HTG'),
            const SizedBox(height: 16),
            const Text(
              'En production, cette fonctionnalité ouvrira l\'API MonCash pour effectuer le paiement.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('Voulez-vous simuler un paiement réussi ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processMonCashPayment();
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _processMonCashPayment() async {
    setState(() => _isLoading = true);

    final request = CotisationRequest(
      membreId: widget.membreId,
      montant: _montantSaisi!, // Utiliser le montant saisi
      moyenPaiement: 'moncash',
    );

    final result = await _apiService.createCotisation(request);

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['success']) {
      // Réinitialiser le champ de montant
      _montantController.clear();
      _montantSaisi = null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement MonCash enregistré avec succès ! En attente de validation.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCotisationStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur lors du paiement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadReceipt() async {
    // Valider le montant
    final error = _validateMontant();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisir un type de fichier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.red),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.red),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
              title: const Text('Choisir un PDF'),
              onTap: () {
                Navigator.pop(context);
                _pickPDF();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      _uploadFile(image.path);
    }
  }

  Future<void> _pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      _uploadFile(result.files.single.path!);
    }
  }

  Future<void> _uploadFile(String filePath) async {
    setState(() => _isLoading = true);

    final request = CotisationRequest(
      membreId: widget.membreId,
      montant: _montantSaisi!, // Utiliser le montant saisi
      moyenPaiement: 'recu_upload',
      recuPath: filePath,
    );

    final result = await _apiService.createCotisation(request);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      // Réinitialiser le champ de montant
      _montantController.clear();
      _montantSaisi = null;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reçu uploadé avec succès ! En attente de validation.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCotisationStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur lors de l\'upload'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'validé':
      case 'valide':
        return Colors.green;
      case 'rejeté':
      case 'rejete':
        return Colors.red;
      case 'en attente':
      case 'attente':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.orange;
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
      case 'en attente':
      case 'attente':
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.schedule;
    }
  }

  String _getStatusMessage(String statut) {
    switch (statut.toLowerCase()) {
      case 'validé':
      case 'valide':
        return 'Votre dernier paiement a été validé.';
      case 'rejeté':
      case 'rejete':
        return 'Votre dernier paiement a été rejeté. Veuillez contacter un administrateur.';
      case 'en attente':
      case 'attente':
      case 'pending':
        return 'Votre dernier reçu est en attente de validation par un administrateur.';
      default:
        return 'Votre dernier paiement est en cours de traitement.';
    }
  }

  Widget _buildAnnualStatusCard() {
    if (_cotisationStatus == null) return const SizedBox.shrink();
    
    final status = _cotisationStatus!;
    final progress = status.montantVerse / status.montantTotalAnnuel;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.red.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre période d\'adhésion',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              color: Colors.red,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 12),
          
          // Montants
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Versé', style: TextStyle(color: Colors.grey)),
                  Text(
                    '${status.montantVerse.toStringAsFixed(0)} HTG',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Restant', style: TextStyle(color: Colors.grey)),
                  Text(
                    '${status.montantRestant.toStringAsFixed(0)} HTG',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // Badge de statut
          if (status.estComplet)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Cotisation complète',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMontantInput() {
    if (_cotisationStatus == null) return const SizedBox.shrink();
    
    final status = _cotisationStatus!;
    final montantMin = status.montantMinimumProchainVersement;
    final montantMax = status.montantRestant;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Montant du versement',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _montantController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Entrez le montant (HTG)',
            prefixIcon: const Icon(Icons.money, color: Colors.red),
            suffixText: 'HTG',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            helperText: status.estPremierVersement
                ? 'Minimum : ${montantMin.toStringAsFixed(0)} HTG (premier versement)'
                : 'Minimum : ${montantMin.toStringAsFixed(0)} HTG - Maximum : ${montantMax.toStringAsFixed(0)} HTG',
            helperMaxLines: 2,
          ),
          onChanged: (value) {
            setState(() {
              _montantSaisi = double.tryParse(value);
            });
          },
        ),
        
        // Suggestions de montants
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (!status.estComplet) ...[
              _buildMontantSuggestion(status.montantRestant, 'Payer le solde'),
              if (status.montantRestant >= 500)
                _buildMontantSuggestion(500, '500 HTG'),
              if (status.montantRestant >= 300)
                _buildMontantSuggestion(300, '300 HTG'),
              if (status.estPremierVersement && status.montantRestant >= 150)
                _buildMontantSuggestion(150, '150 HTG (minimum)'),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMontantSuggestion(double montant, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _montantController.text = montant.toStringAsFixed(0);
          _montantSaisi = montant;
        });
      },
      backgroundColor: Colors.red.shade50,
      side: BorderSide(color: Colors.red.shade200),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Cotisation',
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.payment : Icons.history),
            onPressed: () {
              setState(() => _showHistory = !_showHistory);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showHistory
              ? _buildHistoryView()
              : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    return RefreshIndicator(
      onRefresh: _loadCotisationStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statut annuel de cotisation
            _buildAnnualStatusCard(),
            const SizedBox(height: 24),

            // Statut de cotisation pour la période actuelle
            if (_cotisationStatus != null && !_cotisationStatus!.estActif) ...[
              _buildCurrentPeriodWarning(),
              const SizedBox(height: 24),
            ] else if (_derniereCotisation != null && _derniereCotisation!.statutPaiement.toLowerCase() == 'en attente') ...[
              _buildPendingPaymentCard(),
              const SizedBox(height: 24),
            ],

            // Champ de saisie du montant
            _buildMontantInput(),

            const SizedBox(height: 32),

            // Bouton Payer en ligne (PlopPlop)
            ElevatedButton.icon(
              onPressed: () async {
                // Valider le montant
                final error = _validateMontant();
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                  return;
                }

                // Naviguer vers l'écran de paiement
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      type: 'cotisation',
                      montant: _montantSaisi!,
                      metadata: {
                        'annee': _cotisationStatus?.annee,
                        'membre_id': widget.membreId,
                      },
                    ),
                  ),
                );

                // Gérer le résultat du paiement
                if (result != null && result is Map<String, dynamic>) {
                  final status = result['status'];
                  
                  if (status == 'completed') {
                    // ✅ Paiement réussi
                    _montantController.clear();
                    _montantSaisi = null;
                    
                    // Rafraîchir immédiatement
                    await _loadCotisationStatus();
                    
                    // Afficher message de succès
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Paiement de ${result['montant'].toStringAsFixed(2)} HTG effectué avec succès !',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  } else if (status == 'pending') {
                    // ⏳ Paiement en attente
                    _montantController.clear();
                    _montantSaisi = null;
                    
                    // Rafraîchir quand même (le paiement apparaîtra comme "en attente")
                    await _loadCotisationStatus();
                    
                    // Démarrer vérification périodique
                    _startPendingPaymentCheck(result['reference_id']);
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              Icon(Icons.schedule, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Paiement en cours de traitement. Vous serez notifié dès confirmation.',
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.orange,
                          duration: Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.payment, size: 28),
              label: const Text(
                'Payer en ligne',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Information générale
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Les paiements sont traités de manière sécurisée via PlopPlop.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
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

  Widget _buildCurrentPeriodWarning() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cotisation non à jour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vous devez payer votre cotisation pour la période actuelle.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPaymentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.blue.shade700, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement en attente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Votre dernier paiement est en attente de validation par un administrateur.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final cotisation = _derniereCotisation!;
    final color = _getStatutColor(cotisation.statutPaiement);
    final icon = _getStatutIcon(cotisation.statutPaiement);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statut du dernier paiement',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cotisation.statutPaiement,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Montant',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cotisation.formattedMontant,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Moyen de paiement',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cotisation.moyenPaiement ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date de création',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${cotisation.dateCreation.day}/${cotisation.dateCreation.month}/${cotisation.dateCreation.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              if (cotisation.dateValidation != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date de validation',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${cotisation.dateValidation!.day}/${cotisation.dateValidation!.month}/${cotisation.dateValidation!.year}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_historique.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Aucun historique de paiement',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCotisationStatus,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historique.length,
        itemBuilder: (context, index) {
          final cotisation = _historique[index];
          final color = _getStatutColor(cotisation.statutPaiement);
          final icon = _getStatutIcon(cotisation.statutPaiement);

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cotisation.statutPaiement,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              cotisation.formattedMontant,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Moyen: ${cotisation.moyenPaiement ?? "N/A"}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        '${cotisation.dateCreation.day}/${cotisation.dateCreation.month}/${cotisation.dateCreation.year}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
