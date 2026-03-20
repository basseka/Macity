// Configuration des 24 villes hub avec leurs coordonnées et métadonnées.
// Utilisé par les sources communes (Ticketmaster, Festik) pour filtrer par ville.

export interface CityConfig {
  nom: string;
  lat: number;
  lng: number;
  radius: number; // km pour Ticketmaster
  codePostal: number;
  // Noms variantes pour matcher dans Festik/JSON-LD
  aliases: string[];
  // URL OpenDataSoft si la ville a un portail open data
  odsBase?: string;
  odsDataset?: string;
}

export const CITIES: Record<string, CityConfig> = {
  toulouse: {
    nom: "Toulouse",
    lat: 43.6047,
    lng: 1.4442,
    radius: 25,
    codePostal: 31000,
    aliases: [
      "toulouse", "ramonville", "ramonville-saint-agne", "balma", "colomiers",
      "blagnac", "tournefeuille", "labege", "castanet-tolosan", "saint-orens",
      "l'union", "aucamville", "fenouillet", "cugnaux", "portet-sur-garonne",
      "muret", "plaisance-du-touch", "bruguieres", "cornebarrieu", "pibrac",
    ],
    odsBase: "https://data.toulouse-metropole.fr/api/explore/v2.1/catalog/datasets/agenda-des-manifestations-culturelles-so-toulouse/records",
  },
  lyon: {
    nom: "Lyon",
    lat: 45.764,
    lng: 4.8357,
    radius: 20,
    codePostal: 69000,
    aliases: ["lyon", "villeurbanne", "caluire-et-cuire", "vénissieux", "bron", "vaulx-en-velin"],
    odsBase: "https://data.grandlyon.com/api/explore/v2.1/catalog/datasets/eve_grevene.evenement_csl_eve_grandlyon/records",
  },
  paris: {
    nom: "Paris",
    lat: 48.8566,
    lng: 2.3522,
    radius: 15,
    codePostal: 75000,
    aliases: ["paris", "boulogne-billancourt", "saint-denis", "montreuil", "nanterre"],
    odsBase: "https://opendata.paris.fr/api/explore/v2.1/catalog/datasets/que-faire-a-paris-/records",
  },
  marseille: {
    nom: "Marseille",
    lat: 43.2965,
    lng: 5.3698,
    radius: 20,
    codePostal: 13000,
    aliases: ["marseille", "aix-en-provence", "aubagne"],
  },
  bordeaux: {
    nom: "Bordeaux",
    lat: 44.8378,
    lng: -0.5792,
    radius: 20,
    codePostal: 33000,
    aliases: ["bordeaux", "mérignac", "pessac", "talence", "bègles"],
    odsBase: "https://opendata.bordeaux-metropole.fr/api/explore/v2.1/catalog/datasets/met_agenda/records",
  },
  lille: {
    nom: "Lille",
    lat: 50.6292,
    lng: 3.0573,
    radius: 20,
    codePostal: 59000,
    aliases: ["lille", "roubaix", "tourcoing", "villeneuve-d'ascq"],
  },
  nice: {
    nom: "Nice",
    lat: 43.7102,
    lng: 7.262,
    radius: 20,
    codePostal: 6000,
    aliases: ["nice", "cannes", "antibes", "grasse"],
  },
  nantes: {
    nom: "Nantes",
    lat: 47.2184,
    lng: -1.5536,
    radius: 20,
    codePostal: 44000,
    aliases: ["nantes", "saint-herblain", "rezé", "saint-nazaire"],
    odsBase: "https://data.nantesmetropole.fr/api/explore/v2.1/catalog/datasets/244400404_agenda-evenements-nantes-metropole/records",
  },
  montpellier: {
    nom: "Montpellier",
    lat: 43.6108,
    lng: 3.8767,
    radius: 20,
    codePostal: 34000,
    aliases: ["montpellier", "castelnau-le-lez", "lattes", "mauguio"],
  },
  strasbourg: {
    nom: "Strasbourg",
    lat: 48.5734,
    lng: 7.7521,
    radius: 20,
    codePostal: 67000,
    aliases: ["strasbourg", "schiltigheim", "illkirch-graffenstaden"],
  },
  rennes: {
    nom: "Rennes",
    lat: 48.1173,
    lng: -1.6778,
    radius: 20,
    codePostal: 35000,
    aliases: ["rennes", "cesson-sévigné", "bruz"],
  },
  "aix-en-provence": {
    nom: "Aix-en-Provence",
    lat: 43.5297,
    lng: 5.4474,
    radius: 15,
    codePostal: 13100,
    aliases: ["aix-en-provence", "aix en provence"],
  },
  angers: {
    nom: "Angers",
    lat: 47.4784,
    lng: -0.5632,
    radius: 15,
    codePostal: 49000,
    aliases: ["angers", "avrillé", "trélazé"],
  },
  brest: {
    nom: "Brest",
    lat: 48.3904,
    lng: -4.4861,
    radius: 15,
    codePostal: 29200,
    aliases: ["brest", "plouzané", "guipavas"],
  },
  "clermont-ferrand": {
    nom: "Clermont-Ferrand",
    lat: 45.7772,
    lng: 3.087,
    radius: 15,
    codePostal: 63000,
    aliases: ["clermont-ferrand", "chamalières", "aubière"],
  },
  dijon: {
    nom: "Dijon",
    lat: 47.322,
    lng: 5.0415,
    radius: 15,
    codePostal: 21000,
    aliases: ["dijon", "chenôve", "talant"],
  },
  grenoble: {
    nom: "Grenoble",
    lat: 45.1885,
    lng: 5.7245,
    radius: 15,
    codePostal: 38000,
    aliases: ["grenoble", "échirolles", "saint-martin-d'hères"],
  },
  "le-havre": {
    nom: "Le Havre",
    lat: 49.4944,
    lng: 0.1079,
    radius: 15,
    codePostal: 76600,
    aliases: ["le havre", "le-havre"],
  },
  "le-mans": {
    nom: "Le Mans",
    lat: 48.0061,
    lng: 0.1996,
    radius: 15,
    codePostal: 72000,
    aliases: ["le mans", "le-mans", "allonnes"],
  },
  nimes: {
    nom: "Nîmes",
    lat: 43.8367,
    lng: 4.3601,
    radius: 15,
    codePostal: 30000,
    aliases: ["nîmes", "nimes"],
  },
  reims: {
    nom: "Reims",
    lat: 49.2583,
    lng: 4.0317,
    radius: 15,
    codePostal: 51100,
    aliases: ["reims", "tinqueux", "bétheny"],
  },
  "saint-denis": {
    nom: "Saint-Denis",
    lat: 48.9362,
    lng: 2.3575,
    radius: 10,
    codePostal: 93200,
    aliases: ["saint-denis"],
  },
  "saint-etienne": {
    nom: "Saint-Étienne",
    lat: 45.4397,
    lng: 4.3872,
    radius: 15,
    codePostal: 42000,
    aliases: ["saint-étienne", "saint-etienne"],
  },
  toulon: {
    nom: "Toulon",
    lat: 43.1242,
    lng: 5.928,
    radius: 15,
    codePostal: 83000,
    aliases: ["toulon", "la seyne-sur-mer", "hyères"],
  },
};

/** Resolve a city key from a free-text city name. */
export function resolveCityKey(input: string): string | null {
  const lower = input.toLowerCase().trim();
  for (const [key, config] of Object.entries(CITIES)) {
    if (key === lower || config.nom.toLowerCase() === lower) return key;
    if (config.aliases.some(a => a === lower)) return key;
  }
  return null;
}
