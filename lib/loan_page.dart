import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart'; // Pastikan path ini benar
import 'package:firebase_auth/firebase_auth.dart';

class LoanPage extends StatefulWidget {
  const LoanPage({super.key}); // FIX 2: Menggunakan super.key untuk konstruktor yang lebih ringkas

  @override
  State<LoanPage> createState() => _LoanPageState();
}

class _LoanPageState extends State<LoanPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _tenureController = TextEditingController();

  // Formatter untuk live formatting input
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ', // Sertakan simbol Rupiah untuk live formatting
    decimalDigits: 0, // Tanpa angka desimal
  );

  @override
  void initState() {
    super.initState();
    // Menambahkan listener ke controller jumlah pinjaman
    // Setiap kali teks berubah, fungsi _formatAmountInput akan dipanggil
    _amountController.addListener(_formatAmountInput);
  }

  @override
  void dispose() {
    // Penting: Hapus listener dan dispose controller saat widget dihapus
    _amountController.removeListener(_formatAmountInput);
    _amountController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  // Fungsi untuk memformat input angka secara langsung
  void _formatAmountInput() {
    String text = _amountController.text;

    // Dapatkan posisi kursor sebelum membersihkan teks
    int cursorPosition = _amountController.selection.start;

    // Hapus semua karakter non-digit (termasuk titik, koma, 'Rp ', spasi)
    String cleanText = text.replaceAll(RegExp(r'[^0-9]'), '');

    // Jika teks kosong setelah dibersihkan, atur kembali controller dan keluar
    if (cleanText.isEmpty) {
      _amountController.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      return;
    }

    // Konversi ke angka untuk diformat
    double? value = double.tryParse(cleanText);

    if (value == null) {
      return; // Seharusnya tidak terjadi karena regex sudah menghapus non-digit
    }

    // Hitung berapa banyak karakter non-digit yang ada sebelum kursor di teks asli
    int nonDigitCountBeforeCursor = text.substring(0, cursorPosition).replaceAll(RegExp(r'[0-9]'), '').length;

    // Format angka
    String formattedText = _currencyFormatter.format(value);

    // Update teks controller
    // Pastikan posisi kursor tidak negatif atau melebihi panjang teks
    int newCursorPosition = formattedText.length - (cleanText.length - cursorPosition + nonDigitCountBeforeCursor);
    if (newCursorPosition < 0) newCursorPosition = 0;
    if (newCursorPosition > formattedText.length) newCursorPosition = formattedText.length;

    _amountController.value = TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  void _applyLoan() {
    if (_formKey.currentState!.validate()) {
      final String rawAmountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final double? loanAmount = double.tryParse(rawAmountText); // Parsing jumlah pinjaman
      final String tenure = _tenureController.text;
      final int? tenureMonths = int.tryParse(tenure);

      final String displayedAmount = _amountController.text;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengajuan pinjaman $displayedAmount untuk $tenure bulan berhasil!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // --- START: KODE YANG DITAMBAHKAN UNTUK MEREKAM TRANSAKSI PINJAMAN ---
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && loanAmount != null && loanAmount > 0 && tenureMonths != null && tenureMonths > 0) {
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        
        // Mencatat transaksi pinjaman yang diberikan/disetujui
        transactionProvider.addLoanGrantTransaction(
          userId: user.uid,
          amount: loanAmount,
          tenureMonths: tenureMonths,
          description: 'Pengajuan pinjaman berhasil', // FIX 1: Tambahkan argumen 'description' yang hilang
          // Anda bisa menambahkan detail lain jika ada (misal: loanId, interestRate)
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pinjaman berhasil ditambahkan ke riwayat Anda.'),
            backgroundColor: Colors.blueAccent,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengguna tidak terautentikasi. Pinjaman tidak dapat ditambahkan ke riwayat.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Kasus jika loanAmount atau tenureMonths tidak valid
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jumlah atau jangka waktu pinjaman tidak valid. Pinjaman tidak dapat ditambahkan.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      // --- END: KODE YANG DITAMBAHKAN ---

      _amountController.clear();
      _tenureController.clear();

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return; // FIX 3: Tambahkan pengecekan 'mounted' sebelum menggunakan context
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pengajuan Pinjaman',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Isi detail pinjaman Anda',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Pinjaman',
                  hintText: 'Contoh: Rp 5.000.000',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Color(0xFF1A237E)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1A237E), width: 2.0),
                  ),
                ),
                validator: (value) {
                  String cleanValue = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanValue.isEmpty) {
                    return 'Jumlah pinjaman tidak boleh kosong';
                  }
                  if (double.tryParse(cleanValue) == null || double.parse(cleanValue) <= 0) {
                    return 'Masukkan angka positif yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tenureController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jangka Waktu',
                  hintText: 'Contoh: 12',
                  border: OutlineInputBorder(),
                  suffixText: ' bulan',
                  labelStyle: TextStyle(color: Color(0xFF1A237E)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1A237E), width: 2.0),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jangka waktu tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Masukkan angka bulat positif yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _applyLoan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Ajukan Pinjaman Sekarang',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Proses persetujuan biasanya membutuhkan 1-2 hari kerja.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}