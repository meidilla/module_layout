import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Ini tidak lagi diperlukan untuk fungsi isLogged

// Halaman-halaman lain yang diimpor
import 'ForgotPasswordPage.dart';
import 'RegisterMbankingPage.dart';
import 'home_page.dart'; // Pastikan Anda mengimpor home_page.dart

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController(); // Akan digunakan untuk Email
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  // Fungsi untuk memvalidasi login dengan Firebase Authentication
  Future<void> _validateLogin() async {
    setState(() {
      _errorMessage = ''; // Bersihkan pesan error sebelumnya
    });

    String email = _usernameController.text.trim(); // Gunakan sebagai email untuk Firebase
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Email dan password tidak boleh kosong.';
      });
      return;
    }

    try {
      // Panggil metode login dari Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Login berhasil, TIDAK PERLU lagi menyimpan status login ke SharedPreferences
      // Karena main.dart yang direvert tidak menggunakannya.
      // final SharedPreferences prefs = await SharedPreferences.getInstance();
      // await prefs.setBool('isLoggedIn', true);

      // Navigasi ke halaman utama (HomePage) menggunakan MaterialPageRoute
      // dan hapus halaman login dari stack navigasi
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()), // Mengarahkan ke HomePage
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login Berhasil!')),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login gagal. Silakan coba lagi.';
      if (e.code == 'user-not-found') {
        errorMessage = 'Email tidak terdaftar.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Password salah.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else if (e.code == 'auth/network-request-failed') {
        errorMessage = 'Kesalahan jaringan. Mohon periksa koneksi internet Anda.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Terlalu banyak percobaan login. Mohon coba lagi nanti.';
      } else {
        errorMessage = 'Login gagal: ${e.message ?? e.code}';
      }
      setState(() {
        _errorMessage = errorMessage;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan tak terduga: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Koperasi Undiksha',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // Logo Undiksha
                  Image.asset(
                    'assets/logo.png', // Pastikan path ke logo.png sudah benar
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 30),

                  // Form Login
                  Container(
                    width: constraints.maxWidth > 600 ? 400 : double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Email',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.emailAddress, // Set keyboard type to email
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Password',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tampilkan pesan error jika ada
                        if (_errorMessage.isNotEmpty)
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _validateLogin, // Memanggil fungsi login Firebase
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Login',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                // Navigasi ke halaman registrasi
                                Navigator.pushReplacement( // Menggunakan pushReplacement agar halaman login tidak bisa di-back
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterMbankingPage()),
                                );
                              },
                              child: const Text(
                                'Daftar Mbanking',
                                style: TextStyle(color: Color(0xFF1A237E)),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordPage()),
                                );
                              },
                              child: const Text(
                                'Lupa Password?',
                                style: TextStyle(color: Color(0xFF1A237E)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Copyright
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Copyright @2025 by Meidilla Azmi-2315091009',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}