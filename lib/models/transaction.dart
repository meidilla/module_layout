import 'package:cloud_firestore/cloud_firestore.dart'; // Diperlukan untuk DocumentSnapshot

// Enum untuk Tipe Transaksi (Debit/Credit/LoanGrant)
// module_layout/lib/models/transaction.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum untuk Tipe Transaksi (Debit/Credit/LoanGrant)
enum TransactionType {
  debit,
  credit,
  loanGrant,
  loanRepayment,
  // Anda bisa menambahkan tipe lain jika diperlukan, misal: deposit, withdrawal
}

// Enum untuk Kategori Transaksi
enum TransactionCategory {
  food,
  transportation,
  housing,
  utilities,
  entertainment,
  health,
  education,
  salary,
  investment,
  loan,
  payment,
  deposit,
  transfer, // <--- TAMBAHKAN BARIS INI
  other,
}

class Transaction {
  final String id;
  final String userId;
  final TransactionType type;
  final TransactionCategory category;
  final double amount;
  final DateTime date;
  final String description;
  final String? recipientAccount;
  final String? senderAccount;
  final int? tenureMonths;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    this.recipientAccount,
    this.senderAccount,
    this.tenureMonths,
    this.createdAt,
    this.updatedAt,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Transaction(
      id: doc.id,
      userId: data['userId'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'] as String,
        orElse: () => TransactionType.debit,
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'] as String,
        orElse: () => TransactionCategory.other,
      ),
      amount: (data['amount'] as num).toDouble(),
      date: (data['timestamp'] as Timestamp).toDate(),
      description: data['description'] as String,
      recipientAccount: data['recipientAccount'] as String?,
      senderAccount: data['senderAccount'] as String?,
      tenureMonths: data['tenureMonths'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
      'description': description,
      'recipientAccount': recipientAccount,
      'senderAccount': senderAccount,
      'tenureMonths': tenureMonths,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    final Map<String, dynamic> map = {
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (description.isNotEmpty) map['description'] = description;
    if (recipientAccount != null) map['recipientAccount'] = recipientAccount;
    if (senderAccount != null) map['senderAccount'] = senderAccount;
    if (tenureMonths != null) map['tenureMonths'] = tenureMonths;
    return map;
  }
}