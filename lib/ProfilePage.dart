import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format mata uang
import 'package:firebase_auth/firebase_auth.dart'; // Untuk mendapatkan UID pengguna
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk Firestore
import 'login_page.dart'; // Pastikan mengimpor LoginPage

class ProfilePage extends StatefulWidget {
  // Constructor tanpa parameter saldo, karena saldo akan diambil langsung dari Firestore
  const ProfilePage({super.key}); 

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _userName;
  String? _userEmail;

  // Formatter untuk mata uang
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  // Stream untuk mendapatkan data pengguna secara real-time (termasuk saldo)
  late Stream<DocumentSnapshot> _userDocStream;
  User? _currentUser; // Variabel untuk menyimpan current user

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser; // Dapatkan current user di initState

    // Panggil fungsi untuk memuat nama dan email (satu kali atau sebagai fallback)
    _loadUserDataOnce();

    if (_currentUser != null) {
      // Inisialisasi stream untuk mendengarkan perubahan dokumen pengguna (termasuk saldo)
      _userDocStream = FirebaseFirestore.instance
          .collection('users') // Pastikan nama koleksi di Firestore adalah 'users'
          .doc(_currentUser!.uid) // ID dokumen adalah UID pengguna
          .snapshots();
    }
  }

  // Fungsi untuk memuat data pengguna (nama, email) satu kali dari Firebase Auth/Firestore
  Future<void> _loadUserDataOnce() async {
    if (_currentUser != null) {
      // Ambil displayName dan email dari Firebase Auth sebagai default
      String nameFromAuth = _currentUser!.displayName ?? 'Nama Pengguna';
      String emailFromAuth = _currentUser!.email ?? 'email@contoh.com';

      // Coba ambil data tambahan dari Firestore
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          // Prefer data dari Firestore jika ada
          _userName = userData['name'] ?? nameFromAuth;
          _userEmail = userData['email'] ?? emailFromAuth;
        } else {
          // Jika dokumen pengguna belum ada di Firestore, gunakan dari Firebase Auth
          _userName = nameFromAuth;
          _userEmail = emailFromAuth;
        }
      } catch (e) {
        // Tangani error saat mengambil dari Firestore
        print('Error loading user data from Firestore: $e'); // Hanya untuk debugging
        _userName = nameFromAuth;
        _userEmail = emailFromAuth;
      }
    } else {
      // Handle kasus jika pengguna tidak login
      _userName = 'Nama Pengguna';
      _userEmail = 'email@contoh.com';
    }

    // Perbarui UI hanya jika widget masih terpasang
    if (mounted) {
      setState(() {});
    }
  }

  // Fungsi helper untuk menampilkan dialog konfirmasi logout
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Tutup dialog

                try {
                  await FirebaseAuth.instance.signOut(); // Sign out dari Firebase

                  // Arahkan ke halaman login dan hapus semua rute sebelumnya
                  // Pastikan widget masih terpasang sebelum navigasi
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false, // Hapus semua rute di stack
                    );
                  }
                } catch (e) {
                  // Tangani error jika ada masalah saat logout
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal logout: ${e.toString()}')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Warna merah untuk tombol logout
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Jika pengguna belum login, tampilkan pesan
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Anda harus login untuk melihat profil.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>( // Menggunakan StreamBuilder untuk saldo real-time
        stream: _userDocStream,
        builder: (context, snapshot) {
          // Tampilkan loading jika data masih dalam proses
          if (snapshot.connectionState == ConnectionState.waiting || _userName == null || _userEmail == null) {
            return const Center(child: CircularProgressIndicator());
          }
          // Tampilkan error jika ada masalah
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // Tampilkan pesan jika dokumen pengguna tidak ditemukan
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data pengguna tidak ditemukan.'));
          }

          // Ambil saldo dari snapshot Firestore
          Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
          double currentSaldo = userData['balance'] ?? 0.0; // Default 0.0 jika field 'balance' tidak ada

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center( // Memusatkan bagian atas profil
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 50,
                        // Pastikan 'assets/profile.png' ada dan dideklarasikan di pubspec.yaml
                        backgroundImage: AssetImage('assets/profile.png'), 
                        // Alternatif jika tidak ada gambar:
                        // child: Icon(Icons.person, size: 60, color: Colors.white),
                        // backgroundColor: Colors.blue.shade700,
                      ),
                      const SizedBox(height: 16),
                      // Menampilkan nama dari state _userName
                      Text(
                        'Nasabah: ${_userName!}', // Menggunakan '!' karena sudah dicek null di atas
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Menampilkan email dari state _userEmail
                      Text(
                        'Email: ${_userEmail!}', // Menggunakan '!' karena sudah dicek null di atas
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Menampilkan saldo yang diformat (diambil dari StreamBuilder)
                      Text(
                        'Total Saldo: ${_currencyFormatter.format(currentSaldo)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E), // Warna konsisten
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(), // Untuk mendorong tombol logout ke bagian bawah
                Center( // Memusatkan tombol logout
                  child: ElevatedButton(
                    onPressed: () {
                      _showLogoutConfirmation(context); // Panggil fungsi konfirmasi
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}