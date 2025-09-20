class AcceptedHitchUserModel {
  String userName;
  String userID;
  String profilePicture;
  String bio;
  int acceptedHitchCount;

  AcceptedHitchUserModel({
    required this.userName,
    required this.userID,
    required this.profilePicture,
    required this.bio,
    required this.acceptedHitchCount,
  });

  // Convert an AcceptedHitchUserModel instance into a map
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userID': userID,
      'profilePicture': profilePicture,
      'bio': bio,
      'acceptedHitchCount': acceptedHitchCount,
    };
  }

  // Create an AcceptedHitchUserModel instance from a map
  factory AcceptedHitchUserModel.fromMap(Map<String, dynamic> map) {
    return AcceptedHitchUserModel(
      userName: map['userName'] ?? '',
      userID: map['userID'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
      bio: map['bio'] ?? '',
      acceptedHitchCount: map['acceptedHitchCount'] ?? 0,
    );
  }
}
