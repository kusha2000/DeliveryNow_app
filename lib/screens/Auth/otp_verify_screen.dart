import 'dart:async';
import 'package:delivery_now_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:delivery_now_app/screens/Auth/login_screen.dart';
import 'package:delivery_now_app/screens/Menus/customer_menu.dart';
import 'package:delivery_now_app/services/otp_service.dart';
import 'package:delivery_now_app/utils/colors.dart';
import 'package:delivery_now_app/screens/Menus/rider_menu.dart';
import 'package:delivery_now_app/screens/Menus/staff_menu.dart';

class OTPVerifyScreen extends StatefulWidget {
  final String email;
  final String userType;

  const OTPVerifyScreen({
    Key? key,
    required this.email,
    required this.userType,
  }) : super(key: key);

  @override
  State<OTPVerifyScreen> createState() => _OTPVerifyScreenState();
}

class _OTPVerifyScreenState extends State<OTPVerifyScreen> {
  final TextEditingController _digit1Controller = TextEditingController();
  final TextEditingController _digit2Controller = TextEditingController();
  final TextEditingController _digit3Controller = TextEditingController();
  final TextEditingController _digit4Controller = TextEditingController();

  final FocusNode _digit1FocusNode = FocusNode();
  final FocusNode _digit2FocusNode = FocusNode();
  final FocusNode _digit3FocusNode = FocusNode();
  final FocusNode _digit4FocusNode = FocusNode();

  late OTPVerificationService _otpService;
  final AuthService _authServices = AuthService();

  int _secondsRemaining = 60;
  late Timer _timer;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isResending = false;
  bool _verificationSuccess = false;

  @override
  void initState() {
    super.initState();

    _otpService = OTPVerificationService(
      senderEmail: dotenv.env['SENDEREMAIL']!,
      senderPassword: dotenv.env['SENDERPASSWORD']!,
      smtpServer: dotenv.env['SMTPSERVER']!,
      smtpPort: 587,
      useSSL: false,
    );

    _sendOTP();
    _startCountdown();
    _digit1FocusNode.requestFocus();
  }

  Future<void> _sendOTP() async {
    setState(() {
      _isResending = true;
    });

    final success = await _otpService.sendOTP(
      widget.email,
      customSubject: 'DeliveryNow Account Verification',
      customMessage:
          'Welcome to DeliveryNow!\n\nYour verification code is: [OTP]\n\n'
          'This code will expire in 1 minute.\n\n'
          'If you did not request this code, please ignore this email.',
    );

    setState(() {
      _isResending = false;
      if (!success) {
        _errorMessage = 'Failed to send OTP. Please try again.';
      } else {
        _errorMessage = null;
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _digit1FocusNode.dispose();
    _digit2FocusNode.dispose();
    _digit3FocusNode.dispose();
    _digit4FocusNode.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();
        }
      });
    });
  }

  void _resetCountdown() {
    setState(() {
      _secondsRemaining = 60;
      _startCountdown();
    });
  }

  String get _formattedTime {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getEnteredOTP() {
    return _digit1Controller.text +
        _digit2Controller.text +
        _digit3Controller.text +
        _digit4Controller.text;
  }

  void _verifyOTP() async {
    final enteredOTP = _getEnteredOTP();

    if (enteredOTP.length != 4) {
      setState(() {
        _errorMessage = 'Please enter all 4 digits of the OTP';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = _otpService.verifyOTP(widget.email, enteredOTP);

    if (result == VerificationResult.success) {
      try {
        final currentUser = _authServices.getCurrentUser();
        if (currentUser == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No user is currently signed in.';
          });
          return;
        }

        await _authServices.updateVerificationStatus(currentUser.uid, true);

        setState(() {
          _isLoading = false;
          _verificationSuccess = true;
          _errorMessage = "Verification completed successfully!";
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (widget.userType == 'rider') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RiderMenu()),
            );
          } else if (widget.userType == 'staff') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => StaffMenu()),
            );
          } else if (widget.userType == 'customer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CustomerMenu()),
            );
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error updating verification status: $e";
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid OTP. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Header with back button
                  _buildHeader(),
                  
                  const SizedBox(height: 60),
                  
                  // Main content
                  _buildMainContent(),
                  
                  const SizedBox(height: 40),
                  
                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimaryColor,
              size: 20,
            ),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Hero Icon
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.borderColor,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryColor.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            _verificationSuccess 
                ? Icons.check_circle_rounded
                : Icons.shield_rounded,
            size: 64,
            color: AppColors.whiteColor,
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Title and description
        const Text(
          "Verify Your Email",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryColor,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          "Enter the 4-digit verification code sent to",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondaryColor,
            fontWeight: FontWeight.w400,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Text(
            widget.email,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        const SizedBox(height: 48),
        
        // OTP Form Container
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderColor),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Error/Success Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _verificationSuccess 
                        ? AppColors.successColor.withOpacity(0.1)
                        : AppColors.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _verificationSuccess 
                          ? AppColors.successColor.withOpacity(0.3)
                          : AppColors.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _verificationSuccess 
                              ? AppColors.successColor.withOpacity(0.2)
                              : AppColors.errorColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _verificationSuccess
                              ? Icons.check_circle_outline_rounded
                              : Icons.error_outline_rounded,
                          color: _verificationSuccess 
                              ? AppColors.successColor
                              : AppColors.errorColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: _verificationSuccess 
                                ? AppColors.successColor
                                : AppColors.errorColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
              
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOtpDigitField(
                    _digit1Controller,
                    _digit1FocusNode,
                    _digit2FocusNode,
                  ),
                  _buildOtpDigitField(
                    _digit2Controller,
                    _digit2FocusNode,
                    _digit3FocusNode,
                  ),
                  _buildOtpDigitField(
                    _digit3Controller,
                    _digit3FocusNode,
                    _digit4FocusNode,
                  ),
                  _buildOtpDigitField(
                    _digit4Controller,
                    _digit4FocusNode,
                    null,
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Timer and Resend Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          color: AppColors.textSecondaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Code expires in ",
                          style: TextStyle(
                            color: AppColors.textSecondaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _formattedTime,
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Resend button
                    if (_isResending)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryColor,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Sending new code...",
                            style: TextStyle(
                              color: AppColors.textSecondaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    else
                      TextButton.icon(
                        onPressed: _secondsRemaining == 0
                            ? () async {
                                await _otpService.resendOTP(widget.email);
                                _resetCountdown();
                              }
                            : null,
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: _secondsRemaining == 0
                              ? AppColors.primaryColor
                              : AppColors.textMutedColor,
                        ),
                        label: Text(
                          _secondsRemaining == 0 ? "Resend Code" : "Resend in ${_formattedTime}",
                          style: TextStyle(
                            color: _secondsRemaining == 0
                                ? AppColors.primaryColor
                                : AppColors.textMutedColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Verify Button
              Container(
                decoration: BoxDecoration(
                  gradient: _verificationSuccess 
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.successColor, AppColors.successColor.withOpacity(0.8)],
                        )
                      : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (_verificationSuccess ? AppColors.successColor : AppColors.primaryColor)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: (_isLoading || _verificationSuccess) ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.whiteColor,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.whiteColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_verificationSuccess)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                              ),
                            if (_verificationSuccess) const SizedBox(width: 8),
                            Text(
                              _verificationSuccess ? "Verified" : "Verify Code",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.infoColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.security_rounded,
              color: AppColors.infoColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "Your verification code is secure and will expire in 1 minute for your safety.",
              style: TextStyle(
                color: AppColors.textSecondaryColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpDigitField(
    TextEditingController controller,
    FocusNode focusNode,
    FocusNode? nextFocusNode,
  ) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: controller.text.isNotEmpty 
              ? AppColors.primaryColor 
              : AppColors.borderColor,
          width: controller.text.isNotEmpty ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryColor,
        ),
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          setState(() {}); // Rebuild to update border color
          if (value.isNotEmpty && nextFocusNode != null) {
            nextFocusNode.requestFocus();
          } else if (value.isEmpty && focusNode != _digit1FocusNode) {
            // Move to previous field if current is empty
            if (focusNode == _digit4FocusNode) {
              _digit3FocusNode.requestFocus();
            } else if (focusNode == _digit3FocusNode) {
              _digit2FocusNode.requestFocus();
            } else if (focusNode == _digit2FocusNode) {
              _digit1FocusNode.requestFocus();
            }
          }
        },
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }
}