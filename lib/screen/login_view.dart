import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mightyweb/screen/HomeScreen.dart';

class CustomLoginScreen extends StatefulWidget {
  const CustomLoginScreen({super.key});

  @override
  State<CustomLoginScreen> createState() => _CustomLoginScreenState();
}

class _CustomLoginScreenState extends State<CustomLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isFormFilled = false;

  void _updateFormFilledStatus() {
    setState(() {
      isFormFilled =
          emailController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    emailController.addListener(_updateFormFilledStatus);
    passwordController.addListener(_updateFormFilledStatus);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithFirebase() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      try {
        final auth = FirebaseAuth.instance;

        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        if (!userCredential.user!.emailVerified) {
          await auth.signOut();
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Email not verified"),
              content: const Text(
                "Please verify your email before logging in. Check your inbox/spam.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
          return;
        }

        // ✅ Successful login: Navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              mUrl: "https://your-valid-url.com", // Replace with your valid URL
              title: "Web App",
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        String message = 'Login failed';

        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided.';
        }

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Try Again'),
              ),
            ],
          ),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(375, 812));
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Gap(40.h),
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A9A1E),
                  ),
                ),
                Text(
                  'Login to your account',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: const Color(0xFF4C9A4C),
                  ),
                ),
                Gap(30.h),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: emailController,
                        hintText: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) => val == null || !val.contains('@')
                            ? 'Enter a valid email'
                            : null,
                      ),
                      Gap(15.h),
                      _buildTextField(
                        controller: passwordController,
                        hintText: 'Password',
                        icon: Icons.lock,
                        obscureText: true,
                        validator: (val) => val == null || val.length < 6
                            ? 'Password must be 6+ chars'
                            : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/forgot');
                          },
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: const Color(0xFF1A9A1E),
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ),
                      Gap(25.h),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: isFormFilled && !isLoading
                                  ? _loginWithFirebase
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFormFilled
                                    ? const Color(0xFF1A9A1E)
                                    : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                minimumSize: Size(double.infinity, 50.h),
                              ),
                              child: Text(
                                'Login',
                                style: TextStyle(fontSize: 16.sp),
                              ),
                            ),
                      Gap(20.h),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/signup');
                        },
                        child: const Text(
                          "Don't have an account? Sign up",
                          style: TextStyle(color: Color(0xFF1A9A1E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1A9A1E)),
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFDFF5DF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
