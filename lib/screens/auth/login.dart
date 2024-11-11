import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:inventarisapp/screens/dashboard.dart';
import 'package:sign_in_button/sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginWithEmailPassword() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validasi email dan password
    if (email.isEmpty || password.isEmpty) {
      _showSnackbar(
        'Email dan password tidak boleh kosong.',
        Colors.red,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}').hasMatch(email)) {
      _showSnackbar(
        'Format email tidak valid.',
        Colors.red,
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        if (!user.emailVerified) {
          _showSnackbar(
            'Email belum diverifikasi. Silakan periksa email Anda.',
            Colors.orange,
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        String userEmail = user.email ?? 'No Email';
        String userName = user.displayName ?? 'No Name';

        _showSnackbar('Login berhasil', Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              userEmail: userEmail,
              userName: userName,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackbar('Login gagal: ${_handleAuthError(e)}', Colors.red);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        final String userEmail = userCredential.user?.email ?? 'User';
        final String userName = userCredential.user?.displayName ?? 'Anonymous';

        _showSnackbar('Login berhasil dengan Google', Colors.green);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              userEmail: userEmail,
              userName: userName,
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackbar(
          'Login dengan Google gagal: ${_handleAuthError(e)}', Colors.red);
    }
    setState(() {
      _isLoading = false;
    });
  }

  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Pengguna tidak ditemukan. Silakan periksa email Anda.';
        case 'wrong-password':
          return 'Password salah. Silakan coba lagi.';
        case 'network-request-failed':
          return 'Koneksi jaringan gagal. Periksa koneksi Anda.';
        default:
          return 'Terjadi kesalahan: ${error.message}';
      }
    }
    return 'Terjadi kesalahan yang tidak diketahui.';
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      ElevatedButton(
                        onPressed: _loginWithEmailPassword,
                        child: const Text('Login dengan Email'),
                      ),
                      const SizedBox(height: 8),
                      SignInButton(
                        Buttons.google,
                        onPressed: _loginWithGoogle,
                        text: "Login dengan Google",
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
