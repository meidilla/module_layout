import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Pastikan impor ini ada

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailOrUsernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Key untuk Form

  // Helper function to show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
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

  // Fungsi asinkron untuk mengirim link reset password
  Future<void> _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      final String identifier = _emailOrUsernameController.text.trim();

      try {
        // Panggil metode sendPasswordResetEmail dari FirebaseAuth
        await FirebaseAuth.instance.sendPasswordResetEmail(email: identifier);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link reset password telah dikirim ke email Anda. Silakan cek kotak masuk atau folder spam.')),
        );
        Navigator.pop(context); // Kembali ke halaman login setelah sukses
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
        if (e.code == 'user-not-found') {
          errorMessage = 'Email/username tidak terdaftar.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Format email tidak valid.';
        } else if (e.code == 'auth/network-request-failed') {
          errorMessage = 'Kesalahan jaringan. Mohon periksa koneksi internet Anda.';
        } else {
          // Untuk error lain yang tidak spesifik
          errorMessage = 'Gagal mengirim link reset. Error: ${e.message ?? e.code}';
        }
        _showErrorDialog(errorMessage); // Tampilkan dialog error
      } catch (e) {
        _showErrorDialog('Terjadi kesalahan tak terduga: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lupa Password',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form( // Bungkus dengan Form
          key: _formKey, // Tetapkan GlobalKey
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan username atau email Anda untuk reset password',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Username / Email',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField( // Ganti TextField menjadi TextFormField
                controller: _emailOrUsernameController, // Tetapkan controller
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                keyboardType: TextInputType.emailAddress, // Bisa diatur ke emailAddress
                validator: (value) { // Tambahkan validator
                  if (value == null || value.isEmpty) {
                    return 'Username atau Email tidak boleh kosong';
                  }
                  // Anda bisa menambahkan validasi format email lebih lanjut di sini jika perlu
                  // Contoh: if (!RegExp(r'^[^@]+@[^@]+$').hasMatch(value)) { return 'Format email tidak valid'; }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sendResetLink, // Panggil fungsi yang kita buat
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Center( // Wrap with Center to ensure the text is centered
                  child: Text(
                    'Kirim Link Reset',
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
    _emailOrUsernameController.dispose();
    super.dispose();
  }
}