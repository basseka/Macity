import 'package:flutter/material.dart';

/// Sous-interets detailles par mode, pour le ciblage des notifications.
///
/// Chaque entree est stockee en DB sous la forme "mode:tag"
/// (ex: "sport:football", "day:festival").
class InterestCategory {
  final String mode;
  final String label;
  final IconData icon;
  final List<InterestItem> items;

  const InterestCategory({
    required this.mode,
    required this.label,
    required this.icon,
    required this.items,
  });
}

class InterestItem {
  final String tag;
  final String label;
  final IconData icon;

  const InterestItem({
    required this.tag,
    required this.label,
    required this.icon,
  });

  /// Cle unique stockee en DB : "mode:tag".
  String key(String mode) => '$mode:$tag';
}

const kDetailedInterests = <InterestCategory>[
  // ── Concerts & Spectacles ──
  InterestCategory(
    mode: 'day',
    label: 'Concerts & Spectacles',
    icon: Icons.music_note,
    items: [
      InterestItem(tag: 'concert', label: 'Concerts', icon: Icons.mic),
      InterestItem(tag: 'festival', label: 'Festivals', icon: Icons.festival),
      InterestItem(tag: 'spectacle', label: 'Spectacles vivants', icon: Icons.theater_comedy),
      InterestItem(tag: 'standup', label: 'Stand-up / Humour', icon: Icons.emoji_emotions),
      InterestItem(tag: 'opera', label: 'Opera / Classique', icon: Icons.piano),
      InterestItem(tag: 'dj', label: 'DJ set / Electro', icon: Icons.headphones),
      InterestItem(tag: 'conference', label: 'Conferences / Talks', icon: Icons.record_voice_over),
      InterestItem(tag: 'atelier', label: 'Ateliers / Workshops', icon: Icons.handyman),
    ],
  ),

  // ── Sport ──
  InterestCategory(
    mode: 'sport',
    label: 'Sport',
    icon: Icons.sports_soccer,
    items: [
      InterestItem(tag: 'football', label: 'Football', icon: Icons.sports_soccer),
      InterestItem(tag: 'rugby', label: 'Rugby', icon: Icons.sports_rugby),
      InterestItem(tag: 'basketball', label: 'Basketball', icon: Icons.sports_basketball),
      InterestItem(tag: 'tennis', label: 'Tennis', icon: Icons.sports_tennis),
      InterestItem(tag: 'handball', label: 'Handball', icon: Icons.sports_handball),
      InterestItem(tag: 'course', label: 'Course / Running', icon: Icons.directions_run),
      InterestItem(tag: 'fitness', label: 'Fitness / Musculation', icon: Icons.fitness_center),
      InterestItem(tag: 'yoga', label: 'Yoga / Pilates', icon: Icons.self_improvement),
      InterestItem(tag: 'natation', label: 'Natation', icon: Icons.pool),
      InterestItem(tag: 'cyclisme', label: 'Cyclisme', icon: Icons.pedal_bike),
      InterestItem(tag: 'arts_martiaux', label: 'Arts martiaux / Combat', icon: Icons.sports_martial_arts),
    ],
  ),

  // ── Culture & Arts ──
  InterestCategory(
    mode: 'culture',
    label: 'Culture & Arts',
    icon: Icons.palette,
    items: [
      InterestItem(tag: 'expo', label: 'Expositions', icon: Icons.photo_library),
      InterestItem(tag: 'theatre', label: 'Theatre', icon: Icons.theater_comedy),
      InterestItem(tag: 'musee', label: 'Musees', icon: Icons.museum),
      InterestItem(tag: 'cinema', label: 'Cinema', icon: Icons.movie),
      InterestItem(tag: 'danse', label: 'Danse', icon: Icons.nightlife),
      InterestItem(tag: 'visite', label: 'Visites guidees', icon: Icons.tour),
      InterestItem(tag: 'lecture', label: 'Lecture / Litterature', icon: Icons.menu_book),
      InterestItem(tag: 'photo', label: 'Photographie', icon: Icons.camera_alt),
    ],
  ),

  // ── En Famille ──
  InterestCategory(
    mode: 'family',
    label: 'En Famille',
    icon: Icons.family_restroom,
    items: [
      InterestItem(tag: 'spectacle_enfant', label: 'Spectacles enfants', icon: Icons.child_care),
      InterestItem(tag: 'parc', label: 'Parcs / Jardins', icon: Icons.park),
      InterestItem(tag: 'cinema_famille', label: 'Cinema', icon: Icons.movie),
      InterestItem(tag: 'bowling', label: 'Bowling / Laser game', icon: Icons.sports),
      InterestItem(tag: 'atelier_enfant', label: 'Ateliers creatifs', icon: Icons.brush),
      InterestItem(tag: 'fete_foraine', label: 'Fetes foraines', icon: Icons.attractions),
      InterestItem(tag: 'zoo', label: 'Zoo / Aquarium', icon: Icons.pets),
    ],
  ),

  // ── Food & Lifestyle ──
  InterestCategory(
    mode: 'food',
    label: 'Food & Lifestyle',
    icon: Icons.restaurant,
    items: [
      InterestItem(tag: 'restaurant', label: 'Restaurants', icon: Icons.restaurant),
      InterestItem(tag: 'brunch', label: 'Brunchs', icon: Icons.brunch_dining),
      InterestItem(tag: 'cafe', label: 'Cafes / Salons de the', icon: Icons.coffee),
      InterestItem(tag: 'marche', label: 'Marches / Food markets', icon: Icons.storefront),
      InterestItem(tag: 'degustation', label: 'Degustations / Vin', icon: Icons.wine_bar),
      InterestItem(tag: 'food_truck', label: 'Food trucks', icon: Icons.local_shipping),
      InterestItem(tag: 'cours_cuisine', label: 'Cours de cuisine', icon: Icons.soup_kitchen),
      InterestItem(tag: 'bienetre', label: 'Bien-etre / Spa', icon: Icons.spa),
    ],
  ),

  // ── Gaming & Pop Culture ──
  InterestCategory(
    mode: 'gaming',
    label: 'Gaming & Pop Culture',
    icon: Icons.videogame_asset,
    items: [
      InterestItem(tag: 'esport', label: 'E-sport / Tournois', icon: Icons.emoji_events),
      InterestItem(tag: 'convention', label: 'Conventions / Salons', icon: Icons.groups),
      InterestItem(tag: 'bar_jeux', label: 'Bar a jeux', icon: Icons.casino),
      InterestItem(tag: 'lan', label: 'LAN party', icon: Icons.computer),
      InterestItem(tag: 'manga', label: 'Manga / Anime', icon: Icons.auto_stories),
      InterestItem(tag: 'vr', label: 'Realite virtuelle', icon: Icons.vrpano),
      InterestItem(tag: 'escape_game', label: 'Escape games', icon: Icons.lock_open),
    ],
  ),

  // ── Nuit & Sorties ──
  InterestCategory(
    mode: 'night',
    label: 'Nuit & Sorties',
    icon: Icons.nightlife,
    items: [
      InterestItem(tag: 'bar', label: 'Bars / Pubs', icon: Icons.local_bar),
      InterestItem(tag: 'club', label: 'Clubs / Discothèques', icon: Icons.nightlife),
      InterestItem(tag: 'soiree', label: 'Soirees thematiques', icon: Icons.celebration),
      InterestItem(tag: 'concert_live', label: 'Concerts live / Showcase', icon: Icons.mic_external_on),
      InterestItem(tag: 'karaoke', label: 'Karaoke', icon: Icons.mic),
      InterestItem(tag: 'afterwork', label: 'Afterwork', icon: Icons.work_off),
    ],
  ),

  // ── Tourisme ──
  InterestCategory(
    mode: 'tourisme',
    label: 'Tourisme & Decouvertes',
    icon: Icons.flight,
    items: [
      InterestItem(tag: 'visite_guidee', label: 'Visites guidees', icon: Icons.tour),
      InterestItem(tag: 'balade', label: 'Balades / Randonnees', icon: Icons.hiking),
      InterestItem(tag: 'patrimoine', label: 'Patrimoine / Monuments', icon: Icons.account_balance),
      InterestItem(tag: 'nature', label: 'Nature / Plein air', icon: Icons.forest),
      InterestItem(tag: 'croisiere', label: 'Croisieres fluviales', icon: Icons.sailing),
      InterestItem(tag: 'oenotourisme', label: 'Oenotourisme', icon: Icons.wine_bar),
    ],
  ),
];
