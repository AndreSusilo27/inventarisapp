import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gradient_animation_text/flutter_gradient_animation_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'dart:math' as math;

import 'package:inventarisapp/screens/home.dart';
import 'package:inventarisapp/screens/profile/setting.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen(
      {super.key, required this.userEmail, required this.userName});
  final String userEmail;
  final String userName;

  @override
  _DashboardScreen createState() => _DashboardScreen();
}

class _DashboardScreen extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _connectionStatus = 'Unknown';

  // Fungsi untuk mendapatkan data pengguna saat ini
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Fungsi untuk memeriksa status koneksi
  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    // Pastikan koneksi benar-benar memiliki akses ke internet
    bool hasInternet = false;
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      try {
        final result = await InternetAddress.lookup('example.com');
        hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } on SocketException catch (_) {
        hasInternet = false;
      }
    }

    setState(() {
      _connectionStatus = hasInternet ? 'Online' : 'Offline';
    });

    // Menambahkan print untuk debug log
    print('Connection Status: $_connectionStatus');
  }

  // Fungsi refresh untuk dipanggil saat pull-to-refresh dilakukan
  Future<void> _onRefresh() async {
    await Future.delayed(
        const Duration(seconds: 2)); // Simulasikan loading data baru
    checkConnectivity(); // Cek status koneksi ulang setelah refresh
  }

// Fungsi untuk menampilkan konfirmasi logout
  Future<void> _showLogoutDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin logout dari aplikasi?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Tidak'),
              onPressed: () {
                Navigator.of(context).pop(); // Menutup dialog jika "Tidak"
              },
            ),
            TextButton(
              child: const Text('Ya'),
              onPressed: () async {
                // Logout dari Firebase
                await _auth.signOut();

                // Logout juga dari Google Sign-In
                await GoogleSignIn().signOut();

                // Arahkan ke halaman HomeScreen setelah logout
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    checkConnectivity(); // Cek koneksi saat aplikasi dimulai
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const GradientAnimationText(
          text: Text(
            'Inventaris Sikocak',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          colors: [
            Color(0xFF061A9C),
            Color(0xff92effd),
          ],
          duration: Duration(seconds: 5),
          transform:
              GradientRotation(math.pi / 4), // Menambahkan transformasi rotasi
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingScreens(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Logout dari Firebase
              await _auth.signOut();

              // Logout juga dari Google Sign-In
              await GoogleSignIn().signOut();

              // Arahkan ke halaman HomeScreen setelah logout
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const HomeScreen(), // HomeScreen sebagai halaman login
                ),
              );
            },
          )
        ],
      ),
      drawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.66,
        child: FutureBuilder<User?>(
          future: getCurrentUser(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData) {
              return const Center(child: Text('User not logged in'));
            }

            User? user = snapshot.data;
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade600,
                    Colors.black87,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 37.0),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    margin: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade700,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(4, 6),
                        ),
                      ],
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade700,
                          Colors.deepPurple.shade900,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 65,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : const NetworkImage(
                                  'https://www.w3schools.com/howto/img_avatar.png'),
                          backgroundColor: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${user?.displayName ?? 'Nama Tidak Tersedia'}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            letterSpacing: 1.1,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  Colors.blueAccent,
                                  Colors.purpleAccent
                                ],
                              ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user?.email ?? 'Email Tidak Tersedia',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.circle,
                              color: _connectionStatus == 'Online'
                                  ? Colors.green
                                  : Colors.red,
                              size: 12,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _connectionStatus == 'Online'
                                  ? 'Online'
                                  : 'Offline',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(
                          color: Colors.white38,
                          thickness: 1,
                          height: 30,
                          indent: 50,
                          endIndent: 50,
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.white),
                    title: const Text("Home",
                        style: TextStyle(color: Colors.white)),
                    tileColor: Colors.deepPurple.shade600,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.white),
                    title: const Text("Settings",
                        style: TextStyle(color: Colors.white)),
                    tileColor: Colors.deepPurple.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingScreens(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          children: [
            Center(
              child: Text(
                'Selamat datang di Dashboard',
                style: TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<User?>(
              future: getCurrentUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('User not logged in'));
                }

                User? user = snapshot.data;
                return Center(
                  child: Text(
                    'Nama: ${user?.displayName ?? 'Tidak Ada Nama'}\nEmail: ${user?.email ?? 'Tidak Ada Email'}',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      extendBodyBehindAppBar:
          false, // Pastikan tubuh konten utama tidak menutupi AppBar
    );
  }
}
