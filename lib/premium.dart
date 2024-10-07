import 'package:flutter/material.dart';
import 'package:pay/pay.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pay Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PaymentScreen(),
    );
  }
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final Future<PaymentConfiguration> _googlePayConfigFuture;

  @override
  void initState() {
    super.initState();
    _googlePayConfigFuture =
        PaymentConfiguration.fromAsset('gpay_payment_profile.json');
  }

  void _onGooglePayResult(paymentResult) {
    debugPrint('Google Pay Payment Result: $paymentResult');
    // Handle the payment result
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Pay Example'),
      ),
      body: Center(
        child: FutureBuilder<PaymentConfiguration>(
          future: _googlePayConfigFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return GooglePayButton(
                paymentConfiguration: snapshot.data!,
                paymentItems: const [
                  PaymentItem(
                    label: 'Total',
                    amount: '50.00',
                    status: PaymentItemStatus.final_price,
                  ),
                ],
                type: GooglePayButtonType.pay,
                onPaymentResult: _onGooglePayResult,
                loadingIndicator: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
