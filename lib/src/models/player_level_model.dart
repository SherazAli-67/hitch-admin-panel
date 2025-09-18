class PlayerLevelModel{
  String levelRank;
  String levelTitle;

  PlayerLevelModel({
    required this.levelRank,
    required this.levelTitle,
  });

  // Convert a Level object to a Map
  Map<String, dynamic> toMap() {
    return {
      'levelRank': levelRank,
      'levelTitle': levelTitle,
    };
  }

  // Create a Level object from a Map
  factory PlayerLevelModel.fromMap(Map<String, dynamic> map) {
    return PlayerLevelModel(
      levelRank: map['levelRank'] ?? '',
      levelTitle: map['levelTitle'] ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PlayerLevelModel &&
              runtimeType == other.runtimeType &&
              levelRank == other.levelRank &&
              levelTitle == other.levelTitle;

  @override
  int get hashCode => levelRank.hashCode ^ levelTitle.hashCode;
}