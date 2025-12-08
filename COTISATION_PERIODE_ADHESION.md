# Adaptation : Cotisation par période d'adhésion ✅

## 🔄 Changement de logique backend

Le backend a été modifié pour passer d'une **cotisation par année civile** à une **cotisation par période d'adhésion**.

### Avant (année civile)
```
Tous les membres :
├─ 1er janvier 2025 → 31 décembre 2025
├─ 1er janvier 2026 → 31 décembre 2026
└─ etc.
```

### Maintenant (période d'adhésion)
```
Chaque membre a SA propre période selon sa date d'adhésion :

Membre A (adhésion : 15 mars 2024) :
├─ 15 mars 2024 → 14 mars 2025
├─ 15 mars 2025 → 14 mars 2026
└─ etc.

Membre B (adhésion : 10 juillet 2024) :
├─ 10 juillet 2024 → 9 juillet 2025
├─ 10 juillet 2025 → 9 juillet 2026
└─ etc.
```

## 🔧 Modifications backend

### Fichier : `cotisationService.js`

**Fonction `getTotalCotisationsAnnee(membreId)`** (lignes 29-68)

**Avant** :
```javascript
const debutAnnee = new Date(new Date().getFullYear(), 0, 1); // 1er janvier
const finAnnee = new Date(new Date().getFullYear(), 11, 31); // 31 décembre
```

**Maintenant** :
```javascript
// Récupérer la date de création du membre
const membre = await Membre.findByPk(membreId);
const dateAdhesion = new Date(membre.date_creation);
const maintenant = new Date();

// Calculer le début de la période actuelle (anniversaire le plus récent)
let debutPeriode = new Date(dateAdhesion);
debutPeriode.setFullYear(maintenant.getFullYear());

// Si l'anniversaire n'est pas encore passé, prendre l'année précédente
if (debutPeriode > maintenant) {
  debutPeriode.setFullYear(maintenant.getFullYear() - 1);
}

// Fin de période = 12 mois après le début
const finPeriode = new Date(debutPeriode);
finPeriode.setFullYear(debutPeriode.getFullYear() + 1);
finPeriode.setDate(finPeriode.getDate() - 1);
```

**La même logique s'applique à `isPremierVersementAnnee(membreId)`** (lignes 74-112)

## 📱 Adaptations frontend

### 1. Modification de l'affichage - HomeScreen

**Fichier** : `lib/screens/home_screen.dart`

**Avant** :
```dart
Text('Cotisation ${_cotisationStatus?.annee ?? DateTime.now().year}')
// Affichait : "Cotisation 2025"
```

**Après** :
```dart
Text('Cotisation (période d\'adhésion)')
// Affiche : "Cotisation (période d'adhésion)"
```

### 2. Modification de l'affichage - CotisationScreen

**Fichier** : `lib/screens/cotisation_screen.dart`

**Avant** :
```dart
Text('Cotisation ${status.annee}')
// Affichait : "Cotisation 2025"
```

**Après** :
```dart
const Text('Votre période d\'adhésion')
// Affiche : "Votre période d'adhésion"
```

### 3. Mise à jour des messages d'erreur

**Avant** :
```dart
return 'Votre cotisation ${status.annee} est déjà complète';
// Affichait : "Votre cotisation 2025 est déjà complète"
```

**Après** :
```dart
return 'Votre cotisation pour cette période d\'adhésion est déjà complète';
```

## 🎯 Impact pour l'utilisateur

### Exemple concret : jdupont

**Date d'adhésion de jdupont** : 15 mars 2024

#### Avec l'ancienne logique (année civile)
- 1er janvier 2025 00:00 → jdupont devient **inactif** (nouvelle année)
- Il doit payer à nouveau même si son adhésion date de mars 2024

#### Avec la nouvelle logique (période d'adhésion)
- 15 mars 2025 00:00 → jdupont devient **inactif** (fin de sa période)
- Il reste actif jusqu'à l'anniversaire de son adhésion
- **Plus logique et plus juste !**

### Période actuelle vs période complète

**Date du jour** : 5 décembre 2024  
**jdupont** (adhésion : 15 mars 2024)

- **Période actuelle** : 15 mars 2024 → 14 mars 2025
- **Statut au 5 décembre 2024** : 
  - Si a versé ≥ 1 HTG → **Actif** ✅
  - Si a versé 0 HTG → **Inactif** ❌
  
**Date du jour** : 16 mars 2025  
**jdupont** (adhésion : 15 mars 2024)

- **Période actuelle** : 15 mars 2025 → 14 mars 2026 (nouvelle période !)
- **Statut au 16 mars 2025** :
  - Même s'il avait payé en 2024-2025 → **Inactif** ❌
  - Doit payer à nouveau pour la nouvelle période

## ✅ Avantages de cette approche

1. **Plus équitable** : Chaque membre paie à partir de sa date d'adhésion
2. **Pas de rush en fin d'année** : Les paiements sont répartis tout au long de l'année
3. **Plus logique** : La cotisation correspond vraiment à une période de 12 mois d'adhésion
4. **Gestion simplifiée** : Pas besoin de gérer les adhésions en cours d'année différemment

## 🔐 Logique de validation (inchangée)

Les règles de cotisation restent les mêmes :
- ✅ Premier versement minimum : 150 HTG
- ✅ Versements suivants minimum : 1 HTG
- ✅ Total maximum par période : 1500 HTG
- ✅ Paiements en plusieurs fois possibles

## 📊 Comportement du statut "Actif"

```
┌─────────────────────────────────────────────┐
│ Période d'adhésion du membre                │
│ (date_creation → date_creation + 12 mois)   │
└─────────────────────────────────────────────┘
                    ↓
        ┌───────────────────┐
        │ Montant versé?    │
        └───────────────────┘
             ↓          ↓
          = 0        > 0
             ↓          ↓
        ┌────────┐  ┌────────┐
        │INACTIF │  │ ACTIF  │
        └────────┘  └────────┘
```

## 🧪 Tests recommandés

### Test 1 : Membre récent (adhésion récente)
**Membre** : adhésion le 1er novembre 2024  
**Date test** : 5 décembre 2024

1. Vérifier période : 1er novembre 2024 → 31 octobre 2025
2. Verser 500 HTG → doit être actif
3. Vérifier affichage : "Votre période d'adhésion" avec 500/1500 HTG

### Test 2 : Membre au changement de période
**Membre** : adhésion le 15 mars 2024  
**Date test** : 14 mars 2025 (dernier jour)

1. Vérifier qu'il est actif (si a payé dans la période)
2. Attendre le lendemain (15 mars 2025)
3. Vérifier qu'il devient inactif (nouvelle période commence)

### Test 3 : Ancien membre (jdupont)
**Membre** : adhésion en mars 2024, a payé en 2024  
**Date test** : 5 décembre 2024

1. Si dernière cotisation est de mars-décembre 2024 → actif
2. Si aucune cotisation ou cotisation avant mars 2024 → inactif

## 📝 Note importante sur le champ `annee`

Le contrôleur backend retourne toujours un champ `annee` dans la réponse :

```javascript
data: {
  annee: new Date().getFullYear(),  // 2025
  montant_verse: totalVerse,
  // ...
}
```

**Ce champ n'est plus vraiment pertinent** puisque la période ne suit plus l'année civile. Il serait préférable que le backend retourne plutôt :

```javascript
data: {
  periode_debut: debutPeriode,      // 2024-03-15
  periode_fin: finPeriode,          // 2025-03-14
  montant_verse: totalVerse,
  // ...
}
```

**Pour l'instant**, l'app ignore simplement ce champ et affiche "Période d'adhésion" sans date spécifique.

## 🎉 Conclusion

L'app a été adaptée pour refléter la nouvelle logique de **cotisation par période d'adhésion** :

✅ Affichage mis à jour : "Période d'adhésion" au lieu de "Cotisation 2025"  
✅ Messages d'erreur ajustés  
✅ La logique d'activation reste correcte (basée sur `montantVerse > 0`)  
✅ Le statut actif/inactif est calculé pour la bonne période  

**Les membres ont maintenant une période de cotisation personnalisée basée sur leur date d'adhésion**, ce qui est plus juste et plus logique qu'une période calendaire unique pour tous.
