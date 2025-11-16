class PatientModel {
  String patientId;
  int age;
  String name;
  String gender;
  String stage;
  String homeAddress;
  String? phoneEmergency;
  double latitude;
  double longitude;
  String? photoUrl;

  PatientModel(
      {required this.patientId,
      required this.age,
      required this.name,
      required this.gender,
      this.stage = "Early",
      required this.homeAddress,
      this.phoneEmergency,
      required this.latitude,
      required this.longitude,
      this.photoUrl});
}
