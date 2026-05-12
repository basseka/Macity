import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True quand un autre ecran (ex. Explorer) demande l'ouverture du mode
/// recherche dans FeedScreen. FeedScreen consomme et reset a false.
final searchIntentProvider = StateProvider<bool>((_) => false);
