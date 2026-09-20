class City {
  final String id;
  final String nameEn;
  final String nameAr;
  final String districtId;

  City({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.districtId,
  });

  factory City.fromJson(
    Map<String, dynamic> json, {
    String districtId = '',
  }) {
    final nameEn = json['en']?.toString() ?? json['nameEn']?.toString() ?? '';
    return City(
      id: json['id']?.toString() ?? '$districtId:$nameEn',
      nameEn: nameEn,
      nameAr: json['ar']?.toString() ?? json['nameAr']?.toString() ?? '',
      districtId: json['districtId']?.toString() ?? districtId,
    );
  }
}
