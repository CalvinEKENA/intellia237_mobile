import '../../../core/api/firestore_rest_client.dart';

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

  factory EstablishmentModel.fromFirestore(FirestoreDocument doc) {
    return EstablishmentModel(
      id: doc.id,
      name: doc['name'] as String? ?? 'Établissement sans nom',
      code: doc['code'] as String? ?? doc.id,
      city: doc['city'] as String? ?? 'Non renseignée',
      address: doc['address'] as String? ?? '',
      phone: doc['phone'] as String? ?? '',
      email: doc['email'] as String? ?? '',
      active: doc['active'] as bool? ?? true,
      studentCount: (doc['studentCount'] as num?)?.toInt() ?? 0,
      classCount: (doc['classCount'] as num?)?.toInt() ?? 0,
      staffCount: (doc['staffCount'] as num?)?.toInt() ?? 0,
      hasMobileMoneyOffer: doc['hasMobileMoneyOffer'] as bool? ?? false,
      hasStudyReservePlan: doc['hasStudyReservePlan'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'code': code,
      'city': city,
      'address': address,
      'phone': phone,
      'email': email,
      'active': active,
      'studentCount': studentCount,
      'classCount': classCount,
      'staffCount': staffCount,
      'hasMobileMoneyOffer': hasMobileMoneyOffer,
      'hasStudyReservePlan': hasStudyReservePlan,
    };
  }

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

  factory SchoolClassModel.fromFirestore(FirestoreDocument doc) {
    return SchoolClassModel(
      id: doc.id,
      establishmentId: doc['establishmentId'] as String? ?? '',
      name: doc['name'] as String? ?? doc.id,
      levelLabel: doc['levelLabel'] as String? ?? doc['classLevel'] as String? ?? '',
      series: doc['series'] as String?,
      studentCount: (doc['studentCount'] as num?)?.toInt() ?? 0,
      teacherCount: (doc['teacherCount'] as num?)?.toInt() ?? 0,
      mainTeacherName: doc['mainTeacherName'] as String?,
    );
  }
}
