import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/wallet_balance_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/payment_gateway_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/component/bank_transfer_detail_dialog.dart';
import 'package:booking_system_flutter/services/paypal_service.dart';
import 'package:booking_system_flutter/services/stripe_service_new.dart';
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
                          activeColor: primaryColor,
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
          savePay(paymentMethod: PAYMENT_METHOD_STRIPE);
        },
      );

      stripeServiceNew.stripePay().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PAYPAL) {
      PayPalService.paypalCheckOut(
        context: context,
        paymentSetting: currentPaymentMethod!,
        totalAmount: widget.amount,
        onComplete: (p0) {
          log('PayPalService onComplete: $p0');
          savePay(paymentMethod: PAYMENT_METHOD_PAYPAL);
        },
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_FROM_WALLET) {
      savePay(paymentMethod: PAYMENT_METHOD_FROM_WALLET,);
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_BANK_TRANSFER) {
      savePay(paymentMethod: PAYMENT_METHOD_BANK_TRANSFER,);
    } else {
      appStore.setLoading(false);
      toast(language.paymentMethodNotSupported);
    }
  }

  Future<void> savePay({required String paymentMethod}) async {
   final request = {
     "type": widget.isAdvance ?  "advance" : "remaining",
     "amount": widget.amount,
   };
   String endpoint = '';
   switch(paymentMethod) {
     case PAYMENT_METHOD_STRIPE:
       endpoint = 'postjob/stripe/create/${widget.bidId}';
       break;
     case PAYMENT_METHOD_PAYPAL:
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
     final res = await payBidAmount(endpoint,request);
     appStore.setLoading(false);
     toast(res.message.validate());
     if(res.status ?? false){
       finish(context, true);

     }
   } catch (e) {
      toast(e.toString().validate());
    }

  }
}
