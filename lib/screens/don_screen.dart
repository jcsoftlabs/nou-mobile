import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../models/don.dart';
import '../widgets/custom_text_field.dart';

class DonScreen extends StatefulWidget {
  const DonScreen({super.key});

  @override
  State<DonScreen> createState() => _DonScreenState();
}

class _DonScreenState extends State<DonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();
  final _montantController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  String? _recuPath;

  @override
  void dispose() {
    _montantController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickRecuImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (image != null) {
      setState(() {
        _recuPath = image.path;
      });
    }
  }

  Future<void> _submitDon() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final donRequest = DonRequest(
      montant: double.parse(_montantController.text),
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
    );

    try {
      final result = await _apiService.createDon(
        donRequest,
        recuPath: _recuPath,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Don enregistré avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retourner true pour indiquer succès
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de l\'enregistrement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                        'Votre don sera vérifié par un administrateur avant d\'être validé.',
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
                  if (montant == null || montant <= 0) {
                    return 'Veuillez entrer un montant valide';
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

              const SizedBox(height: 24),

              // Section reçu
              const Text(
                'Reçu de paiement (optionnel)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Bouton pour sélectionner le reçu
              InkWell(
                onTap: _pickRecuImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _recuPath != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_recuPath!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _recuPath = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Ajouter une photo du reçu',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'JPG, PNG (Max 5MB)',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // Bouton soumettre
              ElevatedButton(
                onPressed: _isLoading ? null : _submitDon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Soumettre le don',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
