import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gradient_animation_text/flutter_gradient_animation_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io';
import 'dart:math' as math;

import 'package:inventarisapp/screens/home.dart';
import 'package:inventarisapp/screens/other/about.dart';
import 'package:inventarisapp/screens/profile/setting.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen(
      {super.key,
      required this.userEmail,
      required this.userName,
      required userPhotoUrl});
  final String userEmail;
  final String userName;

  @override
  _DashboardScreen createState() => _DashboardScreen();
}

class _DashboardScreen extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _connectionStatus = 'Unknown';
  String? firebasePhotoUrl;

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

  Future<void> _fetchFirebasePhotoUrl() async {
    final user = FirebaseAuth.instance.currentUser;

    // Dapatkan URL foto dari Firebase Storage (jika ada)
    try {
      final imageRef =
          FirebaseStorage.instance.ref().child('user_photos/${user?.uid}.jpg');
      final url = await imageRef.getDownloadURL();
      setState(() {
        firebasePhotoUrl = url; // Simpan URL foto dari Firebase
      });
    } catch (e) {
      print('Foto dari Firebase tidak tersedia: $e');
      // Tidak melakukan apa-apa, firebasePhotoUrl akan tetap null jika tidak ada foto di Firebase
    }
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

  Widget _buildProductCard({
    required String productName,
    required String productImage,
    required String productPrice,
  }) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image with Rounded Corners
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              productImage,
              fit: BoxFit.cover,
              height: 100,
              width: double.infinity,
            ),
          ),
          // Product Info with Background and White Text
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    productPrice,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.white), // Warna ikon tetap putih
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Teks menjadi putih
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white, // Teks menjadi putih
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue.shade600,
        title: const GradientAnimationText(
          text: Text(
            'Sikoin',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          colors: [
            Color.fromARGB(255, 207, 155, 1), // 1
            Colors.amber, // 2
            Colors.amber, // 3
            Colors.white,
          ],
          duration: Duration(seconds: 7),
          transform:
              GradientRotation(math.pi / 4), // Menambahkan transformasi rotasi
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.settings),
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => const SettingScreens(),
        //         ),
        //       );
        //     },
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     onPressed: () {
        //       _showLogoutDialog();
        //     },
        //   )
        // ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.blue.shade700,
        width: MediaQuery.of(context).size.width * 0.54,
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
                    Colors.blue.shade900,
                    Colors.blue.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 42.0),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    margin: const EdgeInsets.symmetric(
                        vertical: 10.0, horizontal: 12.0),
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
                          Colors.blueAccent.shade700,
                          const Color.fromARGB(255, 14, 41, 116),
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
                          backgroundImage: firebasePhotoUrl != null
                              ? NetworkImage(
                                  firebasePhotoUrl!) // Gunakan foto dari Firebase jika ada
                              : user?.photoURL != null
                                  ? NetworkImage(user!
                                      .photoURL!) // Gunakan foto dari snapshot jika ada
                                  : const NetworkImage(
                                      'https://www.w3schools.com/howto/img_avatar.png', // Gunakan foto default
                                    ),
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
                              style: const TextStyle(
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
                    title: const Text("Dashboard",
                        style: TextStyle(color: Colors.white)),
                    tileColor: Colors.deepPurple.shade600,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.list_alt_outlined,
                        color: Colors.white),
                    title: const Text("Item List",
                        style: TextStyle(color: Colors.white)),
                    tileColor: Colors.deepPurple.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.storage, color: Colors.white),
                    title: const Text("Storage",
                        style: TextStyle(color: Colors.white)),
                    tileColor: Colors.deepPurple.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.inventory_rounded,
                        color: Colors.white),
                    title: const Text("Laporan",
                        style: TextStyle(color: Colors.white)),
                    tileColor: Colors.deepPurple.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.format_list_bulleted_add,
                        color: Colors.white),
                    title: const Text("Add Item & Category",
                        style: TextStyle(color: Colors.white)),
                    tileColor: Colors.deepPurple.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
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
                          builder: (context) => SettingScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_person_sharp,
                        color: Colors.white),
                    title: const Text("Change Password",
                        style: TextStyle(color: Colors.white)),
                    tileColor: Colors.deepPurple.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.info_outline, color: Colors.white),
                    title: const Text("About",
                        style: TextStyle(color: Colors.white)),
                    tileColor: Colors.deepPurple.shade600,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.logout_outlined, color: Colors.white),
                    title: const Text("Logout",
                        style: TextStyle(color: Colors.white)),
                    tileColor: Colors.deepPurple.shade600,
                    onTap: () {
                      _showLogoutDialog();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SizedBox(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            children: [
              // Greeting Section with Container
              Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade500,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'Selamat Datang di Dashboard Sikoin',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),

              // User Information Section
              Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FutureBuilder<User?>(
                  future: getCurrentUser(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                          child: Text('User not logged in',
                              style: TextStyle(color: Colors.white)));
                    }

                    User? user = snapshot.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nama: ${user?.displayName ?? 'Tidak Ada Nama'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email: ${user?.email ?? 'Tidak Ada Email'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Horizontal ListView for Info Cards
              Container(
                padding:
                    const EdgeInsets.all(11), // Padding di sekeliling ListView
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.21,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      _buildInfoCard(
                        title: 'Total Barang',
                        value: '150',
                        icon: Icons.inventory,
                        color: Colors.blue,
                      ),
                      _buildInfoCard(
                        title: 'Kategori',
                        value: '12',
                        icon: Icons.category,
                        color: Colors.amber,
                      ),
                      _buildInfoCard(
                        title: 'Barang Tersedia',
                        value: '120',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      _buildInfoCard(
                        title: 'Barang Keluar',
                        value: '30',
                        icon: Icons.remove_circle,
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Activity Report Section
              Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.trending_up, color: Colors.deepPurple),
                  title: const Text(
                    'Laporan Aktivitas',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple),
                  ),
                  subtitle: const Text(
                    'Lihat ringkasan dan statistik aktivitas inventaris.',
                    style: TextStyle(color: Colors.deepPurpleAccent),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      color: Colors.deepPurple),
                  onTap: () {
                    // Navigasi ke halaman laporan aktivitas
                  },
                ),
              ),

              // New ListView Section - Product Gallery
              const SizedBox(height: 20),
              Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade400,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Galeri Produk',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.25,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildProductCard(
                            productName: 'Produk A',
                            productImage: 'assets/images/productA.jpg',
                            productPrice: 'Rp 150,000',
                          ),
                          _buildProductCard(
                            productName: 'Produk B',
                            productImage: 'assets/images/productB.jpg',
                            productPrice: 'Rp 200,000',
                          ),
                          _buildProductCard(
                            productName: 'Produk C',
                            productImage: 'assets/images/productC.jpg',
                            productPrice: 'Rp 175,000',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
