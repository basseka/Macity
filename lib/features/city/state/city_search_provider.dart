import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulz_app/features/city/domain/models/ville.dart';

final citySearchQueryProvider = StateProvider<String>((ref) => '');

const _availableCities = [
  VilleModel(nom: 'Aix-en-Provence', codePostal: '13100', departement: 'Bouches-du-Rhone', population: 145133),
  VilleModel(nom: 'Amiens', codePostal: '80000', departement: 'Somme', population: 134706),
  VilleModel(nom: 'Angers', codePostal: '49000', departement: 'Maine-et-Loire', population: 157175),
  VilleModel(nom: 'Annecy', codePostal: '74000', departement: 'Haute-Savoie', population: 130721),
  VilleModel(nom: 'Avignon', codePostal: '84000', departement: 'Vaucluse', population: 93671),
  VilleModel(nom: 'Bayonne', codePostal: '64100', departement: 'Pyrenees-Atlantiques', population: 52006),
  VilleModel(nom: 'Besancon', codePostal: '25000', departement: 'Doubs', population: 120271),
  VilleModel(nom: 'Blois', codePostal: '41000', departement: 'Loir-et-Cher', population: 47009),
  VilleModel(nom: 'Bordeaux', codePostal: '33000', departement: 'Gironde', population: 260958),
  VilleModel(nom: 'Brest', codePostal: '29200', departement: 'Finistere', population: 142722),
  VilleModel(nom: 'Carcassonne', codePostal: '11000', departement: 'Aude', population: 47068),
  VilleModel(nom: 'Chartres', codePostal: '28000', departement: 'Eure-et-Loir', population: 39273),
  VilleModel(nom: 'Clermont-Ferrand', codePostal: '63000', departement: 'Puy-de-Dome', population: 147284),
  VilleModel(nom: 'Colmar', codePostal: '68000', departement: 'Haut-Rhin', population: 70284),
  VilleModel(nom: 'Dijon', codePostal: '21000', departement: 'Cote-d\'Or', population: 160106),
  VilleModel(nom: 'Geneve', codePostal: '1200', departement: 'Suisse', population: 203856),
  VilleModel(nom: 'Grenoble', codePostal: '38000', departement: 'Isere', population: 158198),
  VilleModel(nom: 'Le Havre', codePostal: '76600', departement: 'Seine-Maritime', population: 169733),
  VilleModel(nom: 'Le Mans', codePostal: '72000', departement: 'Sarthe', population: 146105),
  VilleModel(nom: 'Lille', codePostal: '59000', departement: 'Nord', population: 236234),
  VilleModel(nom: 'Lyon', codePostal: '69000', departement: 'Rhone', population: 522228),
  VilleModel(nom: 'Marseille', codePostal: '13000', departement: 'Bouches-du-Rhone', population: 873076),
  VilleModel(nom: 'Metz', codePostal: '57000', departement: 'Moselle', population: 120205),
  VilleModel(nom: 'Montpellier', codePostal: '34000', departement: 'Herault', population: 299096),
  VilleModel(nom: 'Nancy', codePostal: '54000', departement: 'Meurthe-et-Moselle', population: 105058),
  VilleModel(nom: 'Nantes', codePostal: '44000', departement: 'Loire-Atlantique', population: 320732),
  VilleModel(nom: 'Nice', codePostal: '06000', departement: 'Alpes-Maritimes', population: 342669),
  VilleModel(nom: 'Nimes', codePostal: '30000', departement: 'Gard', population: 151001),
  VilleModel(nom: 'Paris', codePostal: '75000', departement: 'Paris', population: 2145906),
  VilleModel(nom: 'Reims', codePostal: '51100', departement: 'Marne', population: 187206),
  VilleModel(nom: 'Rennes', codePostal: '35000', departement: 'Ille-et-Vilaine', population: 222485),
  VilleModel(nom: 'Rouen', codePostal: '76000', departement: 'Seine-Maritime', population: 114007),
  VilleModel(nom: 'Saint-Etienne', codePostal: '42000', departement: 'Loire', population: 174082),
  VilleModel(nom: 'Strasbourg', codePostal: '67000', departement: 'Bas-Rhin', population: 290576),
  VilleModel(nom: 'Toulon', codePostal: '83000', departement: 'Var', population: 178745),
  VilleModel(nom: 'Toulouse', codePostal: '31000', departement: 'Haute-Garonne', population: 504078),
];

final citySearchResultsProvider = FutureProvider<List<VilleModel>>((ref) async {
  final query = ref.watch(citySearchQueryProvider).toLowerCase();
  if (query.isEmpty) return _availableCities;

  return _availableCities
      .where((v) => v.nom.toLowerCase().contains(query))
      .toList();
});
