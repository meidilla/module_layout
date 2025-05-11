import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:provider/provider.dart'; // Tambahan
import '../providers/transaction_provider.dart'; // Pastikan path ini benar
import 'package:firebase_auth/firebase_auth.dart'; // Tambahan

// BARIS BERIKUT INI TELAH DIHAPUS UNTUK MENGHILANGKAN WARNING "unused_import":
// import 'package:module_layout/models/transaction.dart'; // Diperlukan untuk TransactionCategory

// ======================================================================
// CurrencyInputFormatter (Re-use from previous code)
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
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }
    if (double.tryParse(newText) == null) {
      return oldValue;
    }

    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
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
// PaymentPage (Complex Real-like Flow)
// ======================================================================
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key}); // <<< PERBAIKAN use_super_parameters

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _amountController = TextEditingController();
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  );

  String? _selectedPaymentMethod; // e.g., 'virtual_account_bca', 'qris', 'credit_card'
  bool _isLoadingPayment = false;
  Map<String, dynamic>? _paymentInstructions; // Details from simulated backend

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
          backgroundColor: isError ? Colors.red[700] : Colors.green[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ======================================================================
  // SIMULASI KOMUNIKASI DENGAN BACKEND UNTUK MEMBUAT TRANSAKSI
  // ======================================================================
  Future<void> _createPaymentTransaction() async {
    setState(() {
      _isLoadingPayment = true;
      _paymentInstructions = null; // Clear previous instructions
    });

    final String cleanedAmountText = _amountController.text.replaceAll('.', '');
    final double? amount = double.tryParse(cleanedAmountText);

    if (amount == null || amount <= 0 || _selectedPaymentMethod == null) {
      _showSnackBar('Harap masukkan jumlah dan pilih metode pembayaran yang valid.', isError: true);
      setState(() {
        _isLoadingPayment = false;
      });
      return;
    }

    // --- SIMULASI PANGGILAN API KE BACKEND (Di dunia nyata, Anda akan menggunakan http.post) ---
    // URL BACKEND ANDA: 'https://your-backend-server.com/api/create-payment'
    // Contoh payload yang akan dikirim ke backend:
    // Map<String, dynamic> requestBody = {
    //   'amount': amount,
    //   'paymentMethod': _selectedPaymentMethod,
    //   'userId': 'user123' // Ambil dari Firebase Auth atau session Anda
    // };

    // Simulasi respons dari backend (yang seharusnya dari Payment Gateway)
    await Future.delayed(const Duration(seconds: 2)); // Simulasi latency jaringan

    Map<String, dynamic> simulatedBackendResponse;

    if (_selectedPaymentMethod == 'virtual_account_bca') {
      simulatedBackendResponse = {
        'success': true,
        'transactionId': 'TRX${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending',
        'paymentDetails': {
          'method': 'Virtual Account BCA',
          'bankName': 'BCA',
          // <<< PERBAIKAN prefer_interpolation_to_compose_strings
          'accountNumber': '80777${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}',
          'amount': amount,
          'expiryTime': DateFormat('dd MMMM, HH:mm').format(DateTime.now().add(const Duration(hours: 2))),
          'instructions': [
            '1. Masuk ke aplikasi BCA Mobile / Internet Banking.',
            '2. Pilih "Transfer" -> "Virtual Account".',
            '3. Masukkan Nomor Virtual Account di atas.',
            '4. Ikuti instruksi pembayaran hingga selesai.'
          ],
        }
      };
    } else if (_selectedPaymentMethod == 'qris') {
      simulatedBackendResponse = {
        'success': true,
        'transactionId': 'QRIS${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending',
        'paymentDetails': {
          'method': 'QRIS',
          // <<< PERBAIKAN prefer_interpolation_to_compose_strings
          'qrisImageUrl': 'https://via.placeholder.com/250?text=QRIS+${currencyFormatter.format(amount).replaceAll('Rp. ', '').replaceAll('.', '')}',
          'amount': amount,
          'expiryTime': DateFormat('dd MMMM, HH:mm').format(DateTime.now().add(const Duration(minutes: 15))),
          'instructions': [
            '1. Buka aplikasi E-Wallet (GoPay, OVO, Dana, LinkAja) atau Mobile Banking yang mendukung QRIS.',
            '2. Pilih menu "Scan QR" atau "QRIS".',
            '3. Pindai kode QR di atas.',
            '4. Pastikan jumlah dan detail pembayaran sudah benar, lalu konfirmasi.'
          ],
        }
      };
    } else if (_selectedPaymentMethod == 'credit_card') {
      simulatedBackendResponse = {
        'success': true,
        'transactionId': 'CC${DateTime.now().millisecondsSinceEpoch}',
        'status': 'pending', // Dalam skenario riil, ini bisa langsung "successful" atau "3ds_required"
        'paymentDetails': {
          'method': 'Kartu Kredit / Debit',
          'amount': amount,
          'message': 'Anda akan dialihkan ke halaman secure payment gateway untuk memasukkan detail kartu Anda.',
          // Di sini, PG akan memberikan URL redirect atau token untuk form kartu kredit.
          'redirectUrl': 'https://secure.paymentgateway.com/pay?token=xyz123' // Contoh redirect URL
        }
      };
    } else {
      simulatedBackendResponse = {
        'success': false,
        'message': 'Metode pembayaran tidak didukung.',
      };
    }

    // Proses respons dari backend
    if (simulatedBackendResponse['success']) {
      setState(() {
        _paymentInstructions = simulatedBackendResponse['paymentDetails'];
      });
      _showSnackBar('Instruksi pembayaran berhasil dibuat. Silakan selesaikan pembayaran.');

      // --- START: KODE UNTUK MEREKAM TRANSAKSI ---
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (!mounted) return;
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        final double actualAmount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0.0;

        // Tambahkan transaksi pembayaran ke provider
        await transactionProvider.addPaymentTransaction(
          userId: user.uid, // ID pengguna yang melakukan pembayaran
          amount: actualAmount,
          paymentMethod: _selectedPaymentMethod ?? 'Unknown',
          description: 'Pembayaran via ${_selectedPaymentMethod?.replaceAll('_', ' ').toUpperCase() ?? 'Unknown'}',
          // Anda bisa menambahkan detail lain jika ada (misalnya ID transaksi dari simulasi backend)
          // transactionId: simulatedBackendResponse['transactionId'],
        );
        _showSnackBar('Transaksi pembayaran berhasil ditambahkan ke riwayat Anda.', isError: false); // Notifikasi tambahan
      } else {
        _showSnackBar('Pengguna tidak terautentikasi. Transaksi tidak dapat ditambahkan ke riwayat.', isError: true);
      }
      // --- END: KODE UNTUK MEREKAM TRANSAKSI ---

    } else {
      _showSnackBar(simulatedBackendResponse['message'] ?? 'Gagal membuat transaksi pembayaran.', isError: true);
    }

    setState(() {
      _isLoadingPayment = false;
    });
  }

  // Widget untuk menampilkan detail instruksi pembayaran
  Widget _buildPaymentInstructions() {
    if (_paymentInstructions == null) {
      return const SizedBox.shrink(); // Tidak menampilkan apa-apa jika belum ada instruksi
    }

    String method = _paymentInstructions!['method'] ?? 'Metode Pembayaran';
    double amount = _paymentInstructions!['amount'] ?? 0.0;
    String expiryTime = _paymentInstructions!['expiryTime'] ?? 'N/A';
    List<String> instructions = List<String>.from(_paymentInstructions!['instructions'] ?? []);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instruksi Pembayaran ($method)',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            const Divider(height: 25, thickness: 1),
            _buildInfoRow('Jumlah Pembayaran:', currencyFormatter.format(amount), isCopyable: true),
            _buildInfoRow('Batas Waktu:', expiryTime),
            const SizedBox(height: 15),

            if (method == 'Virtual Account BCA') ...[
              _buildInfoRow('Nomor Virtual Account:', _paymentInstructions!['accountNumber'] ?? 'N/A', isCopyable: true),
              const SizedBox(height: 15),
              Text(
                'Cara Pembayaran:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              // <<< PERBAIKAN unnecessary_to_list_in_spreads
              ...instructions.asMap().entries.map((entry) {
                int idx = entry.key;
                String val = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('${idx + 1}. $val', style: const TextStyle(fontSize: 15)),
                );
              }),
            ] else if (method == 'QRIS') ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: _paymentInstructions!['qrisImageUrl'] != null
                      ? Image.network(
                          _paymentInstructions!['qrisImageUrl'],
                          width: 220,
                          height: 220,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 150, color: Colors.redAccent),
                        )
                      : const Text('URL QRIS tidak tersedia. Silakan hubungi dukungan.'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cara Pembayaran:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              ),
              const SizedBox(height: 8),
              // <<< PERBAIKAN unnecessary_to_list_in_spreads
              ...instructions.asMap().entries.map((entry) {
                int idx = entry.key;
                String val = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text('${idx + 1}. $val', style: const TextStyle(fontSize: 15)),
                );
              }),
            ] else if (method == 'Kartu Kredit / Debit') ...[
              const SizedBox(height: 15),
              Text(
                _paymentInstructions!['message'] ?? 'Silakan ikuti instruksi untuk menyelesaikan pembayaran.',
                style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic),
              ),
              if (_paymentInstructions!['redirectUrl'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Di sini Anda akan membuka URL redirect di browser atau WebView
                      // Contoh: launchUrl(Uri.parse(_paymentInstructions!['redirectUrl']));
                      _showSnackBar('Simulasi redirect ke Payment Gateway: ${_paymentInstructions!['redirectUrl']}');
                    },
                    icon: const Icon(Icons.launch),
                    label: const Text('Lanjutkan ke Pembayaran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Status pembayaran akan otomatis terupdate di riwayat transaksi Anda setelah pembayaran terverifikasi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pembantu untuk baris informasi yang dapat disalin
  Widget _buildInfoRow(String label, String value, {bool isCopyable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF424242)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF212121)),
                  ),
                ),
                if (isCopyable)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: Colors.grey),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      _showSnackBar('Disalin!');
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pembayaran Kompleks',
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
            const Icon(Icons.payment, size: 80, color: Color(0xFF1A237E)),
            const SizedBox(height: 24),
            const Text(
              'Pilih metode pembayaran dan masukkan jumlah.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // --- Input Jumlah Pembayaran ---
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Jumlah Pembayaran',
                hintText: 'Contoh: 75.000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.monetization_on, color: Color(0xFF1A237E)),
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
              ),
              style: const TextStyle(fontSize: 18),
              onChanged: (text) {
                setState(() {
                  // Memaksa rebuild untuk mengaktifkan/menonaktifkan tombol
                  _paymentInstructions = null; // Reset instruksi saat jumlah berubah
                });
              },
            ),
            const SizedBox(height: 24),

            // --- Pilihan Metode Pembayaran ---
            const Text(
              'Pilih Metode Pembayaran:',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 10),

            _buildPaymentMethodCard('Virtual Account (BCA)', 'virtual_account_bca', 'assets/bca_logo.png'),
            _buildPaymentMethodCard('QRIS (Semua E-Wallet)', 'qris', 'assets/qris_logo.png'),
            _buildPaymentMethodCard('Kartu Kredit / Debit', 'credit_card', 'assets/visa_mastercard_logo.png'),
            _buildPaymentMethodCard('E-Wallet (GoPay, OVO, Dana)', 'e_wallet', 'assets/gopay_ovo_dana_logo.png', isEnabled: false),
            _buildPaymentMethodCard('Gerai Retail (Indomaret/Alfamart)', 'retail_outlet', 'assets/retail_logo.png', isEnabled: false),

            const SizedBox(height: 24),

            // --- Tombol untuk Memproses Pembayaran ---
            _isLoadingPayment
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _amountController.text.isNotEmpty && _selectedPaymentMethod != null
                        ? _createPaymentTransaction
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Proses Pembayaran',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),

            // --- Tampilan Instruksi Pembayaran ---
            _buildPaymentInstructions(),

            // Optional: Tombol untuk kembali setelah pembayaran (jika ingin direset atau kembali ke halaman utama)
            if (_paymentInstructions != null)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _amountController.clear();
                      _selectedPaymentMethod = null;
                      _paymentInstructions = null;
                    });
                    // Navigator.pop(context); // Atau kembali ke halaman utama
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[400],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Mulai Pembayaran Baru',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget pembantu untuk setiap kartu metode pembayaran
  Widget _buildPaymentMethodCard(String title, String value, String imagePath, {bool isEnabled = true}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: _selectedPaymentMethod == value
            ? const BorderSide(color: Color(0xFF1A237E), width: 2) // Border untuk yang dipilih
            : BorderSide.none,
      ),
      elevation: _selectedPaymentMethod == value ? 3 : 1, // Elevasi lebih tinggi untuk yang dipilih
      child: InkWell( // Menggunakan InkWell agar seluruh area kartu bisa diklik
        onTap: isEnabled
            ? () {
                setState(() {
                  _selectedPaymentMethod = value;
                  _paymentInstructions = null; // Reset instruksi saat metode berubah
                });
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              // Pastikan Anda memiliki gambar-gambar ini di folder 'assets/' Anda
              Image.asset(imagePath, height: 30, width: 30, fit: BoxFit.contain,
                color: isEnabled ? null : Colors.grey.withAlpha((0.7 * 255).round()),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isEnabled ? Colors.black87 : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: _selectedPaymentMethod,
                onChanged: isEnabled
                    ? (val) {
                        setState(() {
                          _selectedPaymentMethod = val;
                          _paymentInstructions = null;
                        });
                      }
                    : null,
                activeColor: const Color(0xFF1A237E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}