# Guide de test du mode hors ligne

## Fonctionnalités implémentées

L'application nou_app dispose maintenant d'un **mode hors ligne** qui permet aux membres de consulter leurs données même sans connexion internet.

### Ce qui fonctionne hors ligne :
- ✅ Accès au profil du membre (nom, prénom, photo, etc.)
- ✅ Affichage de toutes les informations personnelles
- ✅ Affichage du statut et du rating (étoiles)
- ✅ Navigation dans l'application
- ✅ Indicateur visuel "Hors ligne" dans l'app bar

### Ce qui nécessite une connexion :
- ❌ Connexion initiale (login)
- ❌ Chargement des podcasts, formations, actualités
- ❌ Paiement de cotisations
- ❌ Mise à jour du profil
- ❌ Actions de parrainage

## Comment tester

### 1. Test avec connexion internet

1. Lancez l'application : `flutter run`
2. Connectez-vous avec un compte valide
3. Vérifiez que vous voyez bien :
   - Votre photo de profil
   - Vos informations (nom, prénom, etc.)
   - Votre rating (étoiles) dans le header
   - Le statut "Actif" ou "Inactif"
4. **Important** : Les données sont maintenant sauvegardées localement

### 2. Test du mode hors ligne (Simulateur iOS)

1. Avec l'app ouverte, appuyez sur `q` pour quitter
2. Activez le mode avion sur le simulateur :
   - Menu : `I/O` > `Cellular` > Décochez toutes les options
   - OU Menu : `Features` > `Toggle Airplane Mode`
3. Relancez l'application : `flutter run`
4. **Résultat attendu** :
   - L'app se connecte automatiquement avec les données en cache
   - Un badge **"Hors ligne"** orange apparaît dans l'app bar
   - Toutes vos données personnelles sont accessibles
   - Le rating (étoiles) s'affiche correctement

### 3. Test du retour en ligne

1. Désactivez le mode avion sur le simulateur
2. Fermez et rouvrez l'app (ou attendez quelques secondes)
3. **Résultat attendu** :
   - Le badge "Hors ligne" disparaît
   - Les données sont synchronisées avec le serveur
   - Toutes les fonctionnalités sont à nouveau disponibles

### 4. Test avec émulateur Android

1. Suivez les mêmes étapes que pour iOS
2. Pour activer le mode avion :
   - Glissez depuis le haut de l'écran pour ouvrir les paramètres rapides
   - Appuyez sur l'icône "Avion"
   - OU Menu : `Extended controls` (icône "...") > `Cellular` > `No network`

## Architecture technique

### Cache local
- Utilise `shared_preferences` pour stocker les données du membre en JSON
- Sauvegarde automatique après chaque connexion réussie
- Sauvegarde automatique après chaque mise à jour du profil

### Stratégie de chargement
1. **Avec connexion** : Charge depuis l'API, puis sauvegarde dans le cache
2. **Sans connexion** : Charge depuis le cache local
3. **Reconnexion** : Synchronise automatiquement avec l'API

### Fichiers modifiés
- `lib/services/membre_cache_service.dart` - Service de cache local
- `lib/data/providers/auth_provider.dart` - Gestion du mode hors ligne
- `lib/screens/home_screen.dart` - Indicateur visuel "Hors ligne"

## Limitations connues

- Le cache ne contient QUE les données du membre connecté
- Les listes dynamiques (podcasts, news, etc.) ne sont pas mises en cache
- La déconnexion supprime le cache local
- Pas de file d'attente pour les actions effectuées hors ligne

## Améliorations futures possibles

- 📦 Cache des podcasts et formations consultés
- 📦 Cache des actualités récentes
- 🔄 File d'attente pour les actions hors ligne (paiements, parrainages)
- 📊 Indicateur de fraîcheur des données (dernière synchronisation)
- 💾 Choix de conserver le cache après déconnexion
