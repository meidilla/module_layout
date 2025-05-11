// module_layout/lib/transfer_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk TextInputFormatter
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Untuk format angka

// Removed unused imports as they are not directly used in this file:
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
// import '../models/transaction.dart'; // Removed: TransactionType is no longer directly used here in the call

import '../providers/transaction_provider.dart';

// Custom TextInputFormatter untuk memformat angka dengan pemisah ribuan
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Jika teks baru kosong, kembalikan nilai kosong
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Hapus semua karakter non-digit dari teks baru (misal: "Rp 1.234.567" menjadi "1234567")
    String cleanedText = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Tangani nol di awal: jika "0123", jadikan "123"
    if (cleanedText.startsWith('0') && cleanedText.length > 1) {
      cleanedText = cleanedText.substring(1);
    }
    // Jika setelah dibersihkan teks kosong, kembalikan nilai kosong
    if (cleanedText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse ke double
    double value;
    try {
      value = double.parse(cleanedText);
    } catch (e) {
      // Jika gagal parse (misalnya, karakter tidak valid masih ada), kembalikan nilai lama
      return oldValue;
    }

    // Format angka sebagai mata uang tanpa simbol (hanya pemisah ribuan)
    final formatter = NumberFormat.currency(
      locale: 'id_ID',    // Menggunakan locale Indonesia untuk format titik sebagai pemisah ribuan
      symbol: '',         // Tidak menampilkan simbol mata uang di dalam TextField
      decimalDigits: 0,   // Tidak menampilkan angka desimal
    );

    String newText = formatter.format(value);

    // Mengatur posisi kursor setelah format
    // Logika ini mencoba mempertahankan posisi kursor relatif terhadap angka yang diketik,
    // meskipun karakter pemisah (titik) ditambahkan.
    int selectionIndex = newValue.selection.end;
    String oldCleanedText = oldValue.text.replaceAll(RegExp(r'\D'), '');

    int dotsAdded = newText.length - cleanedText.length;
    int oldDotsAdded = oldValue.text.length - oldCleanedText.length;

    int newSelectionOffset = selectionIndex + (dotsAdded - oldDotsAdded);

    // Pastikan offset kursor tidak melebihi panjang teks baru dan tidak kurang dari 0
    if (newSelectionOffset > newText.length) {
      newSelectionOffset = newText.length;
    }
    if (newSelectionOffset < 0) {
      newSelectionOffset = 0;
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionOffset),
    );
  }
}

class TransferPage extends StatefulWidget {
  final String currentUserId;

  const TransferPage({super.key, required this.currentUserId});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final TextEditingController _recipientAccountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _recipientAccountController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _performTransfer() async {
    final String recipientAccount = _recipientAccountController.text.trim();
    final String cleanedAmountText = _amountController.text.replaceAll(RegExp(r'\D'), '');
    final double? amount = double.tryParse(cleanedAmountText);
    final String description = _descriptionController.text.trim();

    if (recipientAccount.isEmpty) {
      // Add mounted check before using context
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor rekening penerima tidak boleh kosong.')),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      // Add mounted check before using context
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah transfer tidak valid.')),
      );
      return;
    }

    try {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

      String transactionDescription = 'Transfer ke rekening $recipientAccount';
      if (description.isNotEmpty) {
        transactionDescription += ': $description';
      }

      await transactionProvider.addTransferTransaction(
        userId: widget.currentUserId,
        amount: amount,
        description: transactionDescription,
        recipientAccount: recipientAccount,
      );

      // Add mounted check after await before using context
      if (!mounted) return;

      final NumberFormat displayFormatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      final String formattedAmountForDisplay = displayFormatter.format(amount);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transfer berhasil! Jumlah: $formattedAmountForDisplay')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error performing transfer: $e');
      String errorMessage = 'Gagal melakukan transfer. Silakan coba lagi.';
      if (e is Exception) {
        errorMessage = 'Gagal melakukan transfer: ${e.toString().replaceFirst('Exception: ', '')}';
      }
      // Add mounted check before using context
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Dana'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _recipientAccountController,
              decoration: const InputDecoration(
                labelText: 'Nomor Rekening Penerima',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah Transfer',
                border: OutlineInputBorder(),
                prefixText: 'Rp ',
                prefixIcon: Icon(Icons.money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                CurrencyInputFormatter(),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _performTransfer, // This correctly links the button to the function
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Lakukan Transfer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}