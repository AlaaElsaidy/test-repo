class Doctor {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final String photoUrl;
  final String phone;
  final int years;

  const Doctor(
      {required this.id,
      required this.name,
      required this.specialty,
      required this.rating,
      required this.years,
      required this.phone,
      required this.photoUrl});

  const Doctor.empty()
      : id = '',
        name = '',
        specialty = '',
        rating = 0,
        years = 0,
        phone = '',
        photoUrl = "";

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      phone: json['phone'] ?? "",
      photoUrl: json['photo'] ?? "",
      rating: (json['rating'] ?? 0).toDouble(),
      years: json['years'] ?? 0,
    );
  }
}
