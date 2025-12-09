import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../models/register_request.dart';
import '../utils/validators.dart';
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
        _dateNaissanceController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_formKey1.currentState!.validate()) {
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les mots de passe ne correspondent pas'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        setState(() {
          _currentStep = 1;
        });
      }
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
    if (!_formKey2.currentState!.validate()) {
      return;
    }

    if (!_accepteConditions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez accepter les conditions d\'utilisation pour continuer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final registerRequest = RegisterRequest(
      username: _usernameController.text,
      codeAdhesion: _codeAdhesionController.text,
      password: _passwordController.text,
      nom: _nomController.text,
      prenom: _prenomController.text,
      surnom: _surnomController.text.isEmpty ? null : _surnomController.text,
      sexe: _sexe!,
      lieuDeNaissance: _lieuNaissanceController.text,
      dateDeNaissance: _dateNaissanceController.text,
      nomPere: _nomPereController.text.isEmpty ? null : _nomPereController.text,
      nomMere: _nomMereController.text.isEmpty ? null : _nomMereController.text,
      nin: _ninController.text.isEmpty ? null : _ninController.text,
      nif: _nifController.text.isEmpty ? null : _nifController.text,
      situationMatrimoniale: _situationMatrimoniale,
      nbEnfants: _nbEnfantsController.text.isEmpty
          ? null
          : int.tryParse(_nbEnfantsController.text),
      nbPersonnesACharge: _nbPersonnesChargeController.text.isEmpty
          ? null
          : int.tryParse(_nbPersonnesChargeController.text),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de l\'inscription'),
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
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _codeAdhesionController,
                    hintText: 'Code de référence',
                    prefixIcon: Icons.qr_code,
                    helperText: 'Obligatoire pour l\'inscription',
                    validator: (value) =>
                        Validators.validateRequired(value, 'Le code de référence'),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: IconButton(
                    onPressed: _scanQRCode,
                    icon: const Icon(Icons.qr_code_scanner, size: 32),
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
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _prenomController,
              hintText: 'Prénom',
              validator: (value) =>
                  Validators.validateRequired(value, 'Le prénom'),
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
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _lieuNaissanceController,
              hintText: 'Lieu de naissance',
              validator: (value) =>
                  Validators.validateRequired(value, 'Le lieu de naissance'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _dateNaissanceController,
              hintText: 'Date de naissance (AAAA-MM-JJ)',
              suffixIcon: IconButton(
                icon: const Icon(Icons.calendar_today, color: Colors.red),
                onPressed: () => _selectDate(context),
              ),
              validator: Validators.validateDate,
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
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nifController,
              hintText: 'NIF',
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
            CustomTextField(
              controller: _telephonePrincipalController,
              hintText: 'Téléphone principal',
              keyboardType: TextInputType.phone,
              validator: (value) => Validators.validatePhone(value),
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
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _adresseCompleteController,
              hintText: 'Adresse complète',
              maxLines: 2,
              validator: (value) =>
                  Validators.validateRequired(value, 'L\'adresse'),
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
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _referentPrenomController,
              hintText: 'Prénom',
              validator: (value) =>
                  Validators.validateRequired(value, 'Le prénom du référent'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _referentAdresseController,
              hintText: 'Adresse',
              maxLines: 2,
              validator: (value) =>
                  Validators.validateRequired(value, 'L\'adresse du référent'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _referentTelephoneController,
              hintText: 'Téléphone',
              keyboardType: TextInputType.phone,
              validator: (value) => Validators.validatePhone(value),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _relationReferentController,
              hintText: 'Relation avec la personne',
              validator: (value) =>
                  Validators.validateRequired(value, 'La relation'),
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
}
