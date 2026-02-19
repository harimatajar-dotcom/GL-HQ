import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  String _pin = '';
  bool _loggingIn = false;
  String? _error;

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty || _pin.length != 4) return;
    setState(() {
      _loggingIn = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final error = await auth.login(mobile, _pin);

    if (mounted) {
      if (error != null) {
        setState(() {
          _error = error;
          _loggingIn = false;
        });
      } else {
        _pinFocusNode.unfocus();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/images/logo.png',
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
                const SizedBox(height: 24),
                // Login Card
                Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign in to continue',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Mobile number field
                    TextField(
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      style: GoogleFonts.poppins(fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        labelStyle: GoogleFonts.poppins(),
                        prefixIcon: const Icon(Icons.phone_outlined),
                        hintText: '9048333535',
                        hintStyle: GoogleFonts.poppins(color: AppColors.mutedForeground.withOpacity(0.5)),
                      ),
                      onSubmitted: (_) => _pinFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 16),
                    PinCodeTextField(
                      appContext: context,
                      length: 4,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      animationType: AnimationType.fade,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 56,
                        fieldWidth: 56,
                        activeFillColor: AppColors.muted,
                        inactiveFillColor: AppColors.muted,
                        selectedFillColor: AppColors.accentLight,
                        activeColor: AppColors.accent,
                        selectedColor: AppColors.accent,
                        inactiveColor: AppColors.border,
                      ),
                      enableActiveFill: true,
                      onChanged: (value) => _pin = value,
                      onCompleted: (_) => _login(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loggingIn ? null : _login,
                        child: _loggingIn
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Sign In', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error!,
                          style: GoogleFonts.poppins(
                            color: AppColors.destructive,
                            fontSize: 13,
                          ),
                        ),
                      ).animate().shake(),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Getlead Analytics Pvt Ltd',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.mutedForeground,
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
