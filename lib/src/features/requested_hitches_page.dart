import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/models/hitch_tracker_model.dart';
import 'package:hitch_tracker/src/res/app_colors.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../providers/hitch_count_provider.dart';
import '../widgets/table_column_title_widget.dart';


class RequestedHitchesPage extends StatefulWidget {
  const RequestedHitchesPage({super.key});

  @override
  State<RequestedHitchesPage> createState() => _RequestedHitchesPageState();
}

class _RequestedHitchesPageState extends State<RequestedHitchesPage> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<HitchTrackerUserModel> _users = [];
  List<HitchTrackerUserModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _hasMoreData = true;
  bool _hasMoreSearchResults = true;
  DocumentSnapshot? _lastDocument;
  DocumentSnapshot? _lastSearchDocument;
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool _isInSearchMode = false;

  // Search results count
  int? _totalSearchCount;
  bool _isCountLoading = false;

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
        // Stats section
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 20, top: 20,),
          sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 20,
                    children: [
                      Text("Hitch Requests", style: AppTextStyles.largeTextStyle,),
                      Consumer<HitchCountProvider>(builder: (_, provider, _){
                        return Text(provider.totalUsers == 1 ? "" : '${provider.totalHitchRequests}', style: AppTextStyles.headingTextStyle.copyWith(color: AppColors.primaryColor),);
                      }),
                    ],
                  ),

                  Text("Manage Hitch requests", style: AppTextStyles.smallTextStyle,)
                ],
              )
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 100),
          sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    margin: EdgeInsets.only(right: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
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
                            hintText: 'Search by name',
                            hintStyle: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey,),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Search results count
                  _buildSearchResultsCount(),
                ],
              )
          ),
        ),
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
        color: Colors.white,
        child: Column(
          children: [
            _buildUsersTable(currentUsers),
            // Loading indicator
            if (isCurrentlyLoading || hasMore)
              _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable(List<HitchTrackerUserModel> users) {
    if (users.isEmpty && !_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No users available',
          style: AppTextStyles.regularTextStyle.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: DataTable(
        columnSpacing: 16,
        horizontalMargin: 0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0), // Rounded corners
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        headingRowColor: WidgetStateProperty.all(AppColors.primaryColor.withValues(alpha: 0.1)),
        headingRowHeight: 56,
        dataRowMinHeight: 72,
        dataRowMaxHeight: 72,
        border: TableBorder.all(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),

        columns: [
          DataColumn(
            headingRowAlignment: MainAxisAlignment.center,
            label: SizedBox(
                width: 80,
                child: Center(child: TableColumnWidget(title: 'Profile'))
            ),
          ),
          DataColumn(
            label: Expanded(
              flex: 2,
              child: TableColumnWidget(title: 'User Name'),
            ),
          ),
          DataColumn(
            label: Expanded(
                flex: 3,
                child: TableColumnWidget(title: 'Bio')
            ),
          ),
          DataColumn(
            label: SizedBox(
                width: 100,
                child: TableColumnWidget(title: 'Hitches Count')
            ),
            numeric: true,
          ),
          DataColumn(
            label: Expanded(
              flex: 2,
              child: TableColumnWidget(title: 'User ID'),
            ),
          ),
        ],
        rows: users.map((user) => _buildDataRow(user)).toList(),
      ),
    );
  }

  DataRow _buildDataRow(HitchTrackerUserModel user) {
    return DataRow(
      cells: [
        DataCell(
          Center(
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.textFieldFillColor,
              backgroundImage: user.profilePicture.isNotEmpty
                  ? CachedNetworkImageProvider(user.profilePicture)
                  : null,
              child: user.profilePicture.isEmpty
                  ? Text(
                user.userName.isNotEmpty ? user.userName[0].toUpperCase() : '?',
                style: AppTextStyles.regularTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              )
                  : null,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: double.infinity,
            child: Text(
              user.userName.isNotEmpty ? user.userName : 'Unknown User',
              style: AppTextStyles.regularTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: double.infinity,
            child: Text(
              user.bio.isNotEmpty ? user.bio : 'No bio available',
              style: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              user.hitchesCount.toString(),
              style: AppTextStyles.regularTextStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: double.infinity,
            child: Text(
              user.userID,
              style: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
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
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Text(
            "Found $_totalSearchCount total result${_totalSearchCount == 1 ? '' : 's'} for '$_searchQuery'",
            style: AppTextStyles.smallTextStyle.copyWith(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
    } else if (!_isInSearchMode && _users.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Text(
          "Showing ${_users.length} record${_users.length == 1 ? '' : 's'}",
          style: AppTextStyles.smallTextStyle.copyWith(
            color: Colors.grey[600],
          ),
        ),
      );
    }
    return SizedBox.shrink();
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

    setState(()=> _isLoading = true);

    try {
      Query query = _firestore
          .collection('hitches_tracker').doc('hitch_tracker_doc').collection('users').orderBy('hitchesCount', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot snapshot = await query.get();
      debugPrint("Users: ${snapshot.docs.length}");
      if (snapshot.docs.isNotEmpty) {
        final List<HitchTrackerUserModel> newUsers = snapshot.docs
            .map((doc) => HitchTrackerUserModel.fromMap(doc.data() as Map<String, dynamic>))
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
        setState(()=>  _hasMoreData = false);
      }
    } catch (e) {
      // Handle error silently for now
      debugPrint('Error loading users: $e');
    } finally {
      setState(()=> _isLoading = false);
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
      _lastSearchDocument = null;
      _hasMoreSearchResults = true;
      _totalSearchCount = null;
    });

    // Start count query in parallel
    _getSearchResultsCount(_searchQuery);

    await _searchInFirebase(_searchQuery);
  }

  Future<void> _searchInFirebase(String query) async {
    try {
      // final String queryLower = query.toLowerCase();

      // Search by userName (primary search)
      Query searchQuery = _firestore
          .collection('hitches_tracker').doc('hitch_tracker_doc').collection('users')
          .orderBy('userName')
          .where('userName', isGreaterThanOrEqualTo: query)
          .where('userName', isLessThan: query + '\uf8ff')
          .limit(_pageSize);

      if (_lastSearchDocument != null) {
        searchQuery = searchQuery.startAfterDocument(_lastSearchDocument!);
      }

      final QuerySnapshot snapshot = await searchQuery.get();
      List<HitchTrackerUserModel> results = [];

      if (snapshot.docs.isNotEmpty) {
        results = snapshot.docs
            .map((doc) => HitchTrackerUserModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        _lastSearchDocument = snapshot.docs.last;
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
      setState(()=> _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreSearchResults() async {
    if (_isSearching || !_hasMoreSearchResults) return;
    await _searchInFirebase(_searchQuery);
  }

  Future<void> _getSearchResultsCount(String query) async {
    if (_isCountLoading) return;

    setState(() {
      _isCountLoading = true;
    });

    try {
      // Search count query for userName field
      Query countQuery = _firestore
          .collection('hitches_tracker').doc('hitch_tracker_doc').collection('users')
          .where('userName', isGreaterThanOrEqualTo: query)
          .where('userName', isLessThan: query + '\uf8ff');

      final AggregateQuerySnapshot countResult = await countQuery.count().get();

      setState(() {
        _totalSearchCount = countResult.count ?? 0;
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

}