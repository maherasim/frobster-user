import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WalletPayPalWebViewScreen extends StatefulWidget {
  final String approvalUrl;
  final double amount;

  const WalletPayPalWebViewScreen({
    Key? key,
    required this.approvalUrl,
    required this.amount,
  }) : super(key: key);

  @override
  State<WalletPayPalWebViewScreen> createState() => _WalletPayPalWebViewScreenState();
}

class _WalletPayPalWebViewScreenState extends State<WalletPayPalWebViewScreen> {
  late WebViewController controller;
  bool isPaymentCompleted = false;
  bool showSuccessScreen = false;
  String? successMessage;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) => log('Wallet PayPal Started: $url'),
        onPageFinished: (url) => log('Wallet PayPal Finished: $url'),
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri != null) {
            final path = uri.path.toLowerCase();
            // Intercept before the WebView makes the request so the backend
            // is only called once — by Flutter's authenticated GET below.
            if (path.contains('wallet-paypal/success')) {
              _handleSuccess(request.url);
              return NavigationDecision.prevent;
            }
            if (path.contains('wallet-paypal/cancel')) {
              _handleCancel();
              return NavigationDecision.prevent;
            }
          }
          return NavigationDecision.navigate;
        },
      ));

    controller.loadRequest(Uri.parse(widget.approvalUrl)).catchError((e) {
      log('Error loading PayPal URL: $e');
      if (mounted) {
        toast('${language.lblErrorLoadingPayPal}: ${e.toString()}');
        finish(context, false);
      }
    });
  }

  Future<void> _handleSuccess(String url) async {
    if (isPaymentCompleted) return;
    isPaymentCompleted = true;

    setState(() {
      showSuccessScreen = true;
      successMessage = language.verifyingPayment;
    });

    try {
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];
      final amount = uri.queryParameters['amount'];

      if (token == null || token.isEmpty) {
        toast(language.lblPaymentVerificationMissingToken);
        finish(context, false);
        return;
      }

      appStore.setLoading(true);

      await Future.delayed(const Duration(milliseconds: 800));

      final endpoint = 'wallet-paypal/success?token=$token'
          '${amount != null ? '&amount=$amount' : ''}';

      final successResponse = await buildHttpResponse(endpoint, method: HttpMethodType.GET);
      final responseData = await handleResponse(successResponse);

      appStore.setLoading(false);

      if (responseData is Map && responseData['status'] == true) {
        final message = responseData['message'] as String? ?? language.paymentCompletedSuccessfully;
        setState(() => successMessage = message);

        await appStore.setUserWalletAmount();
        toast(language.yourWalletIsUpdated);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) finish(context, true);
        });
      } else {
        setState(() => showSuccessScreen = false);
        final errorMsg = responseData is Map
            ? (responseData['message'] as String? ?? language.paymentFailed)
            : language.paymentVerificationFailed;
        toast(errorMsg);
        finish(context, false);
      }
    } catch (e) {
      appStore.setLoading(false);
      log('Wallet PayPal verify error: $e');
      setState(() => showSuccessScreen = false);
      toast(language.errorProcessingPayment);
      finish(context, false);
    }
  }

  void _handleCancel() {
    if (isPaymentCompleted) return;
    isPaymentCompleted = true;
    toast(language.cancelled);
    finish(context, false);
  }

  Widget _buildSuccessScreen() {
    return Container(
      color: context.scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: successGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ),
            24.height,
            Text(language.successful, style: boldTextStyle(size: 24)),
            16.height,
            Text(
              successMessage ?? language.paymentCompletedSuccessfully,
              style: secondaryTextStyle(size: 16),
              textAlign: TextAlign.center,
            ).paddingSymmetric(horizontal: 32),
            32.height,
            Text(
              'Redirecting...',
              style: secondaryTextStyle(size: 12, color: textSecondaryColorGlobal),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PayPal Payment',
          style: boldTextStyle(color: Colors.white, size: APP_BAR_TEXT_SIZE),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: appPrimaryGradient),
        ),
        leading: BackWidget(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          if (showSuccessScreen)
            _buildSuccessScreen()
          else
            SizedBox(
              height: context.height(),
              width: context.width(),
              child: WebViewWidget(controller: controller),
            ),
          Observer(
            builder: (_) => LoaderWidget().visible(appStore.isLoading),
          ),
        ],
      ),
    );
  }
}
