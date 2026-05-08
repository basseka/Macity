/// Pseudo affichable du device courant (déterminé une fois, persistant).
/// Si null côté DB, on en attribue un au premier commentaire.
class DevicePseudonym {
  final String deviceUuid;
  final String displayName;
  final String gender;        // 'M' | 'F'
  final String? avatarUrl;

  const DevicePseudonym({
    required this.deviceUuid,
    required this.displayName,
    required this.gender,
    this.avatarUrl,
  });

  factory DevicePseudonym.fromJson(Map<String, dynamic> json) => DevicePseudonym(
        deviceUuid: json['device_uuid'] as String,
        displayName: json['display_name'] as String,
        gender: json['gender'] as String,
        avatarUrl: json['avatar_url'] as String?,
      );
}
