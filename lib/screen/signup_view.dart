import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Assuming this is your login screen
// Assuming this is your home screen

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isLoading = false;

  void signup() async {
    if (_formKey.currentState!.validate()) {
      if (passwordController.text != confirmPasswordController.text) {
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text("Error"),
            content: Text("Passwords do not match."),
          ),
        );
        return;
      }

      setState(() => isLoading = true);

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        User? user = userCredential.user;

        // ✅ Save name and username to Firestore
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'email': emailController.text.trim(),
            'name': nameController.text.trim(),
            'username': usernameController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

          // ✅ Send email verification
          if (!user.emailVerified) {
            await user.sendEmailVerification();
          }
        }

        // Show the dialog after signup and email verification
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Verify Email"),
            content: const Text(
              "A verification link has been sent to your email. Please verify your email before logging in.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                      context, '/home'); // Redirect to home after sign-up
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } on FirebaseAuthException catch (e) {
        String errorMsg = "Signup failed. Please try again.";
        if (e.code == 'email-already-in-use') {
          errorMsg = "Email already in use.";
        } else if (e.code == 'weak-password') {
          errorMsg = "Password should be at least 6 characters.";
        } else if (e.code == 'invalid-email') {
          errorMsg = "Invalid email address.";
        }

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Try Again"),
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
      backgroundColor: const Color.fromARGB(255, 26, 154, 30),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Gap(60.h),
                Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 40.sp,
                ),
                Text(
                  "Create Account",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Gap(10.h),
                Text(
                  "Sign up to get started!",
                  style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                ),
                Gap(30.h),
                buildTextField(
                  controller: nameController,
                  hint: "Name",
                  icon: Icons.person,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                Gap(15.h),
                buildTextField(
                  controller: emailController,
                  hint: "Email",
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                Gap(15.h),
                buildTextField(
                  controller: usernameController,
                  hint: "Username",
                  icon: Icons.account_circle,
                  validator: (value) => value == null || value.isEmpty
                      ? 'Please enter a username'
                      : null,
                ),
                Gap(15.h),
                buildTextField(
                  controller: passwordController,
                  hint: "Password",
                  icon: Icons.lock,
                  obscureText: true,
                  validator: (value) => value != null && value.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                Gap(15.h),
                buildTextField(
                  controller: confirmPasswordController,
                  hint: "Confirm Password",
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) => value != passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
                Gap(30.h),
                isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          minimumSize: Size(double.infinity, 50.h),
                        ),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                              fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                Gap(20.h),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                        context, '/login'); // Redirect to login page
                  },
                  child: const Text(
                    "Already have an account? Login",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Gap(20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
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
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 26, 154, 30)),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }
}
