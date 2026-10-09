import '../../../core/exchange/exchange_payload.dart';

/// Modèle métier du profil professionnel, indépendant de la couche de stockage.
/// Voir docs/DATA_MODEL.md pour la définition complète des champs.
class Profile {
  final String id;
  final String fullName;
  final String jobTitle;
  final String company;
  final String phone;
  final String email;
  final String? website;
  final String? address;
  final String? linkedin;
  final String? whatsapp;
  final String? logoPath;
  final String? logoIcon;
  final String? photoPath;
  final int templateId;
  final String accentColor;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.fullName,
    required this.jobTitle,
    required this.company,
    required this.phone,
    required this.email,
    this.website,
    this.address,
    this.linkedin,
    this.whatsapp,
    this.logoPath,
    this.logoIcon,
    this.photoPath,
    required this.templateId,
    required this.accentColor,
    required this.createdAt,
    required this.updatedAt,
  });

  Profile copyWith({
    String? fullName,
    String? jobTitle,
    String? company,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? linkedin,
    String? whatsapp,
    bool clearWhatsapp = false,
    String? logoPath,
    String? logoIcon,
    bool clearLogoIcon = false,
    String? photoPath,
    int? templateId,
    String? accentColor,
  }) {
    return Profile(
      id: id,
      fullName: fullName ?? this.fullName,
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      linkedin: linkedin ?? this.linkedin,
      whatsapp: clearWhatsapp ? null : whatsapp ?? this.whatsapp,
      logoPath: logoPath ?? this.logoPath,
      logoIcon: clearLogoIcon ? null : logoIcon ?? this.logoIcon,
      photoPath: photoPath ?? this.photoPath,
      templateId: templateId ?? this.templateId,
      accentColor: accentColor ?? this.accentColor,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

extension ProfileExchange on Profile {
  ExchangePayload toExchangePayload() => ExchangePayload(
    fullName: fullName,
    jobTitle: jobTitle,
    company: company,
    phone: phone,
    email: email,
    website: website,
    linkedin: linkedin,
    whatsapp: whatsapp,
  );
}
