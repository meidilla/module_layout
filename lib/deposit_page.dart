import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format mata uang
// import 'package:cloud_firestore/cloud_firestore.dart'; // Sudah tidak perlu jika tidak ada direct Firestore ops lagi
import 'package:firebase_auth/firebase_auth.dart'; // Untuk mendapatkan UID pengguna
import 'package:flutter/services.dart'; // Untuk TextInputFormatter
import 'package:provider/provider.dart'; // Digunakan untuk mengakses TransactionProvider

// PENTING: Pastikan ini mengarah ke file model Transaction yang sudah diperbarui
import 'package:module_layout/models/transaction.dart'; // HARUS DIIMPORT UNTUK TransactionCategory dan TransactionType
import 'package:module_layout/providers/transaction_provider.dart'; // TAMBAHKAN INI (sesuaikan path jika berbeda)


// ======================================================================
// CurrencyInputFormatter - Pastikan kelas ini ada dan berfungsi dengan baik
// ======================================================================
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String newText = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (double.tryParse(newText) == null) {
      return oldValue;
    }

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );

    String formattedText = formatter.format(double.parse(newText));

    int selectionOffset = newValue.selection.end;
    int numCommasOld = (oldValue.text.length - oldValue.text.replaceAll('.', '').length);
    int numCommasNew = (formattedText.length - formattedText.replaceAll('.', '').length);

    int newOffset = selectionOffset + (numCommasNew - numCommasOld);

    if (newOffset < 0) newOffset = 0;
    if (newOffset > formattedText.length) newOffset = formattedText.length;
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

// ======================================================================
// DepositPage Sederhana
// ======================================================================
class DepositPage extends StatefulWidget {
  const DepositPage({super.key});

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  bool _isProcessingDeposit = false; // Untuk menampilkan loading saat proses penambahan saldo

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? const Color(0xFFB02323) : const Color(0xFF388E3C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ======================================================================
  // FUNGSI: Menambah Saldo Pengguna Menggunakan TransactionProvider (SUDAH DIPERBARUI)
  // ======================================================================
  Future<void> _addBalanceDirectly() async {
    setState(() {
      _isProcessingDeposit = true; // Mulai loading
    });

    final String cleanedAmountText = _amountController.text.replaceAll('.', '');
    final double? amountToAdd = double.tryParse(cleanedAmountText);

    if (amountToAdd == null || amountToAdd <= 0) {
      _showSnackBar('Jumlah deposito tidak valid. Silakan masukkan jumlah yang benar.', isError: true);
      setState(() {
        _isProcessingDeposit = false;
      });
      return;
    }

    User? currentUser = FirebaseAuth.instance.currentUser;
    String? currentUserId = currentUser?.uid;

    if (currentUserId == null) {
      _showSnackBar('Anda harus login untuk melakukan deposito. Silakan login terlebih dahulu.', isError: true);
      setState(() {
        _isProcessingDeposit = false;
      });
      return;
    }

    try {
      // Pastikan context masih valid sebelum mengakses Provider
      if (!mounted) return;
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

      // 1. Perbarui saldo pengguna menggunakan TransactionProvider
      await transactionProvider.updateUserBalance(
        currentUserId,
        amountToAdd,
        isDebit: false, // isDebit: false berarti menambahkan dana (kredit)
      );

      // 2. Catat transaksi menggunakan TransactionProvider
      await transactionProvider.addTransactionToFirestore(
        userId: currentUserId,
        amount: amountToAdd,
        description: 'Deposito dana (melalui Deposit Page)',
        type: TransactionType.credit, // Deposit adalah kredit ke akun pengguna
        category: TransactionCategory.deposit.toString().split('.').last, // Mengkonversi enum ke string
      );

      _showSnackBar('Deposito sebesar ${currencyFormatter.format(amountToAdd)} berhasil ditambahkan!');
      _amountController.clear(); // Bersihkan input setelah berhasil
      if (mounted) Navigator.pop(context); // Kembali ke halaman sebelumnya setelah berhasil
    } catch (e) {
      String errorMessage = 'Gagal menambahkan deposito: ${e.toString()}';
      // Coba ekstrak pesan error yang lebih ramah pengguna dari Exception atau FirebaseException
      if (e is Exception) {
        errorMessage = 'Gagal menambahkan deposito: ${e.toString().replaceFirst('Exception: ', '')}';
      } else if (e is FirebaseException) {
        errorMessage = 'Gagal menambahkan deposito: ${e.message ?? 'Terjadi kesalahan Firebase.'}';
      }
      _showSnackBar(errorMessage, isError: true);
      debugPrint('Error adding balance directly: $e'); // Untuk debugging lebih detail
    } finally {
      setState(() {
        _isProcessingDeposit = false; // Hentikan loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Saldo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.add_card, size: 80, color: Color(0xFF1A237E)), // Ikon lebih relevan
            const SizedBox(height: 24),
            const Text(
              'Masukkan jumlah saldo yang ingin Anda tambahkan.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- Input Jumlah Saldo ---
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Jumlah Saldo',
                hintText: 'Contoh: 500.000',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF1A237E)), // Ikon mata uang
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              ),
              style: const TextStyle(fontSize: 18),
              // PENTING: Tambahkan baris onChanged ini untuk memperbarui state dan mengaktifkan tombol
              onChanged: (text) {
                setState(() {
                  // Ini akan memicu rebuild widget dan mengevaluasi ulang kondisi tombol
                });
              },
            ),
            const SizedBox(height: 32), // Spasi lebih besar sebelum tombol

            // --- Tombol untuk Menambah Saldo Sekarang ---
            _isProcessingDeposit
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _amountController.text.isNotEmpty // Tombol aktif jika TextField tidak kosong
                        ? _addBalanceDirectly // Panggil fungsi penambah saldo langsung
                        : null, // Nonaktif jika jumlah kosong
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Tambah Saldo Sekarang',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}