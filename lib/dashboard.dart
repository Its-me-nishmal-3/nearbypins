// dashboard.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import 'user_model.dart';
import 'friend.dart';
import 'all.dart';
import 'premium.dart';
import 'privacy.dart';
import 'social.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  // Define your colors
  final Color primaryColor = Color(0xff1f4068);
  final Color secondaryColor = Color(0xff3fbbe4);
  final Color cardColor = Color(0xff162447);
  final Color textColor = Colors.white;
  final Color premiumColor = Colors.amber;

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isUsersLoading = false;
  Map<String, List<User>> groupedUsers = {};

  // Search state variables
  bool isSearching = false;
  List<User> searchResults = [];
  int searchLimit = 20;
  int searchSkip = 0;
  bool searchHasMore = true;
  bool searchIsFetchingMore = false;

  // Filter parameters
  String? selectedGender;
  String sortBy = 'officeName';
  String order = 'asc';

  // Pagination parameters for default user list
  int limit = 10;
  int skip = 0;
  bool hasMore = true;
  bool isFetchingMore = false;

  // Scroll Controller
  final ScrollController _scrollController = ScrollController();

  // Animation Controller
  late AnimationController _animationController;

  // Variables to store current search parameters
  String _currentSearchMobile = '';
  String _currentSearchName = '';
  String _currentSearchPlace = '';

  @override
  void initState() {
    super.initState();
    _validateTokenAndFetchUser();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll Listener for Pagination
  void _scrollListener() {
    if (!isSearching &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isFetchingMore &&
        hasMore) {
      _fetchMoreUsers();
    }

    if (isSearching &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !searchIsFetchingMore &&
        searchHasMore) {
      _fetchMoreSearchResults();
    }
  }

  // Function to fetch more users for pagination
  Future<void> _fetchMoreUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      await _fetchUsers(token);
    }
  }

  // Function to fetch more search results for pagination
  Future<void> _fetchMoreSearchResults() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null && isSearching) {
      setState(() {
        searchIsFetchingMore = true;
      });
      try {
        final response = await http.get(
          Uri.parse(
              'https://nearbypins.vercel.app/api/auth/search?limit=$searchLimit&skip=$searchSkip&mobile=${Uri.encodeComponent(_currentSearchMobile)}&name=${Uri.encodeComponent(_currentSearchName)}&place=${Uri.encodeComponent(_currentSearchPlace)}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          var res = json.decode(response.body);
          if (res['success'] && res['data'] != null) {
            List<User> tempSearchResults = [];
            for (var userJson in res['data']) {
              tempSearchResults.add(User.fromJson(userJson));
            }

            setState(() {
              searchResults.addAll(tempSearchResults);
              searchSkip += searchLimit;
              searchHasMore = tempSearchResults.length == searchLimit;
              searchIsFetchingMore = false;
            });
          } else {
            _showFlushbar(
              title: "Error",
              message: "Failed to fetch search results.",
              backgroundColor: Colors.red,
            );
            setState(() {
              searchIsFetchingMore = false;
              searchHasMore = false;
            });
          }
        } else {
          _showFlushbar(
            title: "Error",
            message: "Server error while fetching search results.",
            backgroundColor: Colors.red,
          );
          setState(() {
            searchIsFetchingMore = false;
            searchHasMore = false;
          });
        }
      } catch (e) {
        _showFlushbar(
          title: "Error",
          message: "An error occurred while fetching search results.",
          backgroundColor: Colors.red,
        );
        setState(() {
          searchIsFetchingMore = false;
          searchHasMore = false;
        });
      }
    }
  }

  // Validate token and fetch user data
  Future<void> _validateTokenAndFetchUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      _navigateToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://nearbypins.vercel.app/api/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        if (res['success'] && res['data'] != null) {
          setState(() {
            userData = res['data'];
            isLoading = false;
          });
          await _fetchUsers(token, reset: true);
        } else {
          await _clearTokenAndNavigate();
        }
      } else {
        await _clearTokenAndNavigate();
      }
    } catch (e) {
      await _clearTokenAndNavigate();
    }
  }

  // Function to fetch users list with filters
  Future<void> _fetchUsers(String token, {bool reset = false}) async {
    if (reset) {
      setState(() {
        isUsersLoading = true;
        skip = 0;
        groupedUsers.clear();
        hasMore = true;
      });
    } else {
      setState(() {
        isFetchingMore = true;
      });
    }

    // Build query parameters based on filters
    Map<String, dynamic> queryParams = {
      if (selectedGender != null && selectedGender!.isNotEmpty)
        'gender': selectedGender!,
      'sortBy': sortBy,
      'order': order,
      'limit': limit,
      'skip': skip,
    };

    String queryString = Uri(
        queryParameters: queryParams
            .map((key, value) => MapEntry(key, value.toString()))).query;

    try {
      final response = await http.get(
        Uri.parse('https://nearbypins.vercel.app/api/auth/users?$queryString'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        if (res['success'] && res['data'] != null) {
          Map<String, List<User>> tempGroupedUsers = {};

          res['data'].forEach((groupKey, userList) {
            List<User> usersInGroup = [];
            for (var userJson in userList) {
              usersInGroup.add(User.fromJson(userJson));
            }
            tempGroupedUsers[groupKey] = usersInGroup;
          });

          setState(() {
            if (reset) {
              groupedUsers = tempGroupedUsers;
            } else {
              tempGroupedUsers.forEach((key, value) {
                if (groupedUsers.containsKey(key)) {
                  groupedUsers[key]!.addAll(value);
                } else {
                  groupedUsers[key] = value;
                }
              });
            }
            skip += limit;
            hasMore = _userListLength(res['data']) == limit;
            isUsersLoading = false;
            isFetchingMore = false;
          });
        } else {
          _showFlushbar(
            title: "Error",
            message: "Failed to fetch users.",
            backgroundColor: Colors.red,
          );
          setState(() {
            isUsersLoading = false;
            isFetchingMore = false;
            hasMore = false;
          });
        }
      } else {
        _showFlushbar(
          title: "Error",
          message: "Server error while fetching users.",
          backgroundColor: Colors.red,
        );
        setState(() {
          isUsersLoading = false;
          isFetchingMore = false;
          hasMore = false;
        });
      }
    } catch (e) {
      _showFlushbar(
        title: "Error",
        message: "An error occurred while fetching users.",
        backgroundColor: Colors.red,
      );
      setState(() {
        isUsersLoading = false;
        isFetchingMore = false;
        hasMore = false;
      });
    }
  }

  int _userListLength(dynamic data) {
    int length = 0;
    data.forEach((key, value) {
      length += (value.length as int); // Cast to int
    });
    return length;
  }

  // Helper function to display Flushbar alerts
  void _showFlushbar({
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              title == "Success" ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(child: Text("$title: $message")),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _clearSearch() {
    setState(() {
      isSearching = false;
      searchResults.clear();
      searchSkip = 0;
      searchHasMore = true;
      searchIsFetchingMore = false;
      _currentSearchMobile = '';
      _currentSearchName = '';
      _currentSearchPlace = '';
    });
  }

  Future<void> _clearTokenAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _showFlushbar(
      title: "Error",
      message: "Invalid token. Please login again.",
      backgroundColor: Colors.red,
    );
    _navigateToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text('Dashboard', style: TextStyle(fontSize: 20)),
        backgroundColor: secondaryColor,
        leading: isSearching // Show back button only when searching
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  _clearSearch(); // Clear search and go back to the default view
                },
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: () async {
                // Fetch the current user's mobile number from SharedPreferences
                String? currentUserMobile = await _getCurrentUserMobile();

                // Fetch the tapped user's mobile number from userData
                String? tappedUserMobile =
                    userData != null ? userData!['mobile'] : null;

                if (currentUserMobile != null && tappedUserMobile != null) {
                  if (currentUserMobile == tappedUserMobile) {
                    // Navigate to OwnProfileScreen if it's the current user's profile
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FriendScreen(mobile: tappedUserMobile)),
                    );
                  } else {
                    // Navigate to FriendScreen with the tapped user's mobile number
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FriendScreen(
                          mobile: tappedUserMobile,
                        ),
                      ),
                    );
                  }
                } else {
                  // Show an error SnackBar if mobile numbers are not available
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('User information is incomplete.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: userData != null &&
                            userData!['dpurl'] != null &&
                            userData!['dpurl'].isNotEmpty
                        ? NetworkImage(userData!['dpurl'])
                        : null,
                    backgroundColor: cardColor,
                    child: userData != null &&
                            userData!['dpurl'] != null &&
                            userData!['dpurl'].isEmpty
                        ? Icon(Icons.person, color: textColor)
                        : null,
                    radius: 20,
                  ),
                  if (userData != null && userData!['isPremium'] == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: premiumColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 2),
                        ),
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.star, // Premium badge icon
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (!isSearching) // Hide search button when searching
            IconButton(
              icon: Icon(Icons.search),
              onPressed: _showSearchModal,
              tooltip: 'Search',
            ),
          if (!isSearching) // Hide filter button when searching
            IconButton(
              icon: Icon(Icons.filter_list),
              onPressed: _openFilterModal,
              tooltip: 'Filter',
            ),
          // **Add the PopupMenuButton (Hamburger Menu)**
          PopupMenuButton<String>(
            icon: Icon(Icons.menu), // Hamburger menu icon
            onSelected: (String value) {
              if (value == 'Logout') {
                _logout(); // Call your existing logout function
              } else if (value == 'Social Links') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SocialLinksScreen()),
                );
              } else if (value == 'Privacy') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PrivacyScreen()),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Privacy',
                child: Row(
                  children: [
                    Icon(Icons.lock, color: secondaryColor),
                    SizedBox(width: 8),
                    Text('Privacy'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'Social Links',
                child: Row(
                  children: [
                    Icon(Icons.message, color: secondaryColor),
                    SizedBox(width: 8),
                    Text('Social Links'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'Logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: secondaryColor),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
              ),
            )
          : userData != null
              ? RefreshIndicator(
                  onRefresh: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    String? token = prefs.getString('token');
                    if (token != null) {
                      if (isSearching) {
                        await _performSearch(
                            mobile: _currentSearchMobile,
                            name: _currentSearchName,
                            place: _currentSearchPlace);
                      } else {
                        await _fetchUsers(token, reset: true);
                      }
                    }
                  },
                  child: isUsersLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(secondaryColor),
                          ),
                        )
                      : (isSearching
                          ? _buildSearchResults()
                          : (groupedUsers.isNotEmpty
                              ? ListView(
                                  padding: const EdgeInsets.all(16.0),
                                  controller: _scrollController,
                                  children: [
                                    ..._buildGroupedUserLists(),
                                    if (isFetchingMore)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    secondaryColor),
                                          ),
                                        ),
                                      ),
                                  ],
                                )
                              : Center(
                                  child: Text(
                                    'No users available.',
                                    style: TextStyle(
                                        color: textColor, fontSize: 16),
                                  ),
                                ))),
                )
              : Center(
                  child: Text(
                    'User data not available.',
                    style: TextStyle(color: textColor, fontSize: 18),
                  ),
                ),
    );
  }

  Future<String?> _getCurrentUserMobile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('mobile');
  }

  Future<void> _performSearch(
      {String? mobile, String? name, String? place}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      _navigateToLogin();
      return;
    }

    setState(() {
      isSearching = true;
      searchResults.clear();
      searchSkip = 0;
      searchHasMore = true;
      searchIsFetchingMore = false;
      _currentSearchMobile = mobile ?? '';
      _currentSearchName = name ?? '';
      _currentSearchPlace = place ?? '';
    });

    // Build query parameters
    Map<String, dynamic> queryParams = {
      if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
      if (name != null && name.isNotEmpty) 'name': name,
      if (place != null && place.isNotEmpty) 'place': place,
      'limit': searchLimit.toString(),
      'skip': searchSkip.toString(),
    };

    String queryString = Uri(
        queryParameters: queryParams
            .map((key, value) => MapEntry(key, value.toString()))).query;

    try {
      final response = await http.get(
        Uri.parse('https://nearbypins.vercel.app/api/auth/search?$queryString'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        if (res['success'] && res['data'] != null) {
          List<User> tempSearchResults = [];
          for (var userJson in res['data']) {
            tempSearchResults.add(User.fromJson(userJson));
          }

          setState(() {
            searchResults = tempSearchResults;
            searchSkip += searchLimit;
            searchHasMore = tempSearchResults.length == searchLimit;
          });
        } else {
          _showFlushbar(
            title: "Info",
            message: "No users found for the search criteria.",
            backgroundColor: Colors.blue,
          );
          setState(() {
            searchHasMore = false;
          });
        }
      } else {
        _showFlushbar(
          title: "Error",
          message: "Server error while searching users.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      _showFlushbar(
        title: "Error",
        message: "An error occurred while searching users.",
        backgroundColor: Colors.red,
      );
    }
  }

  List<Widget> _buildGroupedUserLists() {
    List<String> groupOrder = [
      'premium_officeName',
      'premium_taluk',
      'premium_districtName',
      'premium_stateName',
      'nonPremium_officeName',
      'nonPremium_taluk',
      'nonPremium_districtName',
      'nonPremium_stateName',
    ];

    List<Widget> groupWidgets = [];

    for (String groupKey in groupOrder) {
      if (groupedUsers.containsKey(groupKey) &&
          groupedUsers[groupKey]!.isNotEmpty) {
        String displayGroupName =
            _getDisplayGroupName(groupKey, groupedUsers[groupKey]!);

        groupWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayGroupName,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward, color: textColor),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllScreen(
                          groupKey: groupKey,
                          groupName: displayGroupName,
                        ),
                      ),
                    );
                  },
                  tooltip: 'View All',
                ),
              ],
            ),
          ),
        );

        groupWidgets.add(
          Container(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: groupedUsers[groupKey]!.length,
              itemBuilder: (context, index) {
                User user = groupedUsers[groupKey]![index];
                return _buildUserCard(user);
              },
            ),
          ),
        );
      }
    }

    return groupWidgets;
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      controller: _scrollController,
      itemCount: searchResults.length + (searchIsFetchingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < searchResults.length) {
          User user = searchResults[index];
          return _buildSearchUserCard(user);
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildSearchUserCard(User user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendScreen(
              mobile: user.mobile,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: user.isPremium
                        ? LinearGradient(
                            colors: [Colors.amber, Colors.amberAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    border: Border.all(
                      color: user.isPremium ? Colors.transparent : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        user.dpUrl.isNotEmpty ? NetworkImage(user.dpUrl) : null,
                    backgroundColor: cardColor,
                    child: user.dpUrl.isEmpty
                        ? Icon(Icons.person, color: textColor, size: 30)
                        : null,
                  ),
                ),
                if (user.isPremium)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 5),
                  Text(
                    user.officeName.isNotEmpty ? user.officeName : 'No Office',
                    style: TextStyle(color: Colors.yellowAccent, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayGroupName(String groupKey, List<User> users) {
    String displayName = '';

    // Determine premium status
    bool isPremium = groupKey.startsWith('premium_');

    // Determine match level
    String matchLevel = groupKey.split('_')[1];

    // Extract place name from users
    String placeName = _getPlaceNameFromUsers(matchLevel, users);

    // Build display name
    if (isPremium) {
      displayName = 'Premium Users in $placeName';
    } else {
      displayName = 'Users in $placeName';
    }

    return displayName;
  }

  void _resetFilters() {
    setState(() {
      selectedGender = null; // Reset gender filter
      searchResults.clear(); // Clear search results
      groupedUsers.clear(); // Clear grouped users
      isSearching = false; // Reset search state
      skip = 0; // Reset pagination
      searchSkip = 0;
      hasMore = true; // Reset pagination flag
      searchHasMore = true;
      isUsersLoading = false;
      isFetchingMore = false;
    });

    // Fetch users again without filters
    _fetchUsersFromFilters();
  }

  String _getPlaceNameFromUsers(String matchLevel, List<User> users) {
    String placeName = '';

    // We assume that all users in the group have the same match level place name
    if (users.isNotEmpty) {
      User firstUser = users[0];

      switch (matchLevel) {
        case 'officeName':
          placeName = firstUser.officeName.isNotEmpty
              ? firstUser.officeName
              : 'Unknown Office';
          break;
        case 'taluk':
          placeName =
              firstUser.taluk.isNotEmpty ? firstUser.taluk : 'Unknown Taluk';
          break;
        case 'districtName':
          placeName = firstUser.districtName.isNotEmpty
              ? firstUser.districtName
              : 'Unknown District';
          break;
        case 'stateName':
          placeName = firstUser.stateName.isNotEmpty
              ? firstUser.stateName
              : 'Unknown State';
          break;
        default:
          placeName = 'Unknown Location';
      }
    } else {
      placeName = 'Unknown Location';
    }

    return placeName;
  }

  Widget _buildUserCard(User user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendScreen(
              mobile: user.mobile,
            ),
          ),
        );
      },
      child: Card(
        color: Color(0xff133051), // Set your desired card background color
        elevation: 4, // Adjust the elevation as needed
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        margin: EdgeInsets.symmetric(
            horizontal: 5, vertical: 10), // Margin around the card
        child: Container(
          width: 120,
          padding: EdgeInsets.all(8), // Padding inside the card
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // Adjust the column size to fit its children
            children: [
              Stack(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: user.isPremium
                          ? LinearGradient(
                              colors: [Colors.amber, Colors.amberAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      border: Border.all(
                        color:
                            user.isPremium ? Colors.transparent : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundImage: user.dpUrl.isNotEmpty
                          ? NetworkImage(user.dpUrl)
                          : null,
                      backgroundColor: cardColor,
                      child: user.dpUrl.isEmpty
                          ? Icon(Icons.person, color: textColor, size: 40)
                          : null,
                    ),
                  ),
                  if (user.isPremium)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                user.name,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4), // Optional: Add some spacing between texts
              Text(
                user.officeName.isNotEmpty ? user.districtName : 'No Office',
                style: TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFilterModal() {
    if (userData != null && userData!['isPremium'] == true) {
      showModalBottomSheet(
        context: context,
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Filter by Gender',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedGender = null;
                    });
                    Navigator.pop(context);
                    _fetchUsersFromFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('All', style: TextStyle(fontSize: 16)),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedGender = 'male';
                    });
                    Navigator.pop(context);
                    _fetchUsersFromFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Men', style: TextStyle(fontSize: 16)),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedGender = 'female';
                    });
                    Navigator.pop(context);
                    _fetchUsersFromFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Women', style: TextStyle(fontSize: 16)),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    setState(() {
                      selectedGender = null;
                    });
                    Navigator.pop(context);
                    _fetchUsersFromFilters();
                  },
                  child: Text('Reset Filters',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
              ],
            ),
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentScreen()),
      );
    }
  }

  void _showSearchModal() {
    if (userData != null && userData!['isPremium'] == true) {
      String? mobile;
      String? name;
      String? place;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: cardColor,
            title: Text('Search Users', style: TextStyle(color: textColor)),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: secondaryColor),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: secondaryColor),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    style: TextStyle(color: textColor),
                    onChanged: (value) {
                      mobile = value.trim();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: secondaryColor),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: secondaryColor),
                      ),
                    ),
                    style: TextStyle(color: textColor),
                    onChanged: (value) {
                      name = value.trim();
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Place',
                      labelStyle: TextStyle(color: textColor),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: secondaryColor),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: secondaryColor),
                      ),
                    ),
                    style: TextStyle(color: textColor),
                    onChanged: (value) {
                      place = value.trim();
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel', style: TextStyle(color: secondaryColor)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text('Search', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _performSearch(mobile: mobile, name: name, place: place);
                },
              ),
            ],
          );
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PaymentScreen()),
      );
    }
  }

  Future<void> _fetchUsersFromFilters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token != null) {
      await _fetchUsers(token, reset: true);
    }
  }

  Future<void> _logout() async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text('Confirm Logout', style: TextStyle(color: textColor)),
          content: Text('Are you sure you want to logout?',
              style: TextStyle(color: textColor)),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: secondaryColor)),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text('Logout', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmLogout != null && confirmLogout) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      _showFlushbar(
        title: "Success",
        message: "Logged out successfully!",
        backgroundColor: Colors.green,
      );
      _navigateToLogin();
    }
  }
}
