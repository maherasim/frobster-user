import 'dart:convert';
import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

class BookingPayPalWebViewScreen extends StatefulWidget {
  final String approvalUrl;
  final num bookingId;
  final String paymentType; // 'advance' or 'remaining'

  const BookingPayPalWebViewScreen({
    Key? key,
    required this.approvalUrl,
    required this.bookingId,
    required this.paymentType,
  }) : super(key: key);

  @override
  State<BookingPayPalWebViewScreen> createState() => _BookingPayPalWebViewScreenState();
}

class _BookingPayPalWebViewScreenState extends State<BookingPayPalWebViewScreen> {
  late WebViewController controller;
  bool isPaymentCompleted = false;
  bool showSuccessScreen = false;
  String? successMessage;
  Map<String, dynamic>? paymentData;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(NavigationDelegate(
      onPageStarted: (url) {
        log('PayPal Page Started: $url');
      },
      onPageFinished: (url) async {
        log('PayPal Page Finished: $url');
        
        // Check if this is the success or cancel redirect URL
        final uri = Uri.tryParse(url);
        if (uri != null) {
          final path = uri.path.toLowerCase();
          
          // Check for success URL pattern (booking-paypal/success)
          if (path.contains('booking-paypal/success') || 
              path.contains('/booking-paypal/success/') ||
              path.contains('booking-paypal-success') ||
              path.contains('/booking-paypal-success/')) {
            // The backend handles payment capture automatically
            // We need to check the response to see if it was successful
            await _checkPaymentStatus(url);
          }
          
          // Check if this is the cancel redirect URL (booking-paypal/cancel)
          if (path.contains('booking-paypal/cancel') || 
              path.contains('/booking-paypal/cancel') ||
              path.contains('booking-paypal-cancel') ||
              path.contains('/booking-paypal-cancel')) {
            _handlePayPalCancel();
          }
        }
      },
      onProgress: (progress) {
        // Update progress if needed
      },
      onNavigationRequest: (request) {
        final url = request.url;
        log('PayPal Navigation: $url');

        // Allow navigation to success/cancel URLs so backend can process them
        final uri = Uri.tryParse(url);
        if (uri != null) {
          final path = uri.path.toLowerCase();
          
          // Don't prevent navigation to success URL - let backend handle it (booking-paypal/success)
          if (path.contains('booking-paypal/success') || 
              path.contains('/booking-paypal/success/') ||
              path.contains('booking-paypal-success') ||
              path.contains('/booking-paypal-success/')) {
            return NavigationDecision.navigate;
          }
          
          // Prevent navigation to cancel URL and handle it (booking-paypal/cancel)
          if (path.contains('booking-paypal/cancel') || 
              path.contains('/booking-paypal/cancel') ||
              path.contains('booking-paypal-cancel') ||
              path.contains('/booking-paypal-cancel')) {
            _handlePayPalCancel();
            return NavigationDecision.prevent;
          }
        }

        return NavigationDecision.navigate;
      },
    ));
    
    // Load the URL
    log('Loading PayPal URL: ${widget.approvalUrl}');
    try {
      await controller.loadRequest(Uri.parse(widget.approvalUrl));
      
      // Update state to show webview
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      log('Error loading PayPal URL: $e');
      if (mounted) {
        toast('${language.paypalErrorLoadingPage}: ${e.toString()}');
        finish(context, false);
      }
    }
  }
  
  Future<void> _checkPaymentStatus(String url) async {
    if (isPaymentCompleted) return;
    isPaymentCompleted = true; // Prevent multiple calls
    
    try {
      // Parse the URL to extract parameters
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];
      final payerId = uri.queryParameters['PayerID'];
      
      if (token == null || token.isEmpty) {
        toast(language.paymentVerificationMissingToken);
        finish(context, false);
        return;
      }
      
      appStore.setLoading(true);
      
      // Hide webview immediately to prevent showing raw JSON
      setState(() {
        showSuccessScreen = true;
        successMessage = language.verifyingPayment;
      });
      
      // Wait a moment for the backend to process the payment
      await Future.delayed(Duration(milliseconds: 1000));
      
      // Make direct API call to verify payment status
      try {
        final endpoint = 'booking-paypal/success/${widget.bookingId}?token=$token${payerId != null ? '&PayerID=$payerId' : ''}';
        
        final successResponse = await buildHttpResponse(
          endpoint,
          method: HttpMethodType.GET,
        );
        
        final responseData = await handleResponse(successResponse);
        
        appStore.setLoading(false);
        
        if (responseData is Map && responseData['status'] == true) {
          final message = responseData['message'] as String? ?? language.paymentCompletedSuccessfully;
          paymentData = responseData['data'] as Map<String, dynamic>?;
          
          // Update success screen with actual message
          setState(() {
            showSuccessScreen = true;
            successMessage = message;
          });
          
          // Auto-close after 2 seconds and return success
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              finish(context, true);
            }
          });
        } else {
          appStore.setLoading(false);
          final errorMsg = responseData is Map 
              ? (responseData['message'] as String? ?? 'Payment failed')
              : 'Payment verification failed';
          
          // Hide success screen and show error
          setState(() {
            showSuccessScreen = false;
          });
          
          toast(errorMsg);
          finish(context, false);
        }
      } catch (e) {
        appStore.setLoading(false);
        log('Error verifying payment via API: $e');
        
        // Check if it's a server error (500, 502, 503, etc.)
        final errorStr = e.toString().toLowerCase();
        final isServerError = errorStr.contains('500') || 
                             errorStr.contains('502') || 
                             errorStr.contains('503') ||
                             errorStr.contains('internal server error') ||
                             errorStr.contains('server error');
        
        if (isServerError) {
          // Server error - don't assume success, show error and let user retry
          setState(() {
            showSuccessScreen = false;
          });
          
          toast(language.paymentVerificationServerError);
          finish(context, false);
        } else {
          // Other errors - might be network issues, but token exists so payment might be processed
          // Show warning but still return success (backend might have processed it)
          setState(() {
            showSuccessScreen = true;
            successMessage = language.paymentMayHaveBeenProcessed;
          });
          
          // Auto-close after 3 seconds with warning
          Future.delayed(Duration(seconds: 3), () {
            if (mounted) {
              finish(context, true);
            }
          });
        }
      }
    } catch (e) {
      appStore.setLoading(false);
      log('Error checking payment status: $e');
      
      // Check if it's a server error
      final errorStr = e.toString().toLowerCase();
      final isServerError = errorStr.contains('500') || 
                           errorStr.contains('502') || 
                           errorStr.contains('503') ||
                           errorStr.contains('internal server error') ||
                           errorStr.contains('server error');
      
      if (isServerError) {
        // Server error - show error message
        setState(() {
          showSuccessScreen = false;
        });
        toast(language.paymentVerificationServerError);
        finish(context, false);
      } else {
        // Other errors - might be network issues
        final uri = Uri.tryParse(url);
        if (uri?.queryParameters.containsKey('token') ?? false) {
          // Token exists, payment might be processed but we can't verify
          setState(() {
            showSuccessScreen = true;
            successMessage = language.paymentMayHaveBeenProcessed;
          });
          
          // Auto-close after 3 seconds with warning
          Future.delayed(Duration(seconds: 3), () {
            if (mounted) {
              finish(context, true);
            }
          });
        } else {
          toast('${language.errorProcessingPayment}: ${e.toString()}');
          finish(context, false);
        }
      }
    }
  }


  void _handlePayPalCancel() {
    if (isPaymentCompleted) return;
    isPaymentCompleted = true;
    appStore.setLoading(false);
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
            // Success icon with gradient
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: successGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: Colors.white,
                size: 50,
              ),
            ),
            24.height,
            Text(
              language.successful,
              style: boldTextStyle(size: 24),
            ),
            16.height,
            Text(
              successMessage ?? language.paymentCompletedSuccessfully,
              style: secondaryTextStyle(size: 16),
              textAlign: TextAlign.center,
            ).paddingSymmetric(horizontal: 32),
            if (paymentData != null) ...[
              24.height,
              Container(
                margin: EdgeInsets.symmetric(horizontal: 32),
                padding: EdgeInsets.all(16),
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (paymentData!['txn_id'] != null)
                      _buildInfoRow('Transaction ID', paymentData!['txn_id'].toString()),
                    if (paymentData!['amount'] != null)
                      _buildInfoRow('Amount', (paymentData!['amount'] is num 
                          ? (paymentData!['amount'] as num) 
                          : (num.tryParse(paymentData!['amount'].toString()) ?? 0)).toPriceFormat()),
                    if (paymentData!['payment_type'] != null)
                      _buildInfoRow('Payment Type', paymentData!['payment_type'].toString().toUpperCase()),
                  ],
                ),
              ),
            ],
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: secondaryTextStyle(size: 14),
          ).expand(),
          Text(
            value,
            style: boldTextStyle(size: 14),
            textAlign: TextAlign.right,
          ).expand(),
        ],
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
          decoration: BoxDecoration(
            gradient: appPrimaryGradient,
          ),
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
              child: WebViewWidget(
                controller: controller,
              ),
            ),
          Observer(
            builder: (context) => LoaderWidget().visible(appStore.isLoading),
          ),
        ],
      ),
    );
  }
}
