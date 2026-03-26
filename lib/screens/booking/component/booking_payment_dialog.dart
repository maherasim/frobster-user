import 'dart:convert';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/wallet_balance_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_detail_model.dart';
import 'package:booking_system_flutter/model/payment_gateway_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/component/bank_transfer_detail_dialog.dart';
import 'package:booking_system_flutter/services/airtel_money/airtel_money_service.dart';
import 'package:booking_system_flutter/services/cinet_pay_services_new.dart';
import 'package:booking_system_flutter/services/flutter_wave_service_new.dart';
import 'package:booking_system_flutter/services/midtrans_service.dart';
import 'package:booking_system_flutter/services/paypal_service.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_paypal_webview_screen.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/services/paystack_service.dart';
import 'package:booking_system_flutter/services/phone_pe/phone_pe_service.dart';
import 'package:booking_system_flutter/services/razorpay_service_new.dart';
import 'package:booking_system_flutter/services/sadad_services_new.dart';
import 'package:booking_system_flutter/services/stripe_service_new.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../component/gradient_button.dart';
import '../../../component/app_common_dialog.dart';

class BookingPaymentDialog extends StatefulWidget {
  final BookingDetailResponse bookings;
  final bool isForAdvancePayment;
  final num amount;

  const BookingPaymentDialog({
    Key? key,
    required this.bookings,
    required this.isForAdvancePayment,
    required this.amount,
  }) : super(key: key);

  @override
  State<BookingPaymentDialog> createState() => _BookingPaymentDialogState();
}

class _BookingPaymentDialogState extends State<BookingPaymentDialog> {
  Future<List<PaymentSetting>>? future;
  PaymentSetting? currentPaymentMethod;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    log('BookingPaymentDialog initialized - amount: ${widget.amount}, isForAdvancePayment: ${widget.isForAdvancePayment}');
    future = getPaymentGateways(requireCOD: !widget.isForAdvancePayment);
    setState(() {});
  }

  num get getAdvancePaymentAmount {
    if (widget.bookings.bookingDetail!.paidAmount.validate() != 0) {
      return widget.bookings.bookingDetail!.paidAmount!;
    } else {
      return widget.bookings.bookingDetail!.totalAmount.validate() *
          widget.bookings.service!.advancePaymentPercentage.validate() /
          100;
    }
  }

  Future<void> _handleSubmitClick() async {
    if (currentPaymentMethod == null) {
      toast(language.chooseAnyOnePayment);
      return;
    }

    appStore.setLoading(true);
    if (currentPaymentMethod!.type == PAYMENT_METHOD_COD) {
      savePay(
        paymentMethod: PAYMENT_METHOD_COD,
        paymentStatus: SERVICE_PAYMENT_STATUS_PENDING,
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_STRIPE) {
      StripeServiceNew stripeServiceNew = StripeServiceNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: widget.amount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_STRIPE,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );

      stripeServiceNew.stripePay().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_RAZOR) {
      RazorPayServiceNew razorPayServiceNew = RazorPayServiceNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: widget.amount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_RAZOR,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );

      razorPayServiceNew.razorPayCheckout().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_FLUTTER_WAVE) {
      FlutterWaveServiceNew flutterWaveServiceNew = FlutterWaveServiceNew();
      flutterWaveServiceNew.checkout(
        paymentSetting: currentPaymentMethod!,
        totalAmount: widget.amount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_FLUTTER_WAVE,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PAYSTACK) {
      PayStackService paystackServices = PayStackService();
      appStore.setLoading(true);
      await paystackServices.init(
        context: context,
        currentPaymentMethod: currentPaymentMethod!,
        loderOnOFF: (p0) {
          appStore.setLoading(p0);
        },
        totalAmount: widget.amount.toDouble(),
        bookingId: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.id.validate()
            : 0,
        onComplete: (res) {
          savePay(
            paymentMethod: PAYMENT_METHOD_PAYSTACK,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: res["transaction_id"],
          );
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      appStore.setLoading(false);
      paystackServices.checkout().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PAYPAL) {
      await _handlePayPalPayment();
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_PHONEPE) {
      PhonePeServices peServices = PhonePeServices(
        paymentSetting: currentPaymentMethod!,
        totalAmount: widget.amount.toDouble(),
        bookingId: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.id.validate()
            : 0,
        onComplete: (res) {
          savePay(
            paymentMethod: PAYMENT_METHOD_PHONEPE,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: res["transaction_id"],
          );
        },
      );

      peServices.phonePeCheckout(context).catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_CINETPAY) {
      CinetPayServicesNew cinetPayServices = CinetPayServicesNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: widget.amount,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_CINETPAY,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );

      cinetPayServices.payWithCinetPay(context: context).catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_SADAD_PAYMENT) {
      SadadServicesNew sadadServices = SadadServicesNew(
        paymentSetting: currentPaymentMethod!,
        totalAmount: widget.amount,
        remarks: language.payment,
        onComplete: (p0) {
          savePay(
            paymentMethod: PAYMENT_METHOD_SADAD_PAYMENT,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: p0['transaction_id'],
          );
        },
      );

      sadadServices.payWithSadad(context).catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_AIRTEL) {
      showInDialog(
        context,
        contentPadding: EdgeInsets.zero,
        barrierDismissible: false,
        builder: (context) {
          return AppCommonDialog(
            title: language.payment,
            child: AirtelMoneyDialog(
              amount: widget.amount,
              reference: APP_NAME,
              paymentSetting: currentPaymentMethod!,
              bookingId: widget.bookings.bookingDetail != null
                  ? widget.bookings.bookingDetail!.id.validate()
                  : 0,
              onComplete: (res) {
                savePay(
                  paymentMethod: PAYMENT_METHOD_AIRTEL,
                  paymentStatus: widget.isForAdvancePayment
                      ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                      : SERVICE_PAYMENT_STATUS_PAID,
                  txnId: res['transaction_id'],
                );
              },
            ),
          );
        },
      );
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_MIDTRANS) {
      MidtransService midtransService = MidtransService();
      appStore.setLoading(true);
      await midtransService.initialize(
        currentPaymentMethod: currentPaymentMethod!,
        totalAmount: widget.amount,
        serviceId: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.serviceId.validate()
            : 0,
        serviceName: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.serviceName.validate()
            : '',
        servicePrice: widget.bookings.bookingDetail != null
            ? widget.bookings.bookingDetail!.amount.validate()
            : 0,
        loaderOnOFF: (p0) {
          appStore.setLoading(p0);
        },
        onComplete: (res) {
          savePay(
            paymentMethod: PAYMENT_METHOD_MIDTRANS,
            paymentStatus: widget.isForAdvancePayment
                ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                : SERVICE_PAYMENT_STATUS_PAID,
            txnId: res["transaction_id"],
          );
        },
      );
      await Future.delayed(const Duration(seconds: 1));
      appStore.setLoading(false);
      midtransService.midtransPaymentCheckout().catchError((e) {
        appStore.setLoading(false);
        toast(e);
      });
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_FROM_WALLET) {
      savePay(paymentMethod: PAYMENT_METHOD_FROM_WALLET);
    } else if (currentPaymentMethod!.type == PAYMENT_METHOD_BANK_TRANSFER) {
      savePay(
        paymentMethod: PAYMENT_METHOD_BANK_TRANSFER,
        paymentStatus: widget.isForAdvancePayment
            ? PENDING_BY_ADMIN
            : SERVICE_PAYMENT_STATUS_PAID,
        txnId: '',
        endPoint: 'save-bank-transfer-payment',
      );
    } else {
      appStore.setLoading(false);
      toast(language.paymentMethodNotSupported);
    }
  }

  Future<void> _handlePayPalPayment() async {
    try {
      // Validate amount
      if (widget.amount <= 0) {
        appStore.setLoading(false);
        toast(language.invalidPaymentAmount);
        log('PayPal Payment Error: Invalid amount - widget.amount=${widget.amount}');
        return;
      }
      
      log('PayPal Payment - widget.amount: ${widget.amount}, type: ${widget.amount.runtimeType}');
      
      // Send amount directly (same as job requests) - backend should handle formatting
      final request = {
        "booking_id": widget.bookings.bookingDetail!.id.validate(),
        "type": widget.isForAdvancePayment ? "advance" : "remaining",
        "amount": widget.amount, // Send directly - backend should use this value
      };
      
      log('PayPal Payment - Request amount: ${request["amount"]}, type: ${request["amount"].runtimeType}');

      log('PayPal Payment Request (JSON): ${jsonEncode(request)}');
      log('PayPal Payment Request (Map): $request');

      // Call backend to create PayPal payment and get approval URL
      final response = await buildHttpResponse(
        'booking-paypal/create',
        request: request,
        method: HttpMethodType.POST,
      );
      
      final jsonResponse = await handleResponse(response);
      
      log('PayPal API Response: $jsonResponse');
      log('PayPal API Response type: ${jsonResponse.runtimeType}');
      
      // The API returns: {"url": "approval_link"} or {"status": true, "url": "approval_link"}
      if (jsonResponse is Map) {
        final error = jsonResponse['error'] as String?;
        
        if (error != null) {
          appStore.setLoading(false);
          log('PayPal API Error: $error');
          // Show the error message from backend
          toast(error);
          return;
        }
        
        final approvalUrl = jsonResponse['url'] as String?;
        final status = jsonResponse['status'] as bool?;
        
        log('PayPal API - Extracted values: url=$approvalUrl, status=$status');
        log('PayPal API - URL check: ${approvalUrl != null}, isEmpty: ${approvalUrl?.isEmpty}, status check: ${status == null || status == true}');
        
        // Check if we have a valid URL (either status is true OR url exists directly)
        if (approvalUrl != null && approvalUrl.isNotEmpty && (status == null || status == true)) {
          log('PayPal API - Opening webview with URL: $approvalUrl');
          appStore.setLoading(false);

          // Open PayPal webview screen with the approval URL
          final paymentType = widget.isForAdvancePayment ? "advance" : "remaining";
          final result = await BookingPayPalWebViewScreen(
            approvalUrl: approvalUrl,
            bookingId: widget.bookings.bookingDetail!.id.validate(),
            paymentType: paymentType,
          ).launch(context);

          // If payment was successful, close dialog and refresh booking details
          if (result == true) {
            // Payment was successful - backend should have already processed it via success callback
            finish(context, true);
          } else {
            appStore.setLoading(false);
            // Payment was cancelled or failed - dialog stays open for user to retry
          }
        } else {
          appStore.setLoading(false);
          final errorMsg = jsonResponse['error'] as String? ?? jsonResponse['message'] as String?;
          log('PayPal API - Missing URL: status=$status, url=$approvalUrl');
          toast(errorMsg ?? language.failedToGetPaypalUrl);
        }
      } else {
        appStore.setLoading(false);
        toast(language.invalidResponseTryAgain);
      }
    } catch (e) {
      appStore.setLoading(false);
      final errMsg = e.toString().trim().toLowerCase();
      if (errMsg.contains('page not found') || errMsg.contains('404')) {
        toast(language.paymentEndpointNotFound);
      } else {
        toast('${language.paypalPaymentError}: ${e.toString()}');
      }
    }
  }

  Future<void> savePay({
    String txnId = '',
    String paymentMethod = '',
    String paymentStatus = '',
    String? endPoint,
  }) async {
    num? advancePaymentAmount;
    if (widget.bookings.service!.isAdvancePayment &&
        !widget.bookings.service!.isFreeService &&
        widget.bookings.bookingDetail!.bookingPackage == null) {
      advancePaymentAmount = widget.bookings.bookingDetail!.totalAmount.validate() *
          widget.bookings.service!.advancePaymentPercentage.validate() /
          100;
    }

    Map request = {
      CommonKeys.bookingId: widget.bookings.bookingDetail!.id.validate(),
      CommonKeys.customerId: appStore.userId,
      CouponKeys.discount: widget.bookings.service!.discount,
      CommonKeys.paymentStatus: paymentStatus,
      CommonKeys.paymentMethod: paymentMethod,
      BookingServiceKeys.totalAmount: widget.amount,
      CommonKeys.txnId: txnId != '' ? txnId : "#${widget.bookings.bookingDetail!.id.validate()}",
      CommonKeys.dateTime: DateFormat(BOOKING_SAVE_FORMAT).format(DateTime.now()),
    };

    if (paymentMethod == PAYMENT_METHOD_BANK_TRANSFER) {
      request[CommonKeys.type] = widget.isForAdvancePayment ? 'advance_payment' : 'remaining';
    }

    if (widget.bookings.service != null &&
        widget.bookings.service!.isAdvancePayment &&
        widget.bookings.bookingDetail!.bookingPackage == null) {
      if (widget.isForAdvancePayment) {
        request[AdvancePaymentKey.advancePaidAmount] = advancePaymentAmount ?? widget.bookings.bookingDetail!.paidAmount;
      } else {
        request[AdvancePaymentKey.advancePaidAmount] = null;
      }

      if (paymentMethod != PAYMENT_METHOD_BANK_TRANSFER) {
        if ((widget.bookings.bookingDetail!.paymentStatus == null ||
                widget.bookings.bookingDetail!.paymentStatus != SERVICE_PAYMENT_STATUS_ADVANCE_PAID ||
                widget.bookings.bookingDetail!.paymentStatus != SERVICE_PAYMENT_STATUS_PAID) &&
            (widget.bookings.bookingDetail!.paidAmount == null ||
                widget.bookings.bookingDetail!.paidAmount.validate() <= 0)) {
          request[CommonKeys.paymentStatus] = SERVICE_PAYMENT_STATUS_ADVANCE_PAID;
        } else if (widget.bookings.bookingDetail!.paymentStatus == SERVICE_PAYMENT_STATUS_ADVANCE_PAID) {
          request[CommonKeys.paymentStatus] = SERVICE_PAYMENT_STATUS_PAID;
        }
      }
    }

    appStore.setLoading(true);
    savePayment(request, endPoint: endPoint).then((value) {
      appStore.setLoading(false);
      if (value.status ?? false) {
        finish(context, true);
      } else {
        toast(value.message ?? language.somethingWentWrong);
      }
    }).catchError((e) {
      toast(e.toString());
      appStore.setLoading(false);
    });
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
                Center(
                  child: Text(
                    widget.isForAdvancePayment ? language.payAdvance : language.lblPayNow,
                    style: boldTextStyle(size: 18),
                  ),
                ),
                8.height,
                Text(
                  "${language.price}: ${widget.amount.toPriceFormat()}",
                  style: boldTextStyle(),
                ).paddingLeft(16),
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
                                  return BankTransferDetailDialog(
                                    bookingAmount: widget.isForAdvancePayment
                                        ? getAdvancePaymentAmount.toPriceFormat()
                                        : (widget.bookings.bookingDetail!.totalAmount.validate() -
                                                getAdvancePaymentAmount)
                                            .toPriceFormat(),
                                    bookingId: widget.bookings.bookingDetail!.id.validate(),
                                  );
                                },
                              );
                            }
                            setState(() {});
                          },
                          title: Text(
                            value.title.validate(),
                            style: primaryTextStyle(),
                          ),
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
}
