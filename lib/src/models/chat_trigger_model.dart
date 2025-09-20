
class EmailMessageTrackerModel {
  final String trackID;
  final String triggeredByUName;
  final String triggeredByUID;
  final String triggeredForUName;
  final String triggeredForUID;
  final DateTime triggeredOn;
  final String triggeredType;

  // Constructor
  EmailMessageTrackerModel({
    required this.trackID,
    required this.triggeredByUName,
    required this.triggeredByUID,
    required this.triggeredForUName,
    required this.triggeredForUID,
    required this.triggeredOn,
    required this.triggeredType,
  });

  // Convert an instance of EmailMessageTrackerModel to a map
  Map<String, dynamic> toMap() {
    return {
      'trackID': trackID,
      'triggeredByUName': triggeredByUName,
      'triggeredByUID': triggeredByUID,
      'triggeredForUName': triggeredForUName,
      'triggeredForUID': triggeredForUID,
      'triggeredOn': triggeredOn.toIso8601String(),
      'triggeredType': triggeredType,
    };
  }

  // Create an instance of EmailMessageTrackerModel from a map
  factory EmailMessageTrackerModel.fromMap(Map<String, dynamic> map) {
    return EmailMessageTrackerModel(
      trackID: map['trackID'] ?? '',
      triggeredByUName: map['triggeredByUName'] ?? '',
      triggeredByUID: map['triggeredByUID'] ?? '',
      triggeredForUName: map['triggeredForUName'] ?? '',
      triggeredForUID: map['triggeredForUID'] ?? '',
      triggeredOn: DateTime.parse(map['triggeredOn']),
      triggeredType: map['triggeredType'] ?? '',
    );
  }
}