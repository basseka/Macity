import 'package:flutter/material.dart';
import 'package:pulz_app/core/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pulz_app/features/city/state/city_provider.dart';

class TopPicksSheet extends ConsumerWidget {
  const TopPicksSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TopPicksSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityProvider);
    final data = _cityData[city.toLowerCase()];

    if (data == null) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F0FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.lineStrong, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 40),
            const Icon(Icons.explore_outlined, size: 48, color: Color(0xFFE91E8C)),
            const SizedBox(height: 16),
            Text('$city arrive bientot !', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF4A1259))),
            const SizedBox(height: 8),
            Text('Les incontournables de $city seront disponibles prochainement.', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDim)),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF8F0FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '\u2B50 $city ',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A1259),
                    ),
                  ),
                  TextSpan(
                    text: 'incontournable',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE91E8C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              labelColor: const Color(0xFF4A1259),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFE91E8C),
              labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Top 10'),
                Tab(text: '1 jour'),
                Tab(text: '3 jours'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(data.top10),
                  _buildList(data.oneDay),
                  _buildList(data.threeDays),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<_TopPick> picks) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: picks.length,
      itemBuilder: (context, i) {
        final pick = picks[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE91E8C), Color(0xFF7B2D8E)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pick.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4A1259),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pick.description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textDim,
                        ),
                      ),
                      if (pick.tip != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          pick.tip!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFE91E8C),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (pick.mapsQuery != null)
                  GestureDetector(
                    onTap: () {
                      final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(pick.mapsQuery!)}';
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B2D8E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.directions,
                        size: 18,
                        color: Color(0xFF7B2D8E),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Data models & city data ──

class _TopPick {
  final String title;
  final String description;
  final String? tip;
  final String? mapsQuery;

  const _TopPick({
    required this.title,
    required this.description,
    this.tip,
    this.mapsQuery,
  });
}

class _CityTopPicks {
  final List<_TopPick> top10;
  final List<_TopPick> oneDay;
  final List<_TopPick> threeDays;

  const _CityTopPicks({
    required this.top10,
    required this.oneDay,
    required this.threeDays,
  });
}

// ── Data par ville ──

const _cityData = <String, _CityTopPicks>{
  'toulouse': _CityTopPicks(
    top10: [
      _TopPick(title: 'Place du Capitole', description: 'Le coeur battant de Toulouse, architecture monumentale', tip: 'Magnifique de nuit avec les illuminations', mapsQuery: 'Place du Capitole Toulouse'),
      _TopPick(title: 'Cite de l\'Espace', description: 'Parc a theme spatial unique en Europe, fusees et simulateurs', tip: 'Prevois au moins 4h de visite', mapsQuery: 'Cite de l\'Espace Toulouse'),
      _TopPick(title: 'Basilique Saint-Sernin', description: 'Plus grande eglise romane d\'Europe, patrimoine UNESCO', mapsQuery: 'Basilique Saint-Sernin Toulouse'),
      _TopPick(title: 'Fondation Bemberg', description: 'Collection privee exceptionnelle dans l\'Hotel d\'Assezat', tip: 'Gratuit le 1er dimanche du mois', mapsQuery: 'Fondation Bemberg Toulouse'),
      _TopPick(title: 'Jardin Japonais', description: 'Un havre de paix au coeur de Compans-Caffarelli', mapsQuery: 'Jardin Japonais Toulouse'),
      _TopPick(title: 'Les Halles de la Machine', description: 'Creatures mecaniques geantes, le Minotaure et l\'Araignee', tip: 'Spectacles gratuits sur le parvis', mapsQuery: 'Halle de la Machine Toulouse'),
      _TopPick(title: 'Le Canal du Midi', description: 'Promenade le long du canal classe UNESCO, velo ou a pied', mapsQuery: 'Canal du Midi Toulouse'),
      _TopPick(title: 'Couvent des Jacobins', description: 'Chef-d\'oeuvre de l\'art gothique meridional, le palmier', mapsQuery: 'Couvent des Jacobins Toulouse'),
      _TopPick(title: 'Marche Victor Hugo', description: 'Marche couvert emblematique, restaurants a l\'etage', tip: 'Les restaurants du 1er etage sont un secret local', mapsQuery: 'Marche Victor Hugo Toulouse'),
      _TopPick(title: 'Pont Neuf au coucher du soleil', description: 'Le plus vieux pont de Toulouse, vue magique sur la Garonne', tip: 'Meilleur spot photo de la ville', mapsQuery: 'Pont Neuf Toulouse'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Capitole + Victor Hugo', description: 'Cafe Place du Capitole, puis marche Victor Hugo pour le brunch', mapsQuery: 'Place du Capitole Toulouse'),
      _TopPick(title: 'Fin de matinee : Saint-Sernin', description: 'Visite de la basilique et du quartier historique', mapsQuery: 'Basilique Saint-Sernin Toulouse'),
      _TopPick(title: 'Dejeuner : Rue du Taur', description: 'Restaurants et terrasses entre Capitole et Saint-Sernin', mapsQuery: 'Rue du Taur Toulouse'),
      _TopPick(title: 'Apres-midi : Jacobins + Berges', description: 'Couvent des Jacobins puis balade sur les berges de la Garonne', mapsQuery: 'Couvent des Jacobins Toulouse'),
      _TopPick(title: 'Soir : Pont Neuf + Saint-Cyprien', description: 'Coucher de soleil sur le Pont Neuf, diner cote rive gauche', tip: 'Saint-Cyprien est le quartier le plus "village" de Toulouse', mapsQuery: 'Pont Neuf Toulouse'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Centre historique', description: 'Capitole, Victor Hugo, Saint-Sernin, Jacobins, Pont Neuf', mapsQuery: 'Place du Capitole Toulouse'),
      _TopPick(title: 'Jour 2 : Culture & Science', description: 'Cite de l\'Espace (matin), Fondation Bemberg + Canal du Midi (apres-midi)', mapsQuery: 'Cite de l\'Espace Toulouse'),
      _TopPick(title: 'Jour 3 : Insolite & Nature', description: 'Halles de la Machine (matin), Jardin Japonais, quartier des Carmes', mapsQuery: 'Halle de la Machine Toulouse'),
      _TopPick(title: 'Bonus : Sorties nocturnes', description: 'Bars de la Place Saint-Pierre, concerts au Bikini ou Zenith', tip: 'Saint-Pierre est LE quartier de la nuit a Toulouse', mapsQuery: 'Place Saint-Pierre Toulouse'),
      _TopPick(title: 'Bonus : Food', description: 'Cassoulet chez Emile, violet de Toulouse, fenetra au dessert', tip: 'Le cassoulet se mange meme en ete a Toulouse', mapsQuery: 'Restaurant Emile Toulouse'),
    ],
  ),
  'paris': _CityTopPicks(
    top10: [
      _TopPick(title: 'Tour Eiffel', description: 'Symbole de Paris, vue panoramique exceptionnelle', tip: 'Reserver en ligne pour eviter 2h de queue', mapsQuery: 'Tour Eiffel Paris'),
      _TopPick(title: 'Musee du Louvre', description: 'Plus grand musee du monde, la Joconde et 35 000 oeuvres', tip: 'Entree gratuite le 1er dimanche du mois (oct-mars)', mapsQuery: 'Musee du Louvre Paris'),
      _TopPick(title: 'Montmartre + Sacre-Coeur', description: 'Village artistique, vue sur tout Paris depuis le parvis', mapsQuery: 'Sacre-Coeur Paris'),
      _TopPick(title: 'Notre-Dame de Paris', description: 'Cathedrale gothique iconique, reouverture apres restauration', mapsQuery: 'Notre-Dame de Paris'),
      _TopPick(title: 'Champs-Elysees + Arc de Triomphe', description: 'La plus belle avenue du monde, montee au sommet de l\'Arc', mapsQuery: 'Arc de Triomphe Paris'),
      _TopPick(title: 'Musee d\'Orsay', description: 'Impressionnistes dans une ancienne gare, Monet, Renoir, Van Gogh', mapsQuery: 'Musee d\'Orsay Paris'),
      _TopPick(title: 'Le Marais', description: 'Quartier historique, boutiques, galeries, Place des Vosges', mapsQuery: 'Le Marais Paris'),
      _TopPick(title: 'Jardin du Luxembourg', description: 'Le plus beau jardin parisien, ambiance paisible', mapsQuery: 'Jardin du Luxembourg Paris'),
      _TopPick(title: 'Saint-Germain-des-Pres', description: 'Quartier litteraire, cafes mythiques (Flore, Deux Magots)', mapsQuery: 'Saint-Germain-des-Pres Paris'),
      _TopPick(title: 'Canal Saint-Martin', description: 'Promenade au bord de l\'eau, ecluses, ambiance boheme', tip: 'Ideal pour un pique-nique le dimanche', mapsQuery: 'Canal Saint-Martin Paris'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Tour Eiffel + Trocadero', description: 'Photo iconique depuis le Trocadero, montee a la Tour', mapsQuery: 'Trocadero Paris'),
      _TopPick(title: 'Midi : Champs-Elysees', description: 'Remontee de l\'avenue jusqu\'a l\'Arc de Triomphe', mapsQuery: 'Champs-Elysees Paris'),
      _TopPick(title: 'Apres-midi : Louvre + Tuileries', description: 'Visite du musee puis promenade dans les jardins', mapsQuery: 'Musee du Louvre Paris'),
      _TopPick(title: 'Soir : Montmartre', description: 'Sacre-Coeur au coucher du soleil, diner Place du Tertre', mapsQuery: 'Montmartre Paris'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Grands monuments', description: 'Tour Eiffel, Champs-Elysees, Arc de Triomphe, Louvre', mapsQuery: 'Tour Eiffel Paris'),
      _TopPick(title: 'Jour 2 : Rive gauche', description: 'Musee d\'Orsay, Saint-Germain, Luxembourg, Pantheon', mapsQuery: 'Musee d\'Orsay Paris'),
      _TopPick(title: 'Jour 3 : Quartiers authentiques', description: 'Montmartre (matin), Le Marais (apres-midi), Canal Saint-Martin (soir)', mapsQuery: 'Montmartre Paris'),
    ],
  ),
  'lyon': _CityTopPicks(
    top10: [
      _TopPick(title: 'Vieux Lyon', description: 'Plus grand quartier Renaissance de France, traboules secretes', tip: 'Visite guidee des traboules gratuite le dimanche', mapsQuery: 'Vieux Lyon'),
      _TopPick(title: 'Basilique de Fourviere', description: 'Vue panoramique sur Lyon, basilique majestueuse', mapsQuery: 'Basilique Fourviere Lyon'),
      _TopPick(title: 'Place Bellecour', description: 'Plus grande place pietonne d\'Europe, coeur de la Presqu\'ile', mapsQuery: 'Place Bellecour Lyon'),
      _TopPick(title: 'Parc de la Tete d\'Or', description: 'Jardin botanique, lac, zoo gratuit, 105 hectares', mapsQuery: 'Parc de la Tete d\'Or Lyon'),
      _TopPick(title: 'Les Halles Paul Bocuse', description: 'Temple de la gastronomie lyonnaise, produits d\'exception', mapsQuery: 'Halles Paul Bocuse Lyon'),
      _TopPick(title: 'Confluences', description: 'Musee d\'architecture futuriste au confluent du Rhone et de la Saone', mapsQuery: 'Musee des Confluences Lyon'),
      _TopPick(title: 'Croix-Rousse', description: 'Quartier des canuts, street art, ambiance village', mapsQuery: 'Croix-Rousse Lyon'),
      _TopPick(title: 'Theatres romains', description: 'Amphitheatres antiques sur la colline de Fourviere', mapsQuery: 'Theatres romains Lyon'),
      _TopPick(title: 'Presqu\'ile', description: 'Shopping, restaurants, architecture Haussmannienne', mapsQuery: 'Presqu\'ile Lyon'),
      _TopPick(title: 'Fresque des Lyonnais', description: 'Mur peint geant avec les celebrites lyonnaises', mapsQuery: 'Fresque des Lyonnais'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Vieux Lyon + Fourviere', description: 'Traboules, cathedrale Saint-Jean, funiculaire jusqu\'a Fourviere', mapsQuery: 'Vieux Lyon'),
      _TopPick(title: 'Dejeuner : Bouchon lyonnais', description: 'Quenelles, tablier de sapeur, cervelle de canut', mapsQuery: 'Bouchon lyonnais Vieux Lyon'),
      _TopPick(title: 'Apres-midi : Presqu\'ile + Bellecour', description: 'Shopping rue de la Republique, Place des Terreaux', mapsQuery: 'Place Bellecour Lyon'),
      _TopPick(title: 'Soir : Berges du Rhone', description: 'Promenade et bars en peniche', mapsQuery: 'Berges du Rhone Lyon'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Vieux Lyon + Fourviere', description: 'Traboules, basilique, theatres romains, bouchon', mapsQuery: 'Vieux Lyon'),
      _TopPick(title: 'Jour 2 : Presqu\'ile + Confluences', description: 'Bellecour, Halles Bocuse, Musee des Confluences', mapsQuery: 'Place Bellecour Lyon'),
      _TopPick(title: 'Jour 3 : Croix-Rousse + Tete d\'Or', description: 'Street art, mur des Canuts, parc et zoo gratuit', mapsQuery: 'Croix-Rousse Lyon'),
    ],
  ),
  'marseille': _CityTopPicks(
    top10: [
      _TopPick(title: 'Vieux-Port', description: 'Coeur historique de Marseille, marche aux poissons', mapsQuery: 'Vieux-Port Marseille'),
      _TopPick(title: 'Notre-Dame de la Garde', description: 'La "Bonne Mere", vue a 360 sur la ville et la mer', mapsQuery: 'Notre-Dame de la Garde Marseille'),
      _TopPick(title: 'Calanques de Marseille', description: 'Criques turquoise entre Marseille et Cassis, randonnee', tip: 'Reservation obligatoire en ete', mapsQuery: 'Calanques Marseille'),
      _TopPick(title: 'MuCEM', description: 'Musee des civilisations au fort Saint-Jean, architecture moderne', mapsQuery: 'MuCEM Marseille'),
      _TopPick(title: 'Le Panier', description: 'Plus vieux quartier de France, street art, ruelles colorees', mapsQuery: 'Le Panier Marseille'),
      _TopPick(title: 'Chateau d\'If', description: 'Forteresse sur une ile, prison du Comte de Monte-Cristo', mapsQuery: 'Chateau d\'If Marseille'),
      _TopPick(title: 'Corniche Kennedy', description: 'Route littorale avec vue mer, plongeoirs, coucher de soleil', mapsQuery: 'Corniche Kennedy Marseille'),
      _TopPick(title: 'La Canebiere', description: 'Avenue mythique de Marseille, du Vieux-Port a la gare', mapsQuery: 'La Canebiere Marseille'),
      _TopPick(title: 'Vallon des Auffes', description: 'Petit port de pecheurs pittoresque, bouillabaisse', mapsQuery: 'Vallon des Auffes Marseille'),
      _TopPick(title: 'Friche la Belle de Mai', description: 'Lieu culturel alternatif, expos, concerts, rooftop', mapsQuery: 'Friche Belle de Mai Marseille'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Vieux-Port + Panier', description: 'Marche aux poissons, ruelles du Panier, street art', mapsQuery: 'Vieux-Port Marseille'),
      _TopPick(title: 'Midi : Bouillabaisse au Vallon', description: 'Dejeuner au Vallon des Auffes face a la mer', mapsQuery: 'Vallon des Auffes Marseille'),
      _TopPick(title: 'Apres-midi : Notre-Dame de la Garde', description: 'Montee a la Bonne Mere, vue panoramique', mapsQuery: 'Notre-Dame de la Garde Marseille'),
      _TopPick(title: 'Soir : Corniche Kennedy', description: 'Coucher de soleil sur la corniche', mapsQuery: 'Corniche Kennedy Marseille'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Centre historique', description: 'Vieux-Port, Panier, MuCEM, Notre-Dame de la Garde', mapsQuery: 'Vieux-Port Marseille'),
      _TopPick(title: 'Jour 2 : Calanques', description: 'Randonnee Sugiton ou Sormiou, baignade eau turquoise', mapsQuery: 'Calanques Marseille'),
      _TopPick(title: 'Jour 3 : Iles + Corniche', description: 'Chateau d\'If, iles du Frioul, Corniche, Vallon des Auffes', mapsQuery: 'Chateau d\'If Marseille'),
    ],
  ),
  'bordeaux': _CityTopPicks(
    top10: [
      _TopPick(title: 'Place de la Bourse + Miroir d\'eau', description: 'Plus grand miroir d\'eau du monde, reflet magique', mapsQuery: 'Place de la Bourse Bordeaux'),
      _TopPick(title: 'Cite du Vin', description: 'Musee immersif sur le vin, architecture spectaculaire', mapsQuery: 'Cite du Vin Bordeaux'),
      _TopPick(title: 'Rue Sainte-Catherine', description: 'Plus longue rue pietonne d\'Europe, shopping', mapsQuery: 'Rue Sainte-Catherine Bordeaux'),
      _TopPick(title: 'Quartier Saint-Pierre', description: 'Vieux Bordeaux, bars, restaurants, ambiance nocturne', mapsQuery: 'Quartier Saint-Pierre Bordeaux'),
      _TopPick(title: 'Grand Theatre', description: 'Chef-d\'oeuvre neo-classique, opera et ballet', mapsQuery: 'Grand Theatre Bordeaux'),
      _TopPick(title: 'Darwin Ecosysteme', description: 'Friche militaire reconvertie, street art, bio, skatepark', mapsQuery: 'Darwin Bordeaux'),
      _TopPick(title: 'Pont de Pierre', description: 'Premier pont de Bordeaux, vue sur les quais', mapsQuery: 'Pont de Pierre Bordeaux'),
      _TopPick(title: 'Jardin Public', description: 'Parc a l\'anglaise, museum d\'histoire naturelle', mapsQuery: 'Jardin Public Bordeaux'),
      _TopPick(title: 'Grosse Cloche', description: 'Beffroi medieval, symbole de la ville', mapsQuery: 'Grosse Cloche Bordeaux'),
      _TopPick(title: 'Les Bassins de Lumieres', description: 'Plus grand centre d\'art numerique au monde, dans une base sous-marine', mapsQuery: 'Bassins de Lumieres Bordeaux'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Centre historique', description: 'Place de la Bourse, miroir d\'eau, Sainte-Catherine', mapsQuery: 'Place de la Bourse Bordeaux'),
      _TopPick(title: 'Dejeuner : Saint-Pierre', description: 'Caneles et entrecote bordelaise dans le vieux quartier', mapsQuery: 'Quartier Saint-Pierre Bordeaux'),
      _TopPick(title: 'Apres-midi : Cite du Vin', description: 'Visite immersive + degustation au belvedere', mapsQuery: 'Cite du Vin Bordeaux'),
      _TopPick(title: 'Soir : Quais + Darwin', description: 'Balade sur les quais, verre a Darwin', mapsQuery: 'Darwin Bordeaux'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Bordeaux classique', description: 'Place de la Bourse, Grand Theatre, Sainte-Catherine, Saint-Pierre', mapsQuery: 'Place de la Bourse Bordeaux'),
      _TopPick(title: 'Jour 2 : Rive droite + Vin', description: 'Darwin, Bassins de Lumieres, Cite du Vin', mapsQuery: 'Darwin Bordeaux'),
      _TopPick(title: 'Jour 3 : Vignobles', description: 'Excursion Saint-Emilion ou Medoc (30 min)', tip: 'Saint-Emilion est classe UNESCO', mapsQuery: 'Saint-Emilion'),
    ],
  ),
  'nice': _CityTopPicks(
    top10: [
      _TopPick(title: 'Promenade des Anglais', description: '7 km de front de mer mythique, chaises bleues', mapsQuery: 'Promenade des Anglais Nice'),
      _TopPick(title: 'Vieux-Nice', description: 'Ruelles colorees, marche du Cours Saleya, socca', mapsQuery: 'Vieux-Nice'),
      _TopPick(title: 'Colline du Chateau', description: 'Vue panoramique sur la Baie des Anges et le port', mapsQuery: 'Colline du Chateau Nice'),
      _TopPick(title: 'Musee Matisse', description: 'Oeuvres du maitre dans une villa genoise', mapsQuery: 'Musee Matisse Nice'),
      _TopPick(title: 'Place Massena', description: 'Place centrale, fontaine du Soleil, statues de Jaume Plensa', mapsQuery: 'Place Massena Nice'),
      _TopPick(title: 'Port Lympia', description: 'Port colore, restaurants, bateaux pour la Corse', mapsQuery: 'Port Lympia Nice'),
      _TopPick(title: 'MAMAC', description: 'Art moderne et contemporain, Klein, Warhol, Niki de Saint Phalle', mapsQuery: 'MAMAC Nice'),
      _TopPick(title: 'Cimiez', description: 'Quartier chic, monastere, arenes romaines, jardins', mapsQuery: 'Cimiez Nice'),
      _TopPick(title: 'Marche du Cours Saleya', description: 'Fleurs, fruits, epices, ambiance provencale', tip: 'Y aller le matin pour les fleurs', mapsQuery: 'Cours Saleya Nice'),
      _TopPick(title: 'Cap de Nice', description: 'Sentier du littoral, criques cachees, eau cristalline', mapsQuery: 'Cap de Nice'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Vieux-Nice + Cours Saleya', description: 'Marche aux fleurs, socca, ruelles', mapsQuery: 'Cours Saleya Nice'),
      _TopPick(title: 'Midi : Colline du Chateau', description: 'Montee a pied ou ascenseur, pique-nique avec vue', mapsQuery: 'Colline du Chateau Nice'),
      _TopPick(title: 'Apres-midi : Promenade des Anglais', description: 'Baignade puis promenade sur la Prom\'', mapsQuery: 'Promenade des Anglais Nice'),
      _TopPick(title: 'Soir : Port Lympia', description: 'Aperitif et diner face aux bateaux', mapsQuery: 'Port Lympia Nice'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Nice centre', description: 'Vieux-Nice, Cours Saleya, Colline du Chateau, Promenade', mapsQuery: 'Vieux-Nice'),
      _TopPick(title: 'Jour 2 : Culture + Cimiez', description: 'MAMAC, Musee Matisse, arenes romaines, jardins', mapsQuery: 'MAMAC Nice'),
      _TopPick(title: 'Jour 3 : Excursion', description: 'Monaco (20 min en train), Eze, ou Cap de Nice a pied', mapsQuery: 'Monaco'),
    ],
  ),
  'nantes': _CityTopPicks(
    top10: [
      _TopPick(title: 'Les Machines de l\'ile', description: 'Grand Elephant mecanique, Carrousel des Mondes Marins', tip: 'Le tour sur l\'Elephant est inoubliable', mapsQuery: 'Machines de l\'ile Nantes'),
      _TopPick(title: 'Chateau des ducs de Bretagne', description: 'Forteresse medievale, musee d\'histoire gratuit', mapsQuery: 'Chateau des ducs de Bretagne Nantes'),
      _TopPick(title: 'Passage Pommeraye', description: 'Galerie commerciale du XIXe siecle, architecture unique', mapsQuery: 'Passage Pommeraye Nantes'),
      _TopPick(title: 'Jardin des Plantes', description: 'Un des plus beaux jardins botaniques de France', mapsQuery: 'Jardin des Plantes Nantes'),
      _TopPick(title: 'Ile de Nantes', description: 'Quartier creatif, street art, Machines de l\'ile', mapsQuery: 'Ile de Nantes'),
      _TopPick(title: 'Cathedrale Saint-Pierre', description: 'Gothique flamboyant, tombeau de Francois II', mapsQuery: 'Cathedrale Saint-Pierre Nantes'),
      _TopPick(title: 'Quartier Bouffay', description: 'Vieux Nantes, rues medievales, bars et creperies', mapsQuery: 'Quartier Bouffay Nantes'),
      _TopPick(title: 'Le Voyage a Nantes', description: 'Parcours artistique dans toute la ville (ligne verte)', mapsQuery: 'Voyage a Nantes'),
      _TopPick(title: 'Trentemoult', description: 'Village de pecheurs colore sur l\'autre rive, navette fluviale', mapsQuery: 'Trentemoult Nantes'),
      _TopPick(title: 'Tour Lu', description: 'Tour iconique de l\'ancienne usine LU, lieu culturel', mapsQuery: 'Lieu Unique Nantes'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Chateau + Bouffay', description: 'Visite du chateau gratuit, ruelles medievales', mapsQuery: 'Chateau des ducs de Bretagne Nantes'),
      _TopPick(title: 'Midi : Passage Pommeraye', description: 'Shopping dans la plus belle galerie de France', mapsQuery: 'Passage Pommeraye Nantes'),
      _TopPick(title: 'Apres-midi : Machines de l\'ile', description: 'L\'Elephant, le Carrousel, l\'Arbre aux Herons', mapsQuery: 'Machines de l\'ile Nantes'),
      _TopPick(title: 'Soir : Trentemoult', description: 'Navette fluviale, aperitif dans le village colore', mapsQuery: 'Trentemoult Nantes'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Centre historique', description: 'Chateau, cathedrale, Bouffay, Passage Pommeraye', mapsQuery: 'Chateau des ducs de Bretagne Nantes'),
      _TopPick(title: 'Jour 2 : Ile de Nantes + Machines', description: 'Elephant, Carrousel, Lieu Unique, street art', mapsQuery: 'Machines de l\'ile Nantes'),
      _TopPick(title: 'Jour 3 : Nature + Trentemoult', description: 'Jardin des Plantes, Erdre en bateau, Trentemoult', mapsQuery: 'Jardin des Plantes Nantes'),
    ],
  ),
  'montpellier': _CityTopPicks(
    top10: [
      _TopPick(title: 'Place de la Comedie', description: 'La place "de l\'Oeuf", coeur vivant de Montpellier', mapsQuery: 'Place de la Comedie Montpellier'),
      _TopPick(title: 'Ecusson', description: 'Centre historique medieval, ruelles pietonnes, hotels particuliers', mapsQuery: 'Ecusson Montpellier'),
      _TopPick(title: 'Promenade du Peyrou', description: 'Arc de triomphe, chateau d\'eau, vue sur les Cevennes', mapsQuery: 'Promenade du Peyrou Montpellier'),
      _TopPick(title: 'Musee Fabre', description: 'Un des plus beaux musees de France, Courbet, Soulages', mapsQuery: 'Musee Fabre Montpellier'),
      _TopPick(title: 'Jardin des Plantes', description: 'Plus vieux jardin botanique de France (1593)', mapsQuery: 'Jardin des Plantes Montpellier'),
      _TopPick(title: 'Cathedrale Saint-Pierre', description: 'Impressionnante cathedrale gothique avec son porche fortifie', mapsQuery: 'Cathedrale Saint-Pierre Montpellier'),
      _TopPick(title: 'Quartier Antigone', description: 'Architecture neo-classique de Ricardo Bofill', mapsQuery: 'Antigone Montpellier'),
      _TopPick(title: 'Plage du Petit Travers', description: 'Plus belle plage de Montpellier, sable fin', tip: 'A 15 min en tram + velo', mapsQuery: 'Plage Petit Travers Montpellier'),
      _TopPick(title: 'Les Arceaux', description: 'Aqueduc Saint-Clement, marche bio le samedi', mapsQuery: 'Les Arceaux Montpellier'),
      _TopPick(title: 'Street art du quartier Gambetta', description: 'Fresques murales et galeries contemporaines', mapsQuery: 'Quartier Gambetta Montpellier'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Ecusson + Peyrou', description: 'Ruelles medievales, Arc de triomphe, vue panoramique', mapsQuery: 'Ecusson Montpellier'),
      _TopPick(title: 'Dejeuner : Place Jean-Jaures', description: 'Terrasses et restaurants autour de la place', mapsQuery: 'Place Jean-Jaures Montpellier'),
      _TopPick(title: 'Apres-midi : Musee Fabre + Comedie', description: 'Collection exceptionnelle puis cafe en terrasse', mapsQuery: 'Musee Fabre Montpellier'),
      _TopPick(title: 'Soir : Quartier Sainte-Anne', description: 'Bars et restaurants animes', mapsQuery: 'Place Sainte-Anne Montpellier'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Centre historique', description: 'Ecusson, Peyrou, Comedie, Musee Fabre', mapsQuery: 'Place de la Comedie Montpellier'),
      _TopPick(title: 'Jour 2 : Mer + Nature', description: 'Plage du Petit Travers, Palavas, etang de Thau', mapsQuery: 'Plage Petit Travers Montpellier'),
      _TopPick(title: 'Jour 3 : Antigone + Arceaux', description: 'Architecture Bofill, marche bio, Jardin des Plantes', mapsQuery: 'Antigone Montpellier'),
    ],
  ),
  'strasbourg': _CityTopPicks(
    top10: [
      _TopPick(title: 'Cathedrale Notre-Dame', description: 'Chef-d\'oeuvre gothique, horloge astronomique, plateforme panoramique', mapsQuery: 'Cathedrale Strasbourg'),
      _TopPick(title: 'Petite France', description: 'Quartier pittoresque, maisons a colombages sur l\'eau', mapsQuery: 'Petite France Strasbourg'),
      _TopPick(title: 'Parlement europeen', description: 'Siege du Parlement de l\'UE, visites gratuites', mapsQuery: 'Parlement europeen Strasbourg'),
      _TopPick(title: 'Ponts Couverts', description: 'Tours medievales et ponts sur l\'Ill', mapsQuery: 'Ponts Couverts Strasbourg'),
      _TopPick(title: 'Barrage Vauban', description: 'Terrasse panoramique gratuite sur les toits', mapsQuery: 'Barrage Vauban Strasbourg'),
      _TopPick(title: 'Musee alsacien', description: 'Vie traditionnelle alsacienne dans une maison a colombages', mapsQuery: 'Musee alsacien Strasbourg'),
      _TopPick(title: 'Parc de l\'Orangerie', description: 'Plus vieux parc de la ville, cigognes, lac', mapsQuery: 'Parc de l\'Orangerie Strasbourg'),
      _TopPick(title: 'Place Kleber', description: 'Place centrale, sapin de Noel geant en decembre', mapsQuery: 'Place Kleber Strasbourg'),
      _TopPick(title: 'Quartier de la Krutenau', description: 'Quartier etudiant anime, bars, terrasses', mapsQuery: 'Krutenau Strasbourg'),
      _TopPick(title: 'Marche de Noel', description: 'Le plus ancien et celebre marche de Noel de France', tip: 'De fin novembre a fin decembre', mapsQuery: 'Marche de Noel Strasbourg'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Cathedrale + Grande Ile', description: 'Montee a la plateforme, horloge astronomique a 12h30', mapsQuery: 'Cathedrale Strasbourg'),
      _TopPick(title: 'Dejeuner : Winstub', description: 'Choucroute, tarte flambee, biere locale', mapsQuery: 'Petite France Strasbourg'),
      _TopPick(title: 'Apres-midi : Petite France', description: 'Balade dans les ruelles, Ponts Couverts, Barrage Vauban', mapsQuery: 'Petite France Strasbourg'),
      _TopPick(title: 'Soir : Krutenau', description: 'Bars a bieres et terrasses animees', mapsQuery: 'Krutenau Strasbourg'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Grande Ile', description: 'Cathedrale, Petite France, Ponts Couverts, Barrage Vauban', mapsQuery: 'Cathedrale Strasbourg'),
      _TopPick(title: 'Jour 2 : Europe + Musees', description: 'Parlement, Orangerie, Musee alsacien, Musee d\'Art Moderne', mapsQuery: 'Parlement europeen Strasbourg'),
      _TopPick(title: 'Jour 3 : Route des vins', description: 'Obernai, Riquewihr, Colmar (1h de train)', tip: 'La route des vins d\'Alsace est magique en automne', mapsQuery: 'Route des vins Alsace'),
    ],
  ),
  'lille': _CityTopPicks(
    top10: [
      _TopPick(title: 'Grand\'Place', description: 'Coeur de Lille, architecture flamande, terrasses', mapsQuery: 'Grand Place Lille'),
      _TopPick(title: 'Vieux-Lille', description: 'Ruelles pavees, maisons flamandes, boutiques', mapsQuery: 'Vieux-Lille'),
      _TopPick(title: 'Palais des Beaux-Arts', description: '2e musee de France apres le Louvre, collection exceptionnelle', mapsQuery: 'Palais des Beaux-Arts Lille'),
      _TopPick(title: 'Citadelle de Lille', description: 'Forteresse Vauban, parc et zoo gratuit', mapsQuery: 'Citadelle Lille'),
      _TopPick(title: 'Marche de Wazemmes', description: 'Plus grand marche du nord, multiculturel et festif', tip: 'Le dimanche matin c\'est une institution', mapsQuery: 'Marche de Wazemmes Lille'),
      _TopPick(title: 'Rue de Bethune', description: 'Rue commercante principale, pietonne', mapsQuery: 'Rue de Bethune Lille'),
      _TopPick(title: 'Beffroi de l\'Hotel de Ville', description: 'Vue a 104m, classe UNESCO', mapsQuery: 'Beffroi Lille'),
      _TopPick(title: 'La Piscine de Roubaix', description: 'Musee d\'art dans une ancienne piscine Art Deco', tip: 'A 15 min en metro', mapsQuery: 'La Piscine Roubaix'),
      _TopPick(title: 'Quartier Solferino', description: 'Bars, restaurants, vie nocturne lilloise', mapsQuery: 'Solferino Lille'),
      _TopPick(title: 'Braderie de Lille', description: 'Plus grande brocante d\'Europe, 1er week-end de septembre', tip: 'Moules-frites obligatoires pendant la Braderie', mapsQuery: 'Braderie Lille'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Vieux-Lille + Grand\'Place', description: 'Ruelles flamandes, architecture, gaufres', mapsQuery: 'Grand Place Lille'),
      _TopPick(title: 'Dejeuner : Welsh ou Carbonade', description: 'Specialites du Nord dans une estaminet', mapsQuery: 'Vieux-Lille'),
      _TopPick(title: 'Apres-midi : Palais des Beaux-Arts', description: 'Collection de Rubens, Delacroix, Monet', mapsQuery: 'Palais des Beaux-Arts Lille'),
      _TopPick(title: 'Soir : Solferino', description: 'Bieres du Nord et ambiance chaleureuse', mapsQuery: 'Solferino Lille'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Lille centre', description: 'Grand\'Place, Vieux-Lille, Palais des Beaux-Arts', mapsQuery: 'Grand Place Lille'),
      _TopPick(title: 'Jour 2 : Citadelle + Wazemmes', description: 'Parc de la Citadelle, marche de Wazemmes, beffroi', mapsQuery: 'Citadelle Lille'),
      _TopPick(title: 'Jour 3 : Roubaix + Belgique', description: 'La Piscine le matin, Bruges ou Gand l\'apres-midi (30 min)', mapsQuery: 'La Piscine Roubaix'),
    ],
  ),
  'rennes': _CityTopPicks(
    top10: [
      _TopPick(title: 'Parlement de Bretagne', description: 'Palais du XVIIe, plafonds peints, visites guidees', mapsQuery: 'Parlement de Bretagne Rennes'),
      _TopPick(title: 'Place des Lices', description: 'Marche du samedi matin, le 2e de France', mapsQuery: 'Place des Lices Rennes'),
      _TopPick(title: 'Rue Saint-Michel', description: 'La "rue de la Soif", bars et ambiance etudiante', mapsQuery: 'Rue Saint-Michel Rennes'),
      _TopPick(title: 'Parc du Thabor', description: 'Jardin a la francaise et a l\'anglaise, roseraie', mapsQuery: 'Parc du Thabor Rennes'),
      _TopPick(title: 'Les Champs Libres', description: 'Musee de Bretagne, planetarium, bibliotheque', mapsQuery: 'Les Champs Libres Rennes'),
      _TopPick(title: 'Centre historique', description: 'Maisons a pans de bois, ruelles medievales colorees', mapsQuery: 'Centre historique Rennes'),
      _TopPick(title: 'Portes Mordelaises', description: 'Vestiges des remparts medievaux', mapsQuery: 'Portes Mordelaises Rennes'),
      _TopPick(title: 'Marche des Lices', description: 'Huitres, crepes, cidre, produits bretons', tip: 'Y aller tot le samedi', mapsQuery: 'Marche des Lices Rennes'),
      _TopPick(title: 'Opera de Rennes', description: 'Opera a l\'italienne du XIXe siecle', mapsQuery: 'Opera de Rennes'),
      _TopPick(title: 'Rue Saint-Georges', description: 'Plus belle rue de Rennes, colombages et creperies', mapsQuery: 'Rue Saint-Georges Rennes'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Centre + Lices', description: 'Maisons a colombages, marche (si samedi), Parlement', mapsQuery: 'Place des Lices Rennes'),
      _TopPick(title: 'Dejeuner : Galette-saucisse', description: 'La specialite rennaise dans une creperie', mapsQuery: 'Rue Saint-Georges Rennes'),
      _TopPick(title: 'Apres-midi : Thabor + Champs Libres', description: 'Parc magnifique puis musee de Bretagne', mapsQuery: 'Parc du Thabor Rennes'),
      _TopPick(title: 'Soir : Rue de la Soif', description: 'Ambiance etudiante garantie', mapsQuery: 'Rue Saint-Michel Rennes'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Rennes historique', description: 'Parlement, Lices, colombages, Portes Mordelaises', mapsQuery: 'Parlement de Bretagne Rennes'),
      _TopPick(title: 'Jour 2 : Culture + Nature', description: 'Champs Libres, Thabor, Opera, Rue Saint-Georges', mapsQuery: 'Les Champs Libres Rennes'),
      _TopPick(title: 'Jour 3 : Excursion', description: 'Mont Saint-Michel (1h) ou Saint-Malo (1h)', tip: 'Le Mont Saint-Michel est a maree haute le matin', mapsQuery: 'Mont Saint-Michel'),
    ],
  ),
  'grenoble': _CityTopPicks(
    top10: [
      _TopPick(title: 'Bastille + Telepherique', description: 'Fort en hauteur, vue sur les Alpes, telepherique mythique', mapsQuery: 'Bastille Grenoble'),
      _TopPick(title: 'Musee de Grenoble', description: 'Collection d\'art moderne exceptionnelle, Matisse, Picasso', mapsQuery: 'Musee de Grenoble'),
      _TopPick(title: 'Place Grenette', description: 'Place centrale animee, terrasses de cafes', mapsQuery: 'Place Grenette Grenoble'),
      _TopPick(title: 'Quartier Saint-Laurent', description: 'Rive droite de l\'Isere, street art, bars', mapsQuery: 'Quartier Saint-Laurent Grenoble'),
      _TopPick(title: 'Parc Paul Mistral', description: 'Grand parc central, Tour Perret, stade', mapsQuery: 'Parc Paul Mistral Grenoble'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Bastille en telepherique', description: 'Vue a 360 sur Grenoble et les Alpes', mapsQuery: 'Bastille Grenoble'),
      _TopPick(title: 'Apres-midi : Vieille ville + Musee', description: 'Place Grenette, musee, ruelles', mapsQuery: 'Place Grenette Grenoble'),
      _TopPick(title: 'Soir : Saint-Laurent', description: 'Bars et restaurants rive droite', mapsQuery: 'Quartier Saint-Laurent Grenoble'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Grenoble', description: 'Bastille, vieille ville, musee, Saint-Laurent', mapsQuery: 'Bastille Grenoble'),
      _TopPick(title: 'Jour 2 : Chartreuse ou Vercors', description: 'Randonnee en montagne a 30 min', mapsQuery: 'Parc de la Chartreuse'),
      _TopPick(title: 'Jour 3 : Lacs', description: 'Lac du Crozet ou lac d\'Annecy (1h)', mapsQuery: 'Lac d\'Annecy'),
    ],
  ),
  'aix-en-provence': _CityTopPicks(
    top10: [
      _TopPick(title: 'Cours Mirabeau', description: 'Avenue mythique bordee de platanes, fontaines, terrasses', mapsQuery: 'Cours Mirabeau Aix-en-Provence'),
      _TopPick(title: 'Atelier Cezanne', description: 'L\'atelier du peintre conserve tel quel', mapsQuery: 'Atelier Cezanne Aix-en-Provence'),
      _TopPick(title: 'Montagne Sainte-Victoire', description: 'Le sujet prefere de Cezanne, randonnees', mapsQuery: 'Montagne Sainte-Victoire'),
      _TopPick(title: 'Vieil Aix', description: 'Ruelles, places, fontaines, hotels particuliers', mapsQuery: 'Vieil Aix-en-Provence'),
      _TopPick(title: 'Marche aux fleurs', description: 'Place de l\'Hotel de Ville, mardi jeudi samedi', mapsQuery: 'Place Hotel de Ville Aix-en-Provence'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Cours Mirabeau + Vieil Aix', description: 'Cafe aux Deux Garcons, fontaines, ruelles', mapsQuery: 'Cours Mirabeau Aix-en-Provence'),
      _TopPick(title: 'Apres-midi : Atelier Cezanne', description: 'Visite de l\'atelier puis vue sur Sainte-Victoire', mapsQuery: 'Atelier Cezanne Aix-en-Provence'),
      _TopPick(title: 'Soir : Place des Cardeurs', description: 'Terrasses animees dans le vieil Aix', mapsQuery: 'Place des Cardeurs Aix-en-Provence'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Aix classique', description: 'Cours Mirabeau, vieil Aix, Atelier Cezanne', mapsQuery: 'Cours Mirabeau Aix-en-Provence'),
      _TopPick(title: 'Jour 2 : Sainte-Victoire', description: 'Randonnee au sommet ou balade au pied', mapsQuery: 'Montagne Sainte-Victoire'),
      _TopPick(title: 'Jour 3 : Luberon', description: 'Villages perches : Gordes, Roussillon, Bonnieux', mapsQuery: 'Gordes Luberon'),
    ],
  ),
  'angers': _CityTopPicks(
    top10: [
      _TopPick(title: 'Chateau d\'Angers', description: 'Forteresse medievale, tapisserie de l\'Apocalypse', mapsQuery: 'Chateau d\'Angers'),
      _TopPick(title: 'Terra Botanica', description: 'Parc a theme vegetal unique en Europe', mapsQuery: 'Terra Botanica Angers'),
      _TopPick(title: 'Cathedrale Saint-Maurice', description: 'Style gothique Plantagenet, vitraux', mapsQuery: 'Cathedrale Saint-Maurice Angers'),
      _TopPick(title: 'Jardin des Plantes', description: 'Jardin anglais au coeur de la ville', mapsQuery: 'Jardin des Plantes Angers'),
      _TopPick(title: 'Rue Saint-Aubin', description: 'Maisons a pans de bois, restaurants', mapsQuery: 'Rue Saint-Aubin Angers'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Chateau', description: 'Tapisserie de l\'Apocalypse, remparts', mapsQuery: 'Chateau d\'Angers'),
      _TopPick(title: 'Apres-midi : Centre + Maine', description: 'Cathedrale, ruelles, bords de Maine', mapsQuery: 'Cathedrale Saint-Maurice Angers'),
      _TopPick(title: 'Soir : Place du Ralliement', description: 'Terrasses et restaurants', mapsQuery: 'Place du Ralliement Angers'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Angers historique', description: 'Chateau, cathedrale, vieille ville', mapsQuery: 'Chateau d\'Angers'),
      _TopPick(title: 'Jour 2 : Terra Botanica', description: 'Journee complete au parc vegetal', mapsQuery: 'Terra Botanica Angers'),
      _TopPick(title: 'Jour 3 : Chateaux de la Loire', description: 'Saumur, Villandry ou Breze (30 min)', mapsQuery: 'Chateau de Saumur'),
    ],
  ),
  'reims': _CityTopPicks(
    top10: [
      _TopPick(title: 'Cathedrale Notre-Dame', description: 'Cathedrale du sacre des rois de France, vitraux de Chagall', mapsQuery: 'Cathedrale de Reims'),
      _TopPick(title: 'Caves de champagne', description: 'Visite des grandes maisons : Taittinger, Veuve Clicquot, Pommery', tip: 'Reserver a l\'avance', mapsQuery: 'Caves Champagne Reims'),
      _TopPick(title: 'Palais du Tau', description: 'Ancien palais des archeveques, tresor de la cathedrale', mapsQuery: 'Palais du Tau Reims'),
      _TopPick(title: 'Place Drouet-d\'Erlon', description: 'Artere principale, terrasses, fontaine', mapsQuery: 'Place Drouet-d\'Erlon Reims'),
      _TopPick(title: 'Basilique Saint-Remi', description: 'Eglise romane du XIe, tombeau de Saint Remi', mapsQuery: 'Basilique Saint-Remi Reims'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Cathedrale + Palais du Tau', description: 'Sacre des rois, vitraux de Chagall', mapsQuery: 'Cathedrale de Reims'),
      _TopPick(title: 'Apres-midi : Caves de champagne', description: 'Visite + degustation chez Taittinger ou Pommery', mapsQuery: 'Caves Champagne Reims'),
      _TopPick(title: 'Soir : Place Drouet-d\'Erlon', description: 'Diner et champagne en terrasse', mapsQuery: 'Place Drouet-d\'Erlon Reims'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Reims monumental', description: 'Cathedrale, Palais du Tau, Saint-Remi', mapsQuery: 'Cathedrale de Reims'),
      _TopPick(title: 'Jour 2 : Champagne', description: 'Caves le matin, route du champagne l\'apres-midi', mapsQuery: 'Caves Champagne Reims'),
      _TopPick(title: 'Jour 3 : Epernay', description: 'Avenue de Champagne, la plus riche avenue du monde', tip: 'Moët & Chandon, Perrier-Jouet, Dom Perignon', mapsQuery: 'Avenue de Champagne Epernay'),
    ],
  ),
  'dijon': _CityTopPicks(
    top10: [
      _TopPick(title: 'Palais des Ducs', description: 'Ancien palais ducal, musee des Beaux-Arts gratuit', mapsQuery: 'Palais des Ducs Dijon'),
      _TopPick(title: 'Parcours de la Chouette', description: '22 etapes dans le vieux Dijon, suivre les fleches', mapsQuery: 'Parcours de la Chouette Dijon'),
      _TopPick(title: 'Rue des Forges', description: 'Hotels particuliers, architecture Renaissance', mapsQuery: 'Rue des Forges Dijon'),
      _TopPick(title: 'Halles de Dijon', description: 'Marche couvert par Eiffel, produits bourguignons', mapsQuery: 'Halles de Dijon'),
      _TopPick(title: 'Moutarderie Fallot', description: 'Derniere moutarderie artisanale de Bourgogne', mapsQuery: 'Moutarderie Fallot Dijon'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Parcours de la Chouette', description: '22 etapes a travers la vieille ville', mapsQuery: 'Parcours de la Chouette Dijon'),
      _TopPick(title: 'Midi : Halles + Moutarde', description: 'Degustation aux Halles, Moutarderie Fallot', mapsQuery: 'Halles de Dijon'),
      _TopPick(title: 'Apres-midi : Palais des Ducs', description: 'Musee gratuit, tour Philippe le Bon', mapsQuery: 'Palais des Ducs Dijon'),
      _TopPick(title: 'Soir : Place de la Liberation', description: 'Aperitif kir (vin blanc + creme de cassis)', mapsQuery: 'Place de la Liberation Dijon'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Dijon', description: 'Parcours Chouette, Palais des Ducs, Halles, Fallot', mapsQuery: 'Palais des Ducs Dijon'),
      _TopPick(title: 'Jour 2 : Route des Grands Crus', description: 'Gevrey-Chambertin, Vougeot, Nuits-Saint-Georges', mapsQuery: 'Route des Grands Crus Bourgogne'),
      _TopPick(title: 'Jour 3 : Beaune', description: 'Hospices de Beaune, degustation dans les caves', tip: 'Les Hospices sont un bijou architectural', mapsQuery: 'Hospices de Beaune'),
    ],
  ),
  'brest': _CityTopPicks(
    top10: [
      _TopPick(title: 'Oceanopolis', description: 'Aquarium geant, 3 pavillons : tropical, polaire, tempere', mapsQuery: 'Oceanopolis Brest'),
      _TopPick(title: 'Chateau de Brest', description: 'Plus vieille forteresse du monde encore en activite, musee de la Marine', mapsQuery: 'Chateau de Brest'),
      _TopPick(title: 'Rue de Siam', description: 'Artere principale, tramway, commerces', mapsQuery: 'Rue de Siam Brest'),
      _TopPick(title: 'Port de Brest', description: 'Rade de Brest, bases nautiques', mapsQuery: 'Port de Brest'),
      _TopPick(title: 'Jardin du Conservatoire botanique', description: 'Plantes rares du bout du monde', mapsQuery: 'Conservatoire botanique Brest'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Oceanopolis', description: 'Requins, manchots, coraux', mapsQuery: 'Oceanopolis Brest'),
      _TopPick(title: 'Apres-midi : Chateau + Rue de Siam', description: 'Musee de la Marine, balade en centre-ville', mapsQuery: 'Chateau de Brest'),
      _TopPick(title: 'Soir : Port', description: 'Fruits de mer face a la rade', mapsQuery: 'Port de Brest'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Brest', description: 'Oceanopolis, chateau, Rue de Siam', mapsQuery: 'Oceanopolis Brest'),
      _TopPick(title: 'Jour 2 : Presqu\'ile de Crozon', description: 'Pointe de Pen-Hir, plages sauvages', mapsQuery: 'Presqu\'ile de Crozon'),
      _TopPick(title: 'Jour 3 : Abers', description: 'Cote des Legendes, phares, ile Vierge', mapsQuery: 'Aber Wrach Finistere'),
    ],
  ),
  'le havre': _CityTopPicks(
    top10: [
      _TopPick(title: 'Eglise Saint-Joseph', description: 'Tour lanterne de 107m par Perret, classee UNESCO', mapsQuery: 'Eglise Saint-Joseph Le Havre'),
      _TopPick(title: 'MuMa', description: 'Musee Malraux, plus grande collection impressionniste apres Orsay', mapsQuery: 'MuMa Le Havre'),
      _TopPick(title: 'Plage du Havre', description: 'Front de mer, cabanes, coucher de soleil', mapsQuery: 'Plage Le Havre'),
      _TopPick(title: 'Appartement temoin Perret', description: 'Reconstitution d\'un appartement des annees 50', mapsQuery: 'Appartement temoin Perret Le Havre'),
      _TopPick(title: 'Les Jardins Suspendus', description: 'Jardin botanique dans un ancien fort militaire', mapsQuery: 'Jardins Suspendus Le Havre'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Centre Perret + Saint-Joseph', description: 'Architecture UNESCO, appartement temoin', mapsQuery: 'Eglise Saint-Joseph Le Havre'),
      _TopPick(title: 'Apres-midi : MuMa + Plage', description: 'Impressionnistes puis balade front de mer', mapsQuery: 'MuMa Le Havre'),
      _TopPick(title: 'Soir : Quartier Saint-Francois', description: 'Fruits de mer et restaurants de poisson', mapsQuery: 'Quartier Saint-Francois Le Havre'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Le Havre', description: 'Perret, Saint-Joseph, MuMa, plage', mapsQuery: 'Eglise Saint-Joseph Le Havre'),
      _TopPick(title: 'Jour 2 : Etretat', description: 'Falaises mythiques, jardin d\'Etretat (30 min)', mapsQuery: 'Etretat'),
      _TopPick(title: 'Jour 3 : Honfleur', description: 'Port pittoresque, Vieux Bassin (20 min)', mapsQuery: 'Honfleur'),
    ],
  ),
  'le mans': _CityTopPicks(
    top10: [
      _TopPick(title: 'Cite Plantagenet', description: 'Vieille ville medievale, maisons a pans de bois', mapsQuery: 'Cite Plantagenet Le Mans'),
      _TopPick(title: 'Cathedrale Saint-Julien', description: 'Mix roman et gothique, vitraux exceptionnels', mapsQuery: 'Cathedrale Saint-Julien Le Mans'),
      _TopPick(title: 'Circuit des 24 Heures', description: 'Musee automobile, circuit mythique', mapsQuery: 'Circuit 24 Heures Le Mans'),
      _TopPick(title: 'Muraille gallo-romaine', description: 'Enceinte du IIIe siecle, la mieux conservee de France', mapsQuery: 'Muraille romaine Le Mans'),
      _TopPick(title: 'La Nuit des Chimeres', description: 'Projections nocturnes sur les monuments (ete)', mapsQuery: 'Nuit des Chimeres Le Mans'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Cite Plantagenet', description: 'Vieille ville, cathedrale, muraille romaine', mapsQuery: 'Cite Plantagenet Le Mans'),
      _TopPick(title: 'Apres-midi : Circuit 24h', description: 'Musee automobile, simulateurs', mapsQuery: 'Circuit 24 Heures Le Mans'),
      _TopPick(title: 'Soir : Chimeres (en ete)', description: 'Projections lumineuses sur les facades', mapsQuery: 'Cite Plantagenet Le Mans'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Le Mans historique', description: 'Cite Plantagenet, cathedrale, muraille', mapsQuery: 'Cite Plantagenet Le Mans'),
      _TopPick(title: 'Jour 2 : Automobile', description: 'Circuit des 24h, musee, karting', mapsQuery: 'Circuit 24 Heures Le Mans'),
      _TopPick(title: 'Jour 3 : Chateaux de la Loire', description: 'Chambord ou Chenonceau (1h30)', mapsQuery: 'Chateau de Chambord'),
    ],
  ),
  'toulon': _CityTopPicks(
    top10: [
      _TopPick(title: 'Mont Faron', description: 'Telepherique, vue sur la rade, zoo', mapsQuery: 'Mont Faron Toulon'),
      _TopPick(title: 'Rade de Toulon', description: 'Plus belle rade d\'Europe, base navale', mapsQuery: 'Rade de Toulon'),
      _TopPick(title: 'Marche du Cours Lafayette', description: 'Marche provencal quotidien, couleurs et senteurs', mapsQuery: 'Cours Lafayette Toulon'),
      _TopPick(title: 'Musee national de la Marine', description: 'Histoire navale dans l\'ancien arsenal', mapsQuery: 'Musee Marine Toulon'),
      _TopPick(title: 'Plages du Mourillon', description: 'Criques amenagees, eau turquoise en ville', mapsQuery: 'Plages du Mourillon Toulon'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Mont Faron', description: 'Telepherique + vue panoramique', mapsQuery: 'Mont Faron Toulon'),
      _TopPick(title: 'Midi : Cours Lafayette', description: 'Marche provencal, socca, olives', mapsQuery: 'Cours Lafayette Toulon'),
      _TopPick(title: 'Apres-midi : Mourillon', description: 'Baignade et farniente', mapsQuery: 'Plages du Mourillon Toulon'),
      _TopPick(title: 'Soir : Vieux-Port', description: 'Restaurants de poisson face aux bateaux', mapsQuery: 'Vieux-Port Toulon'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Toulon', description: 'Mont Faron, marche, Mourillon, musee Marine', mapsQuery: 'Mont Faron Toulon'),
      _TopPick(title: 'Jour 2 : Iles d\'Hyeres', description: 'Porquerolles ou Port-Cros en bateau', mapsQuery: 'Ile de Porquerolles'),
      _TopPick(title: 'Jour 3 : Bandol + Cassis', description: 'Vignobles, calanques, villages de la cote', mapsQuery: 'Cassis'),
    ],
  ),
  'nimes': _CityTopPicks(
    top10: [
      _TopPick(title: 'Arenes de Nimes', description: 'Amphitheatre romain le mieux conserve au monde', mapsQuery: 'Arenes de Nimes'),
      _TopPick(title: 'Maison Carree', description: 'Temple romain du Ier siecle, parfaitement conserve', mapsQuery: 'Maison Carree Nimes'),
      _TopPick(title: 'Jardins de la Fontaine', description: 'Premier jardin public de France, Temple de Diane', mapsQuery: 'Jardins de la Fontaine Nimes'),
      _TopPick(title: 'Tour Magne', description: 'Tour gallo-romaine, vue sur la ville et les Cevennes', mapsQuery: 'Tour Magne Nimes'),
      _TopPick(title: 'Musee de la Romanite', description: 'Musee ultra-moderne face aux Arenes', mapsQuery: 'Musee de la Romanite Nimes'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Arenes + Maison Carree', description: 'Les 2 joyaux romains de Nimes', mapsQuery: 'Arenes de Nimes'),
      _TopPick(title: 'Apres-midi : Jardins de la Fontaine', description: 'Temple de Diane, Tour Magne en montant', mapsQuery: 'Jardins de la Fontaine Nimes'),
      _TopPick(title: 'Soir : Place aux Herbes', description: 'Terrasses et brandade de morue', mapsQuery: 'Place aux Herbes Nimes'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Nimes romaine', description: 'Arenes, Maison Carree, Romanite, Jardins', mapsQuery: 'Arenes de Nimes'),
      _TopPick(title: 'Jour 2 : Pont du Gard', description: 'Aqueduc romain spectaculaire (30 min)', mapsQuery: 'Pont du Gard'),
      _TopPick(title: 'Jour 3 : Camargue', description: 'Flamants roses, chevaux blancs, Saintes-Maries-de-la-Mer', mapsQuery: 'Camargue'),
    ],
  ),
  'clermont-ferrand': _CityTopPicks(
    top10: [
      _TopPick(title: 'Cathedrale Notre-Dame', description: 'Cathedrale en pierre de Volvic noire, unique en France', mapsQuery: 'Cathedrale Clermont-Ferrand'),
      _TopPick(title: 'Puy de Dome', description: 'Volcan emblematique, vue sur la chaine des Puys UNESCO', tip: 'Panoramique des Domes (train a cremaillere)', mapsQuery: 'Puy de Dome'),
      _TopPick(title: 'Vulcania', description: 'Parc a theme volcanique, attractions et science', mapsQuery: 'Vulcania'),
      _TopPick(title: 'Place de Jaude', description: 'Place centrale, statue de Vercingetorix', mapsQuery: 'Place de Jaude Clermont-Ferrand'),
      _TopPick(title: 'Basilique Notre-Dame du Port', description: 'Joyau roman classe UNESCO', mapsQuery: 'Basilique Notre-Dame du Port Clermont-Ferrand'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Vieille ville noire', description: 'Cathedrale, basilique, ruelles en pierre de lave', mapsQuery: 'Cathedrale Clermont-Ferrand'),
      _TopPick(title: 'Apres-midi : Puy de Dome', description: 'Train a cremaillere + vue 360 sur les volcans', mapsQuery: 'Puy de Dome'),
      _TopPick(title: 'Soir : Place de Jaude', description: 'Terrasses et truffade auvergnate', mapsQuery: 'Place de Jaude Clermont-Ferrand'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Clermont', description: 'Cathedrale noire, basilique, vieille ville', mapsQuery: 'Cathedrale Clermont-Ferrand'),
      _TopPick(title: 'Jour 2 : Volcans', description: 'Puy de Dome + Vulcania', mapsQuery: 'Puy de Dome'),
      _TopPick(title: 'Jour 3 : Lacs d\'Auvergne', description: 'Lac Pavin, Super-Besse, fromages AOP', mapsQuery: 'Lac Pavin Auvergne'),
    ],
  ),
  'saint-etienne': _CityTopPicks(
    top10: [
      _TopPick(title: 'Cite du Design', description: 'Capitale du design, expos et biennale', mapsQuery: 'Cite du Design Saint-Etienne'),
      _TopPick(title: 'Musee d\'Art Moderne', description: '2e collection d\'art moderne en France apres Paris', mapsQuery: 'Musee d\'Art Moderne Saint-Etienne'),
      _TopPick(title: 'Stade Geoffroy-Guichard', description: 'Le Chaudron, temple du football francais', mapsQuery: 'Stade Geoffroy-Guichard Saint-Etienne'),
      _TopPick(title: 'Pilat', description: 'Parc naturel aux portes de la ville, randonnees', mapsQuery: 'Parc du Pilat'),
      _TopPick(title: 'Place Jean Jaures', description: 'Place centrale, marche, terrasses', mapsQuery: 'Place Jean Jaures Saint-Etienne'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Cite du Design + Musee', description: 'Design et art moderne', mapsQuery: 'Cite du Design Saint-Etienne'),
      _TopPick(title: 'Apres-midi : Centre + Chaudron', description: 'Vieille ville, visite du stade', mapsQuery: 'Stade Geoffroy-Guichard Saint-Etienne'),
      _TopPick(title: 'Soir : Place Jean Jaures', description: 'Restaurants et bars du centre', mapsQuery: 'Place Jean Jaures Saint-Etienne'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Saint-Etienne', description: 'Cite du Design, Musee d\'Art Moderne, Chaudron', mapsQuery: 'Cite du Design Saint-Etienne'),
      _TopPick(title: 'Jour 2 : Pilat', description: 'Randonnee, Cret de l\'Oeillon, via ferrata', mapsQuery: 'Parc du Pilat'),
      _TopPick(title: 'Jour 3 : Lyon', description: 'A 50 min en TER, Vieux Lyon et Fourviere', mapsQuery: 'Vieux Lyon'),
    ],
  ),
  'avignon': _CityTopPicks(
    top10: [
      _TopPick(title: 'Palais des Papes', description: 'Plus grand palais gothique du monde, residence papale au XIVe', mapsQuery: 'Palais des Papes Avignon'),
      _TopPick(title: 'Pont d\'Avignon', description: 'Le celebre pont Saint-Benezet, symbole de la ville', mapsQuery: 'Pont d\'Avignon'),
      _TopPick(title: 'Rocher des Doms', description: 'Jardin panoramique au-dessus du Rhone, vue sur le Mont Ventoux', mapsQuery: 'Rocher des Doms Avignon'),
      _TopPick(title: 'Remparts', description: '4,3 km de remparts medievaux parfaitement conserves', mapsQuery: 'Remparts Avignon'),
      _TopPick(title: 'Place de l\'Horloge', description: 'Place centrale, terrasses, Hotel de Ville, Opera', mapsQuery: 'Place de l\'Horloge Avignon'),
      _TopPick(title: 'Festival d\'Avignon', description: 'Plus grand festival de theatre au monde (juillet)', tip: 'Le OFF est aussi bien que le IN', mapsQuery: 'Festival d\'Avignon'),
      _TopPick(title: 'Rue des Teinturiers', description: 'Ruelles pavees, roues a aubes, bars bohemes', mapsQuery: 'Rue des Teinturiers Avignon'),
      _TopPick(title: 'Musee du Petit Palais', description: 'Peintures italiennes et provencales medievales', mapsQuery: 'Musee du Petit Palais Avignon'),
      _TopPick(title: 'Collection Lambert', description: 'Art contemporain dans un hotel particulier du XVIIIe', mapsQuery: 'Collection Lambert Avignon'),
      _TopPick(title: 'Ile de la Barthelasse', description: 'Plus grande ile fluviale d\'Europe, balade a velo', mapsQuery: 'Ile de la Barthelasse Avignon'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Palais des Papes + Rocher', description: 'Visite du palais puis vue panoramique', mapsQuery: 'Palais des Papes Avignon'),
      _TopPick(title: 'Midi : Place de l\'Horloge', description: 'Dejeuner en terrasse au coeur de la ville', mapsQuery: 'Place de l\'Horloge Avignon'),
      _TopPick(title: 'Apres-midi : Pont + Remparts', description: 'Pont Saint-Benezet puis tour des remparts', mapsQuery: 'Pont d\'Avignon'),
      _TopPick(title: 'Soir : Rue des Teinturiers', description: 'Aperitif et diner dans le quartier boheme', mapsQuery: 'Rue des Teinturiers Avignon'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Avignon historique', description: 'Palais des Papes, Pont, Rocher des Doms, remparts', mapsQuery: 'Palais des Papes Avignon'),
      _TopPick(title: 'Jour 2 : Culture + Barthelasse', description: 'Collection Lambert, Petit Palais, velo sur l\'ile', mapsQuery: 'Collection Lambert Avignon'),
      _TopPick(title: 'Jour 3 : Luberon', description: 'Gordes, Roussillon (ocres), Fontaine-de-Vaucluse (30 min)', mapsQuery: 'Gordes Luberon'),
    ],
  ),
  'carcassonne': _CityTopPicks(
    top10: [
      _TopPick(title: 'La Cite medievale', description: 'Plus grande cite fortifiee d\'Europe, classee UNESCO', mapsQuery: 'Cite medievale Carcassonne'),
      _TopPick(title: 'Chateau Comtal', description: 'Forteresse dans la forteresse, musee lapidaire', mapsQuery: 'Chateau Comtal Carcassonne'),
      _TopPick(title: 'Basilique Saint-Nazaire', description: 'Vitraux gothiques parmi les plus beaux du Midi', mapsQuery: 'Basilique Saint-Nazaire Carcassonne'),
      _TopPick(title: 'Canal du Midi', description: 'Promenade en peniche ou a velo le long du canal UNESCO', mapsQuery: 'Canal du Midi Carcassonne'),
      _TopPick(title: 'Bastide Saint-Louis', description: 'Ville basse, marche, terrasses, vie locale', mapsQuery: 'Bastide Saint-Louis Carcassonne'),
      _TopPick(title: 'Pont Vieux', description: 'Pont medieval reliant la Cite a la Bastide, vue superbe', mapsQuery: 'Pont Vieux Carcassonne'),
      _TopPick(title: 'Lac de la Cavayere', description: 'Base de loisirs, baignade, accrobranche', mapsQuery: 'Lac de la Cavayere Carcassonne'),
      _TopPick(title: 'Feu d\'artifice du 14 juillet', description: 'L\'embrasement de la Cite, spectacle unique', tip: 'Un des plus beaux feux de France', mapsQuery: 'Cite Carcassonne'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : La Cite', description: 'Remparts, Chateau Comtal, Basilique Saint-Nazaire', mapsQuery: 'Cite medievale Carcassonne'),
      _TopPick(title: 'Dejeuner : Cassoulet', description: 'LE plat de Carcassonne, dans la Cite ou la Bastide', mapsQuery: 'Restaurant Cite Carcassonne'),
      _TopPick(title: 'Apres-midi : Canal du Midi + Bastide', description: 'Balade le long du canal puis ville basse', mapsQuery: 'Canal du Midi Carcassonne'),
      _TopPick(title: 'Soir : Vue sur la Cite illuminee', description: 'Depuis le Pont Vieux, la Cite est magique de nuit', mapsQuery: 'Pont Vieux Carcassonne'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : La Cite', description: 'Remparts, chateau, basilique, ruelles medievales', mapsQuery: 'Cite medievale Carcassonne'),
      _TopPick(title: 'Jour 2 : Canal + Bastide + Lac', description: 'Canal du Midi, marche, Lac de la Cavayere', mapsQuery: 'Canal du Midi Carcassonne'),
      _TopPick(title: 'Jour 3 : Chateaux cathares', description: 'Queribus, Peyrepertuse, paysages vertigineux (1h)', tip: 'Les chateaux cathares sont spectaculaires', mapsQuery: 'Chateau de Queribus'),
    ],
  ),
  'colmar': _CityTopPicks(
    top10: [
      _TopPick(title: 'Petite Venise', description: 'Quartier pittoresque traverse par la Lauch, maisons colorees', mapsQuery: 'Petite Venise Colmar'),
      _TopPick(title: 'Musee Unterlinden', description: 'Retable d\'Issenheim, chef-d\'oeuvre de Grunewald', mapsQuery: 'Musee Unterlinden Colmar'),
      _TopPick(title: 'Maison des Tetes', description: 'Facade Renaissance ornee de 106 tetes sculptees', mapsQuery: 'Maison des Tetes Colmar'),
      _TopPick(title: 'Maison Pfister', description: 'Plus belle maison a colombages de Colmar (1537)', mapsQuery: 'Maison Pfister Colmar'),
      _TopPick(title: 'Quartier des Tanneurs', description: 'Maisons hautes a colombages, anciens ateliers', mapsQuery: 'Quartier des Tanneurs Colmar'),
      _TopPick(title: 'Marche de Noel', description: '5 marches de Noel differents, feerique en decembre', tip: 'Le plus beau marche de Noel d\'Alsace', mapsQuery: 'Marche de Noel Colmar'),
      _TopPick(title: 'Eglise Saint-Martin', description: 'Collegiale gothique, toiture en tuiles vernissees', mapsQuery: 'Eglise Saint-Martin Colmar'),
      _TopPick(title: 'Rue des Marchands', description: 'Artere principale du vieux Colmar, boutiques artisanales', mapsQuery: 'Rue des Marchands Colmar'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Vieille ville', description: 'Maison des Tetes, Pfister, Rue des Marchands', mapsQuery: 'Centre historique Colmar'),
      _TopPick(title: 'Midi : Winstub', description: 'Choucroute, baeckeoffe, tarte flambee', mapsQuery: 'Petite Venise Colmar'),
      _TopPick(title: 'Apres-midi : Petite Venise + Unterlinden', description: 'Promenade en barque puis musee', mapsQuery: 'Petite Venise Colmar'),
      _TopPick(title: 'Soir : Rue des Tanneurs', description: 'Verre de gewurztraminer en terrasse', mapsQuery: 'Quartier des Tanneurs Colmar'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Colmar', description: 'Vieille ville, Petite Venise, Unterlinden', mapsQuery: 'Centre historique Colmar'),
      _TopPick(title: 'Jour 2 : Route des vins', description: 'Riquewihr, Kaysersberg, Eguisheim (plus beau village)', mapsQuery: 'Eguisheim Alsace'),
      _TopPick(title: 'Jour 3 : Haut-Koenigsbourg', description: 'Chateau medieval restaure, vue sur la plaine d\'Alsace', mapsQuery: 'Haut-Koenigsbourg'),
    ],
  ),
  'annecy': _CityTopPicks(
    top10: [
      _TopPick(title: 'Lac d\'Annecy', description: 'Lac le plus pur d\'Europe, baignade, paddle, velo', mapsQuery: 'Lac d\'Annecy'),
      _TopPick(title: 'Vieille ville', description: 'Canaux, ruelles colorees, Palais de l\'Isle', mapsQuery: 'Vieille ville Annecy'),
      _TopPick(title: 'Palais de l\'Isle', description: 'Monument emblematique sur son ilot, ancien tribunal', mapsQuery: 'Palais de l\'Isle Annecy'),
      _TopPick(title: 'Chateau d\'Annecy', description: 'Forteresse medievale, musee, vue sur la ville', mapsQuery: 'Chateau d\'Annecy'),
      _TopPick(title: 'Pont des Amours', description: 'Passerelle romantique entre les Jardins et le Paquier', mapsQuery: 'Pont des Amours Annecy'),
      _TopPick(title: 'Le Pâquier', description: 'Grand parc au bord du lac, vue sur les montagnes', mapsQuery: 'Le Paquier Annecy'),
      _TopPick(title: 'Tour du lac a velo', description: '42 km de piste cyclable autour du lac', tip: 'Location de velo electrique pour le tour complet', mapsQuery: 'Piste cyclable lac Annecy'),
      _TopPick(title: 'Col de la Forclaz', description: 'Vue plongeante sur le lac, spot de parapente', mapsQuery: 'Col de la Forclaz Annecy'),
      _TopPick(title: 'Gorges du Fier', description: 'Canyon spectaculaire sur passerelles (15 min d\'Annecy)', mapsQuery: 'Gorges du Fier'),
      _TopPick(title: 'Marche du dimanche', description: 'Grand marche dans la vieille ville, produits savoyards', mapsQuery: 'Marche Annecy'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Vieille ville + Chateau', description: 'Palais de l\'Isle, canaux, chateau', mapsQuery: 'Vieille ville Annecy'),
      _TopPick(title: 'Midi : Restaurant lacustre', description: 'Tartiflette ou filets de perche face au lac', mapsQuery: 'Restaurant lac Annecy'),
      _TopPick(title: 'Apres-midi : Lac', description: 'Baignade, paddle ou bateau-mouche', mapsQuery: 'Lac d\'Annecy'),
      _TopPick(title: 'Soir : Pont des Amours', description: 'Coucher de soleil sur les montagnes', mapsQuery: 'Pont des Amours Annecy'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Annecy', description: 'Vieille ville, chateau, lac, Pont des Amours', mapsQuery: 'Vieille ville Annecy'),
      _TopPick(title: 'Jour 2 : Tour du lac', description: 'Velo autour du lac, villages, baignade Talloires', mapsQuery: 'Piste cyclable lac Annecy'),
      _TopPick(title: 'Jour 3 : Montagnes', description: 'Col de la Forclaz (parapente), Gorges du Fier, Semnoz', mapsQuery: 'Col de la Forclaz Annecy'),
    ],
  ),
  'rouen': _CityTopPicks(
    top10: [
      _TopPick(title: 'Cathedrale Notre-Dame', description: 'Peinte par Monet, facade gothique spectaculaire', mapsQuery: 'Cathedrale de Rouen'),
      _TopPick(title: 'Gros-Horloge', description: 'Horloge astronomique Renaissance sur une arche', mapsQuery: 'Gros-Horloge Rouen'),
      _TopPick(title: 'Place du Vieux-Marche', description: 'Ou Jeanne d\'Arc fut brulee, eglise moderne', mapsQuery: 'Place du Vieux-Marche Rouen'),
      _TopPick(title: 'Musee des Beaux-Arts', description: 'Impressionnistes, Caravage, Velazquez', mapsQuery: 'Musee des Beaux-Arts Rouen'),
      _TopPick(title: 'Rue du Gros-Horloge', description: 'Rue pietonne, maisons a colombages medievales', mapsQuery: 'Rue du Gros-Horloge Rouen'),
      _TopPick(title: 'Abbatiale Saint-Ouen', description: 'Chef-d\'oeuvre gothique, vitraux, jardins', mapsQuery: 'Abbatiale Saint-Ouen Rouen'),
      _TopPick(title: 'Panorama XXL', description: 'Fresque panoramique geante immersive', mapsQuery: 'Panorama XXL Rouen'),
      _TopPick(title: 'Aitre Saint-Maclou', description: 'Ossuaire medieval unique, cour interieure', mapsQuery: 'Aitre Saint-Maclou Rouen'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Cathedrale + Gros-Horloge', description: 'Les deux icones de Rouen, ruelles medievales', mapsQuery: 'Cathedrale de Rouen'),
      _TopPick(title: 'Midi : Place du Vieux-Marche', description: 'Restaurants normands, canard a la rouennaise', mapsQuery: 'Place du Vieux-Marche Rouen'),
      _TopPick(title: 'Apres-midi : Musee + Saint-Ouen', description: 'Beaux-Arts puis abbatiale et jardins', mapsQuery: 'Musee des Beaux-Arts Rouen'),
      _TopPick(title: 'Soir : Quais de Seine', description: 'Promenade sur les quais renoves', mapsQuery: 'Quais de Seine Rouen'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Rouen historique', description: 'Cathedrale, Gros-Horloge, Vieux-Marche, Aitre Saint-Maclou', mapsQuery: 'Cathedrale de Rouen'),
      _TopPick(title: 'Jour 2 : Musees + Saint-Ouen', description: 'Beaux-Arts, Panorama XXL, abbatiale', mapsQuery: 'Musee des Beaux-Arts Rouen'),
      _TopPick(title: 'Jour 3 : Cote d\'Albatre', description: 'Etretat (1h) ou Dieppe, falaises normandes', mapsQuery: 'Etretat'),
    ],
  ),
  'chartres': _CityTopPicks(
    top10: [
      _TopPick(title: 'Cathedrale Notre-Dame', description: 'Chef-d\'oeuvre gothique UNESCO, vitraux du XIIIe intacts', mapsQuery: 'Cathedrale de Chartres'),
      _TopPick(title: 'Chartres en Lumieres', description: 'Projections nocturnes sur 24 sites (avril-octobre)', tip: 'Gratuit, parcours de 2h dans la ville', mapsQuery: 'Chartres en Lumieres'),
      _TopPick(title: 'Vieille ville', description: 'Maisons medievales, escaliers, lavoirs', mapsQuery: 'Vieille ville Chartres'),
      _TopPick(title: 'Maison Picassiette', description: 'Maison entierement decoree de mosaiques de faience', mapsQuery: 'Maison Picassiette Chartres'),
      _TopPick(title: 'Bords de l\'Eure', description: 'Promenade bucolique le long de la riviere', mapsQuery: 'Bords de l\'Eure Chartres'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Cathedrale', description: 'Vitraux, crypte, tour nord (panorama)', mapsQuery: 'Cathedrale de Chartres'),
      _TopPick(title: 'Apres-midi : Vieille ville + Eure', description: 'Ruelles, Maison Picassiette, bords de l\'Eure', mapsQuery: 'Vieille ville Chartres'),
      _TopPick(title: 'Soir : Chartres en Lumieres', description: 'Parcours lumineux gratuit des la tombee de la nuit', mapsQuery: 'Chartres en Lumieres'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Chartres', description: 'Cathedrale, vieille ville, Lumieres le soir', mapsQuery: 'Cathedrale de Chartres'),
      _TopPick(title: 'Jour 2 : Beauce', description: 'Plaine de Beauce, chateaux d\'Anet et Maintenon', mapsQuery: 'Chateau de Maintenon'),
      _TopPick(title: 'Jour 3 : Versailles', description: 'Chateau de Versailles (1h en voiture)', mapsQuery: 'Chateau de Versailles'),
    ],
  ),
  'blois': _CityTopPicks(
    top10: [
      _TopPick(title: 'Chateau Royal de Blois', description: '4 ailes, 4 styles architecturaux, son et lumiere', mapsQuery: 'Chateau Royal de Blois'),
      _TopPick(title: 'Maison de la Magie', description: 'Musee Robert-Houdin, spectacles de magie, dragons', mapsQuery: 'Maison de la Magie Blois'),
      _TopPick(title: 'Vieille ville', description: 'Escaliers, ruelles medievales, maisons a pans de bois', mapsQuery: 'Vieille ville Blois'),
      _TopPick(title: 'Escalier Denis Papin', description: 'Escalier monumental de 121 marches, vue sur la Loire', mapsQuery: 'Escalier Denis Papin Blois'),
      _TopPick(title: 'Fondation du doute', description: 'Art Fluxus, oeuvres de Ben', mapsQuery: 'Fondation du doute Blois'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Chateau Royal', description: '4 epoques d\'architecture, histoire des rois', mapsQuery: 'Chateau Royal de Blois'),
      _TopPick(title: 'Apres-midi : Vieille ville + Magie', description: 'Ruelles, Denis Papin, Maison de la Magie', mapsQuery: 'Maison de la Magie Blois'),
      _TopPick(title: 'Soir : Bords de Loire', description: 'Coucher de soleil sur le fleuve royal', mapsQuery: 'Bords de Loire Blois'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Blois', description: 'Chateau, vieille ville, Maison de la Magie', mapsQuery: 'Chateau Royal de Blois'),
      _TopPick(title: 'Jour 2 : Chambord + Cheverny', description: 'Les 2 chateaux les plus celebres (20 min)', mapsQuery: 'Chateau de Chambord'),
      _TopPick(title: 'Jour 3 : Chaumont + Amboise', description: 'Festival des jardins + chateau d\'Amboise', mapsQuery: 'Chateau de Chaumont-sur-Loire'),
    ],
  ),
  'bayonne': _CityTopPicks(
    top10: [
      _TopPick(title: 'Grand Bayonne', description: 'Vieille ville, ruelles, maisons a colombages basques', mapsQuery: 'Grand Bayonne'),
      _TopPick(title: 'Cathedrale Sainte-Marie', description: 'Gothique, classee UNESCO sur les chemins de Compostelle', mapsQuery: 'Cathedrale Sainte-Marie Bayonne'),
      _TopPick(title: 'Petit Bayonne', description: 'Quartier festif, bars a tapas, fronton de pelote', mapsQuery: 'Petit Bayonne'),
      _TopPick(title: 'Musee Basque', description: 'Plus grand musee d\'ethnographie du Pays Basque', mapsQuery: 'Musee Basque Bayonne'),
      _TopPick(title: 'Remparts Vauban', description: 'Fortifications le long de la Nive et l\'Adour', mapsQuery: 'Remparts Bayonne'),
      _TopPick(title: 'Chocolat de Bayonne', description: 'Capitale du chocolat depuis le XVIIe, ateliers et degustations', tip: 'La rue Port-Neuf est la rue du chocolat', mapsQuery: 'Chocolat Bayonne'),
      _TopPick(title: 'Fetes de Bayonne', description: 'Plus grandes fetes de France (fin juillet), 5 jours de folie', tip: 'Tout en blanc et rouge', mapsQuery: 'Fetes de Bayonne'),
      _TopPick(title: 'Les Halles', description: 'Marche couvert, jambon de Bayonne, fromage de brebis', mapsQuery: 'Halles Bayonne'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Grand Bayonne', description: 'Cathedrale, ruelles, chocolateries', mapsQuery: 'Grand Bayonne'),
      _TopPick(title: 'Midi : Les Halles', description: 'Jambon, fromage, pintxos', mapsQuery: 'Halles Bayonne'),
      _TopPick(title: 'Apres-midi : Petit Bayonne + Musee', description: 'Musee Basque, remparts, bords de Nive', mapsQuery: 'Petit Bayonne'),
      _TopPick(title: 'Soir : Petit Bayonne', description: 'Bars a tapas et ambiance basque', mapsQuery: 'Petit Bayonne'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Bayonne', description: 'Grand et Petit Bayonne, cathedrale, chocolat, musee', mapsQuery: 'Grand Bayonne'),
      _TopPick(title: 'Jour 2 : Cote basque', description: 'Biarritz, Saint-Jean-de-Luz, Espelette (piment)', mapsQuery: 'Biarritz'),
      _TopPick(title: 'Jour 3 : Montagne basque', description: 'La Rhune (train a cremaillere), villages basques', mapsQuery: 'La Rhune Pays Basque'),
    ],
  ),
  'amiens': _CityTopPicks(
    top10: [
      _TopPick(title: 'Cathedrale Notre-Dame', description: 'Plus grande cathedrale gothique de France, UNESCO', mapsQuery: 'Cathedrale d\'Amiens'),
      _TopPick(title: 'Hortillonnages', description: 'Jardins flottants sur 300 hectares, barque traditionnelle', mapsQuery: 'Hortillonnages Amiens'),
      _TopPick(title: 'Quartier Saint-Leu', description: 'Maisons colorees sur les canaux, restaurants, bars', mapsQuery: 'Quartier Saint-Leu Amiens'),
      _TopPick(title: 'Maison de Jules Verne', description: 'La maison ou l\'ecrivain a vecu 18 ans', mapsQuery: 'Maison de Jules Verne Amiens'),
      _TopPick(title: 'Musee de Picardie', description: 'Beaux-Arts dans un palais Napoleon III', mapsQuery: 'Musee de Picardie Amiens'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Cathedrale + Saint-Leu', description: 'La plus grande cathedrale de France puis les canaux', mapsQuery: 'Cathedrale d\'Amiens'),
      _TopPick(title: 'Apres-midi : Hortillonnages', description: 'Promenade en barque dans les jardins flottants', mapsQuery: 'Hortillonnages Amiens'),
      _TopPick(title: 'Soir : Saint-Leu', description: 'Diner au bord des canaux', mapsQuery: 'Quartier Saint-Leu Amiens'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Amiens', description: 'Cathedrale, Saint-Leu, Hortillonnages', mapsQuery: 'Cathedrale d\'Amiens'),
      _TopPick(title: 'Jour 2 : Jules Verne + Musees', description: 'Maison de Jules Verne, Musee de Picardie', mapsQuery: 'Maison de Jules Verne Amiens'),
      _TopPick(title: 'Jour 3 : Baie de Somme', description: 'Phoques, oiseaux, le Crotoy, Saint-Valery (1h)', mapsQuery: 'Baie de Somme'),
    ],
  ),
  'besancon': _CityTopPicks(
    top10: [
      _TopPick(title: 'Citadelle Vauban', description: 'Chef-d\'oeuvre de Vauban UNESCO, musees, zoo, vue 360', mapsQuery: 'Citadelle Besancon'),
      _TopPick(title: 'Boucle du Doubs', description: 'La ville dans un meandre naturel, promenades', mapsQuery: 'Boucle du Doubs Besancon'),
      _TopPick(title: 'Grande Rue', description: 'Artere principale, architecture Renaissance, hotels particuliers', mapsQuery: 'Grande Rue Besancon'),
      _TopPick(title: 'Musee du Temps', description: 'Horlogerie et mesure du temps, dans le Palais Granvelle', mapsQuery: 'Musee du Temps Besancon'),
      _TopPick(title: 'Cathedrale Saint-Jean', description: 'Horloge astronomique, peinture de Fra Bartolomeo', mapsQuery: 'Cathedrale Saint-Jean Besancon'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Citadelle', description: '3 musees, zoo, vue panoramique', mapsQuery: 'Citadelle Besancon'),
      _TopPick(title: 'Apres-midi : Vieille ville', description: 'Grande Rue, Musee du Temps, cathedrale', mapsQuery: 'Grande Rue Besancon'),
      _TopPick(title: 'Soir : Quais du Doubs', description: 'Promenade et restaurants le long de la riviere', mapsQuery: 'Quais du Doubs Besancon'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Besancon', description: 'Citadelle, vieille ville, Musee du Temps', mapsQuery: 'Citadelle Besancon'),
      _TopPick(title: 'Jour 2 : Saline royale', description: 'Arc-et-Senans, UNESCO, architecture utopique (40 min)', mapsQuery: 'Saline royale Arc-et-Senans'),
      _TopPick(title: 'Jour 3 : Jura', description: 'Reculee des Planches, cascades du Herisson', mapsQuery: 'Cascades du Herisson Jura'),
    ],
  ),
  'metz': _CityTopPicks(
    top10: [
      _TopPick(title: 'Centre Pompidou-Metz', description: 'Art moderne et contemporain, architecture spectaculaire', mapsQuery: 'Centre Pompidou-Metz'),
      _TopPick(title: 'Cathedrale Saint-Etienne', description: 'Plus grande surface de vitraux d\'Europe, Chagall', tip: 'Surnommee "la Lanterne du Bon Dieu"', mapsQuery: 'Cathedrale Saint-Etienne Metz'),
      _TopPick(title: 'Quartier Imperial', description: 'Architecture allemande wilhelmienne, gare monumentale', mapsQuery: 'Quartier Imperial Metz'),
      _TopPick(title: 'Temple Neuf', description: 'Eglise protestante sur une ile, reflet dans la Moselle', mapsQuery: 'Temple Neuf Metz'),
      _TopPick(title: 'Place Saint-Louis', description: 'Arcades medievales, terrasses de cafes', mapsQuery: 'Place Saint-Louis Metz'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Cathedrale + ile', description: 'Vitraux de Chagall, Temple Neuf, bords de Moselle', mapsQuery: 'Cathedrale Saint-Etienne Metz'),
      _TopPick(title: 'Apres-midi : Pompidou-Metz', description: 'Expos temporaires dans un batiment iconique', mapsQuery: 'Centre Pompidou-Metz'),
      _TopPick(title: 'Soir : Place Saint-Louis', description: 'Aperitif sous les arcades', mapsQuery: 'Place Saint-Louis Metz'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Metz centre', description: 'Cathedrale, Temple Neuf, Pompidou-Metz', mapsQuery: 'Cathedrale Saint-Etienne Metz'),
      _TopPick(title: 'Jour 2 : Quartier Imperial + Seille', description: 'Architecture wilhelmienne, gare, marche couvert', mapsQuery: 'Quartier Imperial Metz'),
      _TopPick(title: 'Jour 3 : Luxembourg ou Verdun', description: 'Luxembourg (1h) ou memoriaux de Verdun (1h)', mapsQuery: 'Ville de Luxembourg'),
    ],
  ),
  'nancy': _CityTopPicks(
    top10: [
      _TopPick(title: 'Place Stanislas', description: 'Plus belle place du monde (UNESCO), fontaines dorees', mapsQuery: 'Place Stanislas Nancy'),
      _TopPick(title: 'Musee de l\'Ecole de Nancy', description: 'Art Nouveau, Galle, Majorelle, Daum', mapsQuery: 'Musee Ecole de Nancy'),
      _TopPick(title: 'Parc de la Pepiniere', description: 'Grand parc au coeur de la ville, roseraie, zoo', mapsQuery: 'Parc de la Pepiniere Nancy'),
      _TopPick(title: 'Vieille ville', description: 'Porte de la Craffe, Grande Rue, palais ducal', mapsQuery: 'Vieille ville Nancy'),
      _TopPick(title: 'Place de la Carriere', description: 'Perspective monumentale depuis Stanislas, UNESCO', mapsQuery: 'Place de la Carriere Nancy'),
      _TopPick(title: 'Villa Majorelle', description: 'Chef-d\'oeuvre Art Nouveau, visite guidee', mapsQuery: 'Villa Majorelle Nancy'),
      _TopPick(title: 'Musee des Beaux-Arts', description: 'Collection Daum, peintures du XIVe au XXIe', mapsQuery: 'Musee des Beaux-Arts Nancy'),
      _TopPick(title: 'Basilique Saint-Epvre', description: 'Neo-gothique spectaculaire, vitraux bavarois', mapsQuery: 'Basilique Saint-Epvre Nancy'),
    ],
    oneDay: [
      _TopPick(title: 'Matin : Place Stanislas + Carriere', description: 'Les 3 places UNESCO, fontaines, grilles dorees', mapsQuery: 'Place Stanislas Nancy'),
      _TopPick(title: 'Midi : Marche central', description: 'Quiche lorraine, mirabelles, bergamotes', mapsQuery: 'Marche central Nancy'),
      _TopPick(title: 'Apres-midi : Ecole de Nancy', description: 'Art Nouveau, Villa Majorelle, musee', mapsQuery: 'Musee Ecole de Nancy'),
      _TopPick(title: 'Soir : Place Stanislas illuminee', description: 'Spectacle son et lumiere en ete', mapsQuery: 'Place Stanislas Nancy'),
    ],
    threeDays: [
      _TopPick(title: 'Jour 1 : Nancy classique', description: 'Stanislas, Carriere, vieille ville, Beaux-Arts', mapsQuery: 'Place Stanislas Nancy'),
      _TopPick(title: 'Jour 2 : Art Nouveau', description: 'Musee Ecole de Nancy, Villa Majorelle, quartier Saurupt', mapsQuery: 'Musee Ecole de Nancy'),
      _TopPick(title: 'Jour 3 : Metz ou Luneville', description: 'Pompidou-Metz (30 min) ou chateau de Luneville', mapsQuery: 'Centre Pompidou-Metz'),
    ],
  ),
};
