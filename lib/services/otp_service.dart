import 'dart:async';
import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class OTPVerificationService {
  final Map<String, Map<String, dynamic>> _activeOTPs = {};

  // Email configuration
  final String _senderEmail;
  final String _senderPassword;
  final String _smtpServer;
  final int _smtpPort;
  final bool _useSSL;

  // OTP configuration
  final int _otpLength;
  final int _otpExpiryMinutes;

  OTPVerificationService({
    required String senderEmail,
    required String senderPassword,
    required String smtpServer,
    int smtpPort = 587,
    bool useSSL = false,
    int otpLength = 4,
    int otpExpiryMinutes = 1,
  })  : _senderEmail = senderEmail,
        _senderPassword = senderPassword,
        _smtpServer = smtpServer,
        _smtpPort = smtpPort,
        _useSSL = useSSL,
        _otpLength = otpLength,
        _otpExpiryMinutes = otpExpiryMinutes;

  // Generate a random OTP
  String _generateOTP() {
    final random = Random();
    String otp = '';

    for (int i = 0; i < _otpLength; i++) {
      otp += random.nextInt(10).toString();
    }

    return otp;
  }

  // Send OTP via email
  Future<bool> sendOTP(String recipientEmail,
      {String? customSubject, String? customMessage}) async {
    try {
      // Generate OTP
      final otp = _generateOTP();
      final expiryTime =
          DateTime.now().add(Duration(minutes: _otpExpiryMinutes));

      // Store OTP with expiry time
      _activeOTPs[recipientEmail] = {
        'otp': otp,
        'expiryTime': expiryTime,
      };

      // Configure mail server
      final smtpServer = _useSSL
          ? SmtpServer(
              _smtpServer,
              port: _smtpPort,
              ssl: true,
              username: _senderEmail,
              password: _senderPassword,
            )
          : SmtpServer(
              _smtpServer,
              port: _smtpPort,
              ssl: false,
              allowInsecure: true,
              username: _senderEmail,
              password: _senderPassword,
            );

      // Create email message
      final subject = customSubject ?? 'Your OTP for GoSwift Verification';

      // Replace [OTP] placeholder with actual OTP code
      String body = customMessage ??
          'Your verification code is: $otp\n\nThis code will expire in $_otpExpiryMinutes minutes.';

      if (body.contains('[OTP]')) {
        body = body.replaceAll('[OTP]', otp);
      }

      final message = Message()
        ..from = Address(_senderEmail, 'GoSwift')
        ..recipients.add(recipientEmail)
        ..subject = subject
        ..text = body;

      // Send email
      // ignore: unused_local_variable
      final sendReport = await send(message, smtpServer);

      // Schedule auto-cleanup after expiry
      Timer(Duration(minutes: _otpExpiryMinutes), () {
        _activeOTPs.remove(recipientEmail);
      });

      return true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  // Verify OTP entered by user
  VerificationResult verifyOTP(String email, String userEnteredOTP) {
    // Check if an active OTP exists for this email
    if (!_activeOTPs.containsKey(email)) {
      return VerificationResult.noActiveOTP;
    }

    final otpData = _activeOTPs[email]!;
    final storedOTP = otpData['otp'] as String;
    final expiryTime = otpData['expiryTime'] as DateTime;

    // Check if OTP has expired
    if (DateTime.now().isAfter(expiryTime)) {
      _activeOTPs.remove(email);
      return VerificationResult.expired;
    }

    // Compare entered OTP with stored OTP
    if (userEnteredOTP == storedOTP) {
      // OTP matched, clean up the entry
      _activeOTPs.remove(email);
      return VerificationResult.success;
    } else {
      return VerificationResult.invalid;
    }
  }

  // Get remaining validity time in seconds
  int getRemainingTimeInSeconds(String email) {
    if (!_activeOTPs.containsKey(email)) {
      return 0;
    }

    final expiryTime = _activeOTPs[email]!['expiryTime'] as DateTime;
    final remainingDuration = expiryTime.difference(DateTime.now());

    if (remainingDuration.isNegative) {
      return 0;
    }

    return remainingDuration.inSeconds;
  }

  // Resend OTP
  Future<bool> resendOTP(String email,
      {String? customSubject, String? customMessage}) {
    _activeOTPs.remove(email);
    return sendOTP(email,
        customSubject: customSubject, customMessage: customMessage);
  }
}

// Enum for verification result
enum VerificationResult { success, invalid, expired, noActiveOTP }

// Helper class for OTP usage
class OTPHelper {
  static String getVerificationResultMessage(VerificationResult result) {
    switch (result) {
      case VerificationResult.success:
        return 'OTP verified successfully!';
      case VerificationResult.invalid:
        return 'Invalid OTP. Please try again.';
      case VerificationResult.expired:
        return 'OTP has expired. Please request a new one.';
      case VerificationResult.noActiveOTP:
        return 'No active OTP found. Please request a new one.';
    }
  }

  static String formatRemainingTime(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
