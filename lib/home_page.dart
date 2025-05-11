import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/foundation.dart'; // Import for debugPrint

// Pastikan semua import halaman ini ada di home_page.dart Anda
import 'ProfilePage.dart';
import 'transfer_page.dart'; // Corrected import, ensure this file defines 'TransferPage' class
import 'check_balance_page.dart';
import 'deposit_page.dart';
import 'payment_page.dart';
import 'loan_page.dart';
import 'mutation_page.dart';
import 'login_page.dart'; // Tambahkan import LoginPage untuk logout

class HomePage extends StatefulWidget {
  const HomePage({super.key}); // Menggunakan super.key sesuai praktik terbaik

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _userName;
  User? _currentUser; // Untuk menyimpan objek pengguna Firebase yang sedang login

  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Panggil fungsi untuk memuat data pengguna saat widget diinisialisasi
  }

  // Fungsi untuk memuat data pengguna (termasuk nama dari Firestore)
  Future<void> _loadUserData() async {
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser != null) {
      // Coba ambil nama dari Firestore terlebih dahulu
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();

        if (mounted) { // Tambahkan pengecekan mounted
          setState(() {
            if (userDoc.exists && userDoc.data() != null) {
              _userName = (userDoc.data() as Map<String, dynamic>)['name'] ?? _currentUser!.displayName;
            } else {
              _userName = _currentUser!.displayName; // Fallback ke nama tampilan Firebase
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading user name from Firestore: $e'); // Menggunakan debugPrint
        if (mounted) {
          setState(() {
            _userName = _currentUser!.displayName; // Fallback jika ada error Firestore
          });
        }
      }
    }
    // Tidak ada lagi blok 'else' untuk _currentUser == null karena HomePage seharusnya hanya diakses saat user login.
  }

  // Fungsi untuk logout (Removed as it was unused/commented out in the provided code)
  // If you need to re-enable this, uncomment it and add a 'mounted' check before Navigator.
  /*
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut(); // Logout dari Firebase

    if (mounted) { // Important: Add mounted check before using context
      // Setelah logout, arahkan ke halaman login dan hapus semua halaman sebelumnya dari stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }
  */

  Widget _buildMenuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // Fixed: Replaced withOpacity with withAlpha to avoid deprecated warning
              color: Colors.blue.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    String? currentUserId = _currentUser?.uid; // Mendapatkan UID pengguna yang sedang login

    return Scaffold( // Pastikan Scaffold dimulai di sini
      appBar: AppBar( // AppBar adalah properti dari Scaffold
        title: const Text(
          'Koperasi Undiksha',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
        actions: const [ // Tombol logout dihapus/dikomentari seperti yang diminta sebelumnya
          // IconButton(
          //   icon: const Icon(Icons.logout, color: Colors.white),
          //   onPressed: _logout, // This was commented out, so the _logout method was unused.
          // ),
        ],
      ),
      backgroundColor: Colors.white, // BackgroundColor adalah properti dari Scaffold
      body: Column( // Body adalah properti dari Scaffold
        children: [
          const SizedBox(height: 16),
          // Profile Card
          Container(
            width: screenWidth * 0.9,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/profile.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.grey),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nasabah',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _userName ?? 'Memuat...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Total Saldo Anda',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      // --- BAGIAN INI YANG MENAMPILKAN SALDO DARI FIRESTORE ---
                      currentUserId == null
                          ? const Text(
                              'Saldo: Rp. 0',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            )
                          : StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUserId)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Text(
                                    'Memuat Saldo...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return const Text(
                                    'Gagal Memuat Saldo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.red,
                                    ),
                                  );
                                }
                                if (!snapshot.hasData || !snapshot.data!.exists) {
                                  return const Text(
                                    'Saldo: Rp. 0',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  );
                                }

                                double currentBalance = (snapshot.data!.data() as Map<String, dynamic>)['balance'] ?? 0.0;

                                return Text(
                                  currencyFormatter.format(currentBalance),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Grid Menu
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              crossAxisCount: screenWidth < 600 ? 3 : 4,
              childAspectRatio: 1.2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMenuItem(
                  Icons.credit_card,
                  'Cek Saldo',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CheckBalancePage()),
                    );
                  },
                ),
                _buildMenuItem(Icons.upload, 'Transfer', onTap: () async {
                  if (currentUserId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // Fixed: Changed 'transfer_page' to 'TransferPage'
                        builder: (context) => TransferPage(currentUserId: currentUserId), // Kirim UID ke TransferPage
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Anda harus login untuk melakukan transfer.')),
                    );
                  }
                }),
                _buildMenuItem(
                  Icons.attach_money,
                  'Deposito',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DepositPage()),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.payment,
                  'Pembayaran',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentPage()),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.account_balance_wallet,
                  'Pinjaman',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoanPage()),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.bar_chart,
                  'Mutasi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MutationPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Butuh Bantuan
          Container(
            width: screenWidth * 0.9,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
            ),
            child: Column(
              children: [
                const Text(
                  'Butuh Bantuan?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      '0812-3857-1847',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.phone, color: Colors.blue, size: 24),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Bottom Navigation
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.blue),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur Pengaturan Belum Tersedia')),
                    );
                  },
                ),
                FloatingActionButton(
                  backgroundColor: const Color(0xFF1A237E),
                  child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fitur QR Code Belum Tersedia')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.blue),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfilePage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}