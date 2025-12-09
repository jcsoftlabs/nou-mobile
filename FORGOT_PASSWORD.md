# Récupération de mot de passe par NIN

## Vue d'ensemble

Cette fonctionnalité permet aux membres qui ont oublié leur mot de passe de le réinitialiser en utilisant leur Numéro d'Identification National (NIN).

## Flux utilisateur

### Étape 1 : Vérification du NIN
1. Le membre clique sur "Mot de passe oublié ?" depuis l'écran de connexion
2. Il est redirigé vers l'écran de récupération de mot de passe
3. Il saisit son NIN (Numéro d'Identification National)
4. L'application appelle `POST /auth/verify-nin` pour vérifier le NIN
5. Si le NIN est valide, le backend retourne les informations du membre (nom, prénom, téléphone)

### Étape 2 : Création d'un nouveau mot de passe
1. L'application affiche les informations du membre pour confirmation d'identité
2. Le membre saisit son nouveau mot de passe (minimum 6 caractères)
3. Le membre confirme le nouveau mot de passe
4. L'application appelle `POST /auth/reset-password` avec le NIN et le nouveau mot de passe
5. Le mot de passe est mis à jour dans la base de données
6. Une boîte de dialogue de succès s'affiche
7. Le membre est redirigé vers l'écran de connexion

## Endpoints utilisés

### 1. Vérifier le NIN
**Endpoint:** `POST /auth/verify-nin`

**Payload:**
```json
{
  "nin": "123456789"
}
```

**Réponse (succès):**
```json
{
  "success": true,
  "data": {
    "nom": "Doe",
    "prenom": "John",
    "telephone": "+509 1234 5678"
  }
}
```

### 2. Réinitialiser le mot de passe
**Endpoint:** `POST /auth/reset-password`

**Payload:**
```json
{
  "nin": "123456789",
  "new_password": "nouveau_mot_de_passe"
}
```

**Réponse (succès):**
```json
{
  "success": true,
  "message": "Mot de passe réinitialisé avec succès"
}
```

## Fichiers modifiés/créés

### Nouveaux fichiers
- `lib/screens/forgot_password_screen.dart` - Écran de récupération de mot de passe en 2 étapes

### Fichiers modifiés
- `lib/services/api_service.dart` - Ajout des méthodes `verifyNin()` et `resetPassword()`
- `lib/screens/login_screen.dart` - Ajout du lien "Mot de passe oublié ?"
- `lib/router/app_router.dart` - Ajout de la route `/forgot-password` comme route publique

## Sécurité

- Le mot de passe est hashé côté backend avec bcrypt (10 rounds)
- Le NIN sert d'identifiant unique pour vérifier l'identité du membre
- Validation minimale de 6 caractères pour le nouveau mot de passe
- Les informations sensibles ne sont jamais affichées en clair

## Tests suggérés

1. **Cas nominal:**
   - Saisir un NIN valide
   - Vérifier que les informations du membre s'affichent correctement
   - Créer un nouveau mot de passe valide
   - Vérifier la redirection vers l'écran de connexion
   - Se connecter avec le nouveau mot de passe

2. **Cas d'erreur:**
   - NIN invalide ou inexistant
   - Mot de passe trop court (< 6 caractères)
   - Mots de passe de confirmation différents
   - Perte de connexion Internet pendant le processus

3. **UX:**
   - Tester les animations de transition entre les pages
   - Vérifier l'affichage des messages d'erreur
   - Tester le bouton retour pour revenir à l'écran de connexion
