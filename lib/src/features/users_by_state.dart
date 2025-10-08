import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/models/user_by_state_model.dart';
import 'package:hitch_tracker/src/res/app_colors.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../providers/hitch_count_provider.dart';
import '../widgets/table_column_title_widget.dart';

class UsersByState extends StatefulWidget {
  const UsersByState({super.key});

  @override
  State<UsersByState> createState() => _UsersByStateState();
}

class _UsersByStateState extends State<UsersByState> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<UserByStateModel> _states = [];
  List<UserByStateModel> _searchResults = [];
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
    _loadStates();
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
                      Text("Users by State", style: AppTextStyles.largeTextStyle,),
                      Consumer<HitchCountProvider>(builder: (_, provider, _){
                        return Text(provider.totalStates == 1 ? "" : '${provider.totalStates}', style: AppTextStyles.headingTextStyle.copyWith(color: AppColors.primaryColor),);
                      }),
                    ],
                  ),
                  Text("View user distribution across states", style: AppTextStyles.smallTextStyle,)
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
                            hintText: 'Search by state name',
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
        _buildStatesSliver(),
      ],
    );
  }

  Widget _buildStatesSliver() {
    final currentStates = _isInSearchMode ? _searchResults : _states;
    final isCurrentlyLoading = _isInSearchMode ? _isSearching : _isLoading;
    final hasMore = _isInSearchMode ? _hasMoreSearchResults : _hasMoreData;

    if (currentStates.isEmpty && !isCurrentlyLoading) {
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
            _buildStatesTable(currentStates),
            // Loading indicator
            if (isCurrentlyLoading || hasMore)
              _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatesTable(List<UserByStateModel> states) {
    if (states.isEmpty && !_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Text(
          'No states available',
          style: AppTextStyles.regularTextStyle.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: DataTable(
        columnSpacing: 16,
        horizontalMargin: 20,
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
            label: Expanded(
              flex: 2,
              child: TableColumnWidget(title: 'State Name'),
            ),
          ),
          DataColumn(
            label: SizedBox(
                width: 100,
                child: TableColumnWidget(title: 'Short Name')
            ),
          ),
          DataColumn(
            label: SizedBox(
                width: 120,
                child: TableColumnWidget(title: 'Total Users')
            ),
            numeric: true,
          ),
        ],
        rows: states.map((state) => _buildDataRow(state)).toList(),
      ),
    );
  }

  DataRow _buildDataRow(UserByStateModel state) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: double.infinity,
            child: Text(
              state.state.isNotEmpty ? state.state : 'Unknown State',
              style: AppTextStyles.regularTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Text(
            state.stateShortName.isNotEmpty ? state.stateShortName : 'N/A',
            style: AppTextStyles.smallTextStyle.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        DataCell( Text(
          state.totalUsers.toString(),
          style: AppTextStyles.regularTextStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
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
            Icons.location_on_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No states found' : 'No states match your search',
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
    } else if (!_isInSearchMode && _states.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Text(
          "Showing ${_states.length} record${_states.length == 1 ? '' : 's'}",
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
          _loadMoreStates();
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

  Future<void> _loadStates() async {
    if (_isLoading) return;

    setState(()=> _isLoading = true);

    try {
      Query query = _firestore
          .collection('hitch_user_states')
          .orderBy('totalUsers', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot snapshot = await query.get();
      debugPrint("States: ${snapshot.docs.length}");
      if (snapshot.docs.isNotEmpty) {
        final List<UserByStateModel> newStates = snapshot.docs
            .map((doc) => UserByStateModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        setState(() {
          if (_lastDocument == null) {
            _states = newStates;
          } else {
            _states.addAll(newStates);
          }
          _lastDocument = snapshot.docs.last;
          _hasMoreData = snapshot.docs.length == _pageSize;
        });
      } else {
        setState(()=>  _hasMoreData = false);
      }
    } catch (e) {
      // Handle error silently for now
      debugPrint('Error loading states: $e');
    } finally {
      setState(()=> _isLoading = false);
    }
  }

  Future<void> _loadMoreStates() async {
    await _loadStates();
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
      String lowerQuery = query.toLowerCase();
      // Search by state name (primary search)
      Query searchQuery = _firestore
          .collection('hitch_user_states')
          .orderBy('stateLowerCase')
          .where('stateLowerCase', isGreaterThanOrEqualTo: query)
          .where('stateLowerCase', isLessThan: query + '\uf8ff')
          .limit(_pageSize);

      if (_lastSearchDocument != null) {
        searchQuery = searchQuery.startAfterDocument(_lastSearchDocument!);
      }

      final QuerySnapshot snapshot = await searchQuery.get();
      List<UserByStateModel> results = [];

      if (snapshot.docs.isNotEmpty) {
        results = snapshot.docs
            .map((doc) => UserByStateModel.fromMap(doc.data() as Map<String, dynamic>))
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
      // Search count query for state field
      Query countQuery = _firestore
          .collection('hitch_user_states')
          .where('state', isGreaterThanOrEqualTo: query)
          .where('state', isLessThan: query + '\uf8ff');

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