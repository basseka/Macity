import 'package:flutter/widgets.dart';
import 'package:pulz_app/core/services/analytics_service.dart';

/// Déclare un écran à Firebase Analytics à son ouverture.
///
/// Pour les écrans hors routeur (ouverts par `Navigator.push` ou en bottom
/// sheet) : le routeur ne les voit pas, donc sans ça ils n'apparaissent dans
/// aucun rapport. À utiliser dans un widget sans `State` ; un `State` appelle
/// directement `AnalyticsService.logScreenView` dans son `initState`.
class SuiviEcran extends StatefulWidget {
  final String nom;
  final Widget child;

  const SuiviEcran({super.key, required this.nom, required this.child});

  @override
  State<SuiviEcran> createState() => _SuiviEcranState();
}

class _SuiviEcranState extends State<SuiviEcran> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView(widget.nom);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
