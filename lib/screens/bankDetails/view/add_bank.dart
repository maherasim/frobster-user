import 'dart:convert';

import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/base_scaffold_widget.dart';
import '../../../component/gradient_button.dart';
import '../../../main.dart';
import '../../../model/bank_list_response.dart';
import '../../../model/base_response_model.dart';
import '../../../model/static_data_model.dart';
import '../../../network/network_utils.dart';
import '../../../utils/colors.dart';
import '../../../utils/common.dart';
import '../../../utils/constant.dart';
import '../../../utils/images.dart';
import '../../../utils/model_keys.dart';

class AddBankScreen extends StatefulWidget {
  final BankHistory? data;

  const AddBankScreen({super.key, this.data});

  @override
  State<AddBankScreen> createState() => _AddBankScreenState();
}

class _AddBankScreenState extends State<AddBankScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController bankNameCont = TextEditingController();
  TextEditingController branchNameCont = TextEditingController();
  TextEditingController accNumberCont = TextEditingController();
  TextEditingController accountHolderCont = TextEditingController();
  TextEditingController contactNumberCont = TextEditingController();
  TextEditingController ibanNoCont = TextEditingController();
  TextEditingController bicNumberCont = TextEditingController();
  TextEditingController ifscCodeCont = TextEditingController();
  TextEditingController aadharCardNumberCont = TextEditingController();
  TextEditingController panNumberCont = TextEditingController();
  TextEditingController stripeAccountCont = TextEditingController();

  FocusNode bankNameFocus = FocusNode();
  FocusNode branchNameFocus = FocusNode();
  FocusNode accNumberFocus = FocusNode();
  FocusNode accountHolderFocus = FocusNode();
  FocusNode contactNumberFocus = FocusNode();
  FocusNode ibanNoFocus = FocusNode();
  FocusNode bicNumberFocus = FocusNode();
  FocusNode ifscCodeFocus = FocusNode();
  FocusNode aadharCardNumberFocus = FocusNode();
  FocusNode panNumberFocus = FocusNode();
  FocusNode stripeAccountFocus = FocusNode();

  Future<void> update() async {
    MultipartRequest multiPartRequest = await getMultiPartRequest('save-bank');
    
    // Always sent fields
    if (isUpdate && widget.data != null) {
      multiPartRequest.fields[UserKeys.id] = widget.data!.id.toString();
    }
    multiPartRequest.fields['user_id'] = appStore.userId.toString();
    multiPartRequest.fields[UserKeys.providerId] = appStore.userId.toString();
    multiPartRequest.fields[BankServiceKey.bankName] = bankNameCont.text.trim();
    multiPartRequest.fields[BankServiceKey.branchName] = branchNameCont.text.trim();
    multiPartRequest.fields[BankServiceKey.accountNo] = accNumberCont.text.trim();
    multiPartRequest.fields[UserKeys.status] = getStatusValue().toString();
    multiPartRequest.fields[UserKeys.isDefault] =
        widget.data?.isDefault.toString() ?? "0";
    
    // Sent only if not empty
    if (accountHolderCont.text.trim().isNotEmpty) {
      multiPartRequest.fields[BankServiceKey.accountHolder] = accountHolderCont.text.trim();
    }
    if (contactNumberCont.text.trim().isNotEmpty) {
      multiPartRequest.fields[BankServiceKey.mobileNo] = contactNumberCont.text.trim();
    }
    if (ibanNoCont.text.trim().isNotEmpty) {
      multiPartRequest.fields[BankServiceKey.ibanNo] = ibanNoCont.text.trim();
    }
    if (bicNumberCont.text.trim().isNotEmpty) {
      multiPartRequest.fields[BankServiceKey.bicNumber] = bicNumberCont.text.trim();
    }
    if (ifscCodeCont.text.trim().isNotEmpty) {
      multiPartRequest.fields[BankServiceKey.ifscNo] = ifscCodeCont.text.trim();
    }
    if (aadharCardNumberCont.text.trim().isNotEmpty) {
      multiPartRequest.fields[BankServiceKey.aadharNo] = aadharCardNumberCont.text.trim();
    }
    if (panNumberCont.text.trim().isNotEmpty) {
      multiPartRequest.fields[BankServiceKey.panNo] = panNumberCont.text.trim();
    }
    if (stripeAccountCont.text.trim().isNotEmpty) {
      multiPartRequest.fields[BankServiceKey.stripeAccount] = stripeAccountCont.text.trim();
    }
    
    multiPartRequest.fields[BankServiceKey.bankAttachment] = '';
    multiPartRequest.headers.addAll(buildHeaderTokens());

    appStore.setLoading(true);

    sendMultiPartRequest(
      multiPartRequest,
      onSuccess: (data) async {
        appStore.setLoading(false);
        if (data != null) {
          print(data);
          if ((data as String).isJson()) {
            BaseResponseModel res =
                BaseResponseModel.fromJson(jsonDecode(data));
            finish(context, [true, bankNameCont.text]);
            snackBar(context, title: res.message!);
          }
        }
      },
      onError: (error) {
        toast(error.toString(), print: true);
        appStore.setLoading(false);
      },
    ).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  String bankStatus = 'ACTIVE';
  int getStatusValue() {
    if (bankStatus == 'ACTIVE') {
      return 1;
    } else {
      return 0;
    }
  }

  bool isUpdate = true;

  List<StaticDataModel> statusListStaticData = [
    StaticDataModel(key: ACTIVE, value: language.active),
    StaticDataModel(key: INACTIVE, value: language.inactive),
  ];
  StaticDataModel? blogStatusModel;

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() async {
    isUpdate = widget.data != null;

    if (isUpdate) {
      bankNameCont.text = widget.data!.bankName.validate();
      branchNameCont.text = widget.data!.branchName.validate();
      accNumberCont.text = widget.data!.accountNo.validate();
      ifscCodeCont.text = widget.data!.ifscNo.validate();
      contactNumberCont.text = widget.data!.mobileNo.validate();
      aadharCardNumberCont.text = widget.data!.aadharNo.validate();
      panNumberCont.text = widget.data!.panNo.validate();
      // Note: New fields (accountHolder, ibanNo, bicNumber, stripeAccount) 
      // may not be in existing data, so they'll remain empty
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: AppScaffold(
        appBarTitle: language.addBank,
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                return await update();
              },
              child: Form(
                key: formKey,
                child: AnimatedScrollView(
                  padding: EdgeInsets.all(16),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Bank Name (Required)
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: bankNameCont,
                      focus: bankNameFocus,
                      nextFocus: branchNameFocus,
                      decoration:
                          inputDecoration(context, hintText: language.bankName),
                      suffix: ic_piggy_bank.iconImage(size: 10).paddingAll(14),
                    ),
                    16.height,
                    // 2. Full Name on Bank Account (Required)
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: branchNameCont,
                      focus: branchNameFocus,
                      nextFocus: accNumberFocus,
                      decoration: inputDecoration(context,
                          hintText: language.fullNameOnBankAccount),
                      suffix: ic_piggy_bank.iconImage(size: 10).paddingAll(14),
                    ),
                    16.height,
                    // 3. Account Number (Required)
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: accNumberCont,
                      focus: accNumberFocus,
                      nextFocus: accountHolderFocus,
                      decoration: inputDecoration(context,
                          hintText: language.accountNumber),
                      suffix: ic_password
                          .iconImage(size: 10, fit: BoxFit.contain)
                          .paddingAll(14),
                    ),
                    16.height,
                    // 4. Account Holder Name (Optional)
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: accountHolderCont,
                      focus: accountHolderFocus,
                      nextFocus: contactNumberFocus,
                      decoration: inputDecoration(context,
                          hintText: 'Account Holder Name', counter: false),
                      suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                      isValidationRequired: false,
                    ),
                    16.height,
                    // 5. Mobile Number (Optional)
                    AppTextField(
                      textFieldType: TextFieldType.PHONE,
                      controller: contactNumberCont,
                      focus: contactNumberFocus,
                      nextFocus: ibanNoFocus,
                      decoration: inputDecoration(context,
                          hintText: language.hintContactNumberTxt, counter: false),
                      suffix: ic_calling.iconImage(size: 10).paddingAll(14),
                      isValidationRequired: false,
                    ),
                    16.height,
                    // 6. IBAN Number (Optional)
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: ibanNoCont,
                      focus: ibanNoFocus,
                      nextFocus: bicNumberFocus,
                      decoration: inputDecoration(context,
                          hintText: 'IBAN Number', counter: false),
                      suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                      isValidationRequired: false,
                    ),
                    16.height,
                    // 7. BIC / SWIFT Code (Optional)
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: bicNumberCont,
                      focus: bicNumberFocus,
                      nextFocus: ifscCodeFocus,
                      decoration: inputDecoration(context,
                          hintText: 'BIC / SWIFT Code', counter: false),
                      suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                      isValidationRequired: false,
                    ),
                    16.height,
                    // 8. IFSC Code (Optional)
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: ifscCodeCont,
                      focus: ifscCodeFocus,
                      nextFocus: aadharCardNumberFocus,
                      decoration: inputDecoration(context,
                          hintText: language.iFSCCode, counter: false),
                      suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                      isValidationRequired: false,
                    ),
                    16.height,
                    // 9. Aadhar Number (Optional)
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: aadharCardNumberCont,
                      focus: aadharCardNumberFocus,
                      nextFocus: panNumberFocus,
                      decoration: inputDecoration(context,
                          hintText: 'Aadhar Number', counter: false),
                      suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                      isValidationRequired: false,
                    ),
                    16.height,
                    // 10. PAN Number (Optional)
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: panNumberCont,
                      focus: panNumberFocus,
                      nextFocus: stripeAccountFocus,
                      decoration: inputDecoration(context,
                          hintText: 'PAN Number', counter: false),
                      suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                      isValidationRequired: false,
                    ),
                    16.height,
                    // 11. Stripe Account (Optional)
                    AppTextField(
                      textFieldType: TextFieldType.NAME,
                      controller: stripeAccountCont,
                      focus: stripeAccountFocus,
                      decoration: inputDecoration(context,
                          hintText: 'Stripe Account', counter: false),
                      suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                      isValidationRequired: false,
                    ),
                    16.height,
                    // 12. Status (Required)
                    DropdownButtonFormField<StaticDataModel>(
                      isExpanded: true,
                      dropdownColor: context.cardColor,
                      initialValue: blogStatusModel != null
                          ? blogStatusModel
                          : statusListStaticData.first,
                      items: statusListStaticData.map((StaticDataModel data) {
                        return DropdownMenuItem<StaticDataModel>(
                          value: data,
                          child: Text(data.value.validate(),
                              style: primaryTextStyle()),
                        );
                      }).toList(),
                      decoration: inputDecoration(context,
                          hintText: language.lblStatus),
                      onChanged: (StaticDataModel? value) async {
                        bankStatus = value!.key.validate();
                        setState(() {});
                      },
                      validator: (value) {
                        if (value == null) return errorThisFieldRequired;
                        return null;
                      },
                    ),
                    100.height,
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GradientButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    update();
                  }
                },
                child: Text(
                  language.btnSave,
                  style: boldTextStyle(color: white),
                ),
              ).withWidth(context.width()),
            ),
          ],
        ),
      ),
    );
  }
}
