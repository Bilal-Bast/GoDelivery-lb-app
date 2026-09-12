class District {
  final String id;
  final String nameEn;
  final String nameAr;
  final List<City> cities;
 
  District({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.cities = const [],
  });
 
  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] ?? '',
      nameEn: json['nameEn'] ?? '',
      nameAr: json['nameAr'] ?? '',
      cities: (json['cities'] as List?)?.map((c) => City.fromJson(c)).toList() ?? [],
    );
  }
}