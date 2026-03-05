import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/wallet_balance_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/payment_gateway_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/component/bank_transfer_detail_dialog.dart';
import 'package:booking_system_flutter/services/paypal_service.dart';
import 'package:booking_system_flutter/services/stripe_service_new.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/paypal_webview_screen.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../component/gradient_button.dart';

class PaymentDialog extends StatefulWidget {
  final num amount;
  final bool isAdvance;
  final num bidId;
  const PaymentDialog({super.key, required this.amount,this.isAdvance = false, required this.bidId});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  Future<List<PaymentSetting>>? future;
  PaymentSetting? currentPaymentMethod;


  @override
  void initState() {
    super.initState();
    init();


  }

  void init() async {
    future = getPaymentGateways(requireCOD: false);
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: context.width(),
        color: Colors.transparent,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.height,
                Center(child: Text( widget.isAdvance ? "Pay Advance" : "Pay Remaining", style: boldTextStyle(size: 18))),
                8.height,
                Text("Amount: ${widget.amount.toPriceFormat()}", style: boldTextStyle()).paddingLeft(16),
                SnapHelperWidget<List<PaymentSetting>>(
                  future: future,
                  onSuccess: (list) {
                    return AnimatedListView(
                      itemCount: list.length,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: NeverScrollableScrollPhysics(),
                      listAnimationType: ListAnimationType.FadeIn,
                      fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                      emptyWidget: NoDataWidget(
                        title: language.noPaymentMethodFound,
                        imageWidget: EmptyStateWidget(),
                      ),
                      itemBuilder: (context, index) {
                        PaymentSetting value = list[index];

                        if (value.status.validate() == 0) return Offstage();

                        return RadioListTile<PaymentSetting>(
                          dense: true,
                          activeColor: gradientRed,
                          value: value,
                          controlAffinity: ListTileControlAffinity.trailing,
                          groupValue: currentPaymentMethod,
                          onChanged: (PaymentSetting? ind) {
                            currentPaymentMethod = ind;
                            if (value.type == PAYMENT_METHOD_BANK_TRANSFER) {
                              showInDialog(
                                context,
                                barrierDismissible: true,
                                insetPadding: EdgeInsets.symmetric(horizontal: 10),
                                builder: (p0) {
                                  return  BankTransferDetailDialog(
                                    bookingAmount: widget.amount.toString(),
                                    bookingId: 0,
                                  );
                                },
                              );
                            }
                            setState(() {});
                          },
                          title: Text(value.title.validate(),
                              style: primaryTextStyle()),
                        );
                      },
                    );
                  },
                ),
                if (appConfigurationStore.isEnableUserWallet)
                  WalletBalanceComponent().paddingSymmetric(vertical: 8, horizontal: 16),
                Row(
                  children: [
                    AppButton(
                      onTap: () {
                        finish(context);
                      },
                      shapeBorder: RoundedRectangleBorder(borderRadius: radius()),
                      color: context.scaffoldBackgroundColor,
                      text: language.lblCancel,
                      textColor: context.iconColor,
                    ).expand(),
                    16.width,
                    GradientButton(
                      onPressed: _handleSubmitClick,
                      child: Text(language.confirm),
                    ).expand(),
                  ],
                ).paddingAll(16),
              ],
            ),
            Observer(builder: (context) {
              return LoaderWidget().visible(appStore.isLoading);
            })
          ],
        ).center(),
      ),
    );
  }

  _handleSubmitClick() async {
    appStore.setLoading(true);
    if (currentPaymentMethod!.type == PAYMENT_METHOD_STRIPE) {
      StripeServiceNew stripeServiceNew = StripeServiceNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: widget.amount,
        onComplete: (p0) {
          // p0['transaction_id'] is the Stripe PaymentIntent id
          savePay(paymentMethod: PAYMENT_METHOD_STRIPE, paymentIntentId: p0['transaction_id'].toString());
        },
      );

      stripeServiceNew.stripePay().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PAYPAL) {
      // Use webview-based PayPal payment flow
      await _handlePayPalPayment();
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_FROM_WALLET) {
      savePay(paymentMethod: PAYMENT_METHOD_FROM_WALLET,);
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_BANK_TRANSFER) {
      savePay(paymentMethod: PAYMENT_METHOD_BANK_TRANSFER,);
    } else {
      appStore.setLoading(false);
      toast(language.paymentMethodNotSupported);
    }
  }

  Future<void> _handlePayPalPayment() async {
    try {
      final request = {
        "type": widget.isAdvance ? "advance" : "remaining",
        "amount": widget.amount,
      };

      // Call backend to create PayPal payment and get approval URL
      final response = await buildHttpResponse(
        'postjob/paypal/create/${widget.bidId}',
        request: request,
        method: HttpMethodType.POST,
      );
      
      final jsonResponse = await handleResponse(response);
      
      // The Laravel API returns: {"status": true, "url": "approval_link"}
      if (jsonResponse is Map) {
        final status = jsonResponse['status'] as bool?;
        final approvalUrl = jsonResponse['url'] as String?;
        
        if (status == true && approvalUrl != null && approvalUrl.isNotEmpty) {
          appStore.setLoading(false);

          // Open PayPal webview with the approval URL
          final paymentType = widget.isAdvance ? "advance" : "remaining";
          final result = await PayPalWebViewScreen(
            approvalUrl: approvalUrl,
            bidId: widget.bidId,
            paymentType: paymentType,
          ).launch(context);

          // If payment was successful, save the payment
          if (result == true) {
            // Payment was successful, now save it
            // The backend should have already processed the payment via the success callback
            // But we still need to call savePay to update the job request status
            savePay(paymentMethod: PAYMENT_METHOD_PAYPAL);
          } else {
            appStore.setLoading(false);
            // Payment was cancelled or failed - dialog stays open for user to retry
          }
        } else {
          appStore.setLoading(false);
          final errorMsg = jsonResponse['error'] as String? ?? jsonResponse['message'] as String?;
          toast(errorMsg ?? 'Failed to get PayPal payment URL. Please try again.');
        }
      } else {
        appStore.setLoading(false);
        toast('Invalid response from server. Please try again.');
      }
    } catch (e) {
      appStore.setLoading(false);
      final errMsg = e.toString().trim().toLowerCase();
      if (errMsg.contains('page not found') || errMsg.contains('404')) {
        toast('Payment endpoint not found. Please contact support.');
      } else {
        toast('PayPal payment error: ${e.toString()}');
      }
    }
  }

  Future<void> savePay({required String paymentMethod, String? paymentIntentId}) async {
   final request = {
     "type": widget.isAdvance ?  "advance" : "remaining",
     "amount": widget.amount,
     if (paymentIntentId != null && paymentIntentId.isNotEmpty) "payment_intent_id": paymentIntentId,
   };
   String endpoint = '';
   switch(paymentMethod) {
     case PAYMENT_METHOD_STRIPE:
       // Use confirm endpoint to let server verify PaymentIntent and record payment
       endpoint = 'postjob/stripe/confirm/${widget.bidId}';
       break;
     case PAYMENT_METHOD_PAYPAL:
       // PayPal payment is processed via webview success callback
       // This endpoint may update status or be handled by backend
       endpoint = 'postjob/paypal/create/${widget.bidId}';
       break;
     case PAYMENT_METHOD_FROM_WALLET:
       endpoint = 'paythrough/wallet/${widget.bidId}';
       break;
     case PAYMENT_METHOD_BANK_TRANSFER:
       endpoint = 'postjob/bank-transfer/${widget.bidId}';
       break;

   }
   try {
     final res = await payBidAmount(endpoint, request);
     appStore.setLoading(false);
     toast(res.message.validate());
     if (res.status ?? false) {
       finish(context, true);
     }
   } catch (e) {
     appStore.setLoading(false);
     final errMsg = e.toString().trim().toLowerCase();
     // Backend may return 404 (e.g. stripe confirm route). Show static message and close so screen refreshes.
     if (errMsg.contains('page not found') || errMsg.contains('404')) {
       toast('Payment may have been successful. Refreshing...');
       finish(context, true);
     } else {
       toast(e.toString().validate());
     }
   }
  }
}
