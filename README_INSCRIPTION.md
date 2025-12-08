# Écran d'Inscription - Nou App

## Description

Application Flutter avec un système d'inscription en deux étapes connecté au backend `nou-backend`.

## Architecture

```
lib/
├── constants/
│   └── api_constants.dart          # Configuration API (baseUrl, endpoints)
├── models/
│   └── register_request.dart       # Modèle de données pour l'inscription
├── services/
│   └── api_service.dart            # Service pour les appels API avec Dio
├── utils/
│   └── validators.dart             # Fonctions de validation des champs
├── widgets/
│   ├── custom_text_field.dart      # Widget TextField personnalisé
│   └── custom_dropdown.dart        # Widget Dropdown personnalisé
├── screens/
│   └── inscription_screen.dart     # Écran d'inscription complet
└── main.dart                        # Point d'entrée de l'application
```

## Fonctionnalités

### Étape 1 - Création du compte
- **Nom d'utilisateur** : validation (lettres, chiffres, underscore uniquement)
- **Code de référence** : obligatoire, doit exister dans la base de données
- **Mot de passe** : validation (min 8 caractères, 1 majuscule, 1 chiffre)
- **Confirmation du mot de passe** : vérification de correspondance

### Étape 2 - Informations personnelles (40+ champs)
Organisé en sections :

#### Informations personnelles
- Nom, Prénom, Surnom
- Sexe (dropdown)
- Lieu et date de naissance (avec date picker)
- Nom du père, nom de la mère
- NIN, NIF
- Situation matrimoniale (dropdown)
- Nombre d'enfants et personnes à charge

#### Contact
- Téléphone principal (obligatoire)
- Téléphone étranger (optionnel)
- Email (validation)
- Adresse complète

#### Profession et localisation
- Profession, Occupation
- Département (dropdown - 10 départements d'Haïti)
- Commune, Section communale

#### Réseaux sociaux
- Facebook, Instagram

#### Historique politique et organisations
- Questions oui/non avec champs conditionnels
- Rôles et noms des partis/organisations précédents

#### Référent (en cas d'urgence)
- Nom, Prénom, Adresse, Téléphone
- Relation avec la personne

#### Antécédents
- Questions oui/non (condamnations, drogues, terrorisme)

#### Photo de profil
- Sélection d'image depuis la galerie

## Design

- **Couleurs principales** : Rouge et blanc
- **AppBar** : Rouge avec texte blanc
- **Boutons** : Rouge avec texte blanc
- **Champs de formulaire** : 
  - Fond gris clair (#F5F5F5)
  - Bordure rouge au focus
  - Coins arrondis (8px)
- **Header** : Fond rose clair (#FFF5F5)

## Validation des champs

Toutes les validations sont dans `lib/utils/validators.dart` :
- Email : format email valide
- Téléphone : format international (8-20 caractères)
- Mot de passe : 8+ caractères, 1 majuscule, 1 chiffre
- Date : format YYYY-MM-DD, ne peut pas être dans le futur
- NIN/NIF : longueur minimale
- Champs obligatoires : vérification non vide

## Configuration du backend

Dans `lib/constants/api_constants.dart`, modifiez l'URL du backend :

```dart
static const String baseUrl = 'http://localhost:4000'; // Pour émulateur Android : 10.0.2.2:4000
```

## API Endpoints utilisés

- `POST /auth/register` : Inscription d'un nouveau membre
- `GET /auth/verify-code/:code` : Vérification du code d'adhésion (optionnel)

### Format de la requête d'inscription

```json
{
  "username": "string",
  "code_adhesion": "string",
  "password": "string",
  "nom": "string",
  "prenom": "string",
  "surnom": "string?",
  "sexe": "string",
  "lieu_de_naissance": "string",
  "date_de_naissance": "YYYY-MM-DD",
  // ... tous les autres champs (40+)
}
```

## Dépendances utilisées

```yaml
dependencies:
  provider: ^6.1.2              # State management
  dio: ^5.7.0                   # HTTP client
  flutter_secure_storage: ^9.2.2   # Stockage sécurisé
  shared_preferences: ^2.3.3    # Préférences locales
  image_picker: ^1.1.2          # Sélection d'images
  audioplayers: ^6.1.0          # Lecture audio
  qr_flutter: ^4.1.0            # QR codes
```

## Installation et lancement

1. **Installer les dépendances** :
   ```bash
   flutter pub get
   ```

2. **Lancer le backend nou-backend** :
   ```bash
   cd ../nou-backend
   npm start
   ```

3. **Lancer l'application** :
   ```bash
   flutter run
   ```

## Points d'amélioration futurs

1. **Upload d'images** : Implémenter l'upload de la photo de profil vers le serveur
2. **Vérification du code d'adhésion** : Appel API en temps réel lors de la saisie
3. **Sauvegarde temporaire** : Sauvegarder les données entre les étapes
4. **Indicateur de progression** : Barre de progression visuelle
5. **Internationalisation** : Support multilingue (français/créole)
6. **Mode hors-ligne** : Sauvegarde locale avec synchronisation ultérieure

## Gestion des erreurs

L'application gère :
- Erreurs de validation des champs
- Erreurs de connexion au serveur
- Réponses d'erreur du backend
- Affichage de messages utilisateur via SnackBar

## Notes importantes

- Le code d'adhésion doit exister dans la base de données backend
- Tous les champs marqués comme obligatoires dans le modèle doivent être remplis
- Les mots de passe ne sont jamais stockés en clair
- La validation est à la fois côté client (Flutter) et serveur (backend)
