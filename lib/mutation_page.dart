import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// IMPORT PENTING: Ini adalah import relatif.
// Jika file 'mutation_page.dart' Anda ada di folder 'lib',
// dan folder 'providers' serta 'models' juga ada langsung di folder 'lib',
// maka path ini sudah benar.
import 'providers/transaction_provider.dart';
import 'models/transaction.dart';

class MutationPage extends StatelessWidget {
  const MutationPage({super.key});

  String _formatAmount(double amount, TransactionType type) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    String formatted = formatter.format(amount);
    return type == TransactionType.credit ? '+ $formatted' : '- $formatted';
  }

  Color _getTypeColor(TransactionType type) {
    return type == TransactionType.credit ? Colors.green.shade700 : Colors.red.shade700;
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.transfer:
        return Icons.send_rounded;
      case TransactionCategory.deposit:
        return Icons.account_balance_wallet_rounded;
      case TransactionCategory.loan:
        return Icons.request_quote_rounded;
      case TransactionCategory.payment:
        return Icons.receipt_long_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getCategoryName(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.transfer:
        return 'Transfer';
      case TransactionCategory.deposit:
        return 'Deposit';
      case TransactionCategory.loan:
        return 'Peminjaman';
      case TransactionCategory.payment:
        return 'Pembayaran';
      default:
        return 'Lain-lain';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mutasi Transaksi',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          // Penanganan null safety: Pastikan transactionProvider tidak null
          // dan list transactions tidak null sebelum diakses.
          if (transactionProvider == null || transactionProvider.transactions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada mutasi transaksi.',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lakukan transaksi untuk melihat riwayat di sini.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: transactionProvider.transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactionProvider.transactions[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 22,
                    backgroundColor: _getTypeColor(transaction.type).withOpacity(0.15),
                    child: Icon(
                      _getCategoryIcon(transaction.category),
                      size: 26,
                      color: _getTypeColor(transaction.type),
                    ),
                  ),
                  title: Text(
                    _getCategoryName(transaction.category),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM BCE, HH:mm').format(transaction.date),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  trailing: Text(
                    _formatAmount(transaction.amount, transaction.type),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _getTypeColor(transaction.type),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                ),
              );
            },
          );
        },
      ),
    );
  }
}