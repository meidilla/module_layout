import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import halaman login karena akan diarahkan kembali ke sana
import 'login_page.dart';

class RegisterMbankingPage extends StatefulWidget {
  const RegisterMbankingPage({Key? key}) : super(key: key);

  @override
  _RegisterMbankingPageState createState() => _RegisterMbankingPageState();
}

class _RegisterMbankingPageState extends State<RegisterMbankingPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  // Fungsi untuk menampilkan dialog error
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Registrasi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk mendaftarkan pengguna ke Firebase Authentication dan Firestore
  Future<void> registerUserWithFirebase() async {
    if (!_formKey.currentState!.validate()) {
      return; // Stop jika form tidak valid
    }

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String fullName = nameController.text.trim();
    final String phoneNumber = phoneController.text.trim();

    try {
      // 1. DAFTARKAN PENGGUNA DI FIREBASE AUTHENTICATION
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Opsional: Perbarui display name pengguna di Firebase dengan Nama Lengkap
      if (userCredential.user != null && fullName.isNotEmpty) {
        await userCredential.user!.updateDisplayName(fullName);

        // 3. SIMPAN DATA PENGGUNA KE FIRESTORE
        // Ini adalah cara yang lebih baik dan skalabel untuk menyimpan data pengguna
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'name': fullName,
          'phone': phoneNumber,
          'balance': 0.0, // Inisialisasi saldo awal
          'createdAt': FieldValue.serverTimestamp(),
          // Anda bisa menambahkan field lain di sini
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran berhasil! Anda sekarang dapat login.')),
      );
      // Setelah pendaftaran berhasil, arahkan ke halaman login
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Pendaftaran gagal. Silakan coba lagi.';
      if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah. Mohon gunakan minimal 6 karakter.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email ini sudah terdaftar.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else if (e.code == 'network-request-failed') {
        errorMessage = 'Kesalahan jaringan. Mohon periksa koneksi internet Anda.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Terlalu banyak percobaan. Mohon coba lagi nanti.';
      } else {
        errorMessage = 'Pendaftaran gagal: ${e.message ?? e.code}';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      _showErrorDialog('Terjadi kesalahan tak terduga: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar M-Banking',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // Menggunakan ListView agar bisa di-scroll
            children: [
              const Text(
                'Isi form berikut untuk mendaftar M-Banking',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Nama Lengkap
              const Text(
                'Nama Lengkap',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama lengkap tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email (PENTING: Ini yang akan digunakan untuk login Firebase)
              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nomor Telepon
              const Text(
                'Nomor Telepon',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nomor telepon tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password (PENTING: Ini yang akan digunakan untuk login Firebase)
              const Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password tidak boleh kosong';
                  }
                  if (value.length < 6) { // Firebase default min password length is 6
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: registerUserWithFirebase, // Panggil fungsi pendaftaran Firebase
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Daftar',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8), // Memberi sedikit jarak antara tombol "Daftar" dan "Batal Daftar"

              // Tombol Batal Daftar
              TextButton(
                onPressed: () {
                  // Mengarahkan langsung ke LoginPage dan menghapus semua rute sebelumnya
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (Route<dynamic> route) => false, // Ini memastikan semua rute sebelumnya dihapus
                  );
                },
                child: const Text(
                  'Batal Daftar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1A237E), // Menggunakan warna tema Anda
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}