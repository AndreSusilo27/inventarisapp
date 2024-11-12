import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:inventarisapp/screens/dashboard.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:inventarisapp/services/local_db_service.dart';
import 'package:http/http.dart' as http;

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

  Future<String> _uploadPhotoToFirebase(String photoUrl, String uid) async {
    try {
      final response = await http.get(Uri.parse(photoUrl));
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        final imageRef =
            FirebaseStorage.instance.ref().child('user_photos/$uid.jpg');
        await imageRef.putData(imageBytes);
        return await imageRef.getDownloadURL();
      }
    } catch (e) {
      print('Failed to download or upload photo: $e');
    }
    return 'https://www.w3schools.com/howto/img_avatar.png'; // Gambar default
  }

  Future<void> _loginWithEmailPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String userEmail = userCredential.user?.email ?? 'No Email';
      String userName = userCredential.user?.displayName ?? 'No Name';
      String? userPhotoUrl = userCredential.user?.photoURL;

      if (userPhotoUrl == null) {
        userPhotoUrl = 'https://www.w3schools.com/howto/img_avatar.png';
      }

      String uid = userCredential.user!.uid;
      String photoUrlToStore = await _uploadPhotoToFirebase(userPhotoUrl, uid);

      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': userEmail,
          'name': userName,
          'photo': photoUrlToStore,
          'uid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await LocalDBService().addUser({
        'email': userEmail,
        'name': userName,
        'photo': photoUrlToStore,
      });

      _showSnackbar('Login berhasil', Colors.green);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(
            userEmail: userEmail,
            userName: userName,
            userPhotoUrl: photoUrlToStore,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      final user = await LocalDBService().getUserByEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        _showSnackbar('Login offline berhasil', Colors.green);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              userEmail: user['email'],
              userName: user['name'],
              userPhotoUrl: user['photo'],
            ),
          ),
        );
      } else {
        _showSnackbar('Login gagal: ${e.message}', Colors.red);
      }
    } catch (e) {
      _showSnackbar('Terjadi kesalahan: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Melakukan login menggunakan Google
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Menggunakan kredensial Google untuk login ke Firebase
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        // Mengambil informasi pengguna
        final String userEmail = user?.email ?? 'No Email';
        final String userName = user?.displayName ?? 'No Name';
        String? userPhotoUrl = user?.photoURL;

        // Tentukan URL gambar default jika tidak ada photoURL
        String photoUrlToStore =
            'https://www.w3schools.com/howto/img_avatar.png';

        if (userPhotoUrl != null) {
          try {
            // Mengunduh gambar dari URL photoURL
            final response = await http.get(Uri.parse(userPhotoUrl));
            if (response.statusCode == 200) {
              final imageBytes = response.bodyBytes;

              // Mengunggah gambar ke Firebase Storage
              final imageRef = FirebaseStorage.instance
                  .ref()
                  .child('user_photos/${user!.uid}.jpg');
              await imageRef.putData(imageBytes);

              // Mendapatkan URL gambar yang di-upload dan memperbarui photoUrlToStore
              photoUrlToStore = await imageRef.getDownloadURL();
            }
          } catch (e) {
            print('Gagal mengunduh atau mengunggah foto profil: $e');
            // Tetap gunakan URL default jika ada masalah
          }
        }

        // Cek apakah data pengguna sudah ada di Firestore berdasarkan UID
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get();

        if (!userDoc.exists) {
          // Jika pengguna belum ada, simpan data pengguna ke Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid)
              .set({
            'email': userEmail,
            'name': userName,
            'photo': photoUrlToStore, // Simpan URL foto yang benar ke Firestore
            'uid': user?.uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // Simpan data pengguna ke SQLite
        await LocalDBService().addUser({
          'email': userEmail,
          'name': userName,
          'photo': photoUrlToStore, // Simpan URL foto yang benar ke SQLite
        });

        _showSnackbar('Login berhasil dengan Google', Colors.green);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              userEmail: userEmail,
              userName: userName,
              userPhotoUrl: photoUrlToStore, // Pass photo URL ke Dashboard
            ),
          ),
        );
      }
    } catch (e) {
      _showSnackbar('Login dengan Google gagal: ${e.toString()}', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
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
                        child: const Text('Login'),
                      ),
                      const Divider(
                        color: Colors.white38,
                        thickness: 1,
                        height: 30,
                        indent: 50,
                        endIndent: 50,
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
