class UserByStateModel {
  final String state;
  final String stateShortName;
  final int totalUsers;

  UserByStateModel({required this.state, required this.stateShortName, required this.totalUsers});

  // Convert UploadedFileModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'state': state,
      'stateShortName': stateShortName,
      'totalUsers': totalUsers,

    };
  }

  // Create UploadedFileModel from a Map
  factory UserByStateModel.fromMap(Map<String, dynamic> map) {
    return UserByStateModel(
      state: map['state'] as String,
      stateShortName: map['stateShortName'] as String,
      totalUsers: map['totalUsers'] as int,
    );
  }
}