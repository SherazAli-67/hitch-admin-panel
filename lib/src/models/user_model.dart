import '../res/string_constants.dart';
import 'coach_experience_model.dart';
import 'player_level_model.dart';

import 'uploaded_file_model.dart';

class UserModel {
  String userID;
  String userName;
  String profilePicture;
  bool playerTypePickle;
  bool playerTypeTennis;
  bool playerTypePadel;
  bool playerTypeCoach;
  String level;
  String bio;
  String cellNumber;
  String emailAddress;
  String? age;
  String? experience;
  double distanceFromCurrentLocation;
  final String token;
  List<String> requestSentToUserIDs;
  List<String> hiddenIds;
  List<String> requestReceivedFromUserIDs;
  String? gender;
  final bool isReviewed;
  List<String> declinedRequestsUserIDs;
  double? latitude;
  double? longitude;
  PlayerLevelModel? pickleBallPlayerLevel;
  PlayerLevelModel? tennisBallPlayerLevel;
  PlayerLevelModel? padelBallPlayerLevel;
  CoachExperienceModel? coachPickleBallExperienceLevel;
  CoachExperienceModel? coachTennisBallExperienceLevel;
  CoachExperienceModel? coachPadelBallExperienceLevel;
  List<UploadedFileModel> uploadedSportsPhotos;
  bool isAvailableDaily;
  bool isAvailableInMorning;
  String matchType;
  String genderType;
  String? myDuprID;
  bool isConnectedToDupr;
  double? duprSingleRating;
  double? duprDoubleRating;
  List<String> availableDaysToPlay;
  bool showEventsNoti = true;
  int? lastActive;
  String get lastActiveTime {
    if (lastActive == null) {
      return '';
    }
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(lastActive!);
    return dateTime.toString();
    // return timeago.format(dateTime, locale: 'en').replaceAll('about ', '');
  }

  UserModel(
      {required this.userID,
      required this.userName,
      required this.profilePicture,
      required this.playerTypePickle,
      required this.playerTypeTennis,
      required this.playerTypePadel,
      required this.playerTypeCoach,
      this.level = '',
      required this.bio,
      required this.cellNumber,
      required this.emailAddress,
      this.latitude,
      this.longitude,
      this.gender,
      this.distanceFromCurrentLocation = 10,
      this.age,
      this.token = '',
      this.experience,
      this.requestReceivedFromUserIDs = const [],
      this.hiddenIds = const [],
      this.declinedRequestsUserIDs = const [],
      this.requestSentToUserIDs = const [],
      this.coachPickleBallExperienceLevel,
      this.coachTennisBallExperienceLevel,
      this.coachPadelBallExperienceLevel,
      this.pickleBallPlayerLevel,
      this.tennisBallPlayerLevel,
      this.padelBallPlayerLevel,
      this.uploadedSportsPhotos = const [],
      this.isAvailableDaily = true,
      this.isAvailableInMorning = false,
      this.matchType = 'Both',
      this.genderType = 'Both',
      this.myDuprID,
      this.isConnectedToDupr = false,
      this.duprDoubleRating,
      this.duprSingleRating,
      required this.availableDaysToPlay,
      this.showEventsNoti = true,
      this.isReviewed = false,
      this.lastActive});

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'userName': userName,
      'profilePicture': profilePicture,
      'playerTypePickle': playerTypePickle,
      'playerTypeTennis': playerTypeTennis,
      'playerTypePadel': playerTypePadel,
      'playerTypeCoach': playerTypeCoach,
      'level': level,
      'bio': bio,
      'cellNumber': cellNumber,
      'emailAddress': emailAddress,
      'age': age,
      'experience': experience,
      'token': token,
      'distanceFromCurrentLocation': distanceFromCurrentLocation,
      'requestSentToUserIDs': requestSentToUserIDs,
      'hiddenIds': hiddenIds,
      'requestReceivedFromUserIDs': requestReceivedFromUserIDs,
      'declinedRequestsUserIDs': requestReceivedFromUserIDs,
      // 'languages' : languages,
      'latitude': latitude,
      'longitude': longitude,
      'gender': gender,
      'myDuprID': myDuprID,
      'isConnectedToDupr': isConnectedToDupr,
      'duprDoubleRating': duprDoubleRating,
      'duprSingleRating': duprSingleRating,
      'coachPickleBallExperienceLevel': coachPickleBallExperienceLevel?.toMap(),
      'coachTennisBallExperienceLevel': coachTennisBallExperienceLevel?.toMap(),
      'coachPadelBallExperienceLevel': coachPadelBallExperienceLevel?.toMap(),
      'pickleBallPlayerLevel': pickleBallPlayerLevel?.toMap(),
      'tennisBallPlayerLevel': tennisBallPlayerLevel?.toMap(),
      'padelBallPlayerLevel': padelBallPlayerLevel?.toMap(),
      'showEventsNoti': showEventsNoti,
      uploadedFilesKey: uploadedSportsPhotos
          .map((uploadedSportsPhotos) => uploadedSportsPhotos.toMap())
          .toList(),
      isAvailableDailyKey: isAvailableDaily,
      isAvailableInMorningKey: isAvailableInMorning,
      matchTypeKey: matchType,
      genderTypeKey: genderType,
      availableDaysToPlayKey: availableDaysToPlay,
      isReviewedKey: isReviewed,
      'lastActive': lastActive,
    };
  }

  // Create a UserProfile object from a map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
        userID: map['userID'],
        userName: map['userName'],
        profilePicture: map['profilePicture'],
        playerTypePickle: map['playerTypePickle'] ?? true,
        playerTypeTennis: map['playerTypeTennis'] ?? true,
        playerTypePadel: map['playerTypePadel'] ?? true,
        playerTypeCoach: map['playerTypeCoach'] ?? false,
        level: map['level'],
        bio: map['bio'],
        cellNumber: map['cellNumber'],
        emailAddress: map['emailAddress'],
        age: map['age'],
        experience: map['experience'],
        token: map['token'] ?? '',
        distanceFromCurrentLocation: map['distanceFromCurrentLocation'] > 20
            ? 20
            : map['distanceFromCurrentLocation'],
        requestSentToUserIDs:
            List<String>.from(map['requestSentToUserIDs'] ?? []),
        hiddenIds:
        List<String>.from(map['hiddenIds'] ?? []),
        declinedRequestsUserIDs:
            List<String>.from(map['declinedRequestsUserIDs'] ?? []),
        // languages: List<String>.from(map['languages'] ?? []),
        requestReceivedFromUserIDs:
            List<String>.from(map['requestReceivedFromUserIDs'] ?? []),
        latitude: map['latitude'],
        longitude: map['longitude'],
        gender: map['gender'],
        myDuprID: map['myDuprID'],
        isConnectedToDupr: map['isConnectedToDupr'] ?? false,
        duprDoubleRating: map['duprDoubleRating'],
        duprSingleRating: map['duprSingleRating'],
        coachPickleBallExperienceLevel:
            map['coachPickleBallExperienceLevel'] != null
                ? CoachExperienceModel.fromMap(
                    map['coachPickleBallExperienceLevel'])
                : null,
        coachTennisBallExperienceLevel:
            map['coachTennisBallExperienceLevel'] != null
                ? CoachExperienceModel.fromMap(
                    map['coachTennisBallExperienceLevel'])
                : null,
        coachPadelBallExperienceLevel:
        map['coachPadelBallExperienceLevel'] != null
            ? CoachExperienceModel.fromMap(
            map['coachPadelBallExperienceLevel'])
            : null,
        pickleBallPlayerLevel: map['pickleBallPlayerLevel'] != null
            ? PlayerLevelModel.fromMap(map['pickleBallPlayerLevel'])
            : null,
        tennisBallPlayerLevel: map['tennisBallPlayerLevel'] != null
            ? PlayerLevelModel.fromMap(map['tennisBallPlayerLevel'])
            : null,
        padelBallPlayerLevel: map['padelBallPlayerLevel'] != null
            ? PlayerLevelModel.fromMap(map['padelBallPlayerLevel'])
            : null,
        uploadedSportsPhotos: (map['uploadedFiles'] as List<dynamic>? ?? [])
            .map((fileMap) =>
                UploadedFileModel.fromMap(fileMap as Map<String, dynamic>))
            .toList(),
        isAvailableDaily: map[isAvailableDailyKey] ?? true,
        showEventsNoti: map['showEventsNoti'] ?? true,
        isAvailableInMorning: map[isAvailableInMorningKey] ?? false,
        matchType: map[matchTypeKey] ?? 'Both',
        genderType: map[genderTypeKey] ?? 'Both',
        isReviewed: map[isReviewedKey] ?? false,
        lastActive: map['lastActive'],
        availableDaysToPlay: List<String>.from(
          map[availableDaysToPlayKey] ?? [],
        ));
  }

  void setUserID({required String userID}) {
    this.userID = userID;
  }

  void setProfileUrl({required String profilePicture}) {
    this.profilePicture = profilePicture;
  }
}
