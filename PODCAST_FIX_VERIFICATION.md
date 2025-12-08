# Vérification Backend/Frontend - Podcasts

## Problème initial
Les podcasts ne jouaient pas dans l'application mobile.

## Vérification Backend (nou-backend)

### Structure des données renvoyées par l'API
**Endpoint**: `GET /podcasts`

**Réponse réelle**:
```json
{
  "success": true,
  "message": "Podcasts récupérés avec succès",
  "data": {
    "podcasts": [
      {
        "id": 10,
        "titre": "Intro Podcast",
        "description": "Just a test",
        "url_audio": "https://res.cloudinary.com/djs7521wd/video/upload/v1765068265/nou/podcasts/audio/podcast_audio_1765068264876.mp3",
        "url_live": null,
        "est_en_direct": false,
        "date_publication": "2025-12-07T00:44:27.000Z",
        "duree_en_secondes": null,
        "img_couverture_url": "https://res.cloudinary.com/djs7521wd/image/upload/v1765068266/nou/podcasts/covers/podcast_cover_1765068266299.png",
        "nombre_ecoutes": 0
      }
    ],
    "pagination": { ... }
  }
}
```

### Champs clés du backend

| Champ Backend | Type | Description |
|---------------|------|-------------|
| `url_audio` | String | URL complète (Cloudinary) ou relative (`/uploads/...`) |
| `url_live` | String \| null | URL YouTube pour les lives |
| `img_couverture_url` | String | URL complète (Cloudinary) ou relative |
| `duree_en_secondes` | Integer \| null | Durée en secondes |
| `est_en_direct` | Boolean | Indique si c'est un live |

## Corrections apportées au Frontend

### 1. Modèle Podcast (`lib/models/podcast.dart`)

#### ✅ Mapping JSON corrigé
- Support des clés backend: `url_audio`, `img_couverture_url`, `url_live`
- Support des anciennes clés pour compatibilité: `audio_url`, `image_url`
- Ajout du champ `liveUrl` pour gérer les lives YouTube

#### ✅ Conversion de la durée
- Le backend renvoie `duree_en_secondes` (Integer)
- Le frontend la convertit en format `MM:SS` ou `HH:MM:SS`
- Fonction `formatDuree()` intégrée dans `fromJson()`

### 2. Écran Podcast (`lib/screens/podcast_screen.dart`)

#### ✅ Gestion des URLs relatives
- Les URLs commençant par `/` sont préfixées avec `ApiConstants.baseUrl`
- Exemple: `/uploads/podcasts/episode1.mp3` → `https://nou-backend-production.up.railway.app/uploads/podcasts/episode1.mp3`

#### ✅ Gestion des lives YouTube
- Si `est_en_direct` et `liveUrl` présent → ouverture dans navigateur externe
- Utilise `url_launcher` pour ouvrir YouTube

#### ✅ Gestion d'erreurs améliorée
- Message si URL audio manquante
- Try-catch autour de la lecture
- Listener `onPlayerComplete` pour réinitialiser l'état

#### ✅ Images corrigées
- Les URLs relatives d'images sont aussi préfixées avec `ApiConstants.baseUrl`
- Support des images Cloudinary (URLs complètes)

## Types de podcasts supportés

### 1. Podcasts avec fichiers Cloudinary
```json
{
  "url_audio": "https://res.cloudinary.com/.../audio.mp3",
  "img_couverture_url": "https://res.cloudinary.com/.../cover.png"
}
```
✅ **Fonctionnent directement**

### 2. Podcasts avec chemins relatifs (seed data)
```json
{
  "url_audio": "/uploads/podcasts/episode1.mp3",
  "img_couverture_url": "/uploads/podcasts/covers/episode1.jpg"
}
```
⚠️ **Nécessitent que les fichiers existent sur le serveur**
- URLs transformées en: `https://nou-backend-production.up.railway.app/uploads/podcasts/episode1.mp3`
- Si les fichiers n'existent pas → erreur de lecture avec message explicite

### 3. Lives YouTube
```json
{
  "url_live": "https://youtube.com/live/xyz123",
  "est_en_direct": true
}
```
✅ **S'ouvrent dans l'app YouTube/navigateur**

## Résumé des changements

| Fichier | Changements |
|---------|-------------|
| `lib/models/podcast.dart` | - Ajout `liveUrl`<br>- Support `url_audio` / `img_couverture_url`<br>- Conversion `duree_en_secondes` → `duree` |
| `lib/screens/podcast_screen.dart` | - Import `ApiConstants`<br>- Gestion URLs relatives<br>- Gestion lives YouTube<br>- Meilleure gestion d'erreurs |

## Test recommandé

1. **Podcasts Cloudinary** (ID: 10) → Devrait jouer ✅
2. **Lives YouTube** (ID: 7) → Devrait ouvrir YouTube ✅
3. **Podcasts seed avec URLs relatives** (ID: 5, 6, 8) → Erreur si fichiers absents ⚠️

## Notes

- Les podcasts du seed (épisodes 1-3) ont des URLs relatives vers `/uploads/podcasts/` qui n'existent probablement pas sur le serveur Railway
- Pour tester complètement, il faudrait:
  - Soit uploader de vrais fichiers audio sur Cloudinary via l'interface admin
  - Soit créer les dossiers `/uploads/podcasts/` sur le serveur avec des fichiers de test
