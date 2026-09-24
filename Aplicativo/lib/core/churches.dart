class MassSchedule {
  const MassSchedule({required this.label, required this.times});

  final String label;
  final List<String> times;

  factory MassSchedule.fromJson(Map<String, dynamic> json) => MassSchedule(
    label: (json['label'] as String?)?.trim() ?? '',
    times: List.unmodifiable(
      ((json['times'] as List?) ?? const []).map((time) => time.toString()),
    ),
  );
}

class SupportingChurch {
  const SupportingChurch({
    required this.id,
    required this.name,
    this.parish = '',
    this.diocese = '',
    this.address = '',
    this.city = '',
    this.state = '',
    this.phone = '',
    this.website = '',
    this.instagram = '',
    this.imageUrl,
    this.description = '',
    this.massSchedules = const [],
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String parish;
  final String diocese;
  final String address;
  final String city;
  final String state;
  final String phone;
  final String website;
  final String instagram;
  final String? imageUrl;
  final String description;
  final List<MassSchedule> massSchedules;
  final double? latitude;
  final double? longitude;

  String get location =>
      [city, state].where((part) => part.isNotEmpty).join(' - ');

  factory SupportingChurch.fromJson(Map<String, dynamic> json) {
    String text(String key) => (json[key] as String?)?.trim() ?? '';
    final image = text('imageUrl');
    return SupportingChurch(
      id: json['id'].toString(),
      name: text('name'),
      parish: text('parish'),
      diocese: text('diocese'),
      address: text('address'),
      city: text('city'),
      state: text('state'),
      phone: text('phone'),
      website: text('website'),
      instagram: text('instagram'),
      imageUrl: image.isEmpty ? null : image,
      description: text('description'),
      massSchedules: List.unmodifiable(
        ((json['massSchedules'] as List?) ?? const []).map(
          (item) => MassSchedule.fromJson(item as Map<String, dynamic>),
        ),
      ),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Origem das igrejas apoiadoras. Pode ser trocada por API, banco ou backend
/// próprio sem alterar as telas.
abstract class ChurchRepository {
  Future<List<SupportingChurch>> churches();
}

/// Enquanto nenhuma comunidade for cadastrada, a lista fica vazia.
class EmptyChurchRepository implements ChurchRepository {
  const EmptyChurchRepository();

  @override
  Future<List<SupportingChurch>> churches() async => const [];
}
