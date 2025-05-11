import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// Custom Formatter untuk format mata uang (menambahkan titik ribuan)
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Jika input baru kosong atau kursor berada di awal, biarkan seperti adanya
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    // Hapus semua karakter non-digit (termasuk titik yang sudah ada)
    String newText = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Jika setelah difilter, string kosong, kembalikan kosong
    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Coba parse menjadi double. Jika gagal, kembalikan nilai lama
    // Ini mencegah aplikasi crash jika input tidak valid
    if (double.tryParse(newText) == null) {
      return oldValue;
    }

    // Buat formatter mata uang untuk menampilkan titik ribuan
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '', // Tidak menampilkan simbol mata uang di dalam input field
      decimalDigits: 0, // Tidak menampilkan desimal
    );

    // Format angka menjadi string dengan titik
    String formattedText = formatter.format(double.parse(newText));

    // Sesuaikan posisi kursor setelah format
    int selectionOffset = newValue.selection.end;
    int numCommasOld =
        (oldValue.text.length - oldValue.text.replaceAll('.', '').length);
    int numCommasNew =
        (formattedText.length - formattedText.replaceAll('.', '').length);

    int newOffset = selectionOffset + (numCommasNew - numCommasOld);

    if (newOffset < 0) newOffset = 0;
    if (newOffset > formattedText.length) newOffset = formattedText.length;

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}