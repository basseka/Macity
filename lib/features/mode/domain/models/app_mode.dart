import 'package:pulz_app/features/day/data/day_category_data.dart';
import 'package:pulz_app/features/sport/data/sport_category_data.dart';
import 'package:pulz_app/features/culture/data/culture_category_data.dart';
import 'package:pulz_app/features/family/data/family_category_data.dart';
import 'package:pulz_app/features/food/data/food_category_data.dart';
import 'package:pulz_app/features/gaming/data/gaming_category_data.dart';
import 'package:pulz_app/features/night/data/night_category_data.dart';
import 'package:pulz_app/features/tourisme/data/tourisme_category_data.dart';

enum AppMode {
  day,
  sport,
  culture,
  family,
  food,
  gaming,
  night,
  tourisme;

  String get label {
    switch (this) {
      case AppMode.day:
        return 'Concerts & Spectacles';
      case AppMode.sport:
        return 'Sport & événements sportifs';
      case AppMode.culture:
        return 'Culture & Arts';
      case AppMode.family:
        return 'En Famille';
      case AppMode.food:
        return 'Food & lifestyle';
      case AppMode.gaming:
        return 'Gaming & pop culture';
      case AppMode.night:
        return 'Nuit & sorties';
      case AppMode.tourisme:
        return 'Tourisme & découvertes';
    }
  }

  String get emoji {
    switch (this) {
      case AppMode.day:
        return '☀️';
      case AppMode.sport:
        return '⚽';
      case AppMode.culture:
        return '🎨';
      case AppMode.family:
        return '👨‍👩‍👧‍👦';
      case AppMode.food:
        return '🍽️';
      case AppMode.gaming:
        return '🎮';
      case AppMode.night:
        return '🌙';
      case AppMode.tourisme:
        return '✈️';
    }
  }

  List<String> get rubrics {
    switch (this) {
      case AppMode.day:
        return DayCategoryData.subcategories.map((s) => s.label).toList();
      case AppMode.sport:
        return SportCategoryData.groups.map((g) => g.name).toList();
      case AppMode.culture:
        return CultureCategoryData.groups.map((g) => g.name).toList();
      case AppMode.family:
        return FamilyCategoryData.groups.map((g) => g.name).toList();
      case AppMode.food:
        return FoodCategoryData.groups.map((g) => g.name).toList();
      case AppMode.gaming:
        return GamingCategoryData.groups.map((g) => g.name).toList();
      case AppMode.night:
        return NightCategoryData.groups.map((g) => g.name).toList();
      case AppMode.tourisme:
        return TourismeCategoryData.groups.map((g) => g.name).toList();
    }
  }

  String get routePath => '/mode/$name';

  static AppMode fromName(String name) {
    return AppMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => AppMode.day,
    );
  }

  static const order = [AppMode.day, AppMode.sport, AppMode.culture, AppMode.family, AppMode.food, AppMode.gaming, AppMode.night, AppMode.tourisme];
}
