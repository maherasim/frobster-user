import 'package:flutter/material.dart';
import 'package:flutter_paypal_checkout/flutter_paypal_checkout.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../main.dart';
import '../model/payment_gateway_response.dart';

class PayPalService {
  static Future paypalCheckOut({
    required BuildContext context,
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map<String, dynamic>) onComplete,
  }) async {
    appStore.setLoading(true);
    String payPalClientId = '';
    String secretKey = '';
    if (paymentSetting.isTest.getBoolInt()) {
      payPalClientId = paymentSetting.testValue!.payPalClientId.validate();
      secretKey = paymentSetting.testValue!.payPalSecretKey.validate();
    } else {
      payPalClientId = paymentSetting.liveValue!.payPalClientId.validate();
      secretKey = paymentSetting.liveValue!.payPalSecretKey.validate();
    }
    if (payPalClientId.isEmpty || secretKey.isEmpty) {
      appStore.setLoading(false);
      throw language.accessDeniedContactYourAdmin;
    }

    // Format amount to ensure it has exactly 2 decimal places (required by PayPal)
    final formattedAmount = totalAmount.toStringAsFixed(2);
    final amountValue = num.tryParse(formattedAmount) ?? totalAmount;
    
    // Validate amount
    if (amountValue <= 0) {
      appStore.setLoading(false);
      throw 'Invalid payment amount';
    }
    
    // Validate currency code
    final currencyCode = appConfigurationStore.currencyCode.validate();
    if (currencyCode.isEmpty) {
      appStore.setLoading(false);
      throw 'Currency code is not configured';
    }

    PaypalCheckout(
      sandboxMode: paymentSetting.isTest.getBoolInt(),
      clientId: payPalClientId,
      secretKey: secretKey,
      returnURL: "junedr375.github.io/junedr375-payment/",
      cancelURL: "junedr375.github.io/junedr375-payment/error.html",
      transactions: [
        {
          "amount": {
            "total": formattedAmount,
            "currency": currencyCode,
            "details": {
              "subtotal": formattedAmount,
              "shipping": '0.00',
              "shipping_discount": '0.00'
            }
          },
          "description":
              'Name: ${appStore.userFullName} - Email: ${appStore.userEmail}',
        }
      ],
      note: " - ",
      onSuccess: (Map params) async {
        log("onSuccess: $params");
        appStore.setLoading(false);
        if (params['message'] is String) {
          toast(params['message']);
        }
        onComplete.call({
          'transaction_id': params['data']['id'],
        });
      },
      onError: (error) {
        log("onError: $error");
        appStore.setLoading(false);
        toast(error.toString());
        // Don't finish context here - let the calling screen handle it
      },
      onCancel: (params) {
        log("cancelled: $params");
        toast(language.cancelled);
        appStore.setLoading(false);
      },
    ).launch(context).catchError((e) {
      log("PayPal launch error: $e");
      appStore.setLoading(false);
      toast('Failed to launch PayPal: ${e.toString()}');
    }).whenComplete(() {
      appStore.setLoading(false);
    });
  }
}
