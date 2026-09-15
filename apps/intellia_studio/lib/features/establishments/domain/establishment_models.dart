class EstablishmentModel {
  const EstablishmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.city,
    required this.address,
    required this.phone,
    required this.email,
    required this.active,
    required this.studentCount,
    required this.classCount,
    required this.staffCount,
    this.hasMobileMoneyOffer = false,
    this.hasStudyReservePlan = false,
  });

  final String id;
  final String name;
  final String code;
  final String city;
  final String address;
  final String phone;
  final String email;
  final bool active;
  final int studentCount;
  final int classCount;
  final int staffCount;
  final bool hasMobileMoneyOffer;
  final bool hasStudyReservePlan;

  EstablishmentModel copyWith({bool? active}) {
    return EstablishmentModel(
      id: id,
      name: name,
      code: code,
      city: city,
      address: address,
      phone: phone,
      email: email,
      active: active ?? this.active,
      studentCount: studentCount,
      classCount: classCount,
      staffCount: staffCount,
      hasMobileMoneyOffer: hasMobileMoneyOffer,
      hasStudyReservePlan: hasStudyReservePlan,
    );
  }
}

class SchoolClassModel {
  const SchoolClassModel({
    required this.id,
    required this.establishmentId,
    required this.name,
    required this.levelLabel,
    this.series,
    required this.studentCount,
    required this.teacherCount,
    this.mainTeacherName,
  });

  final String id;
  final String establishmentId;
  final String name;
  final String levelLabel;
  final String? series;
  final int studentCount;
  final int teacherCount;
  final String? mainTeacherName;

  bool get isEmpty => studentCount == 0;
}
