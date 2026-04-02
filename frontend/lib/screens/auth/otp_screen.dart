import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/screens/auth/auth_gatekeeper.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final ConfirmationResult? confirmationResult;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.confirmationResult,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus the hidden text field when screen loads
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    String otp = _otpController.text.trim();

    if (otp.length == 6) {
      setState(() => _isLoading = true);

      try {
        if (kIsWeb && widget.confirmationResult != null) {
          await widget.confirmationResult!.confirm(otp);
        } else {
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: widget.verificationId,
            smsCode: otp,
          );
          await FirebaseAuth.instance.signInWithCredential(credential);
        }

        if (!mounted) return;
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Login Successful!"), backgroundColor: Colors.green)
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGatekeeper()),
              (route) => false,
        );

      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        String errorMsg = "Verification failed. Please check the code and try again.";
        if (e is FirebaseAuthException && e.code == 'invalid-verification-code') {
          errorMsg = "The OTP code entered is incorrect.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red)
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid 6-digit OTP."))
      );
    }
  }

  Widget _buildOtpBoxes() {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_focusNode),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          bool hasText = _otpController.text.length > index;
          bool isFocused = _otpController.text.length == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            // 🚀 FIX: Reduced height and width so it perfectly fits any screen without overflowing
            height: 60,
            width: 45,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasText ? Colors.white : Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isFocused ? const Color(0xFF4A3AFF) : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (hasText || isFocused)
                  BoxShadow(
                    color: const Color(0xFF4A3AFF).withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
              ],
            ),
            child: Text(
              hasText ? _otpController.text[index] : "",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2D3142),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryText = Color(0xFF2D3142);
    const Color brandBlue = Color(0xFF4A3AFF);
    const Color backgroundOffWhite = Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundOffWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              // 🚀 FIX: Reduced side padding to give the boxes more room to breathe
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryText, size: 20),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Center(
                    child: Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: brandBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 40,
                        color: brandBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const Center(
                    child: Text(
                      "Verification",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: primaryText,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "We sent a 6-digit secure code to\n${widget.phoneNumber}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey.shade400,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  Stack(
                    children: [
                      _buildOtpBoxes(),

                      Opacity(
                        opacity: 0.0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          onChanged: (value) {
                            setState(() {});
                            if (value.length == 6) {
                              _verifyOTP();
                            }
                          },
                          decoration: const InputDecoration(counterText: ""),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),

                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () {
                        if (_otpController.text.length == 6) {
                          _verifyOTP();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter the complete 6-digit code."), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBlue,
                        foregroundColor: Colors.white,
                        elevation: 10,
                        shadowColor: brandBlue.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 28,
                        width: 28,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                          : const Text(
                        "Confirm & Login",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Center(
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Requesting a new code..."), backgroundColor: Colors.blueGrey),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Didn't receive the code? ",
                          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 15),
                          children: const [
                            TextSpan(
                              text: "Resend",
                              style: TextStyle(color: brandBlue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
