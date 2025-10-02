import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/models/user_model.dart';
import 'package:hitch_tracker/src/providers/hitch_count_provider.dart';
import 'package:hitch_tracker/src/res/app_colors.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';
import 'package:hitch_tracker/src/res/string_constants.dart';
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

  // Search results count
  int? _totalSearchCount;
  bool _isCountLoading = false;

  // Country filter state
  bool _isInCountryFilterMode = false;
  DocumentSnapshot? _lastCountryDoc;
  bool _hasMoreCountryResults = true;
  List<UserModel> _countryFilteredUsers = [];
  int? _countryFilterCount;
  bool _isLoadingCountryFilter = false;

  static const int _pageSize = 20;

  final List<String> _countries = [
    'United States',
    'United Kingdom',
    'Canada',
    'Austrailia',
    'France',
    'India',
    'China'
  ];
  String? _selectedCountry;
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
                          Expanded(
                              flex: 2,
                              child: SizedBox(
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
                                        _countryFilteredUsers.clear();
                                        _lastDocument = null;
                                        _lastCountryDoc = null;
                                        _resetSearchPagination();
                                        _hasMoreData = true;
                                        _hasMoreSearchResults = true;
                                        _hasMoreCountryResults = true;
                                        _totalSearchCount = null;
                                        _countryFilterCount = null;
                                      });

                                      // Reload data with new filter
                                      if (_isInSearchMode) {
                                        _performFirebaseSearch();
                                      } else if (_isInCountryFilterMode) {
                                        _loadUsersByCountry();
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
                          ),),
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
                                isEmpty: _selectedCountry == null,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCountry,
                                    hint: Text('Filter by county', style: AppTextStyles.smallTextStyle,),
                                    isDense: true,
                                    elevation: 0,
                                    dropdownColor: Colors.white,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedCountry = newValue;
                                        _isInCountryFilterMode = newValue != null;
                                        
                                        // Reset all data when filter changes
                                        _users.clear();
                                        _searchResults.clear();
                                        _countryFilteredUsers.clear();
                                        _lastDocument = null;
                                        _lastCountryDoc = null;
                                        _resetSearchPagination();
                                        _hasMoreData = true;
                                        _hasMoreCountryResults = true;
                                        _totalSearchCount = null;
                                        _countryFilterCount = null;
                                      });
                                      
                                      // Reload data based on mode
                                      if (_isInSearchMode) {
                                        _performFirebaseSearch();
                                      } else if (_isInCountryFilterMode) {
                                        _loadUsersByCountry();
                                      } else {
                                        _loadUsers();
                                      }
                                    },
                                    items: _countries.map((String value) {
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
                  ),
                  // Search results count
                  _buildSearchResultsCount(),
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
    // Determine which user list to display based on active mode
    final currentUsers = _isInSearchMode 
        ? _searchResults 
        : (_isInCountryFilterMode ? _countryFilteredUsers : _users);
    
    final isCurrentlyLoading = _isInSearchMode 
        ? _isSearching 
        : (_isInCountryFilterMode ? _isLoadingCountryFilter : _isLoading);
    
    final hasMore = _isInSearchMode 
        ? _hasMoreSearchResults 
        : (_isInCountryFilterMode ? _hasMoreCountryResults : _hasMoreData);

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

  Widget _buildSearchResultsCount() {
    if (_isInSearchMode) {
      if (_isCountLoading) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              ),
              SizedBox(width: 8),
              Text(
                "Counting results...",
                style: AppTextStyles.smallTextStyle.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }
      if (_totalSearchCount != null) {
        String filterText = _selectedPlayerType != null ? " with ${_selectedPlayerType!} filter" : "";
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Text(
            "Found $_totalSearchCount total result${_totalSearchCount == 1 ? '' : 's'} for '$_searchQuery'$filterText",
            style: AppTextStyles.smallTextStyle.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    } else if (_isInCountryFilterMode) {
      if (_isCountLoading) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                ),
              ),
              SizedBox(width: 8),
              Text(
                "Counting results...",
                style: AppTextStyles.smallTextStyle.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }
      if (_countryFilterCount != null) {
        String filterText = _selectedPlayerType != null ? " with ${_selectedPlayerType!} filter" : "";
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Text(
            "Found $_countryFilterCount total result${_countryFilterCount == 1 ? '' : 's'} for '$_selectedCountry'$filterText",
            style: AppTextStyles.smallTextStyle.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    } else if (!_isInSearchMode && _users.isNotEmpty) {
      String filterText = _selectedPlayerType != null ? " (${_selectedPlayerType!} filter)" : "";
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Text(
          "Showing ${_users.length} record${_users.length == 1 ? '' : 's'}$filterText",
          style: AppTextStyles.smallTextStyle.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }
    return SizedBox.shrink();
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
      } else if (_isInCountryFilterMode) {
        if (!_isLoadingCountryFilter && _hasMoreCountryResults) {
          _loadMoreCountryUsers();
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

  Future<void> _loadUsersByCountry() async {
    if (_isLoadingCountryFilter || _selectedCountry == null) return;

    setState(() {
      _isLoadingCountryFilter = true;
    });

    // Start count query in parallel
    _getCountryFilterCount();

    try {
      final String countryLower = _selectedCountry!.toLowerCase();

      Query countryQuery = _firestore
          .collection('users')
          .orderBy('countryLowerCase')
          .where('countryLowerCase', isGreaterThanOrEqualTo: countryLower)
          .where('countryLowerCase', isLessThan: countryLower + '\uf8ff')
          .limit(_pageSize);

      // Apply player type filter if selected
      if (_selectedPlayerType != null) {
        String fieldName = _getPlayerTypeFieldName(_selectedPlayerType!);
        countryQuery = countryQuery.where(fieldName, isEqualTo: true);
      }

      if (_lastCountryDoc != null) {
        countryQuery = countryQuery.startAfterDocument(_lastCountryDoc!);
      }

      final QuerySnapshot snapshot = await countryQuery.get();
      
      if (snapshot.docs.isNotEmpty) {
        final List<UserModel> newUsers = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        setState(() {
          if (_lastCountryDoc == null) {
            _countryFilteredUsers = newUsers;
          } else {
            _countryFilteredUsers.addAll(newUsers);
          }
          _lastCountryDoc = snapshot.docs.last;
          _hasMoreCountryResults = snapshot.docs.length == _pageSize;
        });
      } else {
        setState(() {
          _hasMoreCountryResults = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users by country: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingCountryFilter = false;
      });
    }
  }

  Future<void> _loadMoreCountryUsers() async {
    await _loadUsersByCountry();
  }

  Future<void> _getCountryFilterCount() async {
    if (_isCountLoading || _selectedCountry == null) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final String countryLower = _selectedCountry!.toLowerCase();

      Query countQuery = _firestore
          .collection('users')
          .where('countryLowerCase', isGreaterThanOrEqualTo: countryLower)
          .where('countryLowerCase', isLessThan: countryLower + '\uf8ff');

      // Apply player type filter if selected
      if (_selectedPlayerType != null) {
        String fieldName = _getPlayerTypeFieldName(_selectedPlayerType!);
        countQuery = countQuery.where(fieldName, isEqualTo: true);
      }

      final AggregateQuerySnapshot countSnapshot = await countQuery.count().get();
      
      setState(() {
        _countryFilterCount = countSnapshot.count;
        _isCountLoading = false;
      });
    } catch (e) {
      debugPrint('Error getting country filter count: $e');
      setState(() {
        _isCountLoading = false;
        _countryFilterCount = null;
      });
    }
  }

  void _resetSearchPagination() {
    _lastUserNameDoc = null;
    _lastBioDoc = null;
    _lastLocationDoc = null;
    _hasMoreUserName = true;
    _hasMoreBio = true;
    _hasMoreLocation = true;
  }

  Future<void> _performFirebaseSearch() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _isInSearchMode = false;
        _searchResults.clear();
        _resetSearchPagination();
        _hasMoreSearchResults = true;
        _totalSearchCount = null;
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
      _resetSearchPagination();
      _hasMoreSearchResults = true;
      _totalSearchCount = null;
    });

    // Start count query in parallel
    _getSearchResultsCount(_searchQuery);

    await _searchInFirebase(_searchQuery);
  }

  Future<void> _searchInFirebase(String query) async {
    try {
      final String queryLower = query.toLowerCase();

      // Perform parallel searches across all fields
      final List<Future<List<UserModel>>> searchFutures = [
        _searchUserNameField(query),
        _searchBioField(queryLower),
        _searchLocationField(queryLower),
      ];

      final List<List<UserModel>> searchResultsLists = await Future.wait(searchFutures);

      // Combine and deduplicate results
      List<UserModel> combinedResults = [];
      Set<String> seenUserIds = {};

      for (List<UserModel> resultsList in searchResultsLists) {
        for (UserModel user in resultsList) {
          if (!seenUserIds.contains(user.userID)) {
            seenUserIds.add(user.userID);
            combinedResults.add(user);
          }
        }
      }

      // Apply player type filter if selected
      if (_selectedPlayerType != null) {
        combinedResults = _filterUsersByPlayerType(combinedResults, _selectedPlayerType!);
      }

      // Check if we have more results available from any field
      bool hasMoreResults = _hasMoreUserName || _hasMoreBio || _hasMoreLocation;

      setState(() {
        if (_searchResults.isEmpty) {
          _searchResults = combinedResults;
        } else {
          // Add new results, avoiding duplicates
          for (UserModel user in combinedResults) {
            if (!_searchResults.any((existing) => existing.userID == user.userID)) {
              _searchResults.add(user);
            }
          }
        }
        _hasMoreSearchResults = hasMoreResults;
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

  Future<List<UserModel>> _searchUserNameField(String query) async {
    try {
      if (!_hasMoreUserName) return [];

      Query searchQuery = _firestore
          .collection('users')
          .orderBy('userName')
          .where('userName', isGreaterThanOrEqualTo: query)
          .where('userName', isLessThan: query + '\uf8ff')
          .limit(_pageSize);

      if (_lastUserNameDoc != null) {
        searchQuery = searchQuery.startAfterDocument(_lastUserNameDoc!);
      }

      final QuerySnapshot snapshot = await searchQuery.get();

      if (snapshot.docs.isNotEmpty) {
        _lastUserNameDoc = snapshot.docs.last;
        _hasMoreUserName = snapshot.docs.length == _pageSize;

        return snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      } else {
        _hasMoreUserName = false;
        return [];
      }
    } catch (e) {
      debugPrint('UserName search error: $e');
      _hasMoreUserName = false;
      return [];
    }
  }

  Future<List<UserModel>> _searchBioField(String queryLower) async {
    try {
      if (!_hasMoreBio) return [];

      Query bioQuery = _firestore
          .collection('users')
          .orderBy('bio')
          .where('bio', isGreaterThanOrEqualTo: queryLower)
          .where('bio', isLessThan: queryLower + '\uf8ff')
          .limit(_pageSize);

      if (_lastBioDoc != null) {
        bioQuery = bioQuery.startAfterDocument(_lastBioDoc!);
      }

      final QuerySnapshot bioSnapshot = await bioQuery.get();

      if (bioSnapshot.docs.isNotEmpty) {
        _lastBioDoc = bioSnapshot.docs.last;
        _hasMoreBio = bioSnapshot.docs.length == _pageSize;

        return bioSnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      } else {
        _hasMoreBio = false;
        return [];
      }
    } catch (e) {
      debugPrint('Bio search error: $e');
      _hasMoreBio = false;
      return [];
    }
  }

  Future<List<UserModel>> _searchLocationField(String queryLower) async {
    try {
      if (!_hasMoreLocation) return [];

      // For location search using countryLowerCase field
      Query locationQuery = _firestore
          .collection('users')
          .orderBy('countryLowerCase')
          .where('countryLowerCase', isGreaterThanOrEqualTo: queryLower)
          .where('countryLowerCase', isLessThan: queryLower + '\uf8ff')
          .limit(_pageSize);

      if (_lastLocationDoc != null) {
        locationQuery = locationQuery.startAfterDocument(_lastLocationDoc!);
      }

      final QuerySnapshot locationSnapshot = await locationQuery.get();

      if (locationSnapshot.docs.isNotEmpty) {
        _lastLocationDoc = locationSnapshot.docs.last;
        _hasMoreLocation = locationSnapshot.docs.length == _pageSize;

        return locationSnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      } else {
        _hasMoreLocation = false;
        return [];
      }
    } catch (e) {
      debugPrint('Location search error: $e');
      _hasMoreLocation = false;
      return [];
    }
  }

  Future<void> _loadMoreSearchResults() async {
    if (_isSearching || !_hasMoreSearchResults) return;

    setState(() {
      _isSearching = true;
    });

    await _searchInFirebase(_searchQuery);
  }

  Future<void> _getSearchResultsCount(String query) async {
    if (_isCountLoading) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      final String queryLower = query.toLowerCase();

      // Build count queries for all search fields
      List<Future<AggregateQuerySnapshot>> countFutures = [];

      // UserName count query
      Query userNameCountQuery = _firestore
          .collection('users')
          .where('userName', isGreaterThanOrEqualTo: query)
          .where('userName', isLessThan: query + '\uf8ff');

      // Apply player type filter if selected
      if (_selectedPlayerType != null) {
        String fieldName = _getPlayerTypeFieldName(_selectedPlayerType!);
        userNameCountQuery = userNameCountQuery.where(fieldName, isEqualTo: true);
      }

      countFutures.add(userNameCountQuery.count().get());

      // Bio count query
      Query bioCountQuery = _firestore
          .collection('users')
          .where('bio', isGreaterThanOrEqualTo: queryLower)
          .where('bio', isLessThan: queryLower + '\uf8ff');

      if (_selectedPlayerType != null) {
        String fieldName = _getPlayerTypeFieldName(_selectedPlayerType!);
        bioCountQuery = bioCountQuery.where(fieldName, isEqualTo: true);
      }

      countFutures.add(bioCountQuery.count().get());

      // Location count query (array-contains)
      Query locationCountQuery = _firestore
          .collection('users')
          .where('countryLowerCase', isGreaterThanOrEqualTo: queryLower)
          .where('countryLowerCase', isLessThan: queryLower + '\uf8ff');

      if (_selectedPlayerType != null) {
        String fieldName = _getPlayerTypeFieldName(_selectedPlayerType!);
        locationCountQuery = locationCountQuery.where(fieldName, isEqualTo: true);
      }

      countFutures.add(locationCountQuery.count().get());

      // Execute all count queries in parallel
      final List<AggregateQuerySnapshot> countResults = await Future.wait(countFutures);

      // Sum up counts but note: this gives total matches across all fields
      // which may include duplicates, but provides a good approximation
      int totalCount = 0;
      for (var result in countResults) {
        totalCount += result.count ?? 0;
      }

      setState(() {
        _totalSearchCount = totalCount;
        _isCountLoading = false;
      });

    } catch (e) {
      debugPrint('Error getting search count: $e');
      setState(() {
        _isCountLoading = false;
        _totalSearchCount = null;
      });
    }
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
