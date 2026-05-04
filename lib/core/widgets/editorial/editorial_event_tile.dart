import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_event_row_card.dart';
import 'package:pulz_app/core/widgets/editorial/editorial_group_header.dart';
import 'package:pulz_app/core/widgets/event_fullscreen_popup.dart';
import 'package:pulz_app/features/day/domain/models/event.dart';

/// Helpers partages pour l'affichage uniforme "A venir" entre les 7 hubs
/// (Day, Night, Culture, Food, Family, Gaming, Sport).
///
/// Reference visuelle : la liste "A venir" du Day mode (cards
/// EditorialEventRowCard avec date pill overlay sur vignette + sous-titre
/// italique + lieu, headers EditorialGroupHeader avec filet + count).
EditorialEventRowCard editorialEventTileFromEvent(
  BuildContext context,
  Event event,
  Color accent, {
  String fallbackImage = 'assets/images/pochette_default.jpg',
}) {
  final parsed = DateTime.tryParse(event.dateDebut);
  final monthAbbr = parsed != null
      ? DateFormat('MMM', 'fr_FR')
          .format(parsed)
          .replaceAll('.', '')
          .toUpperCase()
      : null;
  final dayNum = parsed?.day.toString();
  final weekDay = parsed != null
      ? DateFormat('EEE', 'fr_FR').format(parsed).toLowerCase()
      : null;
  final price = event.isFree
      ? 'Gratuit'
      : (event.tarifNormal.isNotEmpty ? event.tarifNormal : null);
  final imageUrl = (event.photoPath != null && event.photoPath!.isNotEmpty)
      ? event.photoPath
      : fallbackImage;

  return EditorialEventRowCard(
    dateMonth: monthAbbr,
    dateDay: dayNum,
    weekDay: weekDay,
    time: event.horaires,
    title: event.titre,
    subtitle:
        event.descriptifCourt.isNotEmpty ? event.descriptifCourt : null,
    venue: event.lieuNom.isNotEmpty ? event.lieuNom : null,
    price: price,
    imageUrl: imageUrl,
    accent: accent,
    onTap: () => EventFullscreenPopup.show(context, event, fallbackImage),
  );
}

/// Header de groupe pour une journee (Aujourd'hui / Demain / lundi 5 mai).
/// Style aligne sur Day : filet + kicker accent + Fraunces title + count tabular.
EditorialGroupHeader editorialDateHeader(
  String label,
  Color accent, {
  int? count,
}) {
  return EditorialGroupHeader(
    kicker: label,
    title: label,
    count: count,
    accent: accent,
  );
}

/// Convertit une DateTime en label affichable selon contexte
/// (Aujourd'hui / Demain / sinon "lundi 5 mai" capitalise).
String editorialDayLabel(DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  if (day == today) return "Aujourd'hui";
  if (day == tomorrow) return 'Demain';
  final formatted = DateFormat('EEEE d MMMM', 'fr_FR').format(day);
  return formatted.isEmpty
      ? formatted
      : formatted[0].toUpperCase() + formatted.substring(1);
}
