class HitchTrackerUserModel {
  String userName;
  String userID;
  String profilePicture;
  String bio;
  int hitchesCount;

  HitchTrackerUserModel({
    required this.userName,
    required this.userID,
    required this.profilePicture,
    required this.bio,
    required this.hitchesCount,
  });

  // Convert a UserModel instance into a map
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userID': userID,
      'profilePicture': profilePicture,
      'bio': bio,
      'hitchesCount': hitchesCount,
    };
  }

  // Create a UserModel instance from a map
  factory HitchTrackerUserModel.fromMap(Map<String, dynamic> map) {
    return HitchTrackerUserModel(
      userName: map['userName'],
      userID: map['userID'],
      profilePicture: map['profilePicture'],
      bio: map['bio'],
      hitchesCount: map['hitchesCount'],
    );
  }
}