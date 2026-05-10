import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Demande de filtre du feed exprimee depuis l'exterieur (ex: HomeNavTabs).
/// FeedScreen ecoute ce provider et applique le filtre via _switchTab.
/// Valeurs : 'En Scène' | 'Event' | 'Clubbing' | null (= pas de filtre / Tout).
final feedFilterIntentProvider = StateProvider<String?>((ref) => null);
