# Support du bouton retour Android

## Configuration

L'application est maintenant configurée pour gérer correctement le bouton retour système Android.

### 1. Configuration dans `main.dart`

Le `RootBackButtonDispatcher` est activé dans `MaterialApp.router` :

```dart
MaterialApp.router(
  title: 'NOU App',
  routerConfig: router,
  backButtonDispatcher: RootBackButtonDispatcher(),
)
```

### 2. Stratégie de navigation

#### Routes principales (Bottom Navigation)
Les routes principales utilisent `context.go()` pour **remplacer** la route actuelle :
- `/home` - Accueil
- `/podcasts` - Podcasts
- `/formations` - Formations
- `/cotisation` - Cotisation
- `/profil` - Profil

**Comportement** : Le bouton retour Android quittera l'application depuis ces écrans (comportement attendu).

#### Routes secondaires (Écrans de détail)
Les routes secondaires utilisent `context.push()` pour **empiler** une nouvelle route :
- `/parrainage` - Parrainage (accès depuis home)
- `/news` - Actualités (accès depuis home)
- `/annonces` - Annonces (accès depuis home)
- `/don` - Faire un don (accès depuis home)

**Comportement** : Le bouton retour Android retournera à l'écran précédent (home).

#### Routes de détail avec Navigator.push()
Certains détails utilisent encore `Navigator.push()` pour une navigation modale :
- `NewsDetailScreen` - Détail d'une actualité

**Comportement** : Le bouton retour fonctionne normalement.

### 3. Boutons de retour dans les AppBars

Les écrans secondaires ont un bouton retour explicite qui utilise `context.pop()` :

```dart
GradientAppBar(
  title: 'Titre',
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => context.pop(),
  ),
)
```

**Note** : `automaticallyImplyLeading: false` a été retiré pour permettre le bouton retour automatique.

### 4. Gestion du logout

Le logout depuis HomeScreen utilise `context.go('/welcome')` pour **remplacer** toute la pile de navigation :

```dart
await authProvider.logout();
if (context.mounted) {
  context.go('/welcome');
}
```

## Tests recommandés

### Sur émulateur/appareil Android :

1. **Navigation principale**
   - Ouvrir l'app → Home
   - Appuyer sur bouton retour système → App se ferme ✓

2. **Navigation secondaire**
   - Home → Parrainage
   - Appuyer sur bouton retour système → Retour à Home ✓
   
3. **Navigation profonde**
   - Home → Actualités → Détail article
   - Appuyer sur bouton retour système → Retour à Actualités
   - Appuyer à nouveau → Retour à Home ✓

4. **Bottom Navigation**
   - Home → Podcasts (via bottom nav)
   - Appuyer sur bouton retour système → App se ferme (pas de retour à Home) ✓

## Notes importantes

- `context.go()` = Remplacement de route (pas d'historique)
- `context.push()` = Empilement de route (historique maintenu)
- `context.pop()` = Retour à la route précédente dans la pile
- Le bouton retour Android appelle automatiquement `pop()` sur le router

## Future améliorations possibles

1. **Double-tap pour quitter** : Afficher un message "Appuyez à nouveau pour quitter" sur les écrans principaux
2. **WillPopScope** : Ajouter une confirmation avant de quitter depuis certains formulaires non sauvegardés
3. **Deep linking** : Assurer que les deep links maintiennent une pile de navigation cohérente
