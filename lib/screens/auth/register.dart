import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventarisapp/services/local_db_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Fungsi untuk validasi kekuatan password
  bool _isPasswordValid(String password) {
    final RegExp passwordRegExp = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{6,}$',
    );
    return passwordRegExp.hasMatch(password);
  }

  Future<void> _registerWithEmailAndPassword() async {
    setState(() {
      _isLoading = true;
    });

    // Validasi password sebelum mendaftar ke Firebase
    if (!_isPasswordValid(_passwordController.text.trim())) {
      _showSnackbar(
        'Password harus minimal 6 karakter dan mengandung huruf besar, huruf kecil, dan angka',
        Colors.red,
      );
      setState(() {
        _isLoading = false;
      });
      return; // Menghentikan proses jika password tidak valid
    }

    try {
      // Registrasi di Firebase
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        // Jika registrasi Firebase berhasil, simpan data ke SQLite
        await LocalDBService().addUser({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'name': 'User', // Gantilah dengan nama pengguna jika diperlukan
          'photo': '',
          'role': 'user', // Misalnya role user biasa
        });

        // Tampilkan pesan sukses dan kembali ke layar login
        _showSnackbar('Registrasi berhasil!', Colors.green);
        Navigator.pop(context); // Kembali ke layar login
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'Password terlalu lemah!';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email sudah terdaftar!';
      } else {
        message = 'Registrasi gagal!';
      }
      _showSnackbar(message, Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk menampilkan Snackbar dengan warna berbeda
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
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 32.0),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _registerWithEmailAndPassword,
                    child: const Text('Register'),
                  ),
          ],
        ),
      ),
    );
  }
}
