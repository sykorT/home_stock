import 'package:flutter/material.dart';
import 'package:stock_scan_app/home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// AuthPage is a stateful widget that handles user authentication
class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Controllers for email and password input fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  // Method to handle user sign-in
  Future<void> _signIn() async {
    try {
      // Attempt to sign in with email and password
      await supabase.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Navigate to HomePage on successful sign-in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      // Show error message if sign-in fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  // Method to handle user sign-up
  Future<void> _signUp() async {
    try {
      // Attempt to sign up with email and password
      await supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        data: {
          'email': _emailController.text,
        },
      );
      // Show success message and prompt user to check email
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check your email to confirm signup!')),
      );
    } catch (e) {
      // Show error message if sign-up fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(50.0, 50.0, 50.0, 0),
        child: Column(
          children: [
            // Email input field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            // Password input field
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            // Sign In button
            ElevatedButton(onPressed: _signIn, child: Text('Sign In')),
            SizedBox(height: 20),
            // Sign Up button
            TextButton(onPressed: _signUp, child: Text('Sign Up')),
          ],
        ),
      ),
    );
  }
}
