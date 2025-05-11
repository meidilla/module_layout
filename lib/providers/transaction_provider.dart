// module_layout/lib/providers/transaction_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart' as cf;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:module_layout/models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  final cf.FirebaseFirestore _firestore = cf.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _currentUser;
  double _balance = 0.0;
  List<Transaction> _transactions = [];

  double get balance => _balance;
  List<Transaction> get transactions => _transactions;

  TransactionProvider() {
    _currentUser = _auth.currentUser;
    // PRINT DITAMBAHKAN DI SINI
    debugPrint('TransactionProvider initialized. Initial user: ${_currentUser?.uid}');
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      // PRINT DITAMBAHKAN DI SINI
      debugPrint('Auth state changed. New user: ${_currentUser?.uid}');
      if (user != null) {
        _listenToUserBalance();
        _listenToTransactions();
      } else {
        _balance = 0.0;
        _transactions = [];
        notifyListeners();
      }
    });
    if (_currentUser != null) {
      _listenToUserBalance();
      _listenToTransactions();
    }
  }

  void _listenToUserBalance() {
    if (_currentUser != null) {
      // PRINT DITAMBAHKAN DI SINI
      debugPrint('Listening to user balance for user: ${_currentUser!.uid}');
      _firestore.collection('users').doc(_currentUser!.uid).snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          _balance = (snapshot.data()!['balance'] as num?)?.toDouble() ?? 0.0;
          // PRINT DITAMBAHKAN DI SINI
          debugPrint('User balance updated: $_balance');
          notifyListeners();
        } else {
          // PRINT DITAMBAHKAN DI SINI
          debugPrint('User balance document not found, setting to 0.0');
          _firestore.collection('users').doc(_currentUser!.uid).set({'balance': 0.0}, cf.SetOptions(merge: true));
          _balance = 0.0;
          notifyListeners();
        }
      }, onError: (error) {
        debugPrint("Error listening to user balance: $error");
      });
    } else {
      debugPrint('Cannot listen to user balance: No user logged in.'); // PRINT DITAMBAHKAN
    }
  }

  void _listenToTransactions() {
    if (_currentUser != null) {
      // PRINT DITAMBAHKAN DI SINI
      debugPrint('Listening to transactions for user: ${_currentUser!.uid}');
      _firestore.collection('transactions')
          .where('userId', isEqualTo: _currentUser!.uid)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .listen((snapshot) {
        _transactions = snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
        // PRINT DITAMBAHKAN DI SINI
        debugPrint('Fetched ${_transactions.length} transactions.');
        notifyListeners();
      }, onError: (error) {
        debugPrint("Error listening to transactions: $error");
      });
    } else {
      debugPrint('Cannot listen to transactions: No user logged in.'); // PRINT DITAMBAHKAN
    }
  }

  Future<double> fetchUserBalanceOnce() async {
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    try {
      cf.DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        return userData['balance']?.toDouble() ?? 0.0;
      }
      return 0.0;
    } on cf.FirebaseException catch (e) {
      debugPrint('Firebase Error fetching user balance: ${e.message}');
      throw Exception('Failed to fetch user balance: ${e.message}');
    } catch (e) {
      debugPrint('General Error fetching user balance: $e');
      throw Exception('Failed to fetch user balance: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> updateUserBalance(String userId, double amount, {required bool isDebit}) async {
    cf.DocumentReference userDocRef = _firestore.collection('users').doc(userId);

    try {
      // PRINT DITAMBAHKAN DI SINI
      debugPrint('Updating balance for user $userId: amount $amount, isDebit $isDebit');
      await _firestore.runTransaction((transaction) async {
        cf.DocumentSnapshot userSnapshot = await transaction.get(userDocRef);

        if (!userSnapshot.exists || userSnapshot.data() == null) {
          // PRINT DITAMBAHKAN DI SINI
          debugPrint('User data not found for balance update ID: $userId');
          throw Exception('User data not found for ID: $userId');
        }

        double currentBalance = (userSnapshot.data() as Map<String, dynamic>)['balance']?.toDouble() ?? 0.0;
        double newBalance;

        if (isDebit) {
          newBalance = currentBalance - amount;
          if (newBalance < 0) {
            // PRINT DITAMBAHKAN DI SINI
            debugPrint('Insufficient balance for transaction. Current: $currentBalance, Debit: $amount');
            throw Exception('Insufficient balance to complete this transaction.');
          }
        } else {
          newBalance = currentBalance + amount;
        }
        // PRINT DITAMBAHKAN DI SINI
        debugPrint('Balance updated from $currentBalance to $newBalance');
        transaction.update(userDocRef, {'balance': newBalance});
      });
    } on cf.FirebaseException catch (e) {
      debugPrint('Firebase Error updating user balance: ${e.message}');
      throw Exception('Failed to update balance: ${e.message}');
    } catch (e) {
      debugPrint('General Error updating user balance: $e');
      throw Exception('Failed to update balance: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> addTransactionToFirestore({
    required String userId,
    required double amount,
    required String description,
    required TransactionType type,
    required String category,
    String? recipientAccount,
    String? senderAccount,
    int? tenureMonths,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      // PRINT DITAMBAHKAN DI SINI
      debugPrint('Attempted to add transaction, but user not logged in.');
      throw Exception('User not logged in. Cannot record transaction.');
    }

    try {
      // PRINT DITAMBAHKAN DI SINI
      debugPrint('Adding transaction to Firestore: userId=$userId, amount=$amount, type=${type.toString().split('.').last}, category=$category');
      final newTransaction = Transaction(
        id: '',
        userId: userId,
        type: type,
        category: TransactionCategory.values.firstWhere(
            (e) => e.toString().split('.').last == category,
            orElse: () => TransactionCategory.other),
        amount: amount,
        date: DateTime.now(),
        description: description,
        recipientAccount: recipientAccount,
        senderAccount: senderAccount,
        tenureMonths: tenureMonths,
      );

      await _firestore.collection('transactions').add(newTransaction.toMap());
      // PRINT DITAMBAHKAN DI SINI
      debugPrint('Transaction added successfully to Firestore.');
    } on cf.FirebaseException catch (e) {
      debugPrint('Firebase Error adding transaction: ${e.message}');
      throw Exception('Failed to record transaction: ${e.message}');
    } catch (e) {
      debugPrint('General Error adding transaction: $e');
      throw Exception('Failed to record transaction: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> addLoanGrantTransaction({
    required String userId,
    required double amount,
    required int tenureMonths,
    required String description,
  }) async {
    try {
      debugPrint('Attempting to add loan grant transaction...'); // PRINT DITAMBAHKAN
      await updateUserBalance(userId, amount, isDebit: false);

      await addTransactionToFirestore(
        userId: userId,
        amount: amount,
        description: description,
        type: TransactionType.loanGrant,
        category: TransactionCategory.loan.toString().split('.').last,
        tenureMonths: tenureMonths,
      );
      debugPrint('Loan grant transaction processed successfully.'); // PRINT DITAMBAHKAN
    } on cf.FirebaseException catch (e) {
      debugPrint('Firebase Error adding loan grant transaction: ${e.message}');
      throw Exception('Failed to process loan: ${e.message}');
    } catch (e) {
      debugPrint('General Error adding loan grant transaction: $e');
      throw Exception('Failed to process loan: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> addPaymentTransaction({
    required String userId,
    required double amount,
    required String paymentMethod,
    required String description,
  }) async {
    try {
      debugPrint('Attempting to add payment transaction...'); // PRINT DITAMBAHKAN
      await updateUserBalance(userId, amount, isDebit: true);

      await addTransactionToFirestore(
        userId: userId,
        amount: amount,
        description: description,
        type: TransactionType.debit,
        category: _mapPaymentMethodToTransactionCategory(paymentMethod),
      );
      debugPrint('Payment transaction processed successfully.'); // PRINT DITAMBAHKAN
    } on cf.FirebaseException catch (e) {
      debugPrint('Firebase Error adding payment transaction: ${e.message}');
      throw Exception('Failed to record payment: ${e.message}');
    } catch (e) {
      debugPrint('General Error adding payment transaction: $e');
      throw Exception('Failed to record payment: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  String _mapPaymentMethodToTransactionCategory(String paymentMethod) {
    switch (paymentMethod) {
      case 'virtual_account_bca':
      case 'qris':
      case 'credit_card':
      case 'e_wallet':
      case 'retail_outlet':
        return TransactionCategory.payment.toString().split('.').last;
      default:
        return TransactionCategory.other.toString().split('.').last;
    }
  }

  Future<void> addExpenseTransaction({
    required String userId,
    required double amount,
    required String description,
    required TransactionCategory category,
  }) async {
    try {
      debugPrint('Attempting to add expense transaction...'); // PRINT DITAMBAHKAN
      await updateUserBalance(userId, amount, isDebit: true);
      await addTransactionToFirestore(
        userId: userId,
        amount: amount,
        description: description,
        type: TransactionType.debit,
        category: category.toString().split('.').last,
      );
      debugPrint('Expense transaction processed successfully.'); // PRINT DITAMBAHKAN
    } on cf.FirebaseException catch (e) {
      debugPrint('Firebase Error adding expense transaction: ${e.message}');
      throw Exception('Failed to add expense: ${e.message}');
    } catch (e) {
      debugPrint('General Error adding expense transaction: $e');
      throw Exception('Failed to add expense: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  Future<void> addIncomeTransaction({
    required String userId,
    required double amount,
    required String description,
    required TransactionCategory category,
  }) async {
    try {
      debugPrint('Attempting to add income transaction...'); // PRINT DITAMBAHKAN
      await updateUserBalance(userId, amount, isDebit: false);
      await addTransactionToFirestore(
        userId: userId,
        amount: amount,
        description: description,
        type: TransactionType.credit,
        category: category.toString().split('.').last,
      );
      debugPrint('Income transaction processed successfully.'); // PRINT DITAMBAHKAN
    } on cf.FirebaseException catch (e) {
      debugPrint('Firebase Error adding income transaction: ${e.message}');
      throw Exception('Failed to add income: ${e.message}');
    } catch (e) {
      debugPrint('General Error adding income transaction: $e');
      throw Exception('Failed to add income: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }

  // ======================================================================
  // METODE BARU UNTUK TRANSFER (addTransferTransaction)
  // ======================================================================
  Future<void> addTransferTransaction({
    required String userId, // User yang melakukan transfer (sender)
    required double amount,
    required String description,
    required String recipientAccount, // Rekening penerima
  }) async {
    User? user = _auth.currentUser;
    if (user == null || user.uid != userId) {
      debugPrint('User not logged in or mismatched user ID during transfer attempt.'); // PRINT DITAMBAHKAN
      throw Exception('User not logged in or mismatched user ID. Cannot record transfer.');
    }

    try {
      debugPrint('Attempting to process transfer transaction...'); // PRINT DITAMBAHKAN
      // 1. Perbarui saldo pengirim (uang keluar = debit)
      await updateUserBalance(userId, amount, isDebit: true);

      // 2. Catat transaksi transfer untuk pengirim
      await addTransactionToFirestore(
        userId: userId,
        amount: amount,
        description: description,
        type: TransactionType.debit, // Untuk pengirim, ini adalah debit
        category: TransactionCategory.transfer.toString().split('.').last, // Gunakan kategori transfer
        recipientAccount: recipientAccount, // Simpan info rekening penerima
      );
      debugPrint('Transfer transaction processed successfully.'); // PRINT DITAMBAHKAN
      // Tidak perlu notifyListeners() di sini karena _listenToUserBalance dan _listenToTransactions
      // sudah menangani pembaruan saldo dan daftar transaksi secara otomatis.

    } on cf.FirebaseException catch (e) {
      debugPrint('Firebase Error adding transfer transaction: ${e.message}');
      // Pastikan untuk memunculkan kembali error agar bisa ditangkap di UI
      throw Exception('Failed to process transfer: ${e.message}');
    } catch (e) {
      debugPrint('General Error adding transfer transaction: $e');
      throw Exception('Failed to process transfer: ${e.toString().replaceFirst('Exception: ', '')}');
    }
  }
}