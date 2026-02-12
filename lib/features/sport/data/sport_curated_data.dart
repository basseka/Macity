import 'package:pulz_app/features/day/data/day_curated_data.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Curated sport events data.
///
/// Delegates to [DayCuratedData] for sport-related curated events
/// (boxe, natation, etc.) and provides a unified access point for
/// the sport feature.
class SportCuratedData {
  SportCuratedData._();

  // ---------------------------------------------------------------------------
  // Boxe
  // ---------------------------------------------------------------------------

  /// Curated boxing events for Toulouse.
  static List<Event> getBoxeToulouse() => DayCuratedData.getBoxeToulouse();

  // ---------------------------------------------------------------------------
  // Natation
  // ---------------------------------------------------------------------------

  /// Curated swimming events for Toulouse.
  static List<Event> getNatationToulouse() =>
      DayCuratedData.getNatationToulouse();

  // ---------------------------------------------------------------------------
  // All sport curated events
  // ---------------------------------------------------------------------------

  /// Returns all curated sport events for Toulouse.
  static List<Event> getAllToulouse() => [
        ...getBoxeToulouse(),
        ...getNatationToulouse(),
      ];
}
