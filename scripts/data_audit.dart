import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';
import '../lib/src/models/user_model.dart';

class DataAudit {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Future<void> auditUserLocationData() async {
    print('🔍 Starting User Location Data Audit...\n');
    
    try {
      // Get total user count
      final totalUsersSnapshot = await _firestore.collection('users').count().get();
      final totalUsers = totalUsersSnapshot.count ?? 0;
      print('📊 Total Users in Database: $totalUsers');
      
      // Initialize counters
      int usersWithLocationArray = 0;
      int usersWithLocationString = 0;
      int usersWithLatLng = 0;
      int usersWithCompleteLocation = 0;
      int usersWithNoLocation = 0;
      
      Map<String, int> countryCounts = {};
      List<String> usersWithoutLocation = [];
      List<String> problemUsers = [];
      
      // Process users in batches
      print('\n📋 Analyzing user location data...');
      
      QuerySnapshot? lastSnapshot;
      int processedCount = 0;
      const batchSize = 500;
      
      do {
        Query query = _firestore.collection('users').limit(batchSize);
        
        if (lastSnapshot != null && lastSnapshot.docs.isNotEmpty) {
          query = query.startAfterDocument(lastSnapshot.docs.last);
        }
        
        lastSnapshot = await query.get();
        
        for (var doc in lastSnapshot.docs) {
          processedCount++;
          
          try {
            final userData = doc.data() as Map<String, dynamic>;
            final user = UserModel.fromMap(userData);
            
            // Check different location data types
            bool hasLocationArray = user.locattionStringArray != null && 
                                  user.locattionStringArray!.isNotEmpty;
            bool hasLocationString = user.locationString != null && 
                                   user.locationString!.isNotEmpty;
            bool hasLatLng = user.latitude != null && user.longitude != null;
            
            // Count location data availability
            if (hasLocationArray) usersWithLocationArray++;
            if (hasLocationString) usersWithLocationString++;
            if (hasLatLng) usersWithLatLng++;
            
            // Check for complete location data
            if (hasLocationArray && hasLocationString) {
              usersWithCompleteLocation++;
              
              // Count countries from location array
              if (user.locattionStringArray != null) {
                for (String location in user.locattionStringArray!) {
                  String lowerLocation = location.toLowerCase();
                  if (_isCountry(lowerLocation)) {
                    countryCounts[lowerLocation] = (countryCounts[lowerLocation] ?? 0) + 1;
                  }
                }
              }
            }
            
            // Track users with no location data
            if (!hasLocationArray && !hasLocationString && !hasLatLng) {
              usersWithNoLocation++;
              usersWithoutLocation.add(user.userID);
            }
            
            // Track problematic users (partial data)
            if ((hasLatLng && !hasLocationString) || 
                (hasLocationString && !hasLocationArray)) {
              problemUsers.add('${user.userID}: lat/lng=$hasLatLng, string=$hasLocationString, array=$hasLocationArray');
            }
            
          } catch (e) {
            print('❌ Error processing user ${doc.id}: $e');
          }
        }
        
        // Progress indicator
        if (processedCount % 1000 == 0) {
          print('   Processed $processedCount/$totalUsers users...');
        }
        
      } while (lastSnapshot.docs.length == batchSize);
      
      // Print comprehensive report
      _printAuditReport({
        'totalUsers': totalUsers,
        'processedCount': processedCount,
        'usersWithLocationArray': usersWithLocationArray,
        'usersWithLocationString': usersWithLocationString,
        'usersWithLatLng': usersWithLatLng,
        'usersWithCompleteLocation': usersWithCompleteLocation,
        'usersWithNoLocation': usersWithNoLocation,
        'countryCounts': countryCounts,
        'problemUsers': problemUsers,
        'usersWithoutLocation': usersWithoutLocation,
      });
      
    } catch (e) {
      print('❌ Error during audit: $e');
    }
  }
  
  bool _isCountry(String location) {
    const countries = [
      'usa', 'united states', 'america',
      'canada',
      'australia', 'au',
      'china',
      'uk', 'united kingdom', 'britain', 'england', 'scotland', 'wales',
      'india',
      'germany',
      'france',
      'spain',
      'italy',
      'japan',
      'brazil',
      'mexico',
      'argentina',
    ];
    
    return countries.any((country) => location.contains(country));
  }
  
  void _printAuditReport(Map<String, dynamic> data) {
    print('\n' + '='*80);
    print('📊 USER LOCATION DATA AUDIT REPORT');
    print('='*80);
    
    final totalUsers = data['totalUsers'] as int;
    final processedCount = data['processedCount'] as int;
    final usersWithLocationArray = data['usersWithLocationArray'] as int;
    final usersWithLocationString = data['usersWithLocationString'] as int;
    final usersWithLatLng = data['usersWithLatLng'] as int;
    final usersWithCompleteLocation = data['usersWithCompleteLocation'] as int;
    final usersWithNoLocation = data['usersWithNoLocation'] as int;
    final countryCounts = data['countryCounts'] as Map<String, int>;
    final problemUsers = data['problemUsers'] as List<String>;
    
    print('\n📈 SUMMARY STATISTICS:');
    print('   Total Users in Database: $totalUsers');
    print('   Users Processed: $processedCount');
    print('   Users with locationStringArray: $usersWithLocationArray (${(usersWithLocationArray/totalUsers*100).toStringAsFixed(1)}%)');
    print('   Users with locationString: $usersWithLocationString (${(usersWithLocationString/totalUsers*100).toStringAsFixed(1)}%)');
    print('   Users with lat/lng coordinates: $usersWithLatLng (${(usersWithLatLng/totalUsers*100).toStringAsFixed(1)}%)');
    print('   Users with COMPLETE location data: $usersWithCompleteLocation (${(usersWithCompleteLocation/totalUsers*100).toStringAsFixed(1)}%)');
    print('   Users with NO location data: $usersWithNoLocation (${(usersWithNoLocation/totalUsers*100).toStringAsFixed(1)}%)');
    
    print('\n🌍 COUNTRY DISTRIBUTION (from searchable arrays):');
    var sortedCountries = countryCounts.entries.toList();
    sortedCountries.sort((a, b) => b.value.compareTo(a.value));
    
    int totalCountryUsers = 0;
    for (var entry in sortedCountries) {
      print('   ${entry.key.toUpperCase()}: ${entry.value} users');
      totalCountryUsers += entry.value;
    }
    print('   ───────────────────────');
    print('   TOTAL SEARCHABLE BY COUNTRY: $totalCountryUsers');
    
    print('\n⚠️  DATA QUALITY ISSUES:');
    final missingArray = usersWithLocationString - usersWithLocationArray;
    final missingString = usersWithLatLng - usersWithLocationString;
    
    print('   Users with locationString but NO array: $missingArray');
    print('   Users with coordinates but NO locationString: $missingString');
    print('   Users with partial/problematic data: ${problemUsers.length}');
    
    print('\n🔧 RECOMMENDATIONS:');
    if (missingArray > 0) {
      print('   ✅ Run migration script to create locationStringArray for $missingArray users');
    }
    if (missingString > 0) {
      print('   ✅ Run reverse geocoding for $missingString users with only coordinates');
    }
    if (usersWithNoLocation > 500) {
      print('   ⚠️  Consider requiring location data for new user registrations');
    }
    
    final searchableUsers = usersWithLocationArray;
    final expectedTotal = totalUsers - usersWithNoLocation;
    if (searchableUsers < expectedTotal * 0.8) {
      print('   🚨 CRITICAL: Only ${(searchableUsers/expectedTotal*100).toStringAsFixed(1)}% of users with location data are searchable!');
      print('   💡 This explains why your search results (~$totalCountryUsers) are much lower than total users ($totalUsers)');
    }
    
    print('\n' + '='*80);
    print('✅ Audit Complete! Review the recommendations above to improve search coverage.');
    print('='*80);
  }
  
  Future<void> runLocationMigration() async {
    print('🔄 Starting Location Data Migration...\n');
    
    try {
      // Find users with locationString but no locattionStringArray
      final usersToMigrate = await _firestore
          .collection('users')
          .where('locationString', isNotEqualTo: null)
          .where('locattionStringArray', isEqualTo: null)
          .get();
      
      print('📋 Found ${usersToMigrate.docs.length} users needing migration');
      
      if (usersToMigrate.docs.isEmpty) {
        print('✅ No users need migration!');
        return;
      }
      
      int migrated = 0;
      final batch = _firestore.batch();
      
      for (var doc in usersToMigrate.docs) {
        try {
          final userData = doc.data();
          final locationString = userData['locationString'] as String?;
          
          if (locationString != null && locationString.isNotEmpty) {
            // Create array from location string
            final locationArray = _createLocationArray(locationString);
            
            if (locationArray.isNotEmpty) {
              batch.update(doc.reference, {'locattionStringArray': locationArray});
              migrated++;
              
              if (migrated % 500 == 0) {
                await batch.commit();
                print('   Migrated $migrated users...');
              }
            }
          }
        } catch (e) {
          print('❌ Error migrating user ${doc.id}: $e');
        }
      }
      
      // Commit final batch
      if (migrated % 500 != 0) {
        await batch.commit();
      }
      
      print('✅ Migration complete! Updated $migrated users with searchable location arrays.');
      
    } catch (e) {
      print('❌ Error during migration: $e');
    }
  }
  
  List<String> _createLocationArray(String locationString) {
    // Convert location string to searchable array
    final parts = locationString.toLowerCase()
        .split(RegExp(r'[,\s]+'))
        .where((part) => part.isNotEmpty && part.length > 1)
        .toList();
    
    return parts;
  }
}

Future<void> main() async {
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    final audit = DataAudit();
    
    // Run audit
    await audit.auditUserLocationData();
    
    // Ask user if they want to run migration
    print('\n🤔 Would you like to run location data migration? (y/n)');
    final response = stdin.readLineSync()?.toLowerCase();
    
    if (response == 'y' || response == 'yes') {
      await audit.runLocationMigration();
      print('\n🔄 Re-running audit to show updated statistics...');
      await audit.auditUserLocationData();
    }
    
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
  
  exit(0);
}
