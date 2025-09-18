class CoachExperienceModel{
  String experienceInYears;
  String gameTitle;

  CoachExperienceModel({
    required this.experienceInYears,
    required this.gameTitle,
  });

  // Convert a Level object to a Map
  Map<String, dynamic> toMap() {
    return {
      'experienceInYears': experienceInYears,
      'gameTitle': gameTitle,
    };
  }

  // Create a Level object from a Map
  factory CoachExperienceModel.fromMap(Map<String, dynamic> map) {
    return CoachExperienceModel(
      experienceInYears: map['experienceInYears'] ?? '',
      gameTitle: map['gameTitle'] ?? '',
    );
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is CoachExperienceModel &&
              runtimeType == other.runtimeType &&
              gameTitle == other.gameTitle &&
              experienceInYears == other.experienceInYears;

  @override
  int get hashCode => gameTitle.hashCode ^ experienceInYears.hashCode;
}