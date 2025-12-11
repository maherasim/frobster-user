// ignore_for_file: must_be_immutable

import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'dart:developer' as dev;
import '../../../component/base_scaffold_widget.dart';
import '../../../component/gradient_button.dart';
import '../../../component/loader_widget.dart';
import '../../../component/price_widget.dart';
import '../../../model/bank_list_response.dart';
import '../../../network/rest_apis.dart';
import '../../../utils/colors.dart';
import '../../../utils/common.dart';
import '../../component/success_dialog.dart';
import '../bankDetails/view/add_bank.dart';

class WithdrawRequest extends StatefulWidget {
  num availableBalance = 0;
  WithdrawRequest({super.key, required this.availableBalance});

  @override
  State<WithdrawRequest> createState() => _WithdrawRequestState();
}

class _WithdrawRequestState extends State<WithdrawRequest> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  TextEditingController amount = TextEditingController();
  TextEditingController chooseBank = TextEditingController();

  FocusNode amountFocus = FocusNode();
  FocusNode chooseBankFocus = FocusNode();

  Future<List<BankHistory>>? future;
  List<BankHistory> bankHistoryList = [];
  BankHistory? selectedBank;

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init("");
  }

  init(String bankName) async {
    appStore.setLoading(true);
    getBankListDetail(
      page: page,
      list: bankHistoryList,
      lastPageCallback: (b) {
        isLastPage = b;
      },
      userId: appStore.userId,
    ).then((value) {
      setState(() {
        bankHistoryList = value;
      });
      bankHistoryList.forEach((value) {
        if (bankName.isNotEmpty && bankName == value.bankName) {
          setState(() {
            selectedBank = value;
          });
        } else if (value.isDefault == 1) {
          setState(() {
            selectedBank = value;
          });
        }
      });
    }).whenComplete(() {
      appStore.setLoading(false);
    });
  }

  withdrawMoney() {
    appStore.setLoading(true);
    Map request = {
      "_token": appStore.token.validate(),
      "payment_method": "bank",
      "payment_gateway": "razorpayx",
      "user_id": appStore.userId,
      "bank": selectedBank?.id,
      "amount": amount.text.toDouble(),
    };
    dev.log(request.toString());
    peoviderWithdrawMoney(request: request).then((value) {
      showDialog(
        context: context,
        builder: (BuildContext context) => SuccessDialog(
          title: language.successful,
          description:
              language.yourWithdrawalRequestHasBeenSuccessfullySubmitted,
          buttonText: language.done,
        ),
      );
    }).catchError((e) {
      toast(e.toString());
    }).whenComplete(() {
      appStore.setLoading(false);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: AppScaffold(
        appBarTitle: language.withdrawRequest,
        child: Stack(
          children: [
            Form(
              key: formKey,
              child: AnimatedScrollView(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.availableBalance,
                          style: secondaryTextStyle(size: 12)),
                      PriceWidget(
                          price: widget.availableBalance.validate(),
                          color: gradientRed,
                          isBoldText: true),
                    ],
                  ),
                  24.height,
                  Text(language.lblEnterAmount,
                      style:
                          primaryTextStyle(size: 12, weight: FontWeight.w600)),
                  8.height,
                  AppTextField(
                    textFieldType: TextFieldType.NUMBER,
                    controller: amount,
                    focus: amountFocus,
                    nextFocus: chooseBankFocus,
                    decoration:
                        inputDecoration(context, hintText: language.eg3000),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    isValidationRequired: true,
                    validator: (value) {
                      if (value?.isEmpty ?? false) {
                        return errorThisFieldRequired;
                      } else if (num.parse(value.toString()) >
                          num.parse(widget.availableBalance.toString())) {
                        return "${language.pleaseAddLessThanOrEqualTo} ${widget.availableBalance.validate().toPriceFormat()}";
                      }
                      return null;
                    },
                  ),
                  16.height,
                  Row(
                    children: [
                      Text(language.chooseBank,
                          style: primaryTextStyle(
                              size: 12, weight: FontWeight.w600)),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          AddBankScreen().launch(context).then((value) {
                            if (value.isNotEmpty) {
                              if (value[0]) {
                                init(value[1]);
                                setState(() {});
                              }
                            }
                          });
                        },
                        child: Text(language.addBank,
                            style:
                                boldTextStyle(size: 12, color: gradientRed)),
                      ),
                    ],
                  ),
                  8.height,
                  DropdownButtonFormField<BankHistory>(
                    decoration: inputDecoration(context),
                    isExpanded: true,
                    menuMaxHeight: 300,
                    initialValue: selectedBank,
                    hint: Text(
                      language.egCentralNationalBank,
                      style: secondaryTextStyle(size: 12),
                    ),
                    icon: ic_down_arrow.iconImage(size: 16),
                    dropdownColor: context.cardColor,
                    items: bankHistoryList.map((BankHistory e) {
                      return DropdownMenuItem<BankHistory>(
                        value: e,
                        child: Text(e.bankName.validate(),
                            style: primaryTextStyle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (BankHistory? value) async {
                      selectedBank = value;
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null) return errorThisFieldRequired;
                      return null;
                    },
                  ),
                  40.height,
                  GradientButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        withdrawMoney();
                      }
                    },
                    child: Text(language.withdraw, style: boldTextStyle(color: white)),
                  ).withWidth(context.width() - context.navigationBarHeight),
                ],
              ).paddingSymmetric(horizontal: 16, vertical: 16),
            ),
            Observer(
                builder: (_) =>
                    LoaderWidget().center().visible(appStore.isLoading)),
          ],
        ),
      ),
    );
  }
}
