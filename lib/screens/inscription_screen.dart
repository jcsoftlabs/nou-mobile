import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../models/register_request.dart';
import '../services/api_service.dart';
import '../utils/validators.dart';
import '../utils/nif_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown.dart';
import '../constants/haiti_locations.dart';
import 'qr_scanner_screen.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({super.key});

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  // État de validation du code d'adhésion
  bool? _codeAdhesionValid;
  bool _isVerifyingCode = false;
  String? _codeVerificationMessage;
  
  // États de validation en temps réel
  bool? _usernameAvailable;
  bool _isVerifyingUsername = false;
  String? _usernameMessage;
  List<String> _usernameSuggestions = [];
  Timer? _usernameDebounce;
  
  bool? _emailAvailable;
  bool _isVerifyingEmail = false;
  String? _emailMessage;
  Timer? _emailDebounce;
  
  bool? _phoneAvailable;
  bool _isVerifyingPhone = false;
  String? _phoneMessage;
  Timer? _phoneDebounce;
  
  bool? _ninAvailable;
  bool _isVerifyingNin = false;
  String? _ninMessage;
  Timer? _ninDebounce;

  // Contrôleurs Étape 1
  final _usernameController = TextEditingController();
  final _codeAdhesionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Contrôleurs Étape 2
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _surnomController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _dateNaissanceController = TextEditingController();
  final _nomPereController = TextEditingController();
  final _nomMereController = TextEditingController();
  final _ninController = TextEditingController();
  final _nifController = TextEditingController();
  final _nbEnfantsController = TextEditingController();
  final _nbPersonnesChargeController = TextEditingController();
  final _telephonePrincipalController = TextEditingController();
  final _telephoneEtrangerController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseCompleteController = TextEditingController();
  final _professionController = TextEditingController();
  final _occupationController = TextEditingController();
  final _sectionCommunaleController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _rolePolitiquePrecedentController = TextEditingController();
  final _nomPartiPrecedentController = TextEditingController();
  final _roleOrganisationPrecedentController = TextEditingController();
  final _nomOrganisationPrecedenteController = TextEditingController();
  final _referentNomController = TextEditingController();
  final _referentPrenomController = TextEditingController();
  final _referentAdresseController = TextEditingController();
  final _referentTelephoneController = TextEditingController();
  final _relationReferentController = TextEditingController();

  String? _sexe;
  String? _situationMatrimoniale;
  String? _departement;
  String? _commune;
  bool _aEteMembrePolitique = false;
  bool _aEteMembreOrganisation = false;
  bool _aEteCondamne = false;
  bool _aVioleLoiDrogue = false;
  bool _aParticipeActiviteTerroriste = false;
  String? _photoProfilUrl;
  bool _accepteConditions = false;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
    _phoneDebounce?.cancel();
    _ninDebounce?.cancel();
    _usernameController.dispose();
    _codeAdhesionController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _surnomController.dispose();
    _lieuNaissanceController.dispose();
    _dateNaissanceController.dispose();
    _nomPereController.dispose();
    _nomMereController.dispose();
    _ninController.dispose();
    _nifController.dispose();
    _nbEnfantsController.dispose();
    _nbPersonnesChargeController.dispose();
    _telephonePrincipalController.dispose();
    _telephoneEtrangerController.dispose();
    _emailController.dispose();
    _adresseCompleteController.dispose();
    _professionController.dispose();
    _occupationController.dispose();
    _sectionCommunaleController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _rolePolitiquePrecedentController.dispose();
    _nomPartiPrecedentController.dispose();
    _roleOrganisationPrecedentController.dispose();
    _nomOrganisationPrecedenteController.dispose();
    _referentNomController.dispose();
    _referentPrenomController.dispose();
    _referentAdresseController.dispose();
    _referentTelephoneController.dispose();
    _relationReferentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (image != null) {
      setState(() {
        _photoProfilUrl = image.path;
      });
    }
  }

  Future<void> _scanQRCode() async {
    final String? scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    if (scannedCode != null && mounted) {
      setState(() {
        _codeAdhesionController.text = scannedCode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Code scanné : $scannedCode'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // Afficher au format JJ/MM/AAAA (plus intuitif)
        _dateNaissanceController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _verifyCodeAdhesion() async {
    final code = _codeAdhesionController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _codeAdhesionValid = false;
        _codeVerificationMessage = 'Veuillez entrer un code';
      });
      return;
    }

    setState(() {
      _isVerifyingCode = true;
      _codeVerificationMessage = null;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.verifyCodeAdhesion(code);
      
      setState(() {
        _codeAdhesionValid = result['exists'] == true;
        _codeVerificationMessage = result['message'];
        _isVerifyingCode = false;
      });
    } catch (e) {
      setState(() {
        _codeAdhesionValid = false;
        _codeVerificationMessage = 'Erreur lors de la vérification';
        _isVerifyingCode = false;
      });
    }
  }

  Future<void> _verifyUsername(String username) async {
    if (username.isEmpty || username.length < 3) {
      setState(() {
        _usernameAvailable = null;
        _usernameMessage = null;
        _usernameSuggestions = [];
      });
      return;
    }

    setState(() {
      _isVerifyingUsername = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.checkUsernameAvailability(username);
      
      setState(() {
        _usernameAvailable = result['available'] == true;
        _usernameMessage = result['message'];
        _usernameSuggestions = (result['suggestions'] as List?)?.cast<String>() ?? [];
        _isVerifyingUsername = false;
      });
    } catch (e) {
      setState(() {
        _usernameAvailable = null;
        _usernameMessage = null;
        _isVerifyingUsername = false;
      });
    }
  }

  Future<void> _verifyEmail(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _emailAvailable = null;
        _emailMessage = null;
      });
      return;
    }

    setState(() {
      _isVerifyingEmail = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.checkEmailAvailability(email);
      
      setState(() {
        _emailAvailable = result['available'] == true;
        _emailMessage = result['message'];
        _isVerifyingEmail = false;
      });
    } catch (e) {
      setState(() {
        _emailAvailable = null;
        _emailMessage = null;
        _isVerifyingEmail = false;
      });
    }
  }

  Future<void> _verifyPhone(String phone) async {
    if (phone.isEmpty || phone.length < 8) {
      setState(() {
        _phoneAvailable = null;
        _phoneMessage = null;
      });
      return;
    }

    setState(() {
      _isVerifyingPhone = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.checkPhoneAvailability(phone);
      
      setState(() {
        _phoneAvailable = result['available'] == true;
        _phoneMessage = result['message'];
        _isVerifyingPhone = false;
      });
    } catch (e) {
      setState(() {
        _phoneAvailable = null;
        _phoneMessage = null;
        _isVerifyingPhone = false;
      });
    }
  }

  Future<void> _verifyNin(String nin) async {
    if (nin.isEmpty || nin.length < 5) {
      setState(() {
        _ninAvailable = null;
        _ninMessage = null;
      });
      return;
    }

    setState(() {
      _isVerifyingNin = true;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.checkNinAvailability(nin);
      
      setState(() {
        _ninAvailable = result['available'] == true;
        _ninMessage = result['message'];
        _isVerifyingNin = false;
      });
    } catch (e) {
      setState(() {
        _ninAvailable = null;
        _ninMessage = null;
        _isVerifyingNin = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Valider le formulaire de l'étape 1
      if (!_formKey1.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Veuillez remplir tous les champs obligatoires',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Les mots de passe ne correspondent pas',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      
      // ⚠️ NOUVELLE VÉRIFICATION : Code d'adhésion obligatoire
      if (_codeAdhesionValid != true) {
        // Si le code n'a jamais été vérifié, le vérifier maintenant
        if (_codeAdhesionValid == null) {
          _verifyCodeAdhesion();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vérification du code de référence en cours...',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        
        // Si le code a été vérifié et est invalide
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _codeVerificationMessage ?? 'Code de référence invalide',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Scanner QR',
              textColor: Colors.white,
              onPressed: _scanQRCode,
            ),
          ),
        );
        return;
      }
      
      // Tout est valide, passer à l'étape 2
      setState(() {
        _currentStep = 1;
      });
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep = 0;
      });
    }
  }

  Future<void> _submitForm() async {
    // Valider le formulaire de l'étape 2
    if (!_formKey2.currentState!.validate()) {
      // Afficher un message clair à l'utilisateur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Veuillez remplir tous les champs obligatoires marqués en rouge',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_accepteConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vous devez accepter les conditions d\'utilisation pour continuer',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Convertir la date de JJ/MM/AAAA à AAAA-MM-JJ pour le backend
    String? dateNaissanceISO;
    if (_dateNaissanceController.text.isNotEmpty) {
      try {
        final parts = _dateNaissanceController.text.split('/');
        if (parts.length == 3) {
          final day = parts[0];
          final month = parts[1];
          final year = parts[2];
          dateNaissanceISO = '$year-$month-$day';
        }
      } catch (e) {
        // Si la conversion échoue, utiliser la valeur telle quelle
        dateNaissanceISO = _dateNaissanceController.text;
      }
    }

    final registerRequest = RegisterRequest(
      username: _usernameController.text,
      codeAdhesion: _codeAdhesionController.text,
      password: _passwordController.text,
      nom: _nomController.text,
      prenom: _prenomController.text,
      surnom: _surnomController.text.isEmpty ? null : _surnomController.text,
      sexe: _sexe ?? '',
      lieuDeNaissance: _lieuNaissanceController.text.isEmpty
          ? ''
          : _lieuNaissanceController.text,
      dateDeNaissance: dateNaissanceISO ?? '', // Utiliser la date convertie
      nomPere: _nomPereController.text.isEmpty ? null : _nomPereController.text,
      nomMere: _nomMereController.text.isEmpty ? null : _nomMereController.text,
      nin: _ninController.text,
      nif: _nifController.text.isEmpty 
          ? null 
          : nifToBackendFormat(_nifController.text), // Convertir XXX-XXX-XXX-X en XXXXXXXXXX
      situationMatrimoniale: _situationMatrimoniale,
      nbEnfants: _nbEnfantsController.text.isEmpty
          ? 0
          : int.tryParse(_nbEnfantsController.text) ?? 0,
      nbPersonnesACharge: _nbPersonnesChargeController.text.isEmpty
          ? 0
          : int.tryParse(_nbPersonnesChargeController.text) ?? 0,
      telephonePrincipal: _telephonePrincipalController.text,
      telephoneEtranger: _telephoneEtrangerController.text.isEmpty
          ? null
          : _telephoneEtrangerController.text,
      email: _emailController.text,
      adresseComplete: _adresseCompleteController.text,
      profession:
          _professionController.text.isEmpty ? null : _professionController.text,
      occupation:
          _occupationController.text.isEmpty ? null : _occupationController.text,
      departement: _departement!,
      commune: _commune!,
      sectionCommunale: _sectionCommunaleController.text.isEmpty
          ? null
          : _sectionCommunaleController.text,
      facebook:
          _facebookController.text.isEmpty ? null : _facebookController.text,
      instagram:
          _instagramController.text.isEmpty ? null : _instagramController.text,
      aEteMembrePolitique: _aEteMembrePolitique,
      rolePolitiquePrecedent: _rolePolitiquePrecedentController.text.isEmpty
          ? null
          : _rolePolitiquePrecedentController.text,
      nomPartiPrecedent: _nomPartiPrecedentController.text.isEmpty
          ? null
          : _nomPartiPrecedentController.text,
      aEteMembreOrganisation: _aEteMembreOrganisation,
      roleOrganisationPrecedent: _roleOrganisationPrecedentController.text.isEmpty
          ? null
          : _roleOrganisationPrecedentController.text,
      nomOrganisationPrecedente: _nomOrganisationPrecedenteController.text.isEmpty
          ? null
          : _nomOrganisationPrecedenteController.text,
      referentNom: _referentNomController.text,
      referentPrenom: _referentPrenomController.text,
      referentAdresse: _referentAdresseController.text,
      referentTelephone: _referentTelephoneController.text,
      relationAvecReferent: _relationReferentController.text,
      aEteCondamne: _aEteCondamne,
      aVioleLoiDrogue: _aVioleLoiDrogue,
      aParticipeActiviteTerroriste: _aParticipeActiviteTerroriste,
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Envoyer la requête avec la photo si elle existe, et connecter automatiquement
      final result = await authProvider.registerAndLogin(
        registerRequest,
        photoPath: _photoProfilUrl,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie !'),
            backgroundColor: Colors.green,
          ),
        );
        // L'utilisateur est maintenant authentifié : on l'envoie directement sur le Home.
        context.go('/home');
      } else {
        // Afficher un dialogue d'erreur détaillé
        _showErrorDialog(
          result['message'] ?? 'Erreur lors de l\'inscription',
          errorType: result['errorType'],
          fieldErrors: result['fieldErrors'],
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(
        'Une erreur inattendue est survenue',
        errorType: 'unknown',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF5F5),
              ),
              child: Text(
                _currentStep == 0
                    ? 'Inscription - Étape 1/2'
                    : 'Inscription',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
            Expanded(
              child: _currentStep == 0
                  ? _buildStep1()
                  : _buildStep2(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey1,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Icône utilisateur
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Créer un compte',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            CustomTextField(
              controller: _usernameController,
              hintText: 'Nom d\'utilisateur',
              prefixIcon: Icons.person_outline,
              helperText: 'Lettres, chiffres et _ uniquement',
              validator: Validators.validateUsername,
              isRequired: true,
              onChanged: (value) {
                // Annuler le timer précédent
                _usernameDebounce?.cancel();
                
                // Réinitialiser l'état si le champ est vide
                if (value.isEmpty || value.length < 3) {
                  setState(() {
                    _usernameAvailable = null;
                    _usernameMessage = null;
                    _usernameSuggestions = [];
                  });
                  return;
                }
                
                // Créer un nouveau timer de 800ms
                _usernameDebounce = Timer(const Duration(milliseconds: 800), () {
                  _verifyUsername(value);
                });
              },
              suffixIcon: _isVerifyingUsername
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                    )
                  : _usernameAvailable == true
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : _usernameAvailable == false
                          ? const Icon(Icons.cancel, color: Colors.red)
                          : null,
            ),
            if (_usernameMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _usernameAvailable == true
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color: _usernameAvailable == true
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _usernameMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: _usernameAvailable == true
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_usernameSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Suggestions : ${_usernameSuggestions.join(", ")}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _codeAdhesionController,
                        hintText: 'Code de référence',
                        prefixIcon: Icons.qr_code,
                        helperText: 'Obligatoire pour l\'inscription (sans espaces)',
                        isRequired: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le code de référence est requis';
                          }
                          if (value.contains(' ')) {
                            return 'Le code ne doit pas contenir d\'espaces';
                          }
                          // ⚠️ NOUVELLE VALIDATION : Vérifier que le code est valide
                          if (_codeAdhesionValid == false) {
                            return 'Ce code de référence est invalide';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          // Réinitialiser l'état de validation quand l'utilisateur modifie le code
                          if (_codeAdhesionValid != null) {
                            setState(() {
                              _codeAdhesionValid = null;
                              _codeVerificationMessage = null;
                            });
                          }
                          
                          // ⚠️ VÉRIFICATION AUTOMATIQUE avec debouncing
                          if (value.trim().isNotEmpty && value.length >= 3) {
                            // Annuler le timer précédent
                            _usernameDebounce?.cancel();
                            
                            // Créer un nouveau timer de 1 seconde
                            _usernameDebounce = Timer(const Duration(milliseconds: 1000), () {
                              _verifyCodeAdhesion();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: IconButton(
                        onPressed: _isVerifyingCode ? null : _verifyCodeAdhesion,
                        icon: _isVerifyingCode
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        tooltip: 'Vérifier le code',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: IconButton(
                        onPressed: _scanQRCode,
                        icon: const Icon(Icons.qr_code_scanner, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        tooltip: 'Scanner QR Code',
                      ),
                    ),
                  ],
                ),
                if (_codeVerificationMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Row(
                      children: [
                        Icon(
                          _codeAdhesionValid == true
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color: _codeAdhesionValid == true
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _codeVerificationMessage!,
                            style: TextStyle(
                              fontSize: 13,
                              color: _codeAdhesionValid == true
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _passwordController,
              hintText: 'Mot de passe',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              helperText: 'Min 8 caractères, 1 majuscule, 1 chiffre',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: Validators.validatePassword,
              isRequired: true,
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirmer le mot de passe',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
              isRequired: true,
            ),
            const SizedBox(height: 30),
            // Note d'information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Après validation\nVous compléterez vos informations personnelles à l\'étape suivante',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Bouton suivant
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _nextStep,
                child: const Text(
                  'Suivant',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Lien vers la page de connexion
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Vous avez déjà un compte ? ',
                  style: TextStyle(color: Colors.grey),
                ),
                GestureDetector(
                  onTap: () => context.go('/login'),
                  child: const Text(
                    'Se connecter',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Photo de profil
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: _photoProfilUrl == null
                      ? const Icon(
                          Icons.camera_alt,
                          size: 50,
                          color: Colors.white,
                        )
                      : ClipOval(
                          child: Image.network(
                            _photoProfilUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.camera_alt,
                                size: 50,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Informations personnelles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _nomController,
              hintText: 'Nom',
              validator: (value) => Validators.validateRequired(value, 'Le nom'),
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _prenomController,
              hintText: 'Prénom',
              validator: (value) =>
                  Validators.validateRequired(value, 'Le prénom'),
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _surnomController,
              hintText: 'Surnom',
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              value: _sexe,
              hintText: 'Sexe',
              items: const ['Masculin', 'Féminin', 'Autre'],
              onChanged: (value) => setState(() => _sexe = value),
              validator: (value) => Validators.validateRequired(value, 'Le sexe'),
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _lieuNaissanceController,
              hintText: 'Lieu de naissance',
              validator: (value) =>
                  Validators.validateRequired(value, 'Le lieu de naissance'),
              isRequired: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _dateNaissanceController,
                    hintText: 'Date de naissance (JJ/MM/AAAA)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [DateInputFormatter()],
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.red),
                      onPressed: () => _selectDate(context),
                    ),
                    validator: Validators.validateDate,
                    isRequired: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nomPereController,
              hintText: 'Nom du père',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nomMereController,
              hintText: 'Nom de la mère',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _ninController,
              hintText: 'Numéro d\'Identification National',
              validator: (value) => Validators.validateNIN(value),
              isRequired: true,
              onChanged: (value) {
                _ninDebounce?.cancel();
                
                if (value.isEmpty || value.length < 5) {
                  setState(() {
                    _ninAvailable = null;
                    _ninMessage = null;
                  });
                  return;
                }
                
                _ninDebounce = Timer(const Duration(milliseconds: 800), () {
                  _verifyNin(value);
                });
              },
              suffixIcon: _isVerifyingNin
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                    )
                  : _ninAvailable == true
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : _ninAvailable == false
                          ? const Icon(Icons.cancel, color: Colors.red)
                          : null,
            ),
            if (_ninMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Row(
                  children: [
                    Icon(
                      _ninAvailable == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: _ninAvailable == true
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _ninMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _ninAvailable == true
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nifController,
              hintText: 'NIF (ex: 002-882-508-1)',
              keyboardType: TextInputType.number,
              inputFormatters: [NifInputFormatter()],
              validator: (value) => Validators.validateNIF(value),
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              value: _situationMatrimoniale,
              hintText: 'Situation matrimoniale',
              items: const [
                'Célibataire',
                'Marié(e)',
                'Divorcé(e)',
                'Veuf/Veuve',
                'Union libre'
              ],
              onChanged: (value) => setState(() => _situationMatrimoniale = value),
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nbEnfantsController,
              hintText: 'Nombre d\'enfants',
              keyboardType: TextInputType.number,
              validator: (value) => Validators.validateInteger(value),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nbPersonnesChargeController,
              hintText: 'Nombre de personnes à charge',
              keyboardType: TextInputType.number,
              validator: (value) => Validators.validateInteger(value),
            ),
            const SizedBox(height: 30),
            const Text(
              'Contact',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            IntlPhoneField(
              controller: _telephonePrincipalController,
              decoration: InputDecoration(
                hintText: 'Téléphone principal',
                hintStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                suffixIcon: _isVerifyingPhone
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        ),
                      )
                    : _phoneAvailable == true
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : _phoneAvailable == false
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null,
              ),
              initialCountryCode: 'HT', // Haïti par défaut
              dropdownIconPosition: IconPosition.trailing,
              dropdownTextStyle: const TextStyle(fontSize: 16),
              flagsButtonPadding: const EdgeInsets.only(left: 12),
              onChanged: (phone) {
                _phoneDebounce?.cancel();
                
                if (phone.completeNumber.isEmpty || phone.number.length < 8) {
                  setState(() {
                    _phoneAvailable = null;
                    _phoneMessage = null;
                  });
                  return;
                }
                
                _phoneDebounce = Timer(const Duration(milliseconds: 800), () {
                  _verifyPhone(phone.completeNumber);
                });
              },
              validator: (phone) {
                if (phone == null || phone.number.isEmpty) {
                  return 'Le téléphone principal est requis';
                }
                return null;
              },
            ),
            if (_phoneMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Row(
                  children: [
                    Icon(
                      _phoneAvailable == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: _phoneAvailable == true
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _phoneMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _phoneAvailable == true
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _telephoneEtrangerController,
              hintText: 'Numéro WhatsApp',
              keyboardType: TextInputType.phone,
              validator: (value) => Validators.validatePhone(value, required: false),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: (value) => Validators.validateRequired(value, 'L\'email'),
              isRequired: true,
              onChanged: (value) {
                _emailDebounce?.cancel();
                
                if (value.isEmpty || !value.contains('@')) {
                  setState(() {
                    _emailAvailable = null;
                    _emailMessage = null;
                  });
                  return;
                }
                
                _emailDebounce = Timer(const Duration(milliseconds: 800), () {
                  _verifyEmail(value);
                });
              },
              suffixIcon: _isVerifyingEmail
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                        ),
                      ),
                    )
                  : _emailAvailable == true
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : _emailAvailable == false
                          ? const Icon(Icons.cancel, color: Colors.red)
                          : null,
            ),
            if (_emailMessage != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Row(
                  children: [
                    Icon(
                      _emailAvailable == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 16,
                      color: _emailAvailable == true
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _emailMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _emailAvailable == true
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _adresseCompleteController,
              hintText: 'Adresse complète',
              maxLines: 3,
              validator: (value) => Validators.validateRequired(value, 'L\'adresse complète'),
              isRequired: true,
            ),
            const SizedBox(height: 30),
            const Text(
              'Profession et localisation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _professionController,
              hintText: 'Profession',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _occupationController,
              hintText: 'Occupation',
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              value: _departement,
              hintText: 'Département',
              items: const [
                'Artibonite',
                'Centre',
                'Grand\'Anse',
                'Nippes',
                'Nord',
                'Nord-Est',
                'Nord-Ouest',
                'Ouest',
                'Sud',
                'Sud-Est'
              ],
              onChanged: (value) {
                setState(() {
                  _departement = value;
                  // Réinitialiser la commune quand on change de département
                  _commune = null;
                });
              },
              validator: (value) =>
                  Validators.validateRequired(value, 'Le département'),
            ),
            const SizedBox(height: 16),
            CustomDropdown(
              value: _commune,
              hintText: 'Commune',
              items: HaitiLocations.getCommunesByDepartment(_departement),
              onChanged: (value) => setState(() => _commune = value),
              validator: (value) =>
                  Validators.validateRequired(value, 'La commune'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _sectionCommunaleController,
              hintText: 'Section communale',
            ),
            const SizedBox(height: 30),
            const Text(
              'Réseaux sociaux',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _facebookController,
              hintText: 'Facebook',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _instagramController,
              hintText: 'Instagram',
            ),
            const SizedBox(height: 30),
            const Text(
              'Historique politique et organisations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            _buildYesNoSwitch(
              'Avez-vous déjà été membre d\'un parti politique ?',
              _aEteMembrePolitique,
              (value) => setState(() => _aEteMembrePolitique = value),
            ),
            if (_aEteMembrePolitique) ...[
              const SizedBox(height: 16),
              CustomTextField(
                controller: _rolePolitiquePrecedentController,
                hintText: 'Rôle politique précédent',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nomPartiPrecedentController,
                hintText: 'Nom du parti précédent',
              ),
            ],
            const SizedBox(height: 16),
            _buildYesNoSwitch(
              'Avez-vous été membre d\'une organisation ?',
              _aEteMembreOrganisation,
              (value) => setState(() => _aEteMembreOrganisation = value),
            ),
            if (_aEteMembreOrganisation) ...[
              const SizedBox(height: 16),
              CustomTextField(
                controller: _roleOrganisationPrecedentController,
                hintText: 'Rôle dans l\'organisation',
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nomOrganisationPrecedenteController,
                hintText: 'Nom de l\'organisation',
              ),
            ],
            const SizedBox(height: 30),
            const Text(
              'En cas d\'urgence',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _referentNomController,
              hintText: 'Nom',
              validator: (value) =>
                  Validators.validateRequired(value, 'Le nom du référent'),
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _referentPrenomController,
              hintText: 'Prénom',
              validator: (value) =>
                  Validators.validateRequired(value, 'Le prénom du référent'),
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _referentAdresseController,
              hintText: 'Adresse',
              maxLines: 2,
              validator: (value) =>
                  Validators.validateRequired(value, 'L\'adresse du référent'),
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _referentTelephoneController,
              hintText: 'Téléphone (ex: +509 3712 3456)',
              keyboardType: TextInputType.phone,
              validator: (value) => Validators.validatePhone(value),
              isRequired: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _relationReferentController,
              hintText: 'Relation avec le référent',
              validator: (value) =>
                  Validators.validateRequired(value, 'La relation avec le référent'),
              isRequired: true,
            ),
            const SizedBox(height: 30),
            const Text(
              'Antécédents',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            _buildYesNoSwitch(
              'Avez-vous déjà été condamné ?',
              _aEteCondamne,
              (value) => setState(() => _aEteCondamne = value),
            ),
            const SizedBox(height: 16),
            _buildYesNoSwitch(
              'Avez-vous déjà violé une loi liée aux drogues ?',
              _aVioleLoiDrogue,
              (value) => setState(() => _aVioleLoiDrogue = value),
            ),
            const SizedBox(height: 16),
            _buildYesNoSwitch(
              'Avez-vous participé à des activités terroristes ?',
              _aParticipeActiviteTerroriste,
              (value) => setState(() => _aParticipeActiviteTerroriste = value),
            ),
            const SizedBox(height: 40),
            // Case à cocher pour les conditions d'utilisation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _accepteConditions ? Colors.green : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _accepteConditions,
                    onChanged: (value) {
                      setState(() {
                        _accepteConditions = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFFFF0000),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Je certifie avoir lu et compris toutes les questions, que mes informations sont fiables et j\'accepte de signer ce formulaire sans contrainte.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Boutons de navigation
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _previousStep,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Retour',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'S\'inscrire',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Colors.red.shade200,
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(
    String message, {
    String? errorType,
    Map<String, dynamic>? fieldErrors,
  }) {
    // Déterminer le titre et l'icône selon le type d'erreur
    String title = 'Erreur d\'inscription';
    IconData icon = Icons.error_outline;
    Color iconColor = Colors.red;

    if (errorType == 'network') {
      title = 'Problème de connexion';
      icon = Icons.wifi_off;
    } else if (errorType == 'validation') {
      title = 'Données invalides';
      icon = Icons.warning_amber_outlined;
      iconColor = Colors.orange;
    } else if (errorType == 'conflict') {
      title = 'Informations déjà utilisées';
      icon = Icons.person_off_outlined;
    } else if (errorType == 'not_found') {
      title = 'Code invalide';
      icon = Icons.qr_code_scanner_outlined;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            if (fieldErrors != null && fieldErrors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Détails des erreurs :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...fieldErrors.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.arrow_right,
                          size: 20,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_getFieldLabel(entry.key)} : ${entry.value}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
        actions: [
          if (errorType == 'network')
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitForm(); // Réessayer
              },
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              errorType == 'network' ? 'Annuler' : 'OK',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  String _getFieldLabel(String fieldKey) {
    const fieldLabels = {
      'username': 'Nom d\'utilisateur',
      'code_adhesion': 'Code d\'adhésion',
      'password': 'Mot de passe',
      'email': 'Email',
      'telephone_principal': 'Téléphone principal',
      'nom': 'Nom',
      'prenom': 'Prénom',
      'date_de_naissance': 'Date de naissance',
      'departement': 'Département',
      'commune': 'Commune',
    };
    return fieldLabels[fieldKey] ?? fieldKey;
  }
}
