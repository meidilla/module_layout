import 'package:flutter/material.dart';

class BalanceModel extends ChangeNotifier {
  double _balance = 1000000;  // Nilai saldo awal

  double get balance => _balance;

  void updateBalance(double amount) {
    _balance += amount;
    notifyListeners();  // Memberitahu widget untuk memperbarui state
  }
}
