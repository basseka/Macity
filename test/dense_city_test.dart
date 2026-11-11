import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulz_app/core/network/dense_city.dart';
import 'package:pulz_app/features/city/data/city_coordinates.dart';

RequestOptions _req(String path, Map<String, dynamic> qp, {String method = 'GET'}) =>
    RequestOptions(path: path, queryParameters: qp, method: method);

void main() {
  test('Paris : liste Food bornée autour de la zone courante', () {
    CityCoordinates.registerArea('Paris', 48.86, 2.34, 'Paris');
    final o = _req('etablissements', {'ville': 'ilike.Paris', 'rubrique': 'eq.food'});
    DenseCity.apply(o);
    expect(o.queryParameters['and'], startsWith('(latitude.gte.48.84'));
  });

  test('venues avec ilike.Paris* aussi', () {
    CityCoordinates.registerArea('Paris', 48.86, 2.34, 'Paris');
    final o = _req('venues', {'ville': 'ilike.Paris*', 'mode': 'eq.night'});
    DenseCity.apply(o);
    expect(o.queryParameters.containsKey('and'), isTrue);
  });

  test('autres villes, recherche par nom et fiche par id inchangées', () {
    for (final qp in [
      {'ville': 'ilike.Toulouse'},
      {'ville': 'ilike.Paris', 'or': '(nom.ilike.*x*)'},
      {'ville': 'ilike.Paris', 'id': 'eq.4'},
      {'ville': 'ilike.Paris', 'and': '(latitude.gte.1)'},
    ]) {
      final o = _req('etablissements', Map.of(qp));
      DenseCity.apply(o);
      expect(o.queryParameters, qp);
    }
    final evt = _req('user_events', {'ville': 'eq.Paris'});
    DenseCity.apply(evt);
    expect(evt.queryParameters.containsKey('and'), isFalse);
  });
}
