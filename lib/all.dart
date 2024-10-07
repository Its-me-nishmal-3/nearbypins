// all.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_model.dart';
import 'friend.dart'; // Import the FriendScreen
import 'login.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import the animations package

class AllScreen extends StatefulWidget {
  final String groupKey; // e.g., 'premium_officeName', 'nonPremium_taluk', etc.
  final String groupName; // e.g., 'Premium Users in Office XYZ'

  AllScreen({required this.groupKey, required this.groupName});

  @override
  _AllScreenState createState() => _AllScreenState();
}

class _AllScreenState extends State<AllScreen> {
  // Define your colors
  final Color primaryColor = Color(0xff133051); // Updated to 0xff133051
  final Color secondaryColor = Color(0xff3fbbe4); // Vibrant blue
  final Color cardColor = Color(0xff162447); // Darker shade of blue
  final Color textColor = Colors.white; // White text color for contrast

  List<User> users = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMore = true;

  // Pagination parameters
  int limit = 10;
  int skip = 0;

  // Scroll Controller for pagination
  final ScrollController _scrollController = ScrollController();

  // Filter and sort parameters
  String? selectedGender;
  double minMatchScore = 0;
  String sortBy = 'matchScore';
  String order = 'desc';
  String? filterOfficeName;
  String? filterTaluk;
  String? filterDistrictName;
  String? filterStateName;

  @override
  void initState() {
    super.initState();
    _fetchUsers(initialLoad: true);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll Listener for Pagination
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isFetchingMore &&
        hasMore) {
      _fetchUsers();
    }
  }

  // Function to fetch users list with filters and pagination
  Future<void> _fetchUsers({bool initialLoad = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      // No token found, navigate to LoginScreen
      _navigateToLogin();
      return;
    }

    if (initialLoad) {
      setState(() {
        isLoading = true;
        skip = 0;
        users.clear();
        hasMore = true;
      });
    } else {
      setState(() {
        isFetchingMore = true;
      });
    }

    // Extract group details
    bool isPremium = widget.groupKey.startsWith('premium_');
    String matchLevel = widget.groupKey.split('_')[1]; // e.g., 'officeName'

    // Extract placeName from groupName
    String placeName = '';
    if (isPremium) {
      // Remove 'Premium Users in ' prefix
      placeName = widget.groupName.replaceFirst('Premium Users in ', '');
    } else {
      // Remove 'Users in ' prefix
      placeName = widget.groupName.replaceFirst('Users in ', '');
    }

    // Initialize filter parameters based on matchLevel
    switch (matchLevel) {
      case 'officeName':
        filterOfficeName = placeName;
        break;
      case 'taluk':
        filterTaluk = placeName;
        break;
      case 'districtName':
        filterDistrictName = placeName;
        break;
      case 'stateName':
        filterStateName = placeName;
        break;
      default:
        // Handle unknown matchLevel if necessary
        break;
    }

    // Build query parameters based on filters
    Map<String, dynamic> queryParams = {
      if (selectedGender != null && selectedGender!.isNotEmpty)
        'gender': selectedGender!,
      'minMatchScore': minMatchScore.toInt(),
      'sortBy': sortBy,
      'order': order,
      'limit': limit,
      'skip': skip,
      'isPremium': isPremium.toString(), // Add isPremium filter
      'matchLevel': matchLevel, // Add matchLevel filter
    };

    // Add specific filter based on matchLevel
    switch (matchLevel) {
      case 'officeName':
        queryParams['officeName'] = filterOfficeName!;
        break;
      case 'taluk':
        queryParams['taluk'] = filterTaluk!;
        break;
      case 'districtName':
        queryParams['districtName'] = filterDistrictName!;
        break;
      case 'stateName':
        queryParams['stateName'] = filterStateName!;
        break;
      default:
        // Handle unknown matchLevel if necessary
        break;
    }

    // Convert queryParams to URI query string
    String queryString = Uri(
        queryParameters: queryParams
            .map((key, value) => MapEntry(key, value.toString()))).query;

    try {
      final response = await http.get(
        Uri.parse(
            'https://nearbypins.vercel.app/api/auth/users?$queryString'), // Replace with your actual backend URL
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        if (res['success'] && res['data'] != null) {
          List<User> fetchedUsers = [];
          // Since AllScreen expects a flat list, handle accordingly
          if (res['data'] is List) {
            // Flat list response
            for (var userJson in res['data']) {
              fetchedUsers.add(User.fromJson(userJson));
            }
          } else {
            // Unexpected response format
            _showFlushbar(
              title: "Error",
              message: "Unexpected response format.",
              backgroundColor: Colors.red,
            );
            setState(() {
              isLoading = false;
              isFetchingMore = false;
              hasMore = false;
            });
            return;
          }

          setState(() {
            users.addAll(fetchedUsers);
            skip += limit;
            hasMore = fetchedUsers.length == limit;
            isLoading = false;
            isFetchingMore = false;
          });
        } else {
          // Handle case where data is not present
          _showFlushbar(
            title: "Error",
            message: "Failed to fetch users.",
            backgroundColor: Colors.red,
          );
          setState(() {
            isLoading = false;
            isFetchingMore = false;
            hasMore = false;
          });
        }
      } else {
        // Handle server error
        _showFlushbar(
          title: "Error",
          message: "Server error while fetching users.",
          backgroundColor: Colors.red,
        );
        setState(() {
          isLoading = false;
          isFetchingMore = false;
          hasMore = false;
        });
      }
    } catch (e) {
      // Handle network or parsing error
      _showFlushbar(
        title: "Error",
        message: "An error occurred while fetching users.",
        backgroundColor: Colors.red,
      );
      setState(() {
        isLoading = false;
        isFetchingMore = false;
        hasMore = false;
      });
    }
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

  // Function to clear the token and navigate to LoginScreen
  Future<void> _clearTokenAndNavigate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token'); // Clear the token
    _showFlushbar(
      title: "Error",
      message: "Invalid token. Please login again.",
      backgroundColor: Colors.red,
    );
    _navigateToLogin();
  }

  // Navigate to LoginScreen
  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  // Logout Functionality
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Updated background color
      appBar: AppBar(
        title: Text(widget.groupName, style: TextStyle(fontSize: 18)),
        backgroundColor: secondaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        automaticallyImplyLeading: true, // Shows the back button
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
              ),
            )
          : users.isNotEmpty
              ? AnimationLimiter(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: users.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < users.length) {
                        User user = users[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: _buildUserTile(user),
                            ),
                          ),
                        );
                      } else {
                        // Show loading indicator at the bottom
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(secondaryColor),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                )
              : Center(
                  child: Text(
                    'No users available.',
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                ),
    );
  }

  // Helper method to build individual user tile
  Widget _buildUserTile(User user) {
    return ListTile(
      leading: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(2), // Space between border and image
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
              radius: 25,
              backgroundImage:
                  user.dpUrl.isNotEmpty ? NetworkImage(user.dpUrl) : null,
              backgroundColor: cardColor,
              child: user.dpUrl.isEmpty
                  ? Icon(Icons.person, color: textColor, size: 25)
                  : null,
            ),
          ),
          // Premium badge
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
                  Icons.star, // Premium badge icon
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
      title: Text(
        user.name,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Score: ${user.matchScore}',
        style: TextStyle(color: Colors.yellowAccent, fontSize: 12),
      ),
      trailing: Icon(Icons.arrow_forward, color: secondaryColor),
      onTap: () {
        // Navigate to FriendScreen when a user tile is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FriendScreen(
              mobile: user.mobile,
            ),
          ),
        );
      },
    );
  }
}
