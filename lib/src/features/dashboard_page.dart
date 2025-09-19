import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hitch_tracker/src/models/user_model.dart';
import 'package:hitch_tracker/src/res/app_colors.dart';
import 'package:hitch_tracker/src/res/app_textstyles.dart';
import 'dart:async';

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
  List<UserModel> _filteredUsers = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  DocumentSnapshot? _lastDocument;
  Timer? _debounceTimer;
  String _searchQuery = '';
  
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

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      if (!_isLoading && _hasMoreData && _searchQuery.isEmpty) {
        _loadMoreUsers();
      }
    }
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
      _performSearch();
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
          // .orderBy('userName')
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
          _filteredUsers = _users;
        });
      } else {
        setState(() {
          _hasMoreData = false;
        });
      }
    } catch (e) {
      /*if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }*/
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    await _loadUsers();
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredUsers = _users;
      });
      return;
    }

    setState(() {
      _filteredUsers = _users.where((user) {
        final query = _searchQuery.toLowerCase();
        return user.userName.toLowerCase().contains(query) ||
               user.bio.toLowerCase().contains(query) ||
               (user.emailAddress.toLowerCase().contains(query));
      }).toList();
    });
  }

  Future<void> _refreshUsers() async {
    setState(() {
      _users.clear();
      _filteredUsers.clear();
      _lastDocument = null;
      _hasMoreData = true;
    });
    await _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 20,
          children: [
            Expanded(
              child: _buildInfoItemWidget(title: 'Users', value: _users.length),
            ),
            Expanded(
              child: _buildInfoItemWidget(title: 'Requests', value: 2052),
            ),
            Expanded(
              child: _buildInfoItemWidget(title: 'Chats', value: 935),
            ),
          ],
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Text("Users", style: AppTextStyles.headingTextStyle),
              _buildSearchTextField(),
              _buildUsersList()
            ],
          ),
        )
      ],
    );
  }

  Expanded _buildUsersList() {
    return Expanded(
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5)
        ),
        color: Colors.white,
        child: RefreshIndicator(
          onRefresh: _refreshUsers,
          child: _filteredUsers.isEmpty && !_isLoading
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _filteredUsers.length + (_isLoading || _hasMoreData ? 1 : 0),
                  itemBuilder: (ctx, index) {
                    if (index == _filteredUsers.length) {
                      return _buildLoadingIndicator();
                    }
                    
                    final user = _filteredUsers[index];
                    return _buildUserItem(user);
                  },
                ),
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
                        Text(
                          "Lat: ${user.latitude!.toStringAsFixed(2)}, Lng: ${user.longitude!.toStringAsFixed(2)}",
                          style: AppTextStyles.smallTextStyle,
                        ),
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
        hintText: "Search users by name, bio, or email",
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
          Text("$value", style: AppTextStyles.headingTextStyle)
        ],
      ),
    );
  }
}
