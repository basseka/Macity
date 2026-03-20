// Configuration des mairies à scraper.
// Chaque ville a une stratégie de scraping et les URLs sources.

export interface CityConfig {
  ville: string;
  /** Stratégie de scraping */
  strategy: "wp-api" | "wp-html" | "html-article" | "typo3" | "drupal" | "skip";
  /** URL de base du site */
  baseUrl: string;
  /** URLs des pages actualités (HTML scraping) */
  actusUrl?: string;
  /** URLs des pages agenda (HTML scraping) */
  agendaUrl?: string;
  /** WP REST API : endpoints custom post types */
  wpActusEndpoint?: string;
  wpAgendaEndpoint?: string;
  /** Tribe Events Calendar API */
  tribeApi?: boolean;
  /** Notes / raison du skip */
  note?: string;
}

export const CITIES: CityConfig[] = [
  // ── Déjà scrapées individuellement (skip ici pour éviter les doublons) ──
  { ville: "Beaupuy", strategy: "skip", baseUrl: "https://www.ville-beaupuy.fr", note: "scrape-mairie-beaupuy" },
  { ville: "Balma", strategy: "skip", baseUrl: "https://www.mairie-balma.fr", note: "scrape-mairie-balma" },
  { ville: "Montrabé", strategy: "skip", baseUrl: "https://www.mairie-montrabe.fr", note: "scrape-mairie-montrabe" },
  { ville: "L'Union", strategy: "skip", baseUrl: "https://www.ville-lunion.fr", note: "scrape-mairie-lunion" },
  { ville: "Colomiers", strategy: "skip", baseUrl: "https://www.ville-colomiers.fr", note: "scrape-mairie-colomiers" },
  { ville: "Plaisance-du-Touch", strategy: "skip", baseUrl: "https://www.plaisancedutouch.fr", note: "scrape-mairie-plaisance" },
  { ville: "Toulouse", strategy: "skip", baseUrl: "https://metropole.toulouse.fr", note: "scrape-mairie-toulouse" },

  // ── Haute-Garonne ──
  {
    ville: "Tournefeuille",
    strategy: "html-article",
    baseUrl: "https://www.tournefeuille.fr",
    agendaUrl: "https://www.tournefeuille.fr/nav-agenda",
  },
  {
    ville: "Cugnaux",
    strategy: "wp-api",
    baseUrl: "https://www.ville-cugnaux.fr",
    wpActusEndpoint: "/wp-json/wp/v2/news?per_page=20&_fields=title,link,excerpt,date,_links&_embed",
    wpAgendaEndpoint: "/wp-json/wp/v2/event?per_page=20&_fields=title,link,excerpt,date,_links&_embed",
  },
  {
    ville: "Castanet-Tolosan",
    strategy: "typo3",
    baseUrl: "https://www.castanet-tolosan.fr",
    actusUrl: "https://www.castanet-tolosan.fr/actualites-109.html",
    agendaUrl: "https://www.castanet-tolosan.fr/agenda-133.html",
  },
  {
    ville: "Ramonville-Saint-Agne",
    strategy: "wp-api",
    baseUrl: "https://www.ramonville.fr",
    wpActusEndpoint: "/wp-json/wp/v2/news?per_page=20&_fields=title,link,excerpt,date,_links&_embed",
    wpAgendaEndpoint: "/wp-json/wp/v2/event?per_page=20&_fields=title,link,excerpt,date,_links&_embed",
  },
  {
    ville: "Villemur-sur-Tarn",
    strategy: "html-article",
    baseUrl: "https://www.villemur-sur-tarn.fr",
    actusUrl: "https://www.villemur-sur-tarn.fr/actualites/",
  },
  {
    ville: "Fronton",
    strategy: "html-article",
    baseUrl: "https://www.mairie-fronton.fr",
    actusUrl: "https://www.mairie-fronton.fr/actualites/",
  },
  {
    ville: "Revel",
    strategy: "html-article",
    baseUrl: "https://www.mairie-revel.fr",
    actusUrl: "https://www.mairie-revel.fr/actualites/",
  },
  {
    ville: "Saint-Gaudens",
    strategy: "html-article",
    baseUrl: "https://www.saint-gaudens.fr",
    actusUrl: "https://www.saint-gaudens.fr/actualites/",
  },
  {
    ville: "Saint-Lys",
    strategy: "html-article",
    baseUrl: "https://www.saint-lys.fr",
    actusUrl: "https://www.saint-lys.fr/actualites/",
  },
  {
    ville: "Carbonne",
    strategy: "html-article",
    baseUrl: "https://www.ville-carbonne.fr",
    actusUrl: "https://www.ville-carbonne.fr/actualites/",
  },
  {
    ville: "Auterive",
    strategy: "html-article",
    baseUrl: "https://www.auterive31.fr",
    actusUrl: "https://www.auterive31.fr/actualites/",
  },
  {
    ville: "Grenade",
    strategy: "html-article",
    baseUrl: "https://www.ville-grenade31.fr",
    actusUrl: "https://www.ville-grenade31.fr/actualites/",
  },
  {
    ville: "Villefranche-de-Lauragais",
    strategy: "html-article",
    baseUrl: "https://www.villefranchedelauragais.fr",
    actusUrl: "https://www.villefranchedelauragais.fr/actualites/",
  },
  {
    ville: "Nailloux",
    strategy: "html-article",
    baseUrl: "https://www.mairie-nailloux.fr",
    actusUrl: "https://www.mairie-nailloux.fr/actualites/",
  },

  // ── Tarn ──
  {
    ville: "Albi",
    strategy: "drupal",
    baseUrl: "https://www.mairie-albi.fr",
    actusUrl: "https://www.mairie-albi.fr/actualites",
    agendaUrl: "https://www.mairie-albi.fr/que-faire-a-albi/agenda",
  },
  {
    ville: "Castres",
    strategy: "wp-api",
    baseUrl: "https://www.ville-castres.fr",
    wpActusEndpoint: "/wp-json/wp/v2/actualites?per_page=20&_fields=title,link,excerpt,date,_links&_embed",
    wpAgendaEndpoint: "/wp-json/wp/v2/agenda?per_page=20&_fields=title,link,excerpt,date,_links&_embed",
  },
  {
    ville: "Gaillac",
    strategy: "html-article",
    baseUrl: "https://www.ville-gaillac.fr",
    actusUrl: "https://www.ville-gaillac.fr/actualites/",
  },
  {
    ville: "Graulhet",
    strategy: "html-article",
    baseUrl: "https://www.ville-graulhet.fr",
    actusUrl: "https://www.ville-graulhet.fr/actualites/",
  },
  {
    ville: "Mazamet",
    strategy: "html-article",
    baseUrl: "https://www.ville-mazamet.com",
    actusUrl: "https://www.ville-mazamet.com/actualites/",
  },
  {
    ville: "Carmaux",
    strategy: "html-article",
    baseUrl: "https://www.carmaux.fr",
    actusUrl: "https://www.carmaux.fr/actualites/",
  },
  {
    ville: "Lavaur",
    strategy: "html-article",
    baseUrl: "https://www.ville-lavaur.fr",
    actusUrl: "https://www.ville-lavaur.fr/actualites/",
  },

  // ── Tarn-et-Garonne ──
  {
    ville: "Montauban",
    strategy: "typo3",
    baseUrl: "https://www.montauban.com",
    actusUrl: "https://www.montauban.com/information-transversale/actualites",
    agendaUrl: "https://www.montauban.com/information-transversale/agenda",
  },
  {
    ville: "Moissac",
    strategy: "html-article",
    baseUrl: "https://www.moissac.fr",
    actusUrl: "https://www.moissac.fr/actualites/",
  },
  {
    ville: "Castelsarrasin",
    strategy: "html-article",
    baseUrl: "https://www.ville-castelsarrasin.fr",
    actusUrl: "https://www.ville-castelsarrasin.fr/actualites/",
  },
  {
    ville: "Caussade",
    strategy: "html-article",
    baseUrl: "https://www.ville-caussade.fr",
    actusUrl: "https://www.ville-caussade.fr/actualites/",
  },
  {
    ville: "Montech",
    strategy: "html-article",
    baseUrl: "https://www.mairie-montech.fr",
    actusUrl: "https://www.mairie-montech.fr/actualites/",
  },

  // ── Gers ──
  {
    ville: "Fleurance",
    strategy: "html-article",
    baseUrl: "https://www.ville-fleurance.fr",
    actusUrl: "https://www.ville-fleurance.fr/actualites/",
  },
  {
    ville: "Condom",
    strategy: "html-article",
    baseUrl: "https://www.condom.org",
    actusUrl: "https://www.condom.org/actualites/",
  },
  {
    ville: "Lectoure",
    strategy: "html-article",
    baseUrl: "https://www.lectoure.fr",
    actusUrl: "https://www.lectoure.fr/actualites/",
  },
  {
    ville: "L'Isle-Jourdain",
    strategy: "html-article",
    baseUrl: "https://www.mairie-islejourdain.fr",
    actusUrl: "https://www.mairie-islejourdain.fr/actualites/",
  },
  {
    ville: "Gimont",
    strategy: "html-article",
    baseUrl: "https://www.ville-gimont.fr",
    actusUrl: "https://www.ville-gimont.fr/actualites/",
  },
  {
    ville: "Nogaro",
    strategy: "html-article",
    baseUrl: "https://www.nogaro.fr",
    actusUrl: "https://www.nogaro.fr/actualites/",
  },

  // ── Aude ──
  {
    ville: "Carcassonne",
    strategy: "drupal",
    baseUrl: "https://www.carcassonne.org",
    actusUrl: "https://www.carcassonne.org/toutes-les-actualites",
    agendaUrl: "https://www.carcassonne.org/agenda-manifestations-carcassonne",
  },
  {
    ville: "Castelnaudary",
    strategy: "html-article",
    baseUrl: "https://www.ville-castelnaudary.fr",
    actusUrl: "https://www.ville-castelnaudary.fr/actualites/",
  },
  {
    ville: "Limoux",
    strategy: "html-article",
    baseUrl: "https://www.limoux.fr",
    actusUrl: "https://www.limoux.fr/actualites/",
  },
  {
    ville: "Bram",
    strategy: "html-article",
    baseUrl: "https://www.ville-bram.fr",
    actusUrl: "https://www.ville-bram.fr/actualites/",
  },

  // ── Ariège ──
  {
    ville: "Pamiers",
    strategy: "wp-api",
    baseUrl: "https://www.ville-pamiers.fr",
    wpActusEndpoint: "/wp-json/wp/v2/posts?per_page=20&_fields=title,link,excerpt,date,_links&_embed",
    wpAgendaEndpoint: "/wp-json/wp/v2/event?per_page=20&_fields=title,link,excerpt,date,_links&_embed",
  },
  {
    ville: "Foix",
    strategy: "html-article",
    baseUrl: "https://www.mairie-foix.fr",
    actusUrl: "https://www.mairie-foix.fr/index.php/actualit%C3%A9s?idpage=215",
    agendaUrl: "https://www.mairie-foix.fr/index.php/agenda?idpage=216",
  },
  {
    ville: "Saint-Girons",
    strategy: "html-article",
    baseUrl: "https://www.ville-saint-girons.fr",
    actusUrl: "https://www.ville-saint-girons.fr/actualites/",
  },
  {
    ville: "Lavelanet",
    strategy: "html-article",
    baseUrl: "https://www.lavelanet.fr",
    actusUrl: "https://www.lavelanet.fr/actualites/",
  },
  {
    ville: "Saverdun",
    strategy: "html-article",
    baseUrl: "https://www.saverdun.fr",
    actusUrl: "https://www.saverdun.fr/actualites/",
  },
  {
    ville: "Varilhes",
    strategy: "html-article",
    baseUrl: "https://www.varilhes.fr",
    actusUrl: "https://www.varilhes.fr/actualites/",
  },
  {
    ville: "Mirepoix",
    strategy: "html-article",
    baseUrl: "https://www.mirepoix.fr",
    actusUrl: "https://www.mirepoix.fr/actualites/",
  },

  // ── Lot ──
  {
    ville: "Cahors",
    strategy: "drupal",
    baseUrl: "https://www.cahorsagglo.fr",
    actusUrl: "https://www.cahorsagglo.fr/actualites",
    agendaUrl: "https://www.cahorsagglo.fr/agenda",
  },
  {
    ville: "Figeac",
    strategy: "html-article",
    baseUrl: "https://www.ville-figeac.fr",
    actusUrl: "https://www.ville-figeac.fr/actualites/",
  },
  {
    ville: "Gourdon",
    strategy: "html-article",
    baseUrl: "https://www.gourdon.fr",
    actusUrl: "https://www.gourdon.fr/actualites/",
  },
  {
    ville: "Souillac",
    strategy: "html-article",
    baseUrl: "https://www.souillac.fr",
    actusUrl: "https://www.souillac.fr/actualites/",
  },
  {
    ville: "Saint-Céré",
    strategy: "html-article",
    baseUrl: "https://www.saint-cere.fr",
    actusUrl: "https://www.saint-cere.fr/actualites/",
  },
  {
    ville: "Gramat",
    strategy: "html-article",
    baseUrl: "https://www.gramat.fr",
    actusUrl: "https://www.gramat.fr/actualites/",
  },

  // ── Lot-et-Garonne ──
  {
    ville: "Agen",
    strategy: "typo3",
    baseUrl: "https://www.agen.fr",
    actusUrl: "https://www.agen.fr/en-ce-moment/actualites",
    agendaUrl: "https://www.agen.fr/en-ce-moment/agenda",
  },
  {
    ville: "Villeneuve-sur-Lot",
    strategy: "html-article",
    baseUrl: "https://www.ville-villeneuve-sur-lot.fr",
    actusUrl: "https://www.ville-villeneuve-sur-lot.fr/actualites/",
  },
  {
    ville: "Marmande",
    strategy: "html-article",
    baseUrl: "https://www.mairie-marmande.fr",
    actusUrl: "https://www.mairie-marmande.fr/actualites/",
  },
  {
    ville: "Tonneins",
    strategy: "html-article",
    baseUrl: "https://www.tonneins.fr",
    actusUrl: "https://www.tonneins.fr/actualites/",
  },

  // ── Autres ──
  {
    ville: "Tarbes",
    strategy: "wp-api",
    baseUrl: "https://www.tarbes.fr",
    wpActusEndpoint: "/wp-json/wp/v2/actualite?per_page=20&_fields=title,link,excerpt,date,_links&_embed",
  },
  {
    ville: "Lourdes",
    strategy: "html-article",
    baseUrl: "https://www.lourdes.fr",
    actusUrl: "https://www.lourdes.fr/actualites/",
  },
  {
    ville: "Bagnères-de-Bigorre",
    strategy: "html-article",
    baseUrl: "https://www.mairie-bagneres-de-bigorre.fr",
    actusUrl: "https://www.mairie-bagneres-de-bigorre.fr/actualites/",
  },
  {
    ville: "Decazeville",
    strategy: "html-article",
    baseUrl: "https://www.decazeville.fr",
    actusUrl: "https://www.decazeville.fr/actualites/",
  },
  {
    ville: "Villefranche-de-Rouergue",
    strategy: "html-article",
    baseUrl: "https://www.villefranchederouergue.fr",
    actusUrl: "https://www.villefranchederouergue.fr/actualites/",
  },
  {
    ville: "Rodez",
    strategy: "html-article",
    baseUrl: "https://www.ville-rodez.fr",
    actusUrl: "https://www.ville-rodez.fr/actualites/",
  },
  {
    ville: "Espalion",
    strategy: "html-article",
    baseUrl: "https://www.espalion.fr",
    actusUrl: "https://www.espalion.fr/actualites/",
  },
  {
    ville: "Millau",
    strategy: "html-article",
    baseUrl: "https://www.millau.fr",
    actusUrl: "https://www.millau.fr/actualites/",
  },
  {
    ville: "Lombez",
    strategy: "html-article",
    baseUrl: "https://www.lombez.fr",
    actusUrl: "https://www.lombez.fr/actualites/",
  },
  {
    ville: "Samatan",
    strategy: "html-article",
    baseUrl: "https://www.samatan.fr",
    actusUrl: "https://www.samatan.fr/actualites/",
  },
  {
    ville: "Beaumont-de-Lomagne",
    strategy: "html-article",
    baseUrl: "https://www.beaumont-de-lomagne.fr",
    actusUrl: "https://www.beaumont-de-lomagne.fr/actualites/",
  },
  {
    ville: "Valence-d'Agen",
    strategy: "html-article",
    baseUrl: "https://www.mairie-valence-agen.fr",
    actusUrl: "https://www.mairie-valence-agen.fr/actualites/",
  },
];
