import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/models/accepted_hitch_user_model.dart';
import 'package:hitch_tracker/src/res/app_colors.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';
import 'package:hitch_tracker/src/widgets/table_column_title_widget.dart';



class AcceptedHitchRequestsPage extends StatefulWidget {
  const AcceptedHitchRequestsPage({super.key});

  @override
  State<AcceptedHitchRequestsPage> createState() => _AcceptedHitchRequestsPageState();
}

class _AcceptedHitchRequestsPageState extends State<AcceptedHitchRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<AcceptedHitchUserModel> _users = [];
  List<AcceptedHitchUserModel> _filteredUsers = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool _isInSearchMode = false;
  static const int _pageSize = 8;



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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Accepted Hitch Users", style: AppTextStyles.largeTextStyle,),
                  Text("Users who have accepted hitch requests", style: AppTextStyles.smallTextStyle,)
                ],
              )
          ),
        ),
        // Search field
        SliverPadding(
          padding: const EdgeInsets.only(top: 10, bottom: 10, right: 100),
          sliver: SliverToBoxAdapter(
              child: Card(
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
                        hintText: 'Search by name, bio, or user ID',
                        hintStyle: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey,),
                      ),
                    ),
                  ),
                ),
              )
          ),
        ),
        _buildUsersSliver(),
      ],
    );
  }

  Widget _buildUsersSliver() {
    final currentUsers = _isInSearchMode ? _filteredUsers : _users;

    if (currentUsers.isEmpty && !_isLoading) {
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
            if (_isLoading || _hasMoreData)
              _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable(List<AcceptedHitchUserModel> users) {
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
            label: SizedBox(
              width: 80,
              child: Center(child: TableColumnWidget(title: 'Profile'))
            ),
          ),
          DataColumn(
            label: Expanded(
              flex: 2,
              child: TableColumnWidget(title: 'User Name')
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
              width: 120,
              child: TableColumnWidget(title: 'Accepted Hitches')
            ),
            numeric: true,
          ),
          DataColumn(
            label: Expanded(
              flex: 2,
              child: TableColumnWidget(title: 'User ID')
            ),
          ),
        ],
        rows: users.map((user) => _buildDataRow(user)).toList(),
      ),
    );
  }

  DataRow _buildDataRow(AcceptedHitchUserModel user) {
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
              user.acceptedHitchCount.toString(),
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
            _searchQuery.isEmpty ? 'No accepted hitch users found' : 'No users match your search',
            style: AppTextStyles.regularTextStyle.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Users who accept hitches will appear here'
                : 'Try a different search term',
            style: AppTextStyles.smallTextStyle.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(color: AppColors.primaryColor,),
    );
  }


  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isInSearchMode && !_isLoading && _hasMoreData) {
        _loadMoreUsers();
      }
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final newQuery = _searchController.text.trim();
      setState(() {
        _searchQuery = newQuery;
        _isInSearchMode = newQuery.isNotEmpty;
      });
      _filterUsers();
    });
  }

  void _filterUsers() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredUsers.clear();
        _isInSearchMode = false;
      });
      return;
    }

    final query = _searchQuery.toLowerCase();
    final filtered = _users.where((user) {
      return user.userName.toLowerCase().contains(query) ||
             user.bio.toLowerCase().contains(query) ||
             user.userID.toLowerCase().contains(query);
    }).toList();

    setState(() {
      _filteredUsers = filtered;
    });
  }

  Future<void> _loadUsers() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      // First, fetch accepted hitch counts from the accepted_hitches_userCount collection
      Query acceptedHitchQuery = _firestore
          .collection('hitches_tracker')
          .doc('hitches_tracker_doc')
          .collection('accepted_hitches_userCount')
          .orderBy('acceptedHitchCount', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        acceptedHitchQuery = acceptedHitchQuery.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot acceptedHitchSnapshot = await acceptedHitchQuery.get();
      debugPrint("Accepted Hitch Users: ${acceptedHitchSnapshot.docs.length}");

      if (acceptedHitchSnapshot.docs.isNotEmpty) {
        final List<AcceptedHitchUserModel> newUsers = [];

        // For each accepted hitch document, fetch user details
        for (final acceptedHitchDoc in acceptedHitchSnapshot.docs) {
          final String userID = acceptedHitchDoc.id; // Document ID is the userID
          final map = acceptedHitchDoc.data() as Map<String, dynamic>;
          final int acceptedHitchCount = map['acceptedHitchCount'] ?? 0;

          try {
            // Fetch user details from users collection
            final DocumentSnapshot userDoc = await _firestore
                .collection('users')
                .doc(userID)
                .get();

            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final user = AcceptedHitchUserModel(
                userName: userData['userName'] ?? '',
                userID: userID,
                profilePicture: userData['profilePicture'] ?? '',
                bio: userData['bio'] ?? '',
                acceptedHitchCount: acceptedHitchCount,
              );
              newUsers.add(user);
            }
          } catch (e) {
            debugPrint('Error fetching user details for $userID: $e');
            // Continue processing other users even if one fails
          }
        }

        setState(() {
          if (_lastDocument == null) {
            _users = newUsers;
          } else {
            _users.addAll(newUsers);
          }
          _lastDocument = acceptedHitchSnapshot.docs.last;
          _hasMoreData = acceptedHitchSnapshot.docs.length == _pageSize;
        });

        // Reapply search filter if in search mode
        if (_isInSearchMode) {
          _filterUsers();
        }
      } else {
        setState(() => _hasMoreData = false);
      }
    } catch (e) {
      debugPrint('Error loading accepted hitch users: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreUsers() async {
    await _loadUsers();
  }

}
