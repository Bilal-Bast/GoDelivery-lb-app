import 'city.dart';

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
    final names = json['district'] is Map
        ? Map<String, dynamic>.from(json['district'] as Map)
        : <String, dynamic>{};
    final districtId = json['id']?.toString() ?? '';
    return District(
      id: districtId,
      nameEn: names['en']?.toString() ?? json['nameEn']?.toString() ?? '',
      nameAr: names['ar']?.toString() ?? json['nameAr']?.toString() ?? '',
      cities: (json['cities'] as List?)
              ?.whereType<Map>()
              .map((city) => City.fromJson(
                    Map<String, dynamic>.from(city),
                    districtId: districtId,
                  ))
              .toList() ??
          [],
    );
  }
}
