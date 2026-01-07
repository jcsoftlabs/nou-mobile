# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

**nou_app** is a Flutter mobile application for a membership organization ("Nouveau Parti Politique"). Members can register, pay contributions (cotisations), listen to podcasts, access training modules, refer others, make donations, and view news/announcements.

The app connects to the **nou-backend** API (listed as "listing-backend" in some contexts), currently deployed at `https://nou-backend-production.up.railway.app`.

## Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific device
flutter run -d <device-id>

# Check available devices
flutter devices
```

### Code Quality
```bash
# Analyze Dart code
flutter analyze

# Check for outdated packages
flutter pub outdated

# Upgrade dependencies
flutter pub upgrade
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Building
```bash
# Build APK (Android)
flutter build apk --release

# Build iOS
flutter build ios --release

# Clean build artifacts
flutter clean
```

### App Icons
```bash
# Generate app icons after modifying assets/images/icon.jpg
flutter pub run flutter_launcher_icons:main
```

## Architecture

### State Management
- **Provider pattern** with `ChangeNotifier`
- Main providers:
  - `AuthProvider` (`lib/data/providers/auth_provider.dart`) - Authentication state, current user
  - `AudioPlayerService` (`lib/services/audio_player_service.dart`) - Global audio playback state

### Navigation
- **go_router** for declarative routing
- Route definitions in `lib/router/app_router.dart`
- Protected routes redirect unauthenticated users to `/welcome`
- `AppShell` wraps authenticated screens with bottom navigation bar
- **Android back button support**: See `ANDROID_BACK_BUTTON.md` for details
  - Main routes (bottom nav) use `context.go()` - back button exits app
  - Secondary routes use `context.push()` - back button returns to previous screen
  - `RootBackButtonDispatcher` configured in `main.dart`

### API Communication
- **Dio** HTTP client with interceptors
- `ApiService` (`lib/services/api_service.dart`) centralizes all API calls
- `AuthInterceptor` (`lib/core/services/auth_interceptor.dart`) adds auth token to requests
- Base URL defined in `lib/constants/api_constants.dart`

### Authentication Flow
1. User logs in via `LoginScreen`
2. `AuthProvider.login()` calls `ApiService.login()`
3. On success, token + member data stored in `FlutterSecureStorage`
4. `AuthProvider` notifies listeners, triggering route redirect
5. Token automatically included in subsequent API requests via `AuthInterceptor`

### Data Models
All models in `lib/models/`:
- `Membre` - User/member with 40+ fields (registration data)
- `Cotisation` - Membership contribution with payment status
- `CotisationStatus` - Annual contribution status (paid, remaining, complete)
- `Podcast` - Audio content with URL and listen count
- `Formation` - Training courses with modules
- `FormationModule` - Individual course modules (videos, downloadable files, quizzes)
- `Don` - Donations with receipt upload
- `NewsArticle` - News articles
- `Annonce` - Announcements
- `Referral` - Referral/sponsorship records
- `RegisterRequest` - Registration form data

### Key Screens

#### Authentication (`lib/screens/`)
- `SplashScreen` - Initial loading, checks auth state
- `WelcomeScreen` - Entry point for unauthenticated users
- `LoginScreen` - Login with username/email + password
- `ForgotPasswordScreen` - NIN-based password reset
- `InscriptionScreen` - Two-step registration (40+ fields)

#### Main Features
- `HomeScreen` - Dashboard with news, announcements, stats
- `PodcastScreen` - Audio content with background playback
- `FormationsListScreen` / `FormationDetailScreen` / `ModuleViewScreen` - Training courses
- `CotisationScreen` - Pay membership dues (MonCash or receipt upload)
- `ParrainageScreen` - Referral system with QR code generation/scanning
- `ProfileScreen` - User profile with edit capability
- `DonScreen` - Make donations
- `NewsListScreen` / `NewsDetailScreen` - News articles
- `AnnoncesScreen` - Announcements

### Reusable Widgets (`lib/widgets/`)
- `CustomTextField` - Styled text input with validation
- `CustomDropdown` - Styled dropdown selector
- `GlobalMiniPlayer` - Persistent audio player controls (visible across all authenticated screens)
- `GradientAppBar` - Custom app bar with gradient

### Theme & Styling
- Centralized in `lib/core/theme/app_theme.dart`
- **Primary color**: Red (`#FF0000`)
- **Typography**: Poppins font via `google_fonts`
- Material 3 design with custom input decoration
- TextFields have gray background (`#F5F5F5`), red border on focus

### Audio Playback Architecture
**Background audio implementation** (see `BACKGROUND_AUDIO_IMPLEMENTATION.md`):
- **Global service**: `AudioPlayerService` is a singleton Provider
- Configured for background playback on iOS and Android
- Persists across navigation and app backgrounding
- `GlobalMiniPlayer` widget in `AppShell` provides controls on all screens
- Supports seek forward/backward, play/pause
- Handles YouTube live streams by opening externally

### Cotisation (Contribution) Rules
See `COTISATION_REGLES_FIX.md` for detailed business rules:
- Annual contribution: 1500 HTG total
- First payment: minimum 150 HTG
- Subsequent payments: minimum 1 HTG
- Payment methods: MonCash, cash, or receipt upload
- Status workflow: `en_attente` → `valide` or `rejete`
- Backend field mapping:
  - `moyen_paiement`: `'moncash'`, `'cash'`, or `'recu_upload'`
  - `statut_paiement`: `'en_attente'`, `'valide'`, `'rejete'`
  - `url_recu`: receipt URL
  - `date_paiement`: payment date
  - `date_verification`: admin verification date

### Backend Adaptations
When working with backend integration (see `BACKEND_ADAPTATIONS.md`):
- Status values use underscores in backend (`en_attente`) but display format in app ("En attente")
- `normalizeStatut()` helper functions convert between formats
- Payment methods are converted from display format to backend format
- Always check field mapping: e.g., `url_recu` (backend) vs `recuUrl` (app)

## Configuration

### API Endpoint
Change backend URL in `lib/constants/api_constants.dart`:
```dart
static const String baseUrl = 'https://nou-backend-production.up.railway.app';
// For local dev: 'http://10.0.2.2:4000' (Android emulator)
// For local dev: 'http://localhost:4000' (iOS simulator)
```

### Secure Storage
User tokens stored in `FlutterSecureStorage`:
- `access_token` - JWT access token
- `refresh_token` - Refresh token (not yet implemented)
- `membre_id` - Current user ID
- `code_adhesion` - User's membership code

### Assets
Images in `assets/images/` (configured in `pubspec.yaml`)

## Registration System

Two-step registration process with 40+ fields:

### Step 1: Account Creation
- Username (letters, numbers, underscore only)
- Membership code (code d'adhésion) - must exist in backend
- Password (min 8 chars, 1 uppercase, 1 number)
- Password confirmation

### Step 2: Personal Information
Organized in sections:
- Personal info (name, sex, birthdate, parents, NIN, NIF, marital status)
- Contact (phones, email, address)
- Location (department, commune, section communale) - uses Haiti location data
- Profession/occupation
- Social media (Facebook, Instagram)
- Political/organization history (conditional fields)
- Emergency contact (referent)
- Background checks (criminal record, drugs, terrorism)
- Profile photo (optional)

Validation in `lib/utils/validators.dart` - use existing validators when adding form fields.

## Haiti Location Data
`lib/constants/haiti_locations.dart` contains all 10 departments with communes - use this for location dropdowns.

## Common Patterns

### API Calls
```dart
final result = await _apiService.getSomeData(id);
if (result['success']) {
  final data = result['data'];
  // Handle success
} else {
  final message = result['message'];
  // Show error
}
```

### Navigation
```dart
// Using go_router
context.go('/podcasts');
context.push('/profil');
```

### Showing Messages
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Message here')),
);
```

### Provider Usage
```dart
// Read without listening
final authProvider = Provider.of<AuthProvider>(context, listen: false);

// Listen to changes
final authProvider = Provider.of<AuthProvider>(context);

// Consumer pattern
Consumer<AuthProvider>(
  builder: (context, authProvider, child) {
    return Text(authProvider.currentMembre?.nomComplet ?? '');
  },
);
```

## Important Notes

### Payment Status Conversion
Always normalize status values from backend:
- Backend: `'en_attente'`, `'valide'`, `'rejete'`
- Display: "En attente", "Validé", "Rejeté"

### Payment Method Conversion
Convert display values to backend format:
- "MonCash" → `'moncash'`
- "Espèces"/"Cash" → `'cash'`
- Others (Virement, etc.) → `'recu_upload'`

### Photo/File Upload
Use `FormData` with Dio for multipart uploads. See `ApiService.register()` for reference implementation.

### Date Formats
- Display: Use `DateFormat` from `intl` package
- API: Always send dates as `YYYY-MM-DD` strings
- Parse: Use `DateTime.parse()` for ISO 8601 strings from backend

### Error Handling
- Wrap API calls in try-catch with `DioException` handling
- Check `response.statusCode` (200/201 for success)
- Extract error messages from `response.data['message']`
- Always show user-friendly messages

### Testing Before Commits
1. Run `flutter analyze` to check for issues
2. Test critical user flows (login, registration, payment)
3. Verify background audio still works after navigation changes
4. Check status conversions if modifying cotisation/don features

## Google Sign-In
Web client ID for Google authentication: `955108400371-uik3onuhrlibvaik5l6j0a28t8ajg0sd.apps.googleusercontent.com`

## Additional Documentation
Reference these markdown files for specific features:
- `ANDROID_BACK_BUTTON.md` - Android back button support and navigation strategy
- `BACKEND_ADAPTATIONS.md` - Backend field mappings and status conversions
- `COTISATION_REGLES_FIX.md` - Contribution payment rules and validation
- `BACKGROUND_AUDIO_IMPLEMENTATION.md` - Audio service architecture
- `README_INSCRIPTION.md` - Registration system details
- `FORGOT_PASSWORD.md` - Password reset implementation
- `FICHIERS_TELECHARGABLES.md` - Downloadable file handling in formation modules
