class DriverModel {
  final String appToken;
  final int driverID;
  final String fullName;
  final String contactNo;
  final String emailAddress;
  final String imageUrl;
  final String loginTime;

  DriverModel({
    required this.appToken,
    required this.driverID,
    required this.fullName,
    required this.contactNo,
    required this.emailAddress,
    required this.imageUrl,
    required this.loginTime,
  });

  // Factory constructor to create DriverModel from JSON
  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      appToken: json['AppToken'] ?? '',
      driverID: json['DriverID'] ?? 0,
      fullName: json['FullName'] ?? '',
      contactNo: json['ContactNo'] ?? '',
      emailAddress: json['EmailAddress'] ?? '',
      imageUrl: json['ImageUrl'] ?? '',
      loginTime: json['LoginTime'] ?? '',
    );
  }

  // Convert DriverModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'AppToken': appToken,
      'DriverID': driverID,
      'FullName': fullName,
      'ContactNo': contactNo,
      'EmailAddress': emailAddress,
      'ImageUrl': imageUrl,
      'LoginTime': loginTime,
    };
  }

  // Create a copy of DriverModel with updated fields
  DriverModel copyWith({
    String? appToken,
    int? driverID,
    String? fullName,
    String? contactNo,
    String? emailAddress,
    String? imageUrl,
    String? loginTime,
  }) {
    return DriverModel(
      appToken: appToken ?? this.appToken,
      driverID: driverID ?? this.driverID,
      fullName: fullName ?? this.fullName,
      contactNo: contactNo ?? this.contactNo,
      emailAddress: emailAddress ?? this.emailAddress,
      imageUrl: imageUrl ?? this.imageUrl,
      loginTime: loginTime ?? this.loginTime,
    );
  }
}
