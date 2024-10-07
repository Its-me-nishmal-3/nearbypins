// social.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLinksScreen extends StatefulWidget {
  @override
  _SocialLinksScreenState createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends State<SocialLinksScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for each input field
  TextEditingController _instagramController = TextEditingController();
  TextEditingController _youtubeController = TextEditingController();
  TextEditingController _githubController = TextEditingController();
  TextEditingController _telegramController = TextEditingController();
  TextEditingController _websiteController = TextEditingController();

  bool isLoading = false;

  // Colors (consistent with friend.dart)
  final Color primaryColor = Color(0xff1f4068); // Deep blue
  final Color secondaryColor = Color(0xff3fbbe4); // Vibrant blue
  final Color cardColor = Color(0xff162447); // Darker shade of blue
  final Color textColor = Colors.white; // White text color for contrast
  final Color premiumColor = Colors.amber; // Color accent for premium users

  @override
  void dispose() {
    // Dispose controllers when the widget is disposed
    _instagramController.dispose();
    _youtubeController.dispose();
    _githubController.dispose();
    _telegramController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  // Function to fetch current user data and populate fields
  Future<void> _populateFields() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? mobile = prefs.getString('mobile'); // Assuming mobile is stored

    if (token == null || mobile == null) {
      _showSnackBar(
        title: "Error",
        message: "Authentication error. Please log in again.",
        backgroundColor: Colors.red,
      );
      // Optionally, navigate to login screen
      return;
    }

    setState(() {
      isLoading = true;
    });

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
          var userData = res['data'];

          setState(() {
            _instagramController.text = userData['instagramUsername'] ?? '';
            _youtubeController.text = userData['youtubeChannel'] ?? '';
            _githubController.text = userData['githubUsername'] ?? '';
            _telegramController.text = userData['telegramUsername'] ?? '';
            _websiteController.text = userData['website'] ?? '';
            isLoading = false;
          });
        } else {
          _showSnackBar(
            title: "Error",
            message: "Failed to fetch user details.",
            backgroundColor: Colors.red,
          );
          setState(() {
            isLoading = false;
          });
        }
      } else {
        _showSnackBar(
          title: "Error",
          message: "Server error while fetching user details.",
          backgroundColor: Colors.red,
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showSnackBar(
        title: "Error",
        message: "An error occurred while fetching user details.",
        backgroundColor: Colors.red,
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  // Function to handle form submission
  Future<void> _updateLinks() async {
    // Manually validate inputs
    String? instagram = _instagramController.text.trim();
    String? youtube = _youtubeController.text.trim();
    String? github = _githubController.text.trim();
    String? telegram = _telegramController.text.trim();
    String? website = _websiteController.text.trim();

    // Validate Instagram Username
    if (instagram.isNotEmpty) {
      final instagramRegex = RegExp(r'^[a-zA-Z0-9._]{1,30}$');
      if (!instagramRegex.hasMatch(instagram)) {
        _showSnackBar(
          title: "Error",
          message: "Invalid Instagram username.",
          backgroundColor: Colors.red,
        );
        return;
      }
    }

    // Validate YouTube Channel ID
    if (youtube.isNotEmpty) {
      final youtubeRegex = RegExp(r'^[a-zA-Z0-9_-]{22}$');
      if (!youtubeRegex.hasMatch(youtube)) {
        _showSnackBar(
          title: "Error",
          message: "Invalid YouTube Channel ID.",
          backgroundColor: Colors.red,
        );
        return;
      }
    }

    // Validate GitHub Username
    if (github.isNotEmpty) {
      final githubRegex = RegExp(r'^[a-zA-Z0-9-]{1,39}$');
      if (!githubRegex.hasMatch(github)) {
        _showSnackBar(
          title: "Error",
          message: "Invalid GitHub username.",
          backgroundColor: Colors.red,
        );
        return;
      }
    }

    // Validate Telegram Username
    if (telegram.isNotEmpty) {
      final telegramRegex = RegExp(r'^[a-zA-Z0-9_]{5,32}$');
      if (!telegramRegex.hasMatch(telegram)) {
        _showSnackBar(
          title: "Error",
          message: "Invalid Telegram username.",
          backgroundColor: Colors.red,
        );
        return;
      }
    }

    // Validate Website URL
    if (website.isNotEmpty) {
      if (!(website.startsWith('http://') || website.startsWith('https://'))) {
        _showSnackBar(
          title: "Error",
          message: "Website URL must include http:// or https://.",
          backgroundColor: Colors.red,
        );
        return;
      }
      Uri? uri = Uri.tryParse(website);
      if (uri == null ||
          !(uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'))) {
        _showSnackBar(
          title: "Error",
          message: "Invalid Website URL.",
          backgroundColor: Colors.red,
        );
        return;
      }
    }

    // If all validations pass, proceed to update
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? mobile = prefs.getString('mobile'); // Assuming mobile is stored

    if (token == null || mobile == null) {
      _showSnackBar(
        title: "Error",
        message: "Authentication error. Please log in again.",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Prepare the request body
    Map<String, dynamic> body = {};

    if (instagram.isNotEmpty) {
      body['instagramUsername'] = instagram;
    }

    if (youtube.isNotEmpty) {
      body['youtubeChannel'] = youtube;
    }

    if (github.isNotEmpty) {
      body['githubUsername'] = github;
    }

    if (telegram.isNotEmpty) {
      body['telegramUsername'] = telegram;
    }

    if (website.isNotEmpty) {
      body['website'] = website;
    }

    try {
      final response = await http.put(
        Uri.parse('https://nearbypins.vercel.app/api/auth/links'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        if (res['success'] && res['data'] != null) {
          _showSnackBar(
            title: "Success",
            message: "Social links updated successfully.",
            backgroundColor: Colors.green,
          );
          // Optionally, refresh user data or navigate back
          _populateFields(); // Refresh the fields with updated data
        } else {
          _showSnackBar(
            title: "Error",
            message: res['error'] ?? 'Failed to update links.',
            backgroundColor: Colors.red,
          );
        }
      } else {
        var res = json.decode(response.body);
        _showSnackBar(
          title: "Error",
          message: res['error'] ?? 'Server error while updating links.',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      _showSnackBar(
        title: "Error",
        message: "An error occurred while updating links.",
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to show SnackBar messages
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

  // Function to launch URLs
  Future<void> _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar(
        title: "Error",
        message: "Could not launch $url",
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text('Update Social Links'),
        backgroundColor: secondaryColor,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
              ),
            )
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Instagram Username
                      TextFormField(
                        controller: _instagramController,
                        decoration: InputDecoration(
                          labelText: 'Instagram Username',
                          prefixIcon: Icon(
                            FontAwesomeIcons.instagram,
                            color: Colors.purple,
                          ),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        style: TextStyle(color: textColor),
                        // Removed validator
                      ),
                      SizedBox(height: 20),

                      // YouTube Channel ID
                      TextFormField(
                        controller: _youtubeController,
                        decoration: InputDecoration(
                          labelText: 'YouTube Channel ID',
                          prefixIcon: Icon(
                            FontAwesomeIcons.youtube,
                            color: Colors.red,
                          ),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        style: TextStyle(color: textColor),
                        // Removed validator
                      ),
                      SizedBox(height: 20),

                      // GitHub Username
                      TextFormField(
                        controller: _githubController,
                        decoration: InputDecoration(
                          labelText: 'GitHub Username',
                          prefixIcon: Icon(
                            FontAwesomeIcons.github,
                            color: Colors.black,
                          ),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        style: TextStyle(color: textColor),
                        // Removed validator
                      ),
                      SizedBox(height: 20),

                      // Telegram Username
                      TextFormField(
                        controller: _telegramController,
                        decoration: InputDecoration(
                          labelText: 'Telegram Username',
                          prefixIcon: Icon(
                            FontAwesomeIcons.telegram,
                            color: Colors.blue,
                          ),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        style: TextStyle(color: textColor),
                        // Removed validator
                      ),
                      SizedBox(height: 20),

                      // Website URL
                      TextFormField(
                        controller: _websiteController,
                        decoration: InputDecoration(
                          labelText: 'Website URL',
                          prefixIcon: Icon(
                            FontAwesomeIcons.globe,
                            color: Colors.green,
                          ),
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        style: TextStyle(color: textColor),
                        keyboardType: TextInputType.url,
                        // Removed validator
                      ),
                      SizedBox(height: 30),

                      // Update Button
                      ElevatedButton(
                        onPressed: _updateLinks,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: secondaryColor,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Update Links',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
