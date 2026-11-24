/// Contact and consent information, plus saved fit measurements.
class ProfileData {
  const ProfileData({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.privacyConsentAt,
    this.measurements,
  });

  factory ProfileData.fromRows({
    required String id,
    required String? email,
    required Map<String, dynamic> profile,
    required Map<String, dynamic>? measurements,
  }) {
    return ProfileData(
      id: id,
      fullName: profile['full_name'] as String? ?? '',
      email: email ?? '',
      phone: profile['phone'] as String?,
      privacyConsentAt: profile['privacy_consent_at'] == null
          ? null
          : DateTime.parse(profile['privacy_consent_at'].toString()),
      measurements: measurements == null
          ? null
          : ProfileMeasurements.fromMap(measurements),
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final DateTime? privacyConsentAt;
  final ProfileMeasurements? measurements;

  bool get hasPrivacyConsent => privacyConsentAt != null;
}

/// Edited contact values returned by the profile form.
class ProfileContactUpdate {
  const ProfileContactUpdate({required this.fullName, this.phone});

  final String fullName;
  final String? phone;
}

/// One customer's saved body measurements, all in inches.
class ProfileMeasurements {
  const ProfileMeasurements({
    this.chest,
    this.waist,
    this.hips,
    this.shoulder,
    this.height,
    this.inseam,
    this.notes,
    this.consentAt,
    this.updatedAt,
  });

  factory ProfileMeasurements.fromMap(Map<String, dynamic> map) {
    double? number(String key) => (map[key] as num?)?.toDouble();

    DateTime? date(String key) =>
        map[key] == null ? null : DateTime.parse(map[key].toString());

    return ProfileMeasurements(
      chest: number('chest'),
      waist: number('waist'),
      hips: number('hips'),
      shoulder: number('shoulder'),
      height: number('height'),
      inseam: number('inseam'),
      notes: map['notes'] as String?,
      consentAt: date('consent_at'),
      updatedAt: date('updated_at'),
    );
  }

  final double? chest;
  final double? waist;
  final double? hips;
  final double? shoulder;
  final double? height;
  final double? inseam;
  final String? notes;
  final DateTime? consentAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
    'chest': chest,
    'waist': waist,
    'hips': hips,
    'shoulder': shoulder,
    'height': height,
    'inseam': inseam,
    'notes': notes,
  };

  bool get hasValues =>
      chest != null ||
      waist != null ||
      hips != null ||
      shoulder != null ||
      height != null ||
      inseam != null;
}
