import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/models/user_model.dart';
import 'package:hitch_tracker/src/providers/hitch_count_provider.dart';
import 'package:hitch_tracker/src/res/app_colors.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';
import 'package:hitch_tracker/src/service/hitches_service.dart';
import 'dart:async';

import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
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
  DocumentSnapshot? _lastSearchDocument;
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
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Stats section
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 20),
          sliver: SliverToBoxAdapter(
            child: Consumer<HitchCountProvider>(
              builder: (_, provider,_) {
                return Row(
                  spacing: 20,
                  children: [
                    Expanded(
                      child: _buildInfoItemWidget(
                        title: 'Users',
                        value: provider.totalUsers
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItemWidget(title: 'Requested Hitches', value: provider.totalHitchRequests),
                    ),
                    Expanded(
                      child: _buildInfoItemWidget(title: 'Accepted Hitches', value: provider.totalHitchAccepted),
                    ),
                    Expanded(
                      child: _buildInfoItemWidget(title: 'Chats', value: provider.totalChats),
                    ),
                  ],
                );
              }
            ),
          ),
        ),
        // Users section header
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 10),
          sliver: SliverToBoxAdapter(
            child: Text("Users", style: AppTextStyles.headingTextStyle),
          ),
        ),
        // Search field
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 10),
          sliver: SliverToBoxAdapter(
            child: _buildSearchTextField(),
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
          child: Container(
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
        color: Colors.white,
        child: Column(
          children: [
            // User items
            ...currentUsers.map((user) => _buildUserItem(user)).toList(),
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
    if (user.playerTypePickle) playerTypes.add('Pickleball');
    if (user.playerTypeTennis) playerTypes.add('Tennis');
    if (user.playerTypePadel) playerTypes.add('Padel');
    if (user.playerTypeCoach) playerTypes.add('Coach');

    return ElevatedButton(
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
    );
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

  TextField _buildSearchTextField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.transparent)
        ),
        fillColor: AppColors.textFieldFillColor,
        filled: true,
        hintText: "Search users by name or bio (Firebase search)",
        hintStyle: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey),
        prefixIcon: const Icon(Icons.search_sharp, color: Colors.grey),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                },
              )
            : null,
      ),
    );
  }

  Widget _buildPlayerTypeItem({required String playerType}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: AppColors.textFieldFillColor,
      ),
      child: Text(
        playerType,
        style: TextStyle(fontSize: 12, color: AppColors.primaryColor),
      ),
    );
  }

  Widget _buildInfoItemWidget({required String title, required int value}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textFieldFillColor,
        borderRadius: BorderRadius.circular(10)
      ),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 15,
        children: [
          Text(title, style: AppTextStyles.regularTextStyle),
          Text(value == 1 ? '•••••' :"$value", style: AppTextStyles.headingTextStyle)
        ],
      ),
    );
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
        results = snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        _lastSearchDocument = snapshot.docs.last;
      }

      // If we don't have enough results from userName search, search bio field
      if (results.length < 10 && _lastSearchDocument == null) {
        await _searchBioField(queryLower, results);
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
        final bioResults = bioSnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
            .where((user) => !existingResults.any((existing) => existing.userID == user.userID))
            .toList();

        existingResults.addAll(bioResults);
      }
    } catch (e) {
      debugPrint('Bio search error: $e');
    }
  }

  Future<void> _loadMoreSearchResults() async {
    if (_isSearching || !_hasMoreSearchResults) return;
    await _searchInFirebase(_searchQuery);
  }

  Future<void> _refreshUsers() async {
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
  }
}
