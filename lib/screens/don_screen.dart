import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
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

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      ),
      body: SingleChildScrollView(
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
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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

                  // Si le paiement est réussi, retourner
                  if (result == true) {
                    if (!mounted) return;
                    Navigator.pop(context, true);
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
}
