import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/helpers/date_time_helper.dart';
import 'package:hitch_tracker/src/models/chat_trigger_model.dart';
import 'package:hitch_tracker/src/res/app_colors.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/hitch_count_provider.dart';
import '../res/string_constants.dart';
import '../widgets/table_column_title_widget.dart';

class ChatsTriggeredPage extends StatefulWidget {
  const ChatsTriggeredPage({super.key});

  @override
  State<ChatsTriggeredPage> createState() => _ChatsTriggeredPageState();
}

class _ChatsTriggeredPageState extends State<ChatsTriggeredPage> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  String? _selectedTriggerType;

  // List of items in our dropdown menu
  final _triggerTypes = [
    triggerTypeEmail,
    triggerTypeMessage,
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<EmailMessageTrackerModel> _users = [];
  List<EmailMessageTrackerModel> _searchResults = [];
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
    _loadChats();
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
          padding: const EdgeInsets.only(top: 20, bottom: 10, right: 100),
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
                        children: [
                          Text("Chat Triggers", style: AppTextStyles.largeTextStyle,),
                          Consumer<HitchCountProvider>(builder: (_, provider, _){
                            return Text(provider.totalUsers == 1 ? "" : '${provider.totalChats}', style: AppTextStyles.headingTextStyle.copyWith(color: AppColors.primaryColor),);
                          }),
                        ],
                      ),
                      Text('A comprehensive list of all users on triggered the chat feature', style: AppTextStyles.smallTextStyle,)
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
                                hintText: 'Search by user name, trigger ID',
                                hintStyle: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey,),
                              ),
                            ),
                          )),

                          /*Expanded(child: FormField<String>(
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
                                isEmpty: _selectedTriggerType == null,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedTriggerType,
                                    hint: Text('Trigger Type', style: AppTextStyles.smallTextStyle,),
                                    isDense: true,
                                    elevation: 0,
                                    dropdownColor: Colors.white,
                                    onChanged: (String? newValue) {
                                      setState(()=> _selectedTriggerType = newValue);
                                    },
                                    items: _triggerTypes.map((String value) {
                                      return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value)
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),)*/
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
    // final currentUsers = _isInSearchMode ? _searchResults : _users;
    // final isCurrentlyLoading = _isInSearchMode ? _isSearching : _isLoading;
    // final hasMore = _isInSearchMode ? _hasMoreSearchResults : _hasMoreData;

    if (_users.isEmpty && !_isLoading) {
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
            _buildUsersTable(_users),
            // Loading indicator
            if (_isLoading || _hasMoreData)
              _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable(List<EmailMessageTrackerModel> users) {
    if (users.isEmpty) {
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
            label: SizedBox(
                width: 80,
                child: Center(child: TableColumnWidget(title: 'Track ID'))
            ),
          ),
          DataColumn(
            label: Expanded(
                flex: 2,
                child: TableColumnWidget(title: 'Trigger By')
            ),
          ),
          DataColumn(
            label: Expanded(
                flex: 3,
                child: TableColumnWidget(title: 'Triggered For')
            ),
          ),
          DataColumn(
            label: Expanded(
                flex: 2,
                child: TableColumnWidget(title: 'Triggered On')
            ),
            numeric: true,
          ),
          DataColumn(
            label: Expanded(
                flex: 2,
                child: TableColumnWidget(title: 'Trigger Type')
            ),
          ),
        ],
        rows: users.map((user) => _buildDataRow(user)).toList(),
      ),
    );
  }

  DataRow _buildDataRow(EmailMessageTrackerModel user) {
    return DataRow(
      cells: [
        DataCell(
          Center(
              child: Text(
                user.trackID,
                style: AppTextStyles.regularTextStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              )
          ),
        ),
        DataCell(
          SizedBox(
            width: double.infinity,
            child: Text(
              user.triggeredByUName,
              style: AppTextStyles.regularTextStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: double.infinity,
            child: Text(
              user.triggeredForUName,
              style: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: double.infinity,
            child: Text(
              DateTimeHelper.formatDateTime(user.triggeredOn),
              style: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: double.infinity,
            child: Text(
              user.triggeredType,
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

  Future<void> _loadChats() async {
    if (_isLoading) return;

    setState(() =>  _isLoading = true);

    try {
      Query query = _firestore
          .collection(chatClickTrackerCollection).orderBy('triggeredOn', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot snapshot = await query.get();
      // debugPrint("Users: ${snapshot.docs.length}");
      if (snapshot.docs.isNotEmpty) {
        final List<EmailMessageTrackerModel> newUsers = snapshot.docs
            .map((doc) => EmailMessageTrackerModel.fromMap(doc.data() as Map<String, dynamic>))
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
    await _loadChats();
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
          .collection(chatClickTrackerCollection)
          .orderBy('triggeredByUName')
          .where('triggeredByUName', isGreaterThanOrEqualTo: query)
          .where('triggeredByUName', isLessThan: query + '\uf8ff')
          .limit(_pageSize);

      if (_lastSearchDocument != null) {
        searchQuery = searchQuery.startAfterDocument(_lastSearchDocument!);
      }

      final QuerySnapshot snapshot = await searchQuery.get();
      List<EmailMessageTrackerModel> results = [];

      if (snapshot.docs.isNotEmpty) {
        results = snapshot.docs
            .map((doc) => EmailMessageTrackerModel.fromMap(doc.data() as Map<String, dynamic>))
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

  Future<void> _searchBioField(String queryLower, List<EmailMessageTrackerModel> existingResults) async {
    try {
      // Search in bio field for additional results
      final QuerySnapshot bioSnapshot = await _firestore
          .collection(chatClickTrackerCollection)
          .where('triggeredByUName', isGreaterThanOrEqualTo: queryLower)
          .where('triggeredByUName', isLessThan: queryLower + '\uf8ff')
          .limit(_pageSize - existingResults.length)
          .get();

      if (bioSnapshot.docs.isNotEmpty) {
        final bioResults = bioSnapshot.docs
            .map((doc) => EmailMessageTrackerModel.fromMap(doc.data() as Map<String, dynamic>))
            .where((user) => !existingResults.any((existing) => existing.trackID == user.trackID))
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