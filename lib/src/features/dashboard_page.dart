import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/models/user_model.dart';
import 'package:hitch_tracker/src/providers/hitch_count_provider.dart';
import 'package:hitch_tracker/src/res/app_colors.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';
import 'package:hitch_tracker/src/res/string_constants.dart';
import 'package:hitch_tracker/src/service/hitches_service.dart';
import 'dart:async';

import 'package:provider/provider.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  String? _selectedPlayerType;

  // List of items in our dropdown menu
  final _playerTypes = [
    playerTypePickleBallValue,
    playerTypeTennisValue,
    playerTypePadelValue,
    playerTypeCoachValue,
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<UserModel> _users = [];
  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _hasMoreData = true;
  bool _hasMoreSearchResults = true;
  DocumentSnapshot? _lastDocument;
  
  // Separate pagination tracking for each search field
  DocumentSnapshot? _lastUserNameDoc;
  DocumentSnapshot? _lastBioDoc;
  DocumentSnapshot? _lastLocationDoc;
  bool _hasMoreUserName = true;
  bool _hasMoreBio = true;
  bool _hasMoreLocation = true;
  
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool _isInSearchMode = false;
  
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 100),
          sliver: SliverToBoxAdapter(
            child: Column(
              spacing: 20,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 20,
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                            onTap:()async{
                              // await FirebaseFirestore.instance.collection('location_trigger').add({'lowerCaseTest' :  'test'});
                              // debugPrint("Record added");
                            },
                            child: Text("All Users", style: AppTextStyles.largeTextStyle,)),
                        Consumer<HitchCountProvider>(builder: (_, provider, _){
                          return Text(provider.totalUsers == 1 ? "" : '${provider.totalUsers}', style: AppTextStyles.headingTextStyle.copyWith(color: AppColors.primaryColor),);
                        }),

                      ],
                    ),

                    Text('A comprehensive list of all users on the Hitch Platform', style: AppTextStyles.smallTextStyle,)
                  ],
                ),
                Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: EdgeInsets.only(right: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      spacing: 20,
                      children: [
                        Expanded(child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            style: AppTextStyles.smallTextStyle,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: AppColors.textFieldFillColor)
                              ),
                                focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.textFieldFillColor)
                                ),
                              hintText: 'Search by name, location, bio',
                              hintStyle: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey,),
                            ),
                          ),
                        )),

                        Expanded(child: FormField<String>(
                          builder: (FormFieldState<String> state) {
                            return InputDecorator(
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: AppColors.textFieldFillColor)),
                                labelStyle: AppTextStyles.smallTextStyle,
                                hintStyle: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10),
                                errorStyle: AppTextStyles.regularTextStyle.copyWith(color: Colors.red),
                                // hintText: 'Please select expense',
                              ),
                              isEmpty: _selectedPlayerType == null,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedPlayerType,
                                  hint: Text('Filter by sport', style: AppTextStyles.smallTextStyle,),
                                  isDense: true,
                                  elevation: 0,
                                  dropdownColor: Colors.white,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedPlayerType = newValue;
                                      // Reset data when filter changes
                                      _users.clear();
                                      _searchResults.clear();
                                      _lastDocument = null;
                                      _resetSearchPagination();
                                      _hasMoreData = true;
                                      _hasMoreSearchResults = true;
                                    });
                                    
                                    // Reload data with new filter
                                    if (_isInSearchMode) {
                                      _performFirebaseSearch();
                                    } else {
                                      _loadUsers();
                                    }
                                  },
                                  items: _playerTypes.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value)
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        ),)
                      ],
                    ),
                  ),
                )
              ],
            )
          ),
        ),
        // Users list
        _buildUsersSliver(),
      ],
    );
  }

  Widget _buildUsersSliver() {
    final currentUsers = _isInSearchMode ? _searchResults : _users;
    final isCurrentlyLoading = _isInSearchMode ? _isSearching : _isLoading;
    final hasMore = _isInSearchMode ? _hasMoreSearchResults : _hasMoreData;

    if (currentUsers.isEmpty && !isCurrentlyLoading) {
      return SliverToBoxAdapter(
        child: Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5)
          ),
          color: Colors.white,
          child: SizedBox(
            height: 400, // Fixed height for empty state
            child: _buildEmptyState(),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5)
        ),
        margin: EdgeInsets.only(right: 100),
        color: Colors.white,
        child: Column(
          children: [
            // User items
            ...currentUsers.map((user) => _buildUserItem(user)),
            // Loading indicator
            if (isCurrentlyLoading || hasMore)
              _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserItem(UserModel user) {
    List<String> playerTypes = [];
    if (user.playerTypePickle) playerTypes.add(playerTypePickleBallValue);
    if (user.playerTypeTennis) playerTypes.add(playerTypeTennisValue);
    if (user.playerTypePadel) playerTypes.add(playerTypePadelValue);
    if (user.playerTypeCoach) playerTypes.add(playerTypeCoachValue);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            spacing: 20,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.textFieldFillColor,
                backgroundImage: user.profilePicture.isNotEmpty
                    ? CachedNetworkImageProvider(user.profilePicture)
                    : null,
                child: user.profilePicture.isEmpty
                    ? Text(
                  user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                )
                    : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 5,
                  children: [
                    Text(
                        user.userName.isNotEmpty ? user.userName : 'Unknown User',
                        style: AppTextStyles.regularTextStyle.copyWith(fontWeight: FontWeight.w600)
                    ),
                    if(user.locationString != null)
                      SelectableText(
                        user.locationString!,
                        style: AppTextStyles.smallTextStyle,
                      ),
                    /*if (user.latitude != null && user.longitude != null)
                      FutureBuilder(future: HitchesService.getUserLocationFromLatLng(user.latitude!, user.longitude!), builder: (_, snapshot){
                        if(snapshot.hasData){
                          return Text(
                            snapshot.requireData,
                            style: AppTextStyles.smallTextStyle,
                          );
                        }
                        return SizedBox();
                      }),*/
                    if (user.bio.isNotEmpty)
                      Text(
                        user.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 10),
                    if (playerTypes.isNotEmpty)
                      Wrap(
                        spacing: 10,
                        runSpacing: 5,
                        children: playerTypes
                            .map((type) => _buildPlayerTypeItem(playerType: type))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          color: AppColors.textFieldFillColor,
        )
      ],
    );
  /*  return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero
        ),
        surfaceTintColor: Colors.white,
        overlayColor: Colors.grey[300]
      ),
      onPressed: () {
        // Handle user selection if needed
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Row(
              spacing: 20,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.textFieldFillColor,
                  backgroundImage: user.profilePicture.isNotEmpty
                      ? CachedNetworkImageProvider(user.profilePicture)
                      : null,
                  child: user.profilePicture.isEmpty
                      ? Text(
                          user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 5,
                    children: [
                      Text(
                        user.userName.isNotEmpty ? user.userName : 'Unknown User',
                        style: AppTextStyles.regularTextStyle.copyWith(fontWeight: FontWeight.w600)
                      ),
                      if (user.latitude != null && user.longitude != null)
                        FutureBuilder(future: HitchesService.getUserLocationFromLatLng(user.latitude!, user.longitude!), builder: (_, snapshot){
                          if(snapshot.hasData){
                            return Text(
                              snapshot.requireData,
                              style: AppTextStyles.smallTextStyle,
                            );
                          }
                          return SizedBox();
                        }),
                      if (user.bio.isNotEmpty)
                        Text(
                          user.bio,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 10),
                      if (playerTypes.isNotEmpty)
                        Wrap(
                          spacing: 10,
                          runSpacing: 5,
                          children: playerTypes
                              .map((type) => _buildPlayerTypeItem(playerType: type))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.black12,
          )
        ],
      ),
    );*/
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No users found' : 'No users match your search',
            style: AppTextStyles.regularTextStyle.copyWith(color: Colors.grey[600]),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey[500]),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }



  Widget _buildPlayerTypeItem({required String playerType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: Colors.deepPurple.withValues(alpha: 0.1),
      ),
      child: Text(
        playerType,
        style: TextStyle(fontSize: 12, color: Colors.black),
      ),
    );
  }

  String _getPlayerTypeFieldName(String playerType) {
    switch (playerType) {
      case playerTypePickleBallValue:
        return 'playerTypePickle';
      case playerTypeTennisValue:
        return 'playerTypeTennis';
      case playerTypePadelValue:
        return 'playerTypePadel';
      case playerTypeCoachValue:
        return 'playerTypeCoach';
      default:
        return '';
    }
  }

  List<UserModel> _filterUsersByPlayerType(List<UserModel> users, String playerType) {
    switch (playerType) {
      case playerTypePickleBallValue:
        return users.where((user) => user.playerTypePickle).toList();
      case playerTypeTennisValue:
        return users.where((user) => user.playerTypeTennis).toList();
      case playerTypePadelValue:
        return users.where((user) => user.playerTypePadel).toList();
      case playerTypeCoachValue:
        return users.where((user) => user.playerTypeCoach).toList();
      default:
        return users;
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (_isInSearchMode) {
        if (!_isSearching && _hasMoreSearchResults) {
          _loadMoreSearchResults();
        }
      } else {
        if (!_isLoading && _hasMoreData) {
          _loadMoreUsers();
        }
      }
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final newQuery = _searchController.text.trim();
      setState(() {
        _searchQuery = newQuery;
        _isInSearchMode = newQuery.isNotEmpty;
      });
      _performFirebaseSearch();
    });
  }

  Future<void> _loadUsers() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = _firestore
          .collection('users')
          .limit(_pageSize);

      // Apply player type filter if selected
      if (_selectedPlayerType != null) {
        String fieldName = _getPlayerTypeFieldName(_selectedPlayerType!);
        query = query.where(fieldName, isEqualTo: true);
      }

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot snapshot = await query.get();
      debugPrint("Users: ${snapshot.docs.length}");
      if (snapshot.docs.isNotEmpty) {
        final List<UserModel> newUsers = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        setState(() {
          if (_lastDocument == null) {
            _users = newUsers;
          } else {
            _users.addAll(newUsers);
          }
          _lastDocument = snapshot.docs.last;
          _hasMoreData = snapshot.docs.length == _pageSize;
        });
      } else {
        setState(() {
          _hasMoreData = false;
        });
      }
    } catch (e) {
      // Handle error silently for now
      debugPrint('Error loading users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    await _loadUsers();
  }

  Future<void> _performFirebaseSearch() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _isInSearchMode = false;
        _searchResults.clear();
        _lastSearchDocument = null;
        _hasMoreSearchResults = true;
      });
      return;
    }

    if (_searchQuery.length < 2) {
      // Don't search for queries less than 2 characters
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults.clear();
      _lastSearchDocument = null;
      _hasMoreSearchResults = true;
    });

    await _searchInFirebase(_searchQuery);
  }

  Future<void> _searchInFirebase(String query) async {
    try {
      final String queryLower = query.toLowerCase();

      // Search by userName (primary search)
      Query searchQuery = _firestore
          .collection('users')
          .orderBy('userName')
          .where('userName', isGreaterThanOrEqualTo: query)
          .where('userName', isLessThan: query + '\uf8ff')
          .limit(_pageSize);

      if (_lastSearchDocument != null) {
        searchQuery = searchQuery.startAfterDocument(_lastSearchDocument!);
      }

      final QuerySnapshot snapshot = await searchQuery.get();
      List<UserModel> results = [];

      if (snapshot.docs.isNotEmpty) {
        List<UserModel> allResults = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        // Apply player type filter to search results if selected
        if (_selectedPlayerType != null) {
          results = _filterUsersByPlayerType(allResults, _selectedPlayerType!);
        } else {
          results = allResults;
        }

        _lastSearchDocument = snapshot.docs.last;
      }

      // If we don't have enough results from userName search, search bio field
      if (results.length < 10 && _lastSearchDocument == null) {
        await _searchBioField(queryLower, results);
      }

      // If we still don't have enough results, search locationString field
      if (results.length < 10 && _lastSearchDocument == null) {
        await _searchLocationField(queryLower, results);
      }

      setState(() {
        if (_lastSearchDocument == null || _searchResults.isEmpty) {
          _searchResults = results;
        } else {
          _searchResults.addAll(results);
        }
        _hasMoreSearchResults = snapshot.docs.length == _pageSize;
        _isSearching = false;
      });

    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  Future<void> _searchBioField(String queryLower, List<UserModel> existingResults) async {
    try {
      // Search in bio field for additional results
      final QuerySnapshot bioSnapshot = await _firestore
          .collection('users')
          .where('bio', isGreaterThanOrEqualTo: queryLower)
          .where('bio', isLessThan: queryLower + '\uf8ff')
          .limit(_pageSize - existingResults.length)
          .get();

      if (bioSnapshot.docs.isNotEmpty) {
        List<UserModel> bioResults = bioSnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .where((user) => !existingResults.any((existing) => existing.userID == user.userID))
            .toList();

        // Apply player type filter to bio search results if selected
        if (_selectedPlayerType != null) {
          bioResults = _filterUsersByPlayerType(bioResults, _selectedPlayerType!);
        }

        existingResults.addAll(bioResults);
      }
    } catch (e) {
      debugPrint('Bio search error: $e');
    }
  }

  Future<void> _searchLocationField(String queryLower, List<UserModel> existingResults) async {
    try {
      // Search in locattionStringArray field using array-contains for additional results
      final QuerySnapshot locationSnapshot = await _firestore
          .collection('users')
          .where('locationStringArray', arrayContains: queryLower)
          .limit(_pageSize - existingResults.length)
          .get();

      if (locationSnapshot.docs.isNotEmpty) {
        List<UserModel> locationResults = locationSnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .where((user) => !existingResults.any((existing) => existing.userID == user.userID))
            .toList();

        // Apply player type filter to location search results if selected
        if (_selectedPlayerType != null) {
          locationResults = _filterUsersByPlayerType(locationResults, _selectedPlayerType!);
        }

        existingResults.addAll(locationResults);
      }
    } catch (e) {
      debugPrint('Location search error: $e');
    }
  }

  Future<void> _loadMoreSearchResults() async {
    if (_isSearching || !_hasMoreSearchResults) return;
    await _searchInFirebase(_searchQuery);
  }

 /* Future<void> _refreshUsers() async {
    if (_isInSearchMode) {
      // Refresh search results
      setState(() {
        _searchResults.clear();
        _lastSearchDocument = null;
        _hasMoreSearchResults = true;
      });
      await _performFirebaseSearch();
    } else {
      // Refresh normal user list
      setState(() {
        _users.clear();
        _lastDocument = null;
        _hasMoreData = true;
      });
      await _loadUsers();
    }
  }*/
}
