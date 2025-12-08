# Adaptations de l'app mobile aux changements backend

## Date : 26 novembre 2025

## Changements backend identifiés

### Modèle Cotisation
- **moyen_paiement** : ENUM(`'moncash'`, `'cash'`, `'recu_upload'`)
- **url_recu** : Champ pour stocker l'URL du reçu uploadé
- **statut_paiement** : ENUM(`'en_attente'`, `'valide'`, `'rejete'`) avec underscores
- **date_paiement** : Date du paiement
- **date_verification** : Date de vérification par admin

### Modèle Don
- **recu_url** : Champ pour le reçu du don
- **statut_don** : ENUM(`'en_attente'`, `'approuve'`, `'rejete'`)
- **date_verification** : Date de vérification
- **admin_verificateur_id** : ID de l'admin qui a vérifié
- **commentaire_verification** : Commentaire de l'admin

## Adaptations effectuées dans l'app mobile

### 1. Modèle Cotisation (`lib/models/cotisation.dart`)
✅ Ajout d'une fonction `normalizeStatut()` pour convertir les valeurs backend vers format d'affichage :
- `'en_attente'` → `'En attente'`
- `'valide'` → `'Validé'`
- `'rejete'` → `'Rejeté'`

✅ Mise à jour du parsing JSON pour utiliser :
- `json['url_recu']` au lieu de `json['recu']`
- `json['date_paiement']` comme date de création
- `json['date_verification']` comme date de validation

### 2. Service API (`lib/services/api_service.dart`)
✅ Ajout d'une fonction `convertMoyenPaiement()` pour convertir les valeurs de l'app vers le backend :
- `'MonCash'` → `'moncash'`
- `'Espèces'` / `'Cash'` → `'cash'`
- Autres (Virement, etc.) → `'recu_upload'`

### 3. CotisationScreen (`lib/screens/cotisation_screen.dart`)
✅ Mise à jour de `_processMonCashPayment()` :
- Utilise maintenant `'moncash'` comme moyen de paiement
- Message mis à jour : "En attente de validation"

✅ Mise à jour de `_uploadFile()` :
- Utilise maintenant `'recu_upload'` comme moyen de paiement
- Message de confirmation clair

✅ Amélioration de l'affichage du statut :
- Message dynamique basé sur le statut réel
- Meilleure gestion des cas "en_attente", "valide", "rejete"

### 4. Modèle Don (`lib/models/don.dart`)
✅ Déjà compatible avec les changements backend :
- Utilise `recu_url` correctement
- Gère `statut_don` avec valeurs `'en_attente'`, `'approuve'`, `'rejete'`

## Comportement attendu

### Cotisations
1. **Paiement MonCash** : 
   - Statut initial : `'en_attente'`
   - Message : "Paiement MonCash enregistré avec succès ! En attente de validation."

2. **Upload de reçu** :
   - Statut initial : `'en_attente'`
   - Message : "Reçu uploadé avec succès ! En attente de validation."

3. **Affichage des statuts** :
   - En attente → Badge orange avec message "Votre reçu est en attente de validation par un administrateur."
   - Validé → Badge vert avec message "Votre cotisation a été validée avec succès !"
   - Rejeté → Badge rouge avec message "Votre cotisation a été rejetée. Veuillez contacter un administrateur."

### Dons
1. **Création de don** :
   - Statut initial : `'en_attente'`
   - Upload de reçu optionnel via le champ `recu_url`

## Tests à effectuer

- [ ] Créer une cotisation via MonCash
- [ ] Uploader un reçu de cotisation
- [ ] Vérifier l'affichage correct des statuts après validation admin
- [ ] Créer un don avec reçu
- [ ] Vérifier la synchronisation des données entre app et backend
