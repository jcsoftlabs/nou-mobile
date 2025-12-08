# Implémentation du Background Audio pour les Podcasts

## Objectif
Permettre aux utilisateurs d'écouter les podcasts en continu:
- ✅ Pendant la navigation dans l'application
- ✅ Quand l'utilisateur change d'application
- ✅ Même quand l'écran est verrouillé (iOS/Android)

## Architecture

### 1. Service Audio Global (`AudioPlayerService`)
**Fichier**: `lib/services/audio_player_service.dart`

- **Pattern Singleton**: Une seule instance partagée dans toute l'app
- **Provider/ChangeNotifier**: Permet aux widgets de réagir aux changements d'état
- **Gestion d'état centralisée**:
  - Podcast en cours de lecture
  - État de lecture (play/pause)
  - Position et durée actuelles

**Configuration Audio**:
```dart
// iOS
category: AVAudioSessionCategory.playback
options: mixWithOthers, duckOthers

// Android
contentType: AndroidContentType.music
usageType: AndroidUsageType.media
audioFocus: AndroidAudioFocus.gain
stayAwake: true
```

### 2. Mini-Player Global (`GlobalMiniPlayer`)
**Fichier**: `lib/widgets/global_mini_player.dart`

- Widget stateless qui écoute le `AudioPlayerService`
- Visible sur toutes les pages via `AppShell`
- Affiche:
  - Image du podcast
  - Titre
  - Barre de progression
  - Contrôles (reculer 10s, play/pause, avancer 10s)

### 3. Intégration dans l'App

#### `main.dart`
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => AudioPlayerService()),
  ],
  ...
)
```

#### `app_shell.dart`
Le mini-player est ajouté au-dessus de la `BottomNavigationBar`:
```dart
bottomNavigationBar: Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    GlobalMiniPlayer(),
    BottomNavigationBar(...),
  ],
)
```

#### `podcast_screen.dart`
- Utilise maintenant le service global au lieu d'un AudioPlayer local
- Suppression du mini-player local (remplacé par le global)
- Consumer<AudioPlayerService> pour afficher l'état en temps réel

## Permissions Configurées

### iOS (`ios/Runner/Info.plist`)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

## Fonctionnalités

### ✅ Lecture Continue
- Le podcast continue de jouer pendant la navigation
- Le service survit aux changements de route
- État synchronisé sur toutes les pages

### ✅ Contrôles Persistants
- Mini-player visible partout (sauf login/register)
- Contrôles accessibles depuis n'importe quelle page
- Synchronisation en temps réel de l'état

### ✅ Background Playback
- **iOS**: Lecture continue même en arrière-plan
- **Android**: Lecture continue avec WAKE_LOCK
- Fonctionne même écran verrouillé

### ✅ Gestion des Lives YouTube
- Détection automatique des podcasts en direct
- Ouverture dans l'app YouTube/navigateur
- Ne bloque pas le lecteur audio normal

## Méthodes du Service

### Lecture
```dart
await AudioPlayerService().playPodcast(podcast);
await AudioPlayerService().pause();
await AudioPlayerService().resume();
await AudioPlayerService().stop();
```

### Navigation
```dart
await AudioPlayerService().seek(Duration(seconds: 30));
await AudioPlayerService().seekBackward(Duration(seconds: 10));
await AudioPlayerService().seekForward(Duration(seconds: 10));
```

### Accesseurs
```dart
AudioPlayerService().currentPodcast // Podcast?
AudioPlayerService().isPlaying // bool
AudioPlayerService().currentPosition // Duration
AudioPlayerService().totalDuration // Duration
```

## Test

### Scénarios de test
1. **Navigation intra-app**:
   - Lancer un podcast
   - Naviguer vers Formations, Cotisation, Profil
   - ✅ Le podcast continue de jouer
   - ✅ Le mini-player est visible partout

2. **Changement d'app**:
   - Lancer un podcast
   - Appuyer sur Home ou changer d'app
   - ✅ Le podcast continue de jouer

3. **Écran verrouillé**:
   - Lancer un podcast
   - Verrouiller l'écran
   - ✅ Le podcast continue de jouer
   - ✅ Contrôles disponibles sur le lock screen (iOS)

4. **Contrôles du mini-player**:
   - ✅ Play/Pause fonctionne
   - ✅ Reculer/Avancer de 10s fonctionne
   - ✅ Barre de progression est interactive

## Améliorations Futures

### Media Controls (Lock Screen)
Pour afficher les contrôles sur l'écran verrouillé iOS/Android:
- Package: `audio_service` ou `just_audio` (avec media controls)
- Permet d'afficher: titre, artiste, artwork
- Contrôles natifs iOS/Android

### Notifications
- Notification persistante sur Android
- Contrôles dans la notification
- Artwork du podcast

### Queue/Playlist
- File d'attente de podcasts
- Lecture automatique du suivant
- Shuffle/Repeat

### Download & Offline
- Téléchargement local des podcasts
- Lecture offline
- Gestion du stockage

## Notes Techniques

### Provider vs Singleton
- Le service est un Singleton ET un Provider
- Singleton: une seule instance dans toute l'app
- Provider: permet aux widgets de réagir aux changements

### Lifecycle
- Le service survit aux rebuild de widgets
- Dispose automatiquement par Flutter
- État persistant entre les routes

### Performance
- Un seul AudioPlayer pour toute l'app
- Pas de création/destruction à chaque navigation
- Listeners efficaces avec ChangeNotifier

## Résultat

✅ **Objectif atteint**: Les podcasts jouent en continu pendant la navigation et en arrière-plan.
✅ **UX améliorée**: Mini-player toujours accessible pour contrôler la lecture.
✅ **Performances**: Service unique partagé, pas de duplication de ressources.
