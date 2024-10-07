import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user_model.dart';
import 'premium.dart';
import 'login.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FriendScreen extends StatefulWidget {
  final String mobile;

  FriendScreen({required this.mobile});

  @override
  _FriendScreenState createState() => _FriendScreenState();
}

class _FriendScreenState extends State<FriendScreen>
    with SingleTickerProviderStateMixin {
  // Define your colors
  final Color primaryColor = Color(0xff1f4068);
  final Color secondaryColor = Color(0xff3fbbe4);
  final Color cardColor = Color(0xff162447);
  final Color textColor = Colors.white;
  final Color premiumColor = Colors.amber;

  User? user;
  bool isLoading = true;

  // Animation controller for social media buttons
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 0.1,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Fetch user details using the 'auth/user' API
  Future<void> _fetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      _showError('Authentication error. Please log in again.');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://nearbypins.vercel.app/api/auth/user/${widget.mobile}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var res = json.decode(response.body);
        if (res['success'] && res['data'] != null) {
          setState(() {
            user = User.fromJson(res['data']);
            isLoading = false;
          });
        } else {
          _showError('Failed to fetch user details.');
        }
      } else {
        _showError('Server error while fetching user details.');
      }
    } catch (e) {
      _showError('An error occurred while fetching user details.');
    }
  }

  void _showError(String message) {
    setState(() {
      isLoading = false;
    });
    _showSnackBar(
      title: "Error",
      message: message,
      backgroundColor: Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        title: Text('User Details', style: TextStyle(fontFamily: 'Roboto')),
        backgroundColor: secondaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
              ),
            )
          : user != null
              ? _buildUserDetails()
              : Center(
                  child: Text(
                    'User details not available.',
                    style: TextStyle(color: textColor, fontSize: 18),
                  ),
                ),
    );
  }

  Widget _buildUserDetails() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Profile Picture with Premium Badge
          Stack(
            alignment: Alignment.center,
            children: [
              // Animated background for profile picture
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      cardColor.withOpacity(0.6),
                      cardColor.withOpacity(0.9),
                      cardColor,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 60,
                backgroundColor: cardColor,
                child: ClipOval(
                  child: user!.dpUrl.isNotEmpty
                      ? Image.network(
                          user!.dpUrl,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            final String fallbackUrl =
                                generateAvatarUrl(user!.name);
                            return Image.network(
                              fallbackUrl,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            );
                          },
                        )
                      : Icon(Icons.person, color: textColor, size: 60),
                ),
              ),
              if (user!.isPremium)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: premiumColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 6,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 24),
          // Name with Premium Highlight and Shadow
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: user!.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black38,
                        offset: Offset(3, 3),
                      ),
                    ],
                  ),
                ),
                if (user!.isPremium)
                  WidgetSpan(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(
                        Icons.star,
                        color: premiumColor,
                        size: 26,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // WhatsApp Button with animation
          if (user!.mobile.isNotEmpty)
            AnimatedSwitcher(
              duration: Duration(milliseconds: 500),
              child: user!.privacy.mobile
                  ? ElevatedButton.icon(
                      key: ValueKey('whatsapp_hidden'),
                      onPressed: null, // Disabled state
                      icon: FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.white,
                      ),
                      label: Text('WhatsApp (Hidden)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ElevatedButton.icon(
                      key: ValueKey('whatsapp_visible'),
                      onPressed: () {
                        _launchWhatsApp(user!.mobile);
                      },
                      icon: FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Colors.white,
                      ),
                      label: Text('Send WhatsApp Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        textStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        elevation: 5,
                        shadowColor: Colors.black45,
                      ),
                    ),
            ),
          SizedBox(height: 24),
          // Additional User Details with Slide Animation
          AnimatedOpacity(
            opacity: user!.officeName.isNotEmpty ? 1.0 : 0.0,
            duration: Duration(milliseconds: 800),
            child: _buildInfoRow('Place', user!.officeName),
          ),
          _buildInfoRow('Taluk', user!.taluk),
          _buildInfoRow('District', user!.districtName),
          _buildInfoRow('State', user!.stateName),
          SizedBox(height: 24),
          // Social Media Links
          _buildSocialMediaRow(),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty) return SizedBox.shrink(); // Don't show empty fields

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            _getIconForLabel(label),
            color: user!.isPremium ? premiumColor : secondaryColor,
            size: 24,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '$value',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: user!.isPremium ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaRow() {
    List<Widget> socialIcons = [];

    if (user!.instagramUrl != null && user!.instagramUrl!.isNotEmpty) {
      socialIcons.add(_socialIconButton(
        icon: FontAwesomeIcons.instagram,
        gradient: LinearGradient(
          colors: [Color(0xFF833ab4), Color(0xFFfd1d1d), Color(0xFFfcb045)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        url: user!.instagramUrl!,
        tooltip: 'Instagram',
      ));
    }

    if (user!.youtubeUrl != null && user!.youtubeUrl!.isNotEmpty) {
      socialIcons.add(_socialIconButton(
        icon: FontAwesomeIcons.youtube,
        gradient: LinearGradient(
          colors: [Color(0xFFFF0000), Color(0xFFFF5733)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        url: user!.youtubeUrl!,
        tooltip: 'YouTube',
      ));
    }

    if (user!.githubUrl != null && user!.githubUrl!.isNotEmpty) {
      socialIcons.add(_socialIconButton(
        icon: FontAwesomeIcons.github,
        gradient: LinearGradient(
          colors: [Color(0xFF333333), Color(0xFFffffff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        url: user!.githubUrl!,
        tooltip: 'GitHub',
      ));
    }

    if (user!.telegramUrl != null && user!.telegramUrl!.isNotEmpty) {
      socialIcons.add(_socialIconButton(
        icon: FontAwesomeIcons.telegram,
        gradient: LinearGradient(
          colors: [Color(0xFF0088cc), Color(0xFF00c6ff)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        url: user!.telegramUrl!,
        tooltip: 'Telegram',
      ));
    }

    if (user!.websiteUrl != null && user!.websiteUrl!.isNotEmpty) {
      socialIcons.add(_socialIconButton(
        icon: FontAwesomeIcons.globe,
        gradient: LinearGradient(
          colors: [Color(0xFF4caf50), Color(0xFF81c784)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        url: user!.websiteUrl!,
        tooltip: 'Website',
      ));
    }

    if (socialIcons.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: socialIcons,
    );
  }

  Widget _socialIconButton({
    required IconData icon,
    required LinearGradient gradient,
    required String url,
    required String tooltip,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        _animationController.forward();
      },
      onTapUp: (_) {
        _animationController.reverse();
      },
      onTapCancel: () {
        _animationController.reverse();
      },
      onTap: () {
        _launchURL(url);
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          double scale = 1 - _animation.value;
          return Transform.scale(
            scale: scale,
            child: Tooltip(
              message: tooltip,
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(3, 3),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(14),
                child: FaIcon(
                  icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Place':
        return Icons.business;
      case 'Taluk':
        return Icons.location_city;
      case 'District':
        return Icons.location_on;
      case 'State':
        return Icons.map;
      default:
        return Icons.info;
    }
  }

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

  Future<void> _launchWhatsApp(String mobile) async {
    String url = "whatsapp://send?phone=$mobile&text=Hello";
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar(
        title: "Error",
        message: "WhatsApp is not installed on this device.",
        backgroundColor: Colors.red,
      );
    }
  }

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
}

String generateRandomColor({bool light = true}) {
  const lettersLight = 'BCDEF'; // Light background colors
  const lettersDark = '012345'; // Dark text colors
  final rand = Random();
  String letters = light ? lettersLight : lettersDark;
  String color = '#';
  for (int i = 0; i < 6; i++) {
    color += letters[rand.nextInt(letters.length)];
  }
  return color;
}

String generateAvatarUrl(String name) {
  final String lightBgColor =
      generateRandomColor(light: true); // Light background color
  final String darkTextColor =
      generateRandomColor(light: false); // Dark text color
  return 'https://avatar.iran.liara.run/username?username=${Uri.encodeComponent(name)}&background=$lightBgColor&color=$darkTextColor';
}
