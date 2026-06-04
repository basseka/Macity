import 'package:pulz_app/features/reported_events/domain/models/reported_event.dart';

/// Stories Map Live "permanentes" (toujours visibles, ne s'expirent pas).
/// Servent a remplir le stripe "En direct autour de vous" meme sans activite
/// communautaire reelle, et a demontrer la lecture video plein ecran dans le
/// viewer Snap-style.
///
/// Les medias sont hebergees sur Supabase Storage, bucket `user-events`,
/// dossier `fake-stories/` (uploadees une fois pour toutes via supabase CLI).
const _bucketUrl =
    'https://dpqxefmwjfvoysacwgef.supabase.co/storage/v1/object/public/user-events/fake-stories';

/// Date de creation tres recente — fait apparaitre les fakes en tete de
/// liste apres tri chronologique inverse.
DateTime _recent(int minutesAgo) =>
    DateTime.now().subtract(Duration(minutes: minutesAgo));

/// Date d'expiration tres lointaine — assure le caractere "permanent".
final _farFuture = DateTime(2099, 12, 31);

List<ReportedEvent> permanentFakeStories() => [
      ReportedEvent(
        id: 'fake-story-permanent-1',
        reportedBy: 'fake-system',
        rawTitle: 'Soirée electro au bord du canal',
        category: 'soiree',
        lat: 43.6047,
        lng: 1.4442,
        ville: 'Toulouse',
        locationName: 'Canal du Midi',
        // photos vide : la story demarre directement sur la video dans le
        // viewer Snap-style. Le thumbnail reste dispo via coverUrl pour la
        // bulle du carrousel/strip.
        photos: const [],
        coverUrl: '$_bucketUrl/fake-thumb-1.jpg',
        videos: ['$_bucketUrl/fake-story-1.mp4'],
        reportCount: 3,
        reporterPrenom: 'Lucas',
        status: 'published',
        realViews: 142,
        startsAt: _recent(45),
        expiresAt: _farFuture,
        createdAt: _recent(8),
        generated: const ReportedEventGenerated(
          title: 'Electro vibes au canal',
          description:
              'Ambiance electro-house en plein air. Set qui dure jusqu\'à 3h.',
          mood: 'festif',
          tags: ['electro', 'open air'],
          emoji: '🎧',
          gradientFrom: '#FF2DAA',
          gradientTo: '#7C3AED',
          timeLabel: 'LIVE',
          categoryInferred: 'soiree',
        ),
      ),
      ReportedEvent(
        id: 'fake-story-permanent-2',
        reportedBy: 'fake-system',
        rawTitle: 'Concert live au bar',
        category: 'concert',
        lat: 43.6109,
        lng: 1.4537,
        ville: 'Toulouse',
        locationName: 'Le Bikini',
        photos: const [],
        coverUrl: '$_bucketUrl/fake-thumb-2.jpg',
        videos: ['$_bucketUrl/fake-story-2.mp4'],
        reportCount: 5,
        reporterPrenom: 'Léa',
        status: 'published',
        realViews: 287,
        startsAt: _recent(20),
        expiresAt: _farFuture,
        createdAt: _recent(15),
        generated: const ReportedEventGenerated(
          title: 'Live session — guitare-voix',
          description: 'Set acoustique, ambiance intimiste, places encore dispo.',
          mood: 'chill',
          tags: ['concert', 'acoustique'],
          emoji: '🎸',
          gradientFrom: '#FF3D8B',
          gradientTo: '#FBBF24',
          timeLabel: 'LIVE',
          categoryInferred: 'concert',
        ),
      ),
      ReportedEvent(
        id: 'fake-story-permanent-3',
        reportedBy: 'fake-system',
        rawTitle: 'Skyline cinéma',
        category: 'culture',
        lat: 43.5987,
        lng: 1.4348,
        ville: 'Toulouse',
        locationName: 'Rooftop place du Capitole',
        photos: const [],
        coverUrl: '$_bucketUrl/fake-thumb-3.jpg',
        videos: ['$_bucketUrl/fake-story-3.mp4'],
        reportCount: 2,
        reporterPrenom: 'Mila',
        status: 'published',
        realViews: 95,
        startsAt: _recent(30),
        expiresAt: _farFuture,
        createdAt: _recent(25),
        generated: const ReportedEventGenerated(
          title: 'Cinéma en plein air — rooftop',
          description: 'Projection sous les étoiles, transats + boissons sur place.',
          mood: 'cosy',
          tags: ['cinéma', 'rooftop'],
          emoji: '🎬',
          gradientFrom: '#A855F7',
          gradientTo: '#06B6D4',
          timeLabel: 'LIVE',
          categoryInferred: 'culture',
        ),
      ),
    ];
