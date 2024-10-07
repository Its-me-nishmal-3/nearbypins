// main.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:another_flushbar/flushbar.dart'; // Import Flushbar package
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher package
import 'dashboard.dart'; // Import DashboardScreen

void main() {
  runApp(MaterialApp(
    home: LoginScreen(),
    debugShowCheckedModeBanner: false, // Disable the debug banner
  ));
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for input fields
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  String _selectedPlace = '';

  // State variables
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isOtpValid = false;
  bool _resendEnabled = false; // For OTP resend button state
  bool _isTermsAccepted = false; // For Terms and Conditions acceptance

  // List of places for dropdown
  List<String> officeNames = [];

  // Timer for "Resend OTP" button
  Timer? _resendOtpTimer;
  int _resendCountdown = 0;

  // Timer for loading dots
  Timer? _dotTimer;
  int _dotCount = 0;

  // Step Management
  int _currentStep = 0;

  // Define colors for modern design
  final Color primaryColor = Color(0xff1f4068); // Deep blue
  final Color secondaryColor = Color(0xff3fbbe4); // Vibrant red
  final Color cardColor = Color(0xff162447); // Darker shade of blue
  final Color textColor = Colors.white; // White text color for contrast

  @override
  void dispose() {
    _resendOtpTimer?.cancel();
    _dotTimer?.cancel();
    _mobileController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _pincodeController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  // Helper function to display Flushbar alerts
  void _showFlushbar({
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    Flushbar(
      title: title,
      message: message,
      duration: Duration(seconds: 3),
      backgroundColor: backgroundColor,
      flushbarPosition: FlushbarPosition.TOP,
      margin: EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      animationDuration: Duration(milliseconds: 500),
      icon: Icon(
        title == "Success" ? Icons.check_circle : Icons.error,
        size: 28.0,
        color: Colors.white,
      ),
      leftBarIndicatorColor: Colors.white,
    )..show(context);
  }

  // Function to launch Terms and Conditions URL
  Future<void> _launchURL() async {
    const url =
        'https://www.yourtermsandconditions.com'; // Replace with your actual URL
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: false, forceWebView: false);
    } else {
      _showFlushbar(
        title: "Error",
        message: "Could not launch Terms and Conditions",
        backgroundColor: Colors.red,
      );
    }
  }

  // Function to move to the next step in the step-by-step UI
  void _nextStep() {
    setState(() {
      _currentStep += 1;
    });
  }

  // Function to move to the previous step in the step-by-step UI
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        // Clear the current step's inputs before moving back
        if (_currentStep == 1) {
          _otpController.clear();
          _isOtpSent = false;
        } else if (_currentStep == 2) {
          _nameController.clear();
        } else if (_currentStep == 3) {
          _pincodeController.clear();
          officeNames.clear();
          _selectedPlace = '';
        } else if (_currentStep == 4) {
          _selectedPlace = '';
          _isTermsAccepted = false; // Reset terms acceptance
        }
        _currentStep -= 1;
      });
    }
  }

  // Function to create a reusable input field widget
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        style: TextStyle(color: textColor), // Text color
        cursorColor: secondaryColor,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: secondaryColor),
          labelText: label,
          labelStyle: TextStyle(color: textColor),
          filled: true,
          fillColor: cardColor.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: secondaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: secondaryColor, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xff02012a), // Dark blue at the top
              Color(0xff02012a), // Same dark blue at the bottom
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  color: cardColor.withOpacity(0.9),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Stack(
                      children: [
                        _getCurrentStepContent(),
                        // Back Button
                        if (_currentStep > 0)
                          Positioned(
                            top: 0,
                            left: 0,
                            child: IconButton(
                              icon:
                                  Icon(Icons.arrow_back, color: secondaryColor),
                              onPressed: _isLoading ? null : _previousStep,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                if (_currentStep <
                    5) // Display Next or Submit button based on step
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinuePressed,
                    child: _isLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Loading${'.' * _dotCount}',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          )
                        : Text(
                            _currentStep == 4
                                ? 'Submit'
                                : 'Next', // Change button text based on step
                            style: TextStyle(fontSize: 18),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (_currentStep == 5 && !_isLoading)
                  ElevatedButton(
                    onPressed: _isTermsAccepted ? _submitDetails : null,
                    child: Text(
                      'Confirm',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      textStyle: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // **Resend OTP Button Visibility Adjusted Below**
                if (_currentStep == 1 && _isOtpSent) _buildResendOtpButton(),
                // Removed CircularProgressIndicator
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Get content of the current step
  Widget _getCurrentStepContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_currentStep == 0) _buildMobileNumberStep(),
        if (_currentStep == 1) _buildOtpStep(),
        if (_currentStep == 2) _buildUserCheckStep(), // User check step
        if (_currentStep == 3) _buildNameStep(),
        if (_currentStep == 4) _buildPincodeStep(),
        if (_currentStep == 5) _buildPlaceSelectionStep(),
      ],
    );
  }

  Widget _buildMobileNumberStep() {
    return Column(
      children: [
        Text(
          'Your WhatsApp Number',
          style: TextStyle(
              color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        _buildInputField(
          label: 'WhatsApp Number',
          controller: _mobileController,
          icon: Icons.phone,
          inputType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        Text(
          'Enter the OTP',
          style: TextStyle(
              color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        _buildInputField(
          label: 'OTP',
          controller: _otpController,
          icon: Icons.lock,
          inputType: TextInputType.number,
        ),
      ],
    );
  }

  // New Step: Check if user exists after OTP verification
  Widget _buildUserCheckStep() {
    return Column(
      children: [
        Text(
          'Checking User...',
          style: TextStyle(
              color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(secondaryColor),
        ),
      ],
    );
  }

  Widget _buildNameStep() {
    return Column(
      children: [
        Text(
          'Enter Your Name',
          style: TextStyle(
              color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        _buildInputField(
          label: 'Name',
          controller: _nameController,
          icon: Icons.person,
          inputType: TextInputType.text,
        ),
      ],
    );
  }

  Widget _buildPincodeStep() {
    return Column(
      children: [
        Text(
          'Your Pincode',
          style: TextStyle(
              color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        _buildInputField(
          label: 'Pincode',
          controller: _pincodeController,
          icon: Icons.pin_drop,
          inputType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPlaceSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Your Place',
          style: TextStyle(
              color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _selectedPlace.isEmpty ? null : _selectedPlace,
          items: officeNames.map((String place) {
            return DropdownMenuItem<String>(
              value: place,
              child: Text(place,
                  style:
                      TextStyle(color: textColor)), // White text for visibility
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedPlace = newValue ?? '';
            });
          },
          dropdownColor: cardColor, // Dark background for dropdown menu
          style: TextStyle(color: textColor), // White text for better contrast
          decoration: InputDecoration(
            labelText: 'Place',
            labelStyle: TextStyle(color: secondaryColor),
            filled: true,
            fillColor:
                cardColor.withOpacity(0.3), // Dark semi-transparent background
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textColor), // White border
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: textColor), // White enabled border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: secondaryColor, width: 2), // Focused border color
            ),
          ),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Checkbox(
              value: _isTermsAccepted,
              onChanged: (bool? value) {
                setState(() {
                  _isTermsAccepted = value ?? false;
                });
              },
              activeColor: secondaryColor,
            ),
            Expanded(
              child: GestureDetector(
                onTap: _launchURL,
                child: RichText(
                  text: TextSpan(
                    text: 'I agree to the ',
                    style: TextStyle(color: textColor),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Terms and Conditions',
                        style: TextStyle(
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Handle the continue button based on the current step
  void _handleContinuePressed() {
    if (_currentStep == 0) {
      _sendOtp(); // Initial OTP send
    } else if (_currentStep == 1) {
      _verifyOtp();
    } else if (_currentStep == 2) {
      // This step is handled asynchronously by the API response (_checkUserExists)
      // No action needed here
    } else if (_currentStep == 3) {
      _nextStep(); // Proceed to pincode step after name entry
    } else if (_currentStep == 4) {
      _verifyPincode(); // Verify pincode and fetch office names
    }
    // Step 5 does not require a continue button
  }

  // Function to show OTP resend button with timer
  Widget _buildResendOtpButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: _resendEnabled
          ? TextButton(
              onPressed: _isLoading ? null : () => _sendOtp(isResend: true),
              child: Text(
                'Resend OTP',
                style: TextStyle(color: secondaryColor, fontSize: 16),
              ),
            )
          : Text(
              'Resend OTP in $_resendCountdown seconds',
              style: TextStyle(color: textColor, fontSize: 16),
            ),
    );
  }

  // Send OTP to the specified mobile number
  Future<void> _sendOtp({bool isResend = false}) async {
    final String mobileNumber = _mobileController.text.trim();
    if (mobileNumber.isEmpty || mobileNumber.length != 10) {
      _showFlushbar(
        title: "Error",
        message: "Please enter a valid 10-digit mobile number",
        backgroundColor: Colors.red,
      );
      return;
    }

    _showLoading(true);

    final otp = _generateOtp();
    try {
      final response = await http.get(
        Uri.parse(
            'https://rail-way-bot.onrender.com/send/91$mobileNumber/$otp'),
      );

      _showLoading(false);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('otp', otp);
        await prefs.setString(
            'otp_timestamp', DateTime.now().toIso8601String());

        if (!isResend) {
          setState(() {
            _isOtpSent = true;
            _nextStep(); // Move to OTP entry step only on initial send
          });
        }

        _startResendOtpTimer(); // Start resend timer

        _showFlushbar(
          title: "Success",
          message: "OTP sent successfully!",
          backgroundColor: Colors.green,
        );
      } else {
        _showFlushbar(
          title: "Error",
          message: "Failed to send OTP",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      _showLoading(false);
      _showFlushbar(
        title: "Error",
        message: "An error occurred: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  // Verify OTP and check if user exists
  Future<void> _verifyOtp() async {
    _showLoading(true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final storedOtp = prefs.getString('otp');
    final otpTimestamp = prefs.getString('otp_timestamp');

    if (storedOtp != null && otpTimestamp != null) {
      final DateTime timestamp = DateTime.parse(otpTimestamp);
      if (DateTime.now().difference(timestamp).inMinutes <= 3) {
        if (_otpController.text.trim() == storedOtp) {
          // OTP is valid, proceed to check if user exists
          _showFlushbar(
            title: "Success",
            message: "OTP verified successfully!",
            backgroundColor: Colors.green,
          );
          _isOtpValid = true;
          _nextStep(); // Move to user check step
          _checkUserExists(); // Call the API to check user
        } else {
          _showFlushbar(
            title: "Error",
            message: "Invalid OTP. Please try again.",
            backgroundColor: Colors.red,
          );
        }
      } else {
        _showFlushbar(
          title: "Error",
          message: "OTP expired. Please resend OTP.",
          backgroundColor: Colors.red,
        );
        setState(() {
          _isOtpSent = false;
        });
      }
    } else {
      _showFlushbar(
        title: "Error",
        message: "No OTP found. Please resend OTP.",
        backgroundColor: Colors.red,
      );
      setState(() {
        _isOtpSent = false;
      });
    }

    _showLoading(false);
  }

  // Check if the user already exists by calling the login API
  Future<void> _checkUserExists() async {
    final String mobileNumber = _mobileController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://nearbypins.vercel.app/api/auth/login'), // Replace with your actual backend URL
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'mobile': mobileNumber}),
      );

      if (response.statusCode == 200) {
        // User exists, parse token and navigate to dashboard
        final responseData = json.decode(response.body);
        final String token = responseData['token'];

        // Store the token securely
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('mobile', mobileNumber);

        _showFlushbar(
          title: "Success",
          message: "Logged in successfully!",
          backgroundColor: Colors.green,
        );

        // Navigate to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else if (response.statusCode == 401) {
        // User does not exist, proceed to registration
        _showFlushbar(
          title: "Info",
          message: "User not found. Please register.",
          backgroundColor: Colors.blueAccent,
        );
        _nextStep(); // Move to the next step (Name entry)
      } else {
        _showFlushbar(
          title: "Error",
          message: "Failed to verify user. Please try again.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      _showFlushbar(
        title: "Error",
        message: "An error occurred: $e",
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Verify Pincode and fetch office names
  Future<void> _verifyPincode() async {
    final String pincode = _pincodeController.text.trim();
    if (pincode.isEmpty || pincode.length != 6) {
      _showFlushbar(
        title: "Error",
        message: "Please enter a valid 6-digit pincode",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://p1n.vercel.app/$pincode'),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        if (data.containsKey("officeNames")) {
          setState(() {
            officeNames = List<String>.from(data["officeNames"]);
            _nextStep(); // Proceed to place selection step
          });
          _showFlushbar(
            title: "Success",
            message: "Pincode verified successfully!",
            backgroundColor: Colors.green,
          );
        } else {
          _showFlushbar(
            title: "Error",
            message: data['message'] ?? 'Pincode not found',
            backgroundColor: Colors.red,
          );
        }
      } else {
        _showFlushbar(
          title: "Error",
          message: "Error fetching pincode details",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showFlushbar(
        title: "Error",
        message: "An error occurred: $e",
        backgroundColor: Colors.red,
      );
    }
  }

  // Submit the details to API (Registration)
  Future<void> _submitDetails() async {
    final String referral = _referralController.text.trim();
    // Referral is optional, so no validation needed

    if (_selectedPlace.isEmpty) {
      _showFlushbar(
        title: "Error",
        message: "Please select your place",
        backgroundColor: Colors.red,
      );
      return;
    }

    _showLoading(true);

    final data = {
      'mobile': _mobileController.text.trim(),
      'name': _nameController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'place': _selectedPlace,
      'referral': referral, // Include referral if provided
    };

    try {
      final response = await http.post(
        Uri.parse(
            'https://nearbypins.vercel.app/api/auth/register'), // Replace with your API endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      _showLoading(false);

      if (response.statusCode == 200) {
        // User exists, parse token and navigate to dashboard
        final responseData = json.decode(response.body);
        final String token = responseData['token'];

        // Store the token securely
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('mobile', _mobileController.text.trim());

        _showFlushbar(
          title: "Success",
          message: "Registration successful!",
          backgroundColor: Colors.green,
        );
        // Navigate to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        _showFlushbar(
          title: "Error",
          message: "Failed to register: ${response.body}",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      _showLoading(false);
      _showFlushbar(
        title: "Error",
        message: "An error occurred: Contact The Owner",
        backgroundColor: Colors.red,
      );
    }
  }

  // Generate a 4-digit OTP
  String _generateOtp() {
    final random =
        (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    return random;
  }

  // Show loading indicator with animated dots
  void _showLoading(bool show) {
    setState(() {
      _isLoading = show;
    });

    if (show) {
      _dotCount = 0;
      _dotTimer?.cancel();
      _dotTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4; // Cycle through 0 to 3
        });
      });
    } else {
      _dotTimer?.cancel();
      _dotCount = 0;
    }
  }

  // Start resend OTP timer
  void _startResendOtpTimer() {
    setState(() {
      _resendCountdown = 30;
      _resendEnabled = false;
    });

    _resendOtpTimer?.cancel(); // Cancel any existing timer
    _resendOtpTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _resendEnabled = true;
          timer.cancel();
        }
      });
    });
  }
}
