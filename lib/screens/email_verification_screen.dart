import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as app_auth;
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isCheckingVerification = false;
  bool _canResend = true;
  int _resendCountdown = 0;

  @override
  void initState() {
    super.initState();
    // Check verification status every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerification();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;

    setState(() {
      _isCheckingVerification = true;
    });

    try {
      // Reload the user to get the latest emailVerified status
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        _timer?.cancel();
        if (mounted) {
          // Update the user data in the provider
          final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
          await authProvider.refreshUserData();
          
          // Navigate to home screen
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      print('Error checking email verification: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;

    try {
      final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
      await authProvider.resendVerificationEmail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent! Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );

        // Start countdown
        setState(() {
          _canResend = false;
          _resendCountdown = 60;
        });

        Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_resendCountdown == 0) {
            timer.cancel();
            if (mounted) {
              setState(() {
                _canResend = true;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _resendCountdown--;
              });
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    final authProvider = Provider.of<app_auth.AuthProvider>(context, listen: false);
    await authProvider.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Email icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    size: 64,
                    color: Color(0xFFF39C12),
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                const Text(
                  'Verify Your Email',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'We\'ve sent a verification email to:',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please check your inbox and click the verification link to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Checking status
                if (_isCheckingVerification)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Checking verification status...',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Resend button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _canResend ? _resendVerificationEmail : null,
                    icon: const Icon(Icons.send),
                    label: Text(
                      _canResend
                          ? 'Resend Verification Email'
                          : 'Resend in $_resendCountdown seconds',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF39C12),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Manual check button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _checkEmailVerification,
                    icon: const Icon(Icons.refresh),
                    label: const Text('I\'ve Verified - Check Now'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Troubleshooting section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade900, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Not receiving emails?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Check your spam/junk folder\n'
                        '2. Wait 2-5 minutes for delivery\n'
                        '3. Try Gmail instead of institutional email\n'
                        '4. Contact admin to verify manually',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sign out button
                TextButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign Out'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
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
