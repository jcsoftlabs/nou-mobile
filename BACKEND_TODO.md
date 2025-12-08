# Endpoints Backend à implémenter

Ce document liste les endpoints qui doivent être ajoutés au backend `nou-backend` pour que l'application Flutter soit pleinement fonctionnelle.

## ✅ Endpoints existants et fonctionnels

- `POST /auth/login` - Connexion avec username/email/téléphone
- `POST /auth/register` - Inscription d'un nouveau membre
- `GET /membres/:id` - Récupérer les informations d'un membre
- `GET /podcasts` - Liste des podcasts
- `GET /formations` - Liste des formations
- `GET /referrals/:parrainId` - Liste des filleuls d'un parrain
- `GET /points/:membreId` - Points cumulés d'un membre

## ❌ Endpoints manquants

### 1. Mise à jour de la photo de profil
**Endpoint nécessaire** : `PUT /membres/:id/photo` ou `PATCH /membres/:id`

**Description** : Permet à un membre de mettre à jour sa photo de profil

**Méthode** : `PUT` ou `PATCH`

**Headers** :
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Body** (multipart/form-data) :
```
photo: <file>
```

**Réponse attendue** (200 OK) :
```json
{
  "success": true,
  "message": "Photo de profil mise à jour avec succès",
  "data": {
    "photo_profil_url": "http://localhost:4000/uploads/photos/membre_37_photo.jpg"
  }
}
```

**Code Flutter actuel** : Désactivé temporairement dans `lib/screens/profile_screen.dart:69-141`

**Action requise** :
1. ✅ L'endpoint `POST /membres/me/photo` existe déjà
2. ✅ Upload fonctionne et sauvegarde dans `/src/uploads/profiles/`
3. ❌ **PROBLÈME CRITIQUE** : Le dossier `/uploads/` n'est PAS servi comme fichiers statiques
4. ❌ Les fichiers sont dans `/src/uploads/` mais le serveur ne les sert pas
5. **SOLUTION BACKEND NÉCESSAIRE** :
   ```javascript
   // Dans server.js ou app.js
   app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
   // OU si les fichiers sont dans src/uploads :
   app.use('/uploads', express.static(path.join(__dirname, 'src/uploads')));
   ```
6. Mettre à jour le champ `photo_profil_url` pour retourner l'URL complète

---

### 2. Historique des cotisations d'un membre
**Endpoint nécessaire** : `GET /cotisations/membre/:membreId`

**Description** : Récupérer l'historique des cotisations d'un membre

**Méthode** : `GET`

**Headers** :
```
Authorization: Bearer <token>
```

**Réponse attendue** (200 OK) :
```json
{
  "success": true,
  "message": "Cotisations récupérées avec succès",
  "data": [
    {
      "id": 1,
      "membre_id": 37,
      "montant": 1500.00,
      "moyen_paiement": "MonCash",
      "statut_paiement": "validé",
      "date_paiement": "2024-01-15T00:00:00.000Z",
      "recu_url": "/uploads/recus/recu_1.pdf"
    }
  ]
}
```

**État actuel** : L'app gère gracieusement l'erreur 404

**Code Flutter** : Implémenté dans `lib/services/api_service.dart:192-220` et utilisé dans :
- `lib/screens/cotisation_screen.dart`
- `lib/screens/profile_screen.dart`

---

### 3. Création d'une cotisation
**Endpoint nécessaire** : `POST /cotisations`

**Description** : Créer une nouvelle cotisation avec upload du reçu

**Méthode** : `POST`

**Headers** :
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Body** (multipart/form-data) :
```
membre_id: 37
montant: 1500.00
moyen_paiement: "MonCash" | "Virement/Espèces"
recu: <file> (optionnel)
```

**Réponse attendue** (201 Created) :
```json
{
  "success": true,
  "message": "Cotisation enregistrée avec succès",
  "data": {
    "id": 5,
    "membre_id": 37,
    "montant": 1500.00,
    "statut_paiement": "en_attente",
    "date_paiement": "2024-11-25T15:34:22.000Z"
  }
}
```

**Code Flutter** : Implémenté dans `lib/services/api_service.dart:134-189`

---

### 4. Mise à jour générale d'un membre
**Endpoint nécessaire** : `PUT /membres/:id` ou `PATCH /membres/:id`

**Description** : Mettre à jour les informations d'un membre (nom, email, téléphone, etc.)

**Méthode** : `PUT` ou `PATCH`

**Headers** :
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Body** :
```json
{
  "nom": "Dupont",
  "prenom": "Jean",
  "telephone_principal": "+50937111111",
  "email": "jean.dupont@example.ht",
  ...
}
```

**Réponse attendue** (200 OK) :
```json
{
  "success": true,
  "message": "Informations mises à jour avec succès",
  "data": {
    "id": 37,
    "nom": "Dupont",
    "prenom": "Jean",
    ...
  }
}
```

---

## 📋 Priorités d'implémentation

1. **HAUTE** : `POST /cotisations` - Fonctionnalité critique pour les paiements
2. **HAUTE** : `GET /cotisations/membre/:id` - Affichage de l'historique
3. **MOYENNE** : `PUT /membres/:id/photo` - Upload de photo de profil
4. **BASSE** : `PUT /membres/:id` - Mise à jour générale du profil

---

## 🔧 Notes techniques

### Upload de fichiers
- Utiliser `multer` pour gérer les uploads multipart
- Stocker les fichiers dans `/uploads/photos/` et `/uploads/recus/`
- Limiter la taille des fichiers (ex: 5MB pour les photos, 10MB pour les PDFs)
- Valider les types MIME (images: jpeg/png, documents: pdf)

### Sécurité
- Vérifier que l'utilisateur authentifié correspond à `membre_id`
- Valider et sanitizer tous les inputs
- Scanner les fichiers uploadés pour les malwares
- Générer des noms de fichiers uniques (éviter les collisions)

### Base de données
- S'assurer que les champs suivants existent dans la table `membres` :
  - `photo_profil_url` (VARCHAR, nullable)
  
- S'assurer que la table `cotisations` existe avec :
  - `id` (INT, PRIMARY KEY, AUTO_INCREMENT)
  - `membre_id` (INT, FOREIGN KEY -> membres.id)
  - `montant` (DECIMAL(10,2))
  - `moyen_paiement` (VARCHAR)
  - `statut_paiement` (ENUM: 'en_attente', 'validé', 'rejeté')
  - `date_paiement` (DATETIME)
  - `recu_url` (VARCHAR, nullable)
  - `date_validation` (DATETIME, nullable)
  - `validé_par` (INT, nullable, FOREIGN KEY -> membres.id)
