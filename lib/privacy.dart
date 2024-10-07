// privacy.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_model.dart';
import 'premium.dart'; // Import the PremiumScreen
import 'login.dart';

class PrivacyScreen extends StatefulWidget {
  @override
  _PrivacyScreenState createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  // Define your colors
  final Color primaryColor = Color(0xff1f4068); // Deep blue
  final Color secondaryColor = Color(0xff3fbbe4); // Vibrant blue
  final Color cardColor = Color(0xff162447); // Darker shade of blue
  final Color textColor = Colors.white; // White text color for contrast
  final Color premiumColor = Colors.amber; // Define premiumColor as needed

  bool isLoading = true;
  bool isUpdating = false;

  // User details
  User? currentUser;

  // Privacy settings
  bool hideMobile = false;
  bool hideOfficeName = false;
  bool hideDpurl = false;
  bool hideInstagramUsername = false;
  bool hideYoutubeChannel = false;
  bool hideGithubUsername = false;
  bool hideTelegramUsername = false;
  bool hideWebsiteUrl = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  // Function to fetch current user's data
  Future<void> _fetchCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      // No token found, navigate to LoginScreen
      _navigateToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://nearbypins.vercel.app/api/auth/me'), // Replace with your actual backend endpoint to get current user
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        if (res['success'] && res['data'] != null) {
          User fetchedUser = User.fromJson(res['data']);
          setState(() {
            currentUser = fetchedUser;
            hideMobile = fetchedUser.privacy.mobile;
            hideOfficeName = fetchedUser.privacy.officeName;
            hideDpurl = fetchedUser.privacy.dpurl;
            hideInstagramUsername = fetchedUser.privacy.instagramUsername;
            hideYoutubeChannel = fetchedUser.privacy.youtubeChannel;
            hideGithubUsername = fetchedUser.privacy.githubUsername;
            hideTelegramUsername = fetchedUser.privacy.telegramUsername;
            hideWebsiteUrl = fetchedUser.privacy.website;
            isLoading = false;
          });
        } else {
          _showSnackBar(
            title: "Error",
            message: "Failed to fetch user data.",
            backgroundColor: Colors.red,
          );
          setState(() {
            isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Unauthorized, token might be invalid
        _clearTokenAndNavigate();
      } else {
        _showSnackBar(
          title: "Error",
          message: "Server error while fetching user data.",
          backgroundColor: Colors.red,
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar(
        title: "Error",
        message: "An error occurred while fetching user data.",
        backgroundColor: Colors.red,
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to update privacy settings
  Future<void> _updatePrivacySettings(String field, bool value) async {
    if (currentUser == null) return;

    setState(() {
      isUpdating = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      _navigateToLogin();
      return;
    }

    // Create an update object dynamically
    Map<String, dynamic> updateData = {
      'privacy': {field: value},
    };

    try {
      final response = await http.put(
        Uri.parse(
            'https://nearbypins.vercel.app/api/auth/privacy'), // Replace with your actual backend endpoint to update privacy
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        if (res['success'] && res['data'] != null) {
          // Update the local state based on the field
          setState(() {
            switch (field) {
              case 'mobile':
                hideMobile = value;
                break;
              case 'officeName':
                hideOfficeName = value;
                break;
              case 'dpurl':
                hideDpurl = value;
                break;
              case 'instagramUsername':
                hideInstagramUsername = value;
                break;
              case 'youtubeChannel':
                hideYoutubeChannel = value;
                break;
              case 'githubUsername':
                hideGithubUsername = value;
                break;
              case 'telegramUsername':
                hideTelegramUsername = value;
                break;
              case 'website':
                hideWebsiteUrl = value;
                break;
              default:
                break;
            }
            isUpdating = false;
          });

          _showSnackBar(
            title: "Success",
            message: "Privacy settings updated successfully.",
            backgroundColor: Colors.green,
          );
        } else {
          _showSnackBar(
            title: "Error",
            message: "Failed to update privacy settings.",
            backgroundColor: Colors.red,
          );
          setState(() {
            isUpdating = false;
          });
        }
      } else if (response.statusCode == 401) {
        // Unauthorized, token might be invalid
        _clearTokenAndNavigate();
      } else {
        _showSnackBar(
          title: "Error",
          message: "Server error while updating privacy settings.",
          backgroundColor: Colors.red,
        );
        setState(() {
          isUpdating = false;
        });
      }
    } catch (e) {
      _showSnackBar(
        title: "Error",
        message:
            "An error occurred while updating privacy settings: ${e.toString()}",
        backgroundColor: Colors.red,
      );
      setState(() {
        isUpdating = false;
      });
    }
  }

  // Helper function to display SnackBar alerts
  void _showSnackBar({
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
    _showSnackBar(
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

  // Navigate to PremiumScreen
  void _navigateToPremium() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentScreen()),
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
      _showSnackBar(
        title: "Success",
        message: "Logged out successfully!",
        backgroundColor: Colors.green,
      );
      _navigateToLogin();
    }
  }

  // Function to prompt user to upgrade to Premium
  void _promptUpgrade() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text('Upgrade Required', style: TextStyle(color: textColor)),
          content: Text(
            'This feature is available for premium users only. Would you like to upgrade?',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: secondaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Upgrade', style: TextStyle(color: Colors.green)),
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToPremium();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text('Privacy Settings', style: TextStyle(fontSize: 18)),
        backgroundColor: secondaryColor,
        actions: [
          // Hamburger Menu with Logout Option
          PopupMenuButton<String>(
            icon: Icon(Icons.menu), // Hamburger menu icon
            onSelected: (String value) {
              if (value == 'Logout') {
                _logout(); // Call your existing logout function
              } else if (value == 'Privacy') {
                // Already on PrivacyScreen; optionally show a message or navigate elsewhere
                _showSnackBar(
                  title: "Info",
                  message: "You are already on the Privacy Settings screen.",
                  backgroundColor: Colors.blue,
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
        automaticallyImplyLeading: true, // Shows the back button
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
              ),
            )
          : currentUser == null
              ? Center(
                  child: Text(
                    'User data not available.',
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      // Hide Mobile Number (Accessible to all users)
                      SwitchListTile(
                        title: Text(
                          'Hide Mobile Number',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        value: hideMobile,
                        onChanged: isUpdating
                            ? null
                            : (bool value) {
                                setState(() {
                                  hideMobile = value;
                                });
                                _updatePrivacySettings('mobile', value);
                              },
                        secondary: Icon(Icons.phone, color: secondaryColor),
                      ),
                      Divider(color: Colors.grey),
                      // Hide Office Name (Premium only)
                      SwitchListTile(
                        title: Text(
                          'Hide Office Name',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        value: hideOfficeName,
                        onChanged: isUpdating
                            ? null
                            : (bool value) {
                                if (currentUser!.isPremium) {
                                  setState(() {
                                    hideOfficeName = value;
                                  });
                                  _updatePrivacySettings('officeName', value);
                                } else {
                                  _promptUpgrade();
                                }
                              },
                        secondary: Icon(Icons.business, color: secondaryColor),
                      ),
                      Divider(color: Colors.grey),
                      // Hide Display Picture URL (Premium only)
                      SwitchListTile(
                        title: Text(
                          'Hide Display Picture URL',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        value: hideDpurl,
                        onChanged: isUpdating
                            ? null
                            : (bool value) {
                                if (currentUser!.isPremium) {
                                  setState(() {
                                    hideDpurl = value;
                                  });
                                  _updatePrivacySettings('dpurl', value);
                                } else {
                                  _promptUpgrade();
                                }
                              },
                        secondary: Icon(Icons.image, color: secondaryColor),
                      ),
                      Divider(color: Colors.grey),
                      // Hide Instagram Username (Premium only)
                      SwitchListTile(
                        title: Text(
                          'Hide Instagram Username',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        value: hideInstagramUsername,
                        onChanged: isUpdating
                            ? null
                            : (bool value) {
                                if (currentUser!.isPremium) {
                                  setState(() {
                                    hideInstagramUsername = value;
                                  });
                                  _updatePrivacySettings(
                                      'instagramUsername', value);
                                } else {
                                  _promptUpgrade();
                                }
                              },
                        secondary:
                            Icon(Icons.camera_alt, color: secondaryColor),
                      ),
                      Divider(color: Colors.grey),
                      // Hide YouTube Channel (Premium only)
                      SwitchListTile(
                        title: Text(
                          'Hide YouTube Channel',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        value: hideYoutubeChannel,
                        onChanged: isUpdating
                            ? null
                            : (bool value) {
                                if (currentUser!.isPremium) {
                                  setState(() {
                                    hideYoutubeChannel = value;
                                  });
                                  _updatePrivacySettings(
                                      'youtubeChannel', value);
                                } else {
                                  _promptUpgrade();
                                }
                              },
                        secondary:
                            Icon(Icons.video_library, color: secondaryColor),
                      ),
                      Divider(color: Colors.grey),
                      // Hide GitHub Username (Premium only)
                      SwitchListTile(
                        title: Text(
                          'Hide GitHub Username',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        value: hideGithubUsername,
                        onChanged: isUpdating
                            ? null
                            : (bool value) {
                                if (currentUser!.isPremium) {
                                  setState(() {
                                    hideGithubUsername = value;
                                  });
                                  _updatePrivacySettings(
                                      'githubUsername', value);
                                } else {
                                  _promptUpgrade();
                                }
                              },
                        secondary: Icon(Icons.code, color: secondaryColor),
                      ),
                      Divider(color: Colors.grey),
                      // Hide Telegram Username (Premium only)
                      SwitchListTile(
                        title: Text(
                          'Hide Telegram Username',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        value: hideTelegramUsername,
                        onChanged: isUpdating
                            ? null
                            : (bool value) {
                                if (currentUser!.isPremium) {
                                  setState(() {
                                    hideTelegramUsername = value;
                                  });
                                  _updatePrivacySettings(
                                      'telegramUsername', value);
                                } else {
                                  _promptUpgrade();
                                }
                              },
                        secondary: Icon(Icons.telegram, color: secondaryColor),
                      ),
                      Divider(color: Colors.grey),
                      // Hide Website URL (Premium only)
                      SwitchListTile(
                        title: Text(
                          'Hide Website URL',
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                        value: hideWebsiteUrl,
                        onChanged: isUpdating
                            ? null
                            : (bool value) {
                                if (currentUser!.isPremium) {
                                  setState(() {
                                    hideWebsiteUrl = value;
                                  });
                                  _updatePrivacySettings('website', value);
                                } else {
                                  _promptUpgrade();
                                }
                              },
                        secondary: Icon(Icons.web, color: secondaryColor),
                      ),
                      SizedBox(height: 20),
                      if (isUpdating)
                        Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(secondaryColor),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
