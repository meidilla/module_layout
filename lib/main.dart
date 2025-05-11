import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // PASTIKAN INI ADA
import 'firebase_options.dart';

import 'login_page.dart';
import 'home_page.dart'; // Penting: Import halaman home Anda
import 'providers/transaction_provider.dart'; // PASTIKAN INI ADA DAN IMPORTNYA BENAR

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // INI BAGIAN PENTINGNYA:
  // ChangeNotifierProvider membungkus seluruh aplikasi Anda (MyApp).
  // Ini memastikan TransactionProvider tersedia di SEMUA bagian aplikasi
  // yang membutuhkan akses ke data transaksi, termasuk MutationPage.
  runApp(
    ChangeNotifierProvider(
      create: (context) => TransactionProvider(),
      child: const MyApp(), // MyApp adalah child dari provider
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koperasi Undiksha',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Colors.white,
        ),
      ),
      debugShowCheckedModeBanner: false,
      // StreamBuilder untuk autentikasi tetap ada di dalam MaterialApp
      // sehingga provider dapat diakses oleh LoginPage atau HomePage.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasData && snapshot.data != null) {
            // Jika pengguna sudah login, arahkan ke HomePage
            // HomePage Anda (atau bagian lain dari aplikasi)
            // HARUS memiliki TabBar atau Navigator yang akan menampilkan MutationPage
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}