import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../res/string_constants.dart';
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
  static Future<int> getTotalStatesCount()async{
    final results = await _fireStoreColRef.collection('hitch_user_states').get();

    return results.size;
  }


  static Future<String> getUserLocationFromLatLng(double latitude, double longitude) async {
    String address = 'Unknown Location';
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$googleAPIKey';

    try {
      final response = await http.get(Uri.parse(url));
      // debugPrint("Result: ${response.body}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final List<dynamic> addressComponents = data['results'][0]['address_components'];
          String city = '';
          String state = '';
          String country = '';

          // Iterate through address components to find city, state, and country
          for (var component in addressComponents) {
            final types = component['types'] as List;
            if (types.contains('locality')) {
              city = component['long_name'];
            } else if (types.contains('administrative_area_level_1')) {
              state = component['short_name'];
            } else if (types.contains('country')) {
              country = component['long_name'];
            }
          }

          address = '$city, $state, $country';
          // Format the address as "City, State, Country"
          /* if (city.isNotEmpty && state.isNotEmpty && country.isNotEmpty) {
            address = '$city, $state, $country';
          } else {
            print('Missing components: City, State, or Country');
          }*/
        } else {
          debugPrint('Geocoding API returned no results or status not OK. Status: ${data['status']}');
        }
      } else {
        debugPrint('Failed to fetch geocoding data. HTTP status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error during geocoding: $e');
    }

    return address;
  }

}