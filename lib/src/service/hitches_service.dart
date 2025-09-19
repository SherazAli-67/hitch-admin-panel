import 'package:cloud_firestore/cloud_firestore.dart';

class HitchesService {
  static final _fireStoreColRef = FirebaseFirestore.instance;

  static Future<int> getTotalUsersCount()async{
    final results = await _fireStoreColRef.collection('users').count().get();
    return results.count ?? 1;
  }

  static Future<int> getTotalHitchRequestCount()async{
    final results = await _fireStoreColRef.collection('hitches_tracker').doc('hitch_tracker_doc').get();
    if(results.data() != null){
      return results.data()!['totalHitchRequestsCount'];
    }

    return 1;

  }

  static Future<int> getTotalChatsCount()async{
    final results = await _fireStoreColRef.collection('chats').count().get();
    return results.count ?? 1;
  }

  static Future<int> getTotalHitchAcceptedCount()async{
    final results = await _fireStoreColRef.collection('hitches_tracker').doc('hitches_tracker_doc').get();
    if(results.data() != null){
      return results.data()!['acceptedHitches'];
    }

    return 1;
  }

}