import 'dart:convert';

import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../main.dart';
import '../model/payment_gateway_response.dart';
import '../model/stripe_pay_model.dart';
import '../network/network_utils.dart';
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/configs.dart';

class StripeServiceNew {
  late PaymentSetting paymentSetting;
  num totalAmount = 0;
  late Function(Map<String, dynamic>) onComplete;

  StripeServiceNew({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map<String, dynamic>) onComplete,
  }) {
    this.paymentSetting = paymentSetting;
    this.totalAmount = totalAmount;
    this.onComplete = onComplete;
  }

  //StripPayment
  Future<dynamic> stripePay() async {
    String stripePaymentKey = '';
    String stripeURL = 'https://api.stripe.com/v1/payment_intents';
    String stripePaymentPublishKey = '';

    bool isValidUrl(String value) {
      try {
        final uri = Uri.tryParse(value);
        return uri != null && uri.hasScheme && uri.host.isNotEmpty;
      } catch (e) {
        return false;
      }
    }

    if (paymentSetting.isTest == 1) {
      stripePaymentKey = paymentSetting.testValue!.stripeKey.validate();
      stripePaymentPublishKey =
          paymentSetting.testValue!.stripePublickey.validate();
      final candidate = paymentSetting.testValue!.stripeUrl.validate();
      if (candidate.isNotEmpty && isValidUrl(candidate)) stripeURL = candidate;
    } else {
      stripePaymentKey = paymentSetting.liveValue!.stripeKey.validate();
      stripePaymentPublishKey =
          paymentSetting.liveValue!.stripePublickey.validate();
      final candidate = paymentSetting.liveValue!.stripeUrl.validate();
      if (candidate.isNotEmpty && isValidUrl(candidate)) stripeURL = candidate;
    }
    if (stripePaymentKey.isEmpty ||
        stripeURL.isEmpty ||
        stripePaymentPublishKey.isEmpty)
      throw language.accessDeniedContactYourAdmin;

    // Basic sanity checks to avoid misconfigured keys from API
    if (!stripePaymentKey.startsWith('sk_') ||
        !stripePaymentPublishKey.startsWith('pk_')) {
      throw language.accessDeniedContactYourAdmin;
    }

    Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
    Stripe.publishableKey = stripePaymentPublishKey;

    Stripe.instance.applySettings().catchError((e) {
      toast(e.toString(), print: true);

      throw e.toString();
    });

    Request request =
        http.Request(HttpMethodType.POST.name, Uri.parse(stripeURL));

    request.bodyFields = {
      'amount': '${(totalAmount * 100).toInt()}',
      'currency': '${appConfigurationStore.currencyCode}',
      'description':
          'Name: ${appStore.userFullName} - Email: ${appStore.userEmail}',
    };

    request.headers.addAll(buildHeaderForStripe(stripePaymentKey));

    log('URL: ${request.url}');
    log('Request: ${request.bodyFields}');

    appStore.setLoading(true);
    await request.send().then((value) {
      http.Response.fromStream(value).then((response) async {
        if (response.statusCode.isSuccessful()) {
          StripePayModel res =
              StripePayModel.fromJson(jsonDecode(response.body));

          SetupPaymentSheetParameters setupPaymentSheetParameters =
              SetupPaymentSheetParameters(
            paymentIntentClientSecret: res.clientSecret.validate(),
            style: appThemeMode,
            appearance: PaymentSheetAppearance(
                colors: PaymentSheetAppearanceColors(primary: primaryColor)),
            applePay: PaymentSheetApplePay(
                merchantCountryCode: STRIPE_MERCHANT_COUNTRY_CODE),
            googlePay: PaymentSheetGooglePay(
                merchantCountryCode: STRIPE_MERCHANT_COUNTRY_CODE,
                testEnv: paymentSetting.isTest == 1),
            merchantDisplayName: APP_NAME,
            customerId: appStore.userId.toString(),
            // customerEphemeralKeySecret: isAndroid ? res.id.validate() : null,
            setupIntentClientSecret: res.clientSecret.validate(),
            billingDetails: BillingDetails(
                name: appStore.userFullName, email: appStore.userEmail),
          );

          await Stripe.instance
              .initPaymentSheet(
                  paymentSheetParameters: setupPaymentSheetParameters)
              .then((value) async {
            try {
              await Stripe.instance.presentPaymentSheet();
              onComplete.call({
                'transaction_id': res.id,
              });
              appStore.setLoading(false);
            } on StripeException catch (e) {
              // User closed sheet or Stripe error
              appStore.setLoading(false);
              if (e.error.message.validate().isNotEmpty) {
                toast(e.error.message.validate(), print: true);
              }
              throw e;
            } catch (e) {
              appStore.setLoading(false);
              throw errorSomethingWentWrong;
            }
          }).catchError((e) {
            appStore.setLoading(false);
            throw errorSomethingWentWrong;
          });
        } else if (response.statusCode == 400) {
          appStore.setLoading(false);
          throw errorSomethingWentWrong;
        } else {
          // Any other non-2xx status
          appStore.setLoading(false);
          try {
            final body = jsonDecode(response.body);
            throw body['message'] ?? errorSomethingWentWrong;
          } catch (_) {
            throw errorSomethingWentWrong;
          }
        }
      }).catchError((e) {
        appStore.setLoading(false);
        throw errorSomethingWentWrong;
      });
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);

      throw e.toString();
    });
  }
}
