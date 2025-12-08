# Correctifs pour respecter les règles de cotisation

## 🚨 Problèmes identifiés

### 1. Montant fixe hardcodé
**Fichier** : `lib/screens/cotisation_screen.dart:29`
```dart
final double _montantCotisation = 1500.0; // HTG
```

**❌ Problème** : L'app force 1500 HTG à chaque fois, empêchant les versements multiples.

### 2. Pas de récupération du statut annuel
L'app ne consulte pas l'endpoint `/cotisations/mon-statut` pour savoir :
- Combien le membre a déjà versé cette année
- Combien il reste à payer
- Si c'est son premier versement

### 3. Pas de validation du montant minimum
Aucune vérification que :
- Premier versement >= 150 HTG
- Versements suivants >= 1 HTG
- Total annuel <= 1500 HTG

---

## ✅ Solutions recommandées

### Solution A : Interface avec saisie de montant (RECOMMANDÉE)

#### Étape 1 : Créer un modèle pour le statut annuel
**Fichier** : `lib/models/cotisation_status.dart`
```dart
class CotisationStatus {
  final int annee;
  final double montantTotalAnnuel;  // 1500 HTG
  final double montantVerse;        // Déjà payé
  final double montantRestant;      // Reste à payer
  final bool estComplet;            // true si >= 1500 HTG
  final bool estPremierVersement;   // true si aucun versement validé
  final double montantMinimumProchainVersement; // 150 HTG ou 1 HTG

  // ... reste du code
}
```

#### Étape 2 : Ajouter l'appel API
**Fichier** : `lib/services/api_service.dart`
```dart
Future<CotisationStatus?> getCotisationStatus(int membreId) async {
  try {
    final response = await _dio.get('/cotisations/mon-statut');
    if (response.statusCode == 200 && response.data['data'] != null) {
      return CotisationStatus.fromJson(response.data['data']);
    }
    return null;
  } catch (e) {
    print('Erreur getCotisationStatus: $e');
    return null;
  }
}
```

#### Étape 3 : Modifier l'interface utilisateur
**Changements dans** : `lib/screens/cotisation_screen.dart`

1. **Remplacer le montant fixe par un champ de saisie**
```dart
// SUPPRIMER
// final double _montantCotisation = 1500.0;

// AJOUTER
CotisationStatus? _cotisationStatus;
final _montantController = TextEditingController();
double? _montantSaisi;
```

2. **Charger le statut annuel au démarrage**
```dart
Future<void> _loadCotisationStatus() async {
  setState(() => _isLoading = true);
  
  try {
    // Charger le statut annuel
    final status = await _apiService.getCotisationStatus(widget.membreId);
    
    // Charger la dernière cotisation
    final derniere = await _apiService.getLastCotisation(widget.membreId);
    
    // Charger l'historique
    final result = await _apiService.getCotisations(widget.membreId);
    
    if (mounted) {
      setState(() {
        _cotisationStatus = status;
        _derniereCotisation = derniere;
        if (result['success']) {
          _historique = result['data'] as List<Cotisation>;
        }
        _isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

3. **Afficher le statut de la cotisation annuelle**
```dart
Widget _buildAnnualStatusCard() {
  if (_cotisationStatus == null) return const SizedBox.shrink();
  
  final status = _cotisationStatus!;
  final progress = status.montantVerse / status.montantTotalAnnuel;
  
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.red.shade50, Colors.red.shade100],
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cotisation ${status.annee}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Barre de progression
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          color: Colors.red,
          minHeight: 10,
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 12),
        
        // Montants
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Versé', style: TextStyle(color: Colors.grey)),
                Text(
                  '${status.montantVerse.toStringAsFixed(2)} HTG',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Restant', style: TextStyle(color: Colors.grey)),
                Text(
                  '${status.montantRestant.toStringAsFixed(2)} HTG',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Badge de statut
        if (status.estComplet)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Cotisation complète',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
```

4. **Ajouter un champ de saisie pour le montant**
```dart
Widget _buildMontantInput() {
  if (_cotisationStatus == null) return const SizedBox.shrink();
  
  final status = _cotisationStatus!;
  final montantMin = status.montantMinimumProchainVersement;
  final montantMax = status.montantRestant;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Montant du versement',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _montantController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Entrez le montant (HTG)',
          prefixIcon: const Icon(Icons.money),
          suffixText: 'HTG',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          helperText: status.estPremierVersement
              ? 'Minimum : $montantMin HTG (premier versement)'
              : 'Minimum : $montantMin HTG - Maximum : $montantMax HTG',
        ),
        onChanged: (value) {
          setState(() {
            _montantSaisi = double.tryParse(value);
          });
        },
      ),
      
      // Suggestions de montants
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        children: [
          if (!status.estComplet) ...[
            _buildMontantSuggestion(status.montantRestant, 'Payer le solde'),
            if (status.montantRestant >= 500)
              _buildMontantSuggestion(500, '500 HTG'),
            if (status.montantRestant >= 300)
              _buildMontantSuggestion(300, '300 HTG'),
            if (status.estPremierVersement && status.montantRestant >= 150)
              _buildMontantSuggestion(150, '150 HTG (minimum)'),
          ],
        ],
      ),
    ],
  );
}

Widget _buildMontantSuggestion(double montant, String label) {
  return ActionChip(
    label: Text(label),
    onPressed: () {
      setState(() {
        _montantController.text = montant.toStringAsFixed(0);
        _montantSaisi = montant;
      });
    },
  );
}
```

5. **Valider le montant avant le paiement**
```dart
String? _validateMontant() {
  if (_cotisationStatus == null || _montantSaisi == null) {
    return 'Veuillez entrer un montant';
  }
  
  final status = _cotisationStatus!;
  
  // Vérifier le minimum
  if (_montantSaisi! < status.montantMinimumProchainVersement) {
    if (status.estPremierVersement) {
      return 'Le premier versement doit être d\'au moins ${status.montantMinimumProchainVersement} HTG';
    }
    return 'Le montant minimum est de ${status.montantMinimumProchainVersement} HTG';
  }
  
  // Vérifier le maximum
  if (_montantSaisi! > status.montantRestant) {
    return 'Le montant dépasse le solde restant (${status.montantRestant} HTG)';
  }
  
  // Cotisation déjà complète
  if (status.estComplet) {
    return 'Votre cotisation ${status.annee} est déjà complète';
  }
  
  return null; // Valide
}

Future<void> _payWithMonCash() async {
  final error = _validateMontant();
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red),
    );
    return;
  }
  
  // Procéder au paiement avec _montantSaisi!
  _processMonCashPayment();
}
```

6. **Mettre à jour la logique de paiement**
```dart
Future<void> _processMonCashPayment() async {
  setState(() => _isLoading = true);

  final request = CotisationRequest(
    membreId: widget.membreId,
    montant: _montantSaisi!, // Utiliser le montant saisi
    moyenPaiement: 'moncash',
  );

  final result = await _apiService.createCotisation(request);
  // ... reste du code
}

Future<void> _uploadFile(String filePath) async {
  setState(() => _isLoading = true);

  final request = CotisationRequest(
    membreId: widget.membreId,
    montant: _montantSaisi!, // Utiliser le montant saisi
    moyenPaiement: 'recu_upload',
    recuPath: filePath,
  );

  final result = await _apiService.createCotisation(request);
  // ... reste du code
}
```

---

### Solution B : Interface simplifiée (paiement complet uniquement)

Si vous préférez garder une interface simple sans versements multiples :

1. **Bloquer les paiements si déjà payé**
```dart
Future<void> _payWithMonCash() async {
  if (_cotisationStatus?.estComplet == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Votre cotisation annuelle est déjà payée'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
  
  // Continuer avec le paiement de 1500 HTG
  _processMonCashPayment();
}
```

2. **Avertir si le membre a déjà des versements partiels**
```dart
if (_cotisationStatus != null && _cotisationStatus!.montantVerse > 0 && !_cotisationStatus!.estComplet) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Attention'),
      content: Text(
        'Vous avez déjà versé ${_cotisationStatus!.montantVerse} HTG cette année. '
        'Il reste ${_cotisationStatus!.montantRestant} HTG à payer.'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _processMonCashPayment();
          },
          child: const Text('Payer quand même'),
        ),
      ],
    ),
  );
}
```

---

## 📋 Checklist d'implémentation

- [ ] Créer/Mettre à jour le modèle `CotisationStatus`
- [ ] Ajouter l'appel API `getCotisationStatus()` dans `ApiService`
- [ ] Afficher le statut annuel dans `CotisationScreen`
- [ ] Ajouter un champ de saisie pour le montant
- [ ] Implémenter la validation du montant
- [ ] Mettre à jour les fonctions de paiement pour utiliser le montant saisi
- [ ] Tester avec différents scénarios :
  - [ ] Premier versement < 150 HTG (doit être refusé)
  - [ ] Premier versement >= 150 HTG (doit passer)
  - [ ] Versement dépassant le solde (doit être refusé)
  - [ ] Paiement complet en une fois
  - [ ] Paiement en plusieurs versements
  - [ ] Tentative de payer après avoir complété la cotisation

---

## 🎯 Résultat attendu

Après ces correctifs, l'app mobile respectera toutes les règles du backend :

✅ Montant minimum du premier versement : 150 HTG  
✅ Montant minimum des versements suivants : 1 HTG  
✅ Total annuel maximum : 1500 HTG  
✅ Affichage du statut de cotisation en temps réel  
✅ Validation des montants avant envoi au serveur  
✅ Support des versements multiples  
