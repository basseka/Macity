import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/core/data/scraped_events_supabase_service.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Dernier resultat reussi par ville, garde en memoire process. Sert de
/// repli quand les 3 tentatives de [tonightEventsProvider] echouent : mieux
/// vaut un compteur perime que de faire croire qu'il n'y a "rien aujourd'hui".
final _lastKnownTodayEvents = <String, List<Event>>{};

/// true quand la derniere tentative de fetch a echoue apres 3 essais. Le
/// bandeau s'en sert pour ne jamais afficher le message "Rien aujourd'hui"
/// (qui affirme a tort qu'il n'y a aucun evenement) : sur erreur reseau, on
/// garde le titre normal et un compteur potentiellement perime plutot que
/// de mentir sur l'etat reel.
final tonightEventsFetchFailedProvider =
    StateProvider.autoDispose<bool>((ref) => false);

/// Événements d'AUJOURD'HUI (journée + soirée, toutes rubriques/catégories) de
/// la ville sélectionnée. Alimente le carrousel « Quoi faire ce soir » ET la
/// pastille compteur du bouton du meme nom (meme liste, meme longueur, pour
/// que les deux affichent toujours le meme chiffre).
///
/// Limit volontairement large (500) : sur une seule ville et une seule
/// journee, on ne s'attend jamais a en approcher le compte, mais un plafond
/// bas (l'ancien 60) tronquait silencieusement la liste et faisait mentir le
/// compteur.
///
/// Retry 3 fois (avec un court delai croissant) avant d'abandonner : un
/// echec ponctuel de Supabase ne doit pas vider le bandeau pour autant.
final tonightEventsProvider =
    FutureProvider.autoDispose<List<Event>>((ref) async {
  final city = ref.watch(selectedCityProvider);
  final now = DateTime.now();
  String pad(int v) => v.toString().padLeft(2, '0');
  final todayStr = '${now.year}-${pad(now.month)}-${pad(now.day)}';

  List<Event>? result;
  for (var attempt = 1; attempt <= 3; attempt++) {
    try {
      final (events, _) = await ScrapedEventsSupabaseService().fetchAllEvents(
        dateGte: todayStr,
        ville: city,
        limit: 500,
      );
      // Uniquement les events qui commencent aujourd'hui.
      result = events.where((e) {
        final d = DateTime.tryParse(e.dateDebut);
        if (d == null) return false;
        return '${d.year}-${pad(d.month)}-${pad(d.day)}' == todayStr;
      }).toList();
      break;
    } catch (_) {
      if (attempt < 3) {
        await Future.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  if (result != null) {
    _lastKnownTodayEvents[city] = result;
    ref.read(tonightEventsFetchFailedProvider.notifier).state = false;
    return result;
  }

  ref.read(tonightEventsFetchFailedProvider.notifier).state = true;
  return _lastKnownTodayEvents[city] ?? const <Event>[];
});

/// Nombre d'evenements d'aujourd'hui — alimente la pastille compteur du
/// bouton "Quoi faire ce soir". Toujours egal a la longueur de la liste
/// affichee dans [TonightEventsSheet] (meme provider source).
final tonightEventsCountProvider = Provider.autoDispose<int>((ref) {
  final async = ref.watch(tonightEventsProvider);
  return async.maybeWhen(
    data: (events) => events.length,
    orElse: () => 0,
  );
});
