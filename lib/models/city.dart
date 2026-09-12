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
 
  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] ?? '',
      nameEn: json['nameEn'] ?? '',
      nameAr: json['nameAr'] ?? '',
      districtId: json['districtId'] ?? '',
    );
  }
}
