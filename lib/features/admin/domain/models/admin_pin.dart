import 'package:flutter/foundation.dart';

enum AdminPinType { featured, top }

extension AdminPinTypeX on AdminPinType {
  String get value => this == AdminPinType.featured ? 'featured' : 'top';
  static AdminPinType fromString(String v) =>
      v == 'featured' ? AdminPinType.featured : AdminPinType.top;
}

enum AdminPinSource { scrapedEvents, userEvents }

extension AdminPinSourceX on AdminPinSource {
  String get value =>
      this == AdminPinSource.scrapedEvents ? 'scraped_events' : 'user_events';
  static AdminPinSource fromString(String v) =>
      v == 'user_events' ? AdminPinSource.userEvents : AdminPinSource.scrapedEvents;
}

@immutable
class AdminPin {
  final String id;
  final AdminPinSource source;
  final String identifiant;
  final AdminPinType pinType;
  final DateTime pinnedUntil;
  final String? adminEmail;
  final DateTime createdAt;

  const AdminPin({
    required this.id,
    required this.source,
    required this.identifiant,
    required this.pinType,
    required this.pinnedUntil,
    required this.createdAt,
    this.adminEmail,
  });

  factory AdminPin.fromJson(Map<String, dynamic> json) => AdminPin(
        id: json['id'] as String,
        source: AdminPinSourceX.fromString(json['event_source'] as String),
        identifiant: json['event_identifiant'] as String,
        pinType: AdminPinTypeX.fromString(json['pin_type'] as String),
        pinnedUntil: DateTime.parse(json['pinned_until'] as String),
        adminEmail: json['admin_email'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isActive => pinnedUntil.isAfter(DateTime.now());
}
