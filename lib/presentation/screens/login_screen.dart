import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/presentation/screens/camera_inference_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Screen'),
        backgroundColor: Colors.blue, // Assuming a blue app bar from the image
        foregroundColor: Colors.white, // Text color for the app bar title
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'testlogin@gmail.com', // Example from image
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: '123123', // Example from image
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity, // Make the button full width
              child: ElevatedButton(
                onPressed: () {
                  // Implement login logic here
                  print('Email: ${_emailController.text}');
                  print('Password: ${_passwordController.text}');

                   Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (context) => const CameraInferenceScreen())
                  )
                  .then((value) {
                    // Handle any actions after returning from TransactionPage
                    if (value != null) {
                      // For example, you can refresh the home page or update the state
                      setState(() {});
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color from image
                  foregroundColor: Colors.white, // Text color for the button
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'LOGIN',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Belum punya akun?'),
                TextButton(
                  onPressed: () {
                    // Navigate to registration screen or show a message
                    print('Daftar Sekarang tapped');
                  },
                  child: const Text(
                    'DAFTAR SEKARANG',
                    style: TextStyle(color: Colors.blue), // Link color from image
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}