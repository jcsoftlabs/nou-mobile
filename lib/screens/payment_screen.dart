import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../data/providers/auth_provider.dart';
import '../services/payment_service.dart';
import 'dart:async';

class PaymentScreen extends StatefulWidget {
  final String type; // 'cotisation' ou 'don'
  final double montant;
  final Map<String, dynamic>? metadata;

  const PaymentScreen({
    super.key,
    required this.type,
    required this.montant,
    this.metadata,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  String? _paymentUrl;
  String? _referenceId;
  bool _isLoading = true;
  String? _error;
  String _selectedMethod = 'all';
  Timer? _statusCheckTimer;
  
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePayment() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _error = 'Session expirée. Veuillez vous reconnecter.';
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await _paymentService.initiatePayment(
        token: token,
        type: widget.type,
        montant: widget.montant,
        paymentMethod: _selectedMethod,
        metadata: widget.metadata,
      );

      if (result['success']) {
        setState(() {
          _paymentUrl = result['data']['payment_url'];
          _referenceId = result['data']['reference_id'];
          _isLoading = false;
        });

        // Initialiser le WebView
        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                // Détecter le retour du callback
                if (url.contains('nouapp://payment/')) {
                  _handlePaymentCallback(url);
                }
              },
              onPageFinished: (String url) {
                if (url.contains('nouapp://payment/')) {
                  _handlePaymentCallback(url);
                }
              },
            ),
          )
          ..loadRequest(Uri.parse(_paymentUrl!));

        // Démarrer la vérification périodique du statut
        _startStatusCheck();
      } else {
        setState(() {
          _error = result['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de l\'initiation du paiement: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (_referenceId == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) return;

    try {
      final result = await _paymentService.checkPaymentStatus(
        token: token,
        referenceId: _referenceId!,
      );

      if (result['success']) {
        final status = result['data']['status'];
        if (status == 'completed') {
          _statusCheckTimer?.cancel();
          _showSuccessDialog();
        } else if (status == 'failed') {
          _statusCheckTimer?.cancel();
          _showErrorDialog('Le paiement a échoué');
        }
      }
    } catch (e) {
      // Ignorer les erreurs de vérification
    }
  }

  void _handlePaymentCallback(String url) {
    _statusCheckTimer?.cancel();

    if (url.contains('success')) {
      _showSuccessDialog();
    } else if (url.contains('error')) {
      final uri = Uri.parse(url);
      final message = uri.queryParameters['message'] ?? 'Erreur de paiement';
      _showErrorDialog(message);
    } else if (url.contains('pending')) {
      _showPendingDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Paiement réussi !'),
          ],
        ),
        content: Text(
          'Votre ${widget.type} de ${widget.montant.toStringAsFixed(2)} HTG a été effectué avec succès.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer dialog
              Navigator.of(context).pop(true); // Retourner avec succès
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 32),
            SizedBox(width: 12),
            Text('Erreur'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer dialog
              Navigator.of(context).pop(false); // Retourner avec échec
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pending, color: Colors.orange, size: 32),
            SizedBox(width: 12),
            Text('Paiement en attente'),
          ],
        ),
        content: const Text(
          'Votre paiement est en cours de traitement. Vous recevrez une notification une fois confirmé.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fermer dialog
              Navigator.of(context).pop(null); // Retourner avec statut pending
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paiement ${widget.type}'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.red),
                  SizedBox(height: 16),
                  Text('Initialisation du paiement...'),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retour'),
                        ),
                      ],
                    ),
                  ),
                )
              : _paymentUrl != null
                  ? WebViewWidget(controller: _webViewController)
                  : const Center(child: Text('Erreur de chargement')),
    );
  }
}
