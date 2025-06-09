import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String userType;
  final Timestamp createdAt;
  final bool isVerified;
  final int? age;
  final String? gender;
  final String availabilityStatus;
  final String? profileImage;
  final double? rating;
  final String? phoneNumber;
  final int? deliveriesCount;
  final Map<String, String>? attendanceRecords;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.userType,
    required this.createdAt,
    required this.isVerified,
    this.age,
    this.gender,
    this.availabilityStatus = 'offline',
    this.profileImage,
    this.rating,
    this.phoneNumber,
    this.deliveriesCount,
    this.attendanceRecords,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'userType': userType,
      'createdAt': createdAt,
      'isVerified': isVerified,
      'age': age,
      'gender': gender,
      'availabilityStatus': availabilityStatus,
      'profileImage': profileImage,
      'rating': rating,
      'phoneNumber': phoneNumber,
      'deliveriesCount': deliveriesCount,
      'attendanceRecords': attendanceRecords,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      userType: map['userType'] as String? ?? '',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      isVerified: map['isVerified'] as bool? ?? false,
      age: map['age'] as int?,
      gender: map['gender'] as String?,
      availabilityStatus: map['availabilityStatus'] as String? ?? 'offline',
      profileImage: map['profileImage'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      phoneNumber: map['phoneNumber'] as String?,
      deliveriesCount: map['deliveriesCount'] as int?,
      attendanceRecords: map['attendanceRecords'] != null
          ? Map<String, String>.from(map['attendanceRecords'])
          : null,
    );
  }
}
