import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Untuk mendapatkan UID pengguna
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class CheckBalancePage extends StatelessWidget {
  const CheckBalancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp. ',
      decimalDigits: 0,
    );

    User? currentUser = FirebaseAuth.instance.currentUser;
    String? currentUserId = currentUser?.uid;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cek Saldo'),
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Anda harus login untuk mengecek saldo.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cek Saldo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Gagal Memuat Saldo', style: TextStyle(color: Colors.red, fontSize: 18)),
                  Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data saldo tidak ditemukan.'));
          }

          double currentSaldo = (snapshot.data!.data() as Map<String, dynamic>)['balance'] ?? 0.0;

          return SingleChildScrollView( // Menggunakan SingleChildScrollView agar halaman bisa di-scroll jika konten lebih panjang
            child: Padding(
              padding: const EdgeInsets.all(24.0), // Padding di sekitar seluruh konten
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start, // Menyelaraskan konten ke bagian atas
                crossAxisAlignment: CrossAxisAlignment.stretch, // Meregangkan Card agar memenuhi lebar yang tersedia
                children: [
                  const SizedBox(height: 20), // Memberikan sedikit jarak dari AppBar
                  // Card untuk menampilkan saldo
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Memastikan kolom di dalam Card tetap ringkas
                        children: [
                          const Text(
                            'Saldo Anda Saat Ini:',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currencyFormatter.format(currentSaldo), // Saldo dari Firestore
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30), // Jarak antara Card dan teks deskripsi
                  const Text(
                    'Saldo ini adalah jumlah total dana yang tersedia di akun Anda dan siap untuk digunakan dalam berbagai transaksi.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  // Karena SingleChildScrollView dan padding sudah diatur,
                  // tombol "Kembali" di bagian bawah tidak diperlukan dan sudah dihapus di revisi sebelumnya.
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}