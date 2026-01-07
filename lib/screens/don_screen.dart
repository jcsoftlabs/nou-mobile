import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/payment_service.dart';
import '../services/notification_service.dart';
import '../data/providers/auth_provider.dart';
import '../models/don.dart';
import '../widgets/custom_text_field.dart';
import 'payment_screen.dart';

class DonScreen extends StatefulWidget {
  const DonScreen({super.key});

  @override
  State<DonScreen> createState() => _DonScreenState();
}

class _DonScreenState extends State<DonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _montantController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Don> _historique = [];
  bool _isLoading = false;
  bool _showHistory = false;
  Timer? _pendingPaymentTimer;

  @override
  void initState() {
    super.initState();
    _loadDonHistory();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    _pendingPaymentTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDonHistory() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final membreId = authProvider.currentMembre?.id;

      if (membreId != null) {
        final result = await _apiService.getDonsByMembre(membreId);
        if (result['success']) {
          setState(() {
            _historique = (result['data'] as List)
                .map((json) => Don.fromJson(json))
                .toList();
          });
        } else {
          print('Erreur chargement dons: ${result['message']}');
        }
      }
    } catch (e) {
      print('Exception chargement dons: $e');
    } finally {
      setState(() => _isLoading = false);
    }
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
              'don',
            );

            // Rafraîchir
            await _loadDonHistory();

            // Afficher snackbar
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Votre don a été confirmé !'),
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
                      Text('Votre don a échoué.'),
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

  Color _getStatutColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'approuve':
        return Colors.green;
      case 'rejete':
        return Colors.red;
      case 'en_attente':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut.toLowerCase()) {
      case 'approuve':
        return Icons.check_circle;
      case 'rejete':
        return Icons.cancel;
      case 'en_attente':
      default:
        return Icons.schedule;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut.toLowerCase()) {
      case 'approuve':
        return 'Approuvé';
      case 'rejete':
        return 'Rejeté';
      case 'en_attente':
      default:
        return 'En attente';
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Faire un don',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.add : Icons.history),
            onPressed: () {
              setState(() => _showHistory = !_showHistory);
            },
            tooltip: _showHistory ? 'Nouveau don' : 'Historique',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _showHistory
              ? _buildHistoryView()
              : _buildFormView(),
    );
  }

  Widget _buildFormView() {
    return RefreshIndicator(
      onRefresh: _loadDonHistory,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Message d'information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.red.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Votre don sera traité de manière sécurisée via PlopPlop.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Champ Montant
              CustomTextField(
                controller: _montantController,
                hintText: 'Montant du don (HTG)',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.attach_money,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\\d+\\.?\\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final montant = double.tryParse(value);
                  if (montant == null || montant < 20) {
                    return 'Le montant minimum est de 20 HTG';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Champ Description
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Message ou description (optionnel)',
                maxLines: 4,
                prefixIcon: Icons.message_outlined,
              ),

              const SizedBox(height: 40),

              // Bouton Payer en ligne
              ElevatedButton.icon(
                onPressed: () async {
                  // Valider le formulaire
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }

                  final montant = double.parse(_montantController.text);

                  // Naviguer vers l'écran de paiement
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        type: 'don',
                        montant: montant,
                        metadata: {
                          'description': _descriptionController.text.isEmpty
                              ? null
                              : _descriptionController.text,
                        },
                      ),
                    ),
                  );

                  // Gérer le résultat du paiement
                  if (result != null && result is Map<String, dynamic>) {
                    final status = result['status'];

                    if (status == 'completed') {
                      // ✅ Don réussi
                      _montantController.clear();
                      _descriptionController.clear();

                      // Rafraîchir immédiatement
                      await _loadDonHistory();

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
                                    'Don de ${result['montant'].toStringAsFixed(2)} HTG effectué avec succès !',
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
                      // ⏳ Don en attente
                      _montantController.clear();
                      _descriptionController.clear();

                      // Rafraîchir quand même
                      await _loadDonHistory();

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
                                    'Don en cours de traitement. Vous serez notifié dès confirmation.',
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
                icon: const Icon(Icons.payment, size: 24),
                label: const Text(
                  'Payer en ligne',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),

              const SizedBox(height: 20),

              // Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Les paiements sont traités de manière sécurisée via PlopPlop (MonCash, Kashpaw, NatCash).',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
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

  Widget _buildHistoryView() {
    if (_historique.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Aucun don enregistré',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos dons apparaîtront ici',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDonHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _historique.length,
        itemBuilder: (context, index) {
          final don = _historique[index];
          final color = _getStatutColor(don.statutDon);
          final icon = _getStatutIcon(don.statutDon);
          final label = _getStatutLabel(don.statutDon);

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
                              label,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            Text(
                              '${don.montant} HTG',
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
                  if (don.description != null && don.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      don.description!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date: ${DateFormat.yMd('fr_FR').format(don.dateDon)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (don.dateVerification != null)
                        Text(
                          'Vérifié: ${DateFormat.yMd('fr_FR').format(don.dateVerification!)}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
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
