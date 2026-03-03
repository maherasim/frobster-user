import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/gradient_button.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/model/city_list_model.dart';
import 'package:booking_system_flutter/model/country_list_model.dart';
import 'package:booking_system_flutter/model/login_model.dart';
import 'package:booking_system_flutter/model/state_list_model.dart';
import 'package:booking_system_flutter/network/network_utils.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/configs.dart';
import '../../utils/profile_languages.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  File? imageFile;
  XFile? pickedFile;

  List<CountryListResponse> countryList = [];
  List<String> availabilityList = <String>['Full Time', 'Hybrid'];
  List<StateListResponse> stateList = [];
  List<CityListResponse> cityList = [];

  CountryListResponse? selectedCountry;
  StateListResponse? selectedState;
  CityListResponse? selectedCity;

  TextEditingController fNameCont = TextEditingController();
  TextEditingController lNameCont = TextEditingController();
  TextEditingController cNameCont = TextEditingController();
  TextEditingController vatNumCont = TextEditingController();
  TextEditingController experienceCont = TextEditingController();
  TextEditingController mobilityCont = TextEditingController();
  TextEditingController knownLangCont = TextEditingController();
  TextEditingController skillsCont = TextEditingController();
  TextEditingController certificationCont = TextEditingController();
  TextEditingController aboutMeCont = TextEditingController();
  TextEditingController emailCont = TextEditingController();
  TextEditingController userNameCont = TextEditingController();
  TextEditingController mobileCont = TextEditingController();
  TextEditingController addressCont = TextEditingController();

  FocusNode fNameFocus = FocusNode();
  FocusNode lNameFocus = FocusNode();
  FocusNode emailFocus = FocusNode();
  FocusNode cNameFocus = FocusNode();
  FocusNode userNameFocus = FocusNode();
  FocusNode mobileFocus = FocusNode();
  FocusNode mobilityFocus = FocusNode();
  FocusNode experienceFocus = FocusNode();
  FocusNode knownLangFocus = FocusNode();
  FocusNode skillsFocus = FocusNode();
  FocusNode certificationFocus = FocusNode();
  FocusNode aboutMeFocus = FocusNode();

  ValueNotifier _valueNotifier = ValueNotifier(true);

  int countryId = 0;
  int stateId = 0;
  int cityId = 0;

  String selectedAvailability = 'Full Time';

  CareerLevel selectedCareerLevel = CareerLevel.notSpecified;
  EducationLevel selectedEducation = EducationLevel.notSpecified;
  YearsOfExperience selectedYearsOfExperience = YearsOfExperience.lessThan1;

  int? serviceAddressId;
  List<Map<String, dynamic>> serviceAddressList = [];

  Country selectedCountryCode = defaultCountry();

  bool isEmailVerified = getBoolAsync(IS_EMAIL_VERIFIED);

  bool showRefresh = false;

  /// Selected language values (keys from profileLanguageOptions). Multi-select for Known languages.
  List<String> selectedLanguages = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    afterBuildCreated(() {
      appStore.setLoading(true);
    });

    countryId = getIntAsync(COUNTRY_ID);
    stateId = getIntAsync(STATE_ID);
    cityId = getIntAsync(CITY_ID);

    fNameCont.text = appStore.userFirstName;
    lNameCont.text = appStore.userLastName;
    emailCont.text = appStore.userEmail;
    userNameCont.text = appStore.userName;
    mobileCont.text = appStore.userContactNumber.split("-").last;
    countryId = appStore.countryId;
    stateId = appStore.stateId;
    cityId = appStore.cityId;
    addressCont.text = appStore.address;
    selectedCountryCode = Country(
      countryCode: appStore.userContactNumber.split("-").last,
      phoneCode: appStore.userContactNumber.split("-").first.isEmpty
          ? "91"
          : appStore.userContactNumber.split("-").first,
      e164Sc: 0,
      geographic: true,
      level: 1,
      name: '',
      example: '',
      displayName: '',
      displayNameNoCountryCode: '',
      e164Key: '',
      fullExampleWithPlusSign: '',
    );

    userDetailAPI();

    if (getIntAsync(COUNTRY_ID) != 0) {
      await getCountry();

      setState(() {});
    } else {
      await getCountry();
    }
  }

  //region Logic
  String buildMobileNumber() {
    if (mobileCont.text.isEmpty) {
      return '';
    } else {
      return '${selectedCountryCode.phoneCode}-${mobileCont.text.trim()}';
    }
  }

  Future<void> userDetailAPI() async {
    await getUserDetail(appStore.userId).then((value) {
      isEmailVerified = value.emailVerified.validate().getBoolInt();
      setValue(IS_EMAIL_VERIFIED, isEmailVerified);

      // Populate form from user-detail API so existing data shows when editing
      vatNumCont.text = value.vatNumber.validate();
      cNameCont.text = value.companyName.validate();
      mobilityCont.text = value.mobility.validate();
      // Prefer API languages array ["english", "german"]; fallback known_languages "English, German"
      selectedLanguages = List<String>.from(value.effectiveLanguagesArray);
      if (selectedLanguages.isEmpty &&
          value.knownLanguages.validate().trim().isNotEmpty) {
        for (String part in value.knownLanguages!
            .split(RegExp(r'[,،]'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)) {
          String? key = profileLanguageOptions.entries
              .cast<MapEntry<String, String>>()
              .where((e) =>
                  e.value.toLowerCase().trim() == part.toLowerCase().trim())
              .map((e) => e.key)
              .firstOrNull;
          if (key != null) selectedLanguages.add(key);
        }
      }
      knownLangCont.text = selectedLanguages.isNotEmpty
          ? selectedLanguages
              .map((k) => profileLanguageOptions[k] ?? k)
              .join(', ')
          : value.knownLanguages.validate();
      skillsCont.text = value.skillsArray.isNotEmpty
          ? value.skillsArray.join(", ")
          : value.skills.validate();
      experienceCont.text = value.experience.validate();
      certificationCont.text = value.certification.validate();
      aboutMeCont.text = value.aboutMe.validate();

      final avail = value.availability.validate().toLowerCase();
      selectedAvailability = avail == 'hybrid'
          ? 'Hybrid'
          : (avail == 'full_time' ? 'Full Time' : 'Full Time');

      final careerStr = value.careerLevel.validate();
      selectedCareerLevel = CareerLevel.values.firstWhere(
        (e) => e.backendValue == careerStr,
        orElse: () => CareerLevel.notSpecified,
      );

      final educationStr = value.education.validate();
      selectedEducation = EducationLevel.values.firstWhere(
        (e) => e.backendValue == educationStr,
        orElse: () => EducationLevel.notSpecified,
      );

      final yearsStr = value.yearsOfExperience.validate();
      selectedYearsOfExperience = YearsOfExperience.values.firstWhere(
        (e) => e.backendValue == yearsStr,
        orElse: () => YearsOfExperience.lessThan1,
      );

      serviceAddressId = value.serviceAddressId;

      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  Future<void> getCountry() async {
    await getCountryList().then((value) async {
      countryList.clear();
      countryList.addAll(value);

      if (value.any((element) => element.id == getIntAsync(COUNTRY_ID))) {
        selectedCountry = value
            .firstWhere((element) => element.id == getIntAsync(COUNTRY_ID));
      }

      setState(() {});
      await getStates(getIntAsync(COUNTRY_ID));
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> getStates(int countryId) async {
    appStore.setLoading(true);
    await getStateList({UserKeys.countryId: countryId}).then((value) async {
      stateList.clear();
      stateList.addAll(value);

      if (value.any((element) => element.id == getIntAsync(STATE_ID))) {
        selectedState =
            value.firstWhere((element) => element.id == getIntAsync(STATE_ID));
      }

      setState(() {});
      if (getIntAsync(STATE_ID) != 0) {
        await getCity(getIntAsync(STATE_ID));
      }
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> getCity(int stateId) async {
    appStore.setLoading(true);

    await getCityList({UserKeys.stateId: stateId}).then((value) async {
      cityList.clear();
      cityList.addAll(value);

      if (value.any((element) => element.id == getIntAsync(CITY_ID))) {
        selectedCity =
            value.firstWhere((element) => element.id == getIntAsync(CITY_ID));
      }

      setState(() {});
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> update() async {
    hideKeyboard(context);

    MultipartRequest multiPartRequest =
        await getMultiPartRequest('update-profile');
    multiPartRequest.fields[UserKeys.id] = appStore.userId.toString();
    multiPartRequest.fields[UserKeys.firstName] = fNameCont.text;
    multiPartRequest.fields[UserKeys.lastName] = lNameCont.text;
    multiPartRequest.fields[UserKeys.userName] = userNameCont.text;
    // multiPartRequest.fields[UserKeys.userType] = appStore.loginType;
    multiPartRequest.fields[UserKeys.contactNumber] = buildMobileNumber();
    multiPartRequest.fields[UserKeys.email] = emailCont.text;
    multiPartRequest.fields[UserKeys.countryId] = countryId.toString();
    multiPartRequest.fields[UserKeys.stateId] = stateId.toString();
    multiPartRequest.fields[UserKeys.cityId] = cityId.toString();
    multiPartRequest.fields[CommonKeys.address] = addressCont.text;
    multiPartRequest.fields[UserKeys.displayName] =
        '${fNameCont.text.validate() + " " + lNameCont.text.validate()}';

    multiPartRequest.fields['company_name'] = cNameCont.text.validate();
    multiPartRequest.fields['vat_number'] = vatNumCont.text.validate();
    multiPartRequest.fields['mobility'] = mobilityCont.text.validate();
    multiPartRequest.fields['known_languages'] =
        jsonEncode(selectedLanguages);
    multiPartRequest.fields['skills'] = skillsCont.text.validate();
    multiPartRequest.fields['experience'] = experienceCont.text.validate();
    multiPartRequest.fields['career_level'] = selectedCareerLevel.backendValue;
    multiPartRequest.fields['education'] = selectedEducation.backendValue;
    multiPartRequest.fields['years_of_experience'] = selectedYearsOfExperience.backendValue;
    multiPartRequest.fields['certification'] = certificationCont.text.validate();
    multiPartRequest.fields['about_me'] = aboutMeCont.text.validate();
    multiPartRequest.fields['availability'] =
        selectedAvailability == 'Hybrid' ? 'hybrid' : 'full_time';
    if (serviceAddressId != null) {
      multiPartRequest.fields['service_address_id'] = serviceAddressId.toString();
    }

    if (imageFile != null) {
      multiPartRequest.files.add(
          await MultipartFile.fromPath(UserKeys.profileImage, imageFile!.path));
    }

    multiPartRequest.headers.addAll(buildHeaderTokens());
    appStore.setLoading(true);

    sendMultiPartRequest(
      multiPartRequest,
      onSuccess: (data) async {
        appStore.setLoading(false);
        if (data != null) {
          if ((data as String).isJson()) {
            LoginResponse res = LoginResponse.fromJson(jsonDecode(data));

            if (FirebaseAuth.instance.currentUser != null) {
              userService.updateDocument({
                'profile_image': res.userData!.profileImage.validate(),
                'updated_at': Timestamp.now().toDate().toString(),
              }, FirebaseAuth.instance.currentUser!.uid);
            }

            saveUserData(res.userData!);
            finish(context);
            toast(res.message.validate().capitalizeFirstLetter());
          }
        }
      },
      onError: (error) {
        toast(error.toString(), print: true);
        appStore.setLoading(false);
      },
    ).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  void _getFromGallery() async {
    pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      imageFile = File(pickedFile!.path);
      setState(() {});
    }
  }

  _getFromCamera() async {
    pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (pickedFile != null) {
      imageFile = File(pickedFile!.path);
      setState(() {});
    }
  }

  Future<void> verifyEmail() async {
    appStore.setLoading(true);

    await verifyUserEmail(emailCont.text).then((value) async {
      isEmailVerified = value.isEmailVerified.validate().getBoolInt();

      toast(value.message);

      await setValue(IS_EMAIL_VERIFIED, isEmailVerified);
      setState(() {});
      appStore.setLoading(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString());
    });
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      backgroundColor: context.cardColor,
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SettingItemWidget(
              title: language.lblGallery,
              leading: Icon(Icons.image, color: primaryColor),
              onTap: () {
                _getFromGallery();
                finish(context);
              },
            ),
            Divider(color: context.dividerColor),
            SettingItemWidget(
              title: language.camera,
              leading: Icon(Icons.camera, color: primaryColor),
              onTap: () {
                _getFromCamera();
                finish(context);
              },
            ),
          ],
        ).paddingAll(16.0);
      },
    );
  }

  void _showLanguagePicker() {
    List<String> tempSelected = List<String>.from(selectedLanguages);
    TextEditingController searchCont = TextEditingController();
    List<MapEntry<String, String>> entries =
        profileLanguageOptions.entries.toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String query = searchCont.text.trim().toLowerCase();
            List<MapEntry<String, String>> filtered = query.isEmpty
                ? entries
                : entries
                    .where((e) =>
                        e.key.toLowerCase().contains(query) ||
                        e.value.toLowerCase().contains(query))
                    .toList();
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) => Column(
                children: [
                  Text('Select languages', style: boldTextStyle(size: 18))
                      .paddingOnly(top: 16, bottom: 8),
                  AppTextField(
                    controller: searchCont,
                    textFieldType: TextFieldType.OTHER,
                    decoration: inputDecoration(context,
                        hintText: language.search, labelText: language.search),
                    onChanged: (_) => setModalState(() {}),
                  ).paddingSymmetric(horizontal: 16, vertical: 8),
                  Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        String value = filtered[index].key;
                        String label = filtered[index].value;
                        bool checked = tempSelected.contains(value);
                        return CheckboxListTile(
                          value: checked,
                          title: Text(label, style: primaryTextStyle()),
                          onChanged: (bool? v) {
                            setModalState(() {
                              if (v == true) {
                                tempSelected.add(value);
                              } else {
                                tempSelected.remove(value);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        border: Border(
                          top: BorderSide(
                              color: context.dividerColor, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => finish(context),
                              child: Text('Cancel',
                                  style: boldTextStyle(
                                      color: context.primaryColor)),
                            ),
                          ),
                          16.width,
                          Expanded(
                            child: GradientButton(
                              onPressed: () {
                                setState(() {
                                  selectedLanguages =
                                      List<String>.from(tempSelected);
                                  knownLangCont.text = selectedLanguages
                                      .map((k) =>
                                          profileLanguageOptions[k] ?? k)
                                      .join(', ');
                                });
                                finish(context);
                              },
                              child: Text('Apply',
                                  style: boldTextStyle(color: white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> changeCountry() async {
    showCountryPicker(
      context: context,
      countryListTheme: CountryListThemeData(
        textStyle: secondaryTextStyle(color: textSecondaryColorGlobal),
        searchTextStyle: primaryTextStyle(),
        inputDecoration: InputDecoration(
          labelText: language.search,
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
            ),
          ),
        ),
      ),

      showPhoneCode:
          true, // optional. Shows phone code before the country name.
      onSelect: (Country country) {
        selectedCountryCode = country;
        setState(() {});
      },
    );
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.editProfile,
      child: RefreshIndicator(
        onRefresh: () async {
          return await userDetailAPI();
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          physics: AlwaysScrollableScrollPhysics(),
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: boxDecorationDefault(
                        border: Border.all(
                            color: context.scaffoldBackgroundColor, width: 4),
                        shape: BoxShape.circle,
                      ),
                      child: imageFile != null
                          ? Image.file(
                              imageFile!,
                              width: 85,
                              height: 85,
                              fit: BoxFit.cover,
                            ).cornerRadiusWithClipRRect(40)
                          : Observer(
                              builder: (_) => CachedImageWidget(
                                url: appStore.userProfileImage,
                                height: 85,
                                width: 85,
                                fit: BoxFit.cover,
                                radius: 43,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: boxDecorationWithRoundedCorners(
                          boxShape: BoxShape.circle,
                          backgroundColor: primaryColor,
                          border: Border.all(color: Colors.white),
                        ),
                        child: Icon(AntDesign.camera,
                            color: Colors.white, size: 12),
                      ).onTap(() async {
                        _showBottomSheet(context);
                      }),
                    ).visible(!isLoginTypeGoogle && !isLoginTypeApple)
                  ],
                ),
                16.height,
                AppTextField(
                  textFieldType: TextFieldType.NAME,
                  controller: fNameCont,
                  focus: fNameFocus,
                  errorThisFieldRequired: language.requiredText,
                  nextFocus: lNameFocus,
                  enabled: !isLoginTypeApple,
                  decoration: inputDecoration(context,
                      labelText: language.hintFirstNameTxt),
                  suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                ),
                16.height,
                AppTextField(
                  textFieldType: TextFieldType.NAME,
                  controller: lNameCont,
                  focus: lNameFocus,
                  errorThisFieldRequired: language.requiredText,
                  nextFocus: userNameFocus,
                  enabled: !isLoginTypeApple,
                  decoration: inputDecoration(context,
                      labelText: language.hintLastNameTxt),
                  suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                ),
                16.height,
                AppTextField(
                  textFieldType: TextFieldType.NAME,
                  controller: userNameCont,
                  focus: userNameFocus,
                  enabled: false,
                  errorThisFieldRequired: language.requiredText,
                  nextFocus: emailFocus,
                  decoration: inputDecoration(context,
                      labelText: language.hintUserNameTxt),
                  suffix: ic_profile2.iconImage(size: 10).paddingAll(14),
                ),
                16.height,
                AppTextField(
                  textFieldType: TextFieldType.NAME,
                  controller: cNameCont,
                  focus: cNameFocus,
                  errorThisFieldRequired: language.requiredText,
                  nextFocus: emailFocus,
                  enabled: !isLoginTypeApple,
                  decoration:
                      inputDecoration(context, labelText: 'Company Name'),
                ),
                16.height,
                AppTextField(
                  textFieldType: TextFieldType.EMAIL_ENHANCED,
                  controller: emailCont,
                  focus: emailFocus,
                  nextFocus: mobileFocus,
                  errorThisFieldRequired: language.requiredText,
                  decoration: inputDecoration(context,
                      labelText: language.hintEmailTxt),
                  suffix: ic_message.iconImage(size: 10).paddingAll(14),
                  autoFillHints: [AutofillHints.email],
                  onFieldSubmitted: (email) async {
                    if (emailCont.text.isNotEmpty) await verifyEmail();
                  },
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Wrap(
                    spacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        isEmailVerified
                            ? language.verified
                            : language.verifyEmail,
                        style: isEmailVerified
                            ? secondaryTextStyle(color: Colors.green)
                            : secondaryTextStyle(),
                      ),
                      if (!isEmailVerified && !showRefresh)
                        ic_pending.iconImage(color: Colors.amber, size: 14)
                      else
                        Icon(
                          isEmailVerified ? Icons.check_circle : Icons.refresh,
                          color: isEmailVerified ? Colors.green : Colors.grey,
                          size: 16,
                        )
                    ],
                  ).paddingSymmetric(horizontal: 6, vertical: 2).onTap(
                    () {
                      verifyEmail();
                    },
                    borderRadius: radius(),
                  ),
                ).paddingSymmetric(vertical: 4),
                10.height,
                AppTextField(
                  textFieldType: TextFieldType.NUMBER,
                  controller: vatNumCont,
                  nextFocus: mobileFocus,
                  enabled: !isLoginTypeApple,
                  isValidationRequired: false,
                  decoration: inputDecoration(context, labelText: 'VAT Number (optional)'),
                ),
                16.height,
                // AppTextField(
                //   textFieldType: isAndroid ? TextFieldType.PHONE : TextFieldType.NAME,
                //   controller: mobileCont,
                //   focus: mobileFocus,
                //   maxLength: 15,
                //   buildCounter: (_, {required int currentLength, required bool isFocused, required int? maxLength}) {
                //     return Offstage();
                //   },
                //   enabled: !isLoginTypeOTP,
                //   errorThisFieldRequired: language.requiredText,
                //   decoration: inputDecoration(context, labelText: language.hintContactNumberTxt),
                //   suffix: ic_calling.iconImage(size: 10).paddingAll(14),
                //   validator: (mobileCont) {
                //     if (mobileCont!.isEmpty) return language.phnRequiredText;
                //     if (isIOS && !RegExp(r"^([0-9]{1,5})-([0-9]{1,10})$").hasMatch(mobileCont)) {
                //       return language.inputMustBeNumberOrDigit;
                //     }
                //     if (!mobileCont.trim().contains('-')) return '"-" ${language.requiredAfterCountryCode}';
                //     return null;
                //   },
                // ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Country code ...
                    Container(
                      height: 48.0,
                      margin: EdgeInsets.only(bottom: context.height() * 0.032),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: ValueListenableBuilder(
                          valueListenable: _valueNotifier,
                          builder: (context, value, child) => Row(
                            children: [
                              Text(
                                "+${selectedCountryCode.phoneCode}",
                                style: primaryTextStyle(size: 12),
                              ),
                              Icon(Icons.arrow_drop_down)
                            ],
                          ).paddingOnly(left: 8),
                        ),
                      ),
                    ).onTap(() => changeCountry()),
                    10.width,
                    // Mobile number text field...
                    Expanded(
                      child: AppTextField(
                        textFieldType: isAndroid
                            ? TextFieldType.PHONE
                            : TextFieldType.NAME,
                        controller: mobileCont,
                        focus: mobileFocus,
                        enabled: !isLoginTypeOTP,
                        isValidationRequired: false,
                        errorThisFieldRequired: language.requiredText,
                        decoration: inputDecoration(context,
                                hintText: '${language.hintContactNumberTxt}')
                            .copyWith(
                          // hintText: '${selectedCountry.example}',
                          hintStyle: secondaryTextStyle(),
                        ),
                        maxLength: 15,
                        suffix: ic_calling.iconImage(size: 10).paddingAll(14),
                      ),
                    ),
                  ],
                ),
                16.height,
                Row(
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: inputDecoration(context,
                          labelText: 'Select Availability'),
                      isExpanded: true,
                      initialValue: selectedAvailability,
                      dropdownColor: context.cardColor,
                      items: availabilityList.map((String e) {
                        return DropdownMenuItem<String>(
                          value: e,
                          child: Text(
                            e,
                            style: primaryTextStyle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (String? value) async {
                        hideKeyboard(context);
                        selectedAvailability = value ?? 'Full Time';
                        setState(() {});
                      },
                    ).expand(),
                  ],
                ),
                16.height,
                AppTextField(
                  textFieldType: TextFieldType.NAME,
                  controller: mobilityCont,
                  focus: mobilityFocus,
                  errorThisFieldRequired: language.requiredText,
                  nextFocus: emailFocus,
                  enabled: !isLoginTypeApple,
                  decoration: inputDecoration(context, labelText: 'Mobility'),
                ),

                16.height,

                Row(
                  children: [
                    DropdownButtonFormField<CountryListResponse>(
                      decoration: inputDecoration(context,
                          labelText: language.selectCountry),
                      isExpanded: true,
                      initialValue: selectedCountry,
                      dropdownColor: context.cardColor,
                      items: countryList.map((CountryListResponse e) {
                        return DropdownMenuItem<CountryListResponse>(
                          value: e,
                          child: Text(
                            e.name!,
                            style: primaryTextStyle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (CountryListResponse? value) async {
                        hideKeyboard(context);
                        countryId = value!.id!;
                        selectedCountry = value;
                        selectedState = null;
                        selectedCity = null;
                        getStates(value.id!);

                        setState(() {});
                      },
                    ).expand(),
                    8.width.visible(stateList.isNotEmpty),
                    if (stateList.isNotEmpty)
                      DropdownButtonFormField<StateListResponse>(
                        decoration: inputDecoration(context,
                            labelText: language.selectState),
                        isExpanded: true,
                        dropdownColor: context.cardColor,
                        initialValue: selectedState,
                        items: stateList.map((StateListResponse e) {
                          return DropdownMenuItem<StateListResponse>(
                            value: e,
                            child: Text(
                              e.name!,
                              style: primaryTextStyle(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (StateListResponse? value) async {
                          hideKeyboard(context);
                          selectedCity = null;
                          selectedState = value;
                          stateId = value!.id!;
                          await getCity(value.id!);
                          setState(() {});
                        },
                      ).expand(),
                  ],
                ),
                16.height,
                if (cityList.isNotEmpty)
                  DropdownButtonFormField<CityListResponse>(
                    decoration: inputDecoration(context,
                        labelText: language.selectCity),
                    isExpanded: true,
                    initialValue: selectedCity,
                    dropdownColor: context.cardColor,
                    items: cityList.map((CityListResponse e) {
                      return DropdownMenuItem<CityListResponse>(
                        value: e,
                        child: Text(e.name!,
                            style: primaryTextStyle(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (CityListResponse? value) async {
                      hideKeyboard(context);
                      selectedCity = value;
                      cityId = value!.id!;
                      setState(() {});
                    },
                  ),
                16.height,
                if (appStore.userType == USER_TYPE_HANDYMAN) ...[
                  DropdownButtonFormField<int?>(
                    decoration: inputDecoration(context,
                        labelText: 'Service address'),
                    isExpanded: true,
                    initialValue: serviceAddressId,
                    dropdownColor: context.cardColor,
                    items: [
                      DropdownMenuItem<int?>(value: null, child: Text('Select Service address', style: primaryTextStyle())),
                      ...serviceAddressList.map((e) {
                        final id = e['id'] as int?;
                        final name = e['name'] as String?;
                        return DropdownMenuItem<int?>(
                          value: id,
                          child: Text(name ?? '${id ?? ''}', style: primaryTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }),
                    ].toList(),
                    onChanged: (int? value) {
                      hideKeyboard(context);
                      serviceAddressId = value;
                      setState(() {});
                    },
                  ),
                  16.height,
                ],
                AppTextField(
                  controller: addressCont,
                  textFieldType: TextFieldType.ADDRESS,
                  maxLines: 5,
                  decoration:
                      inputDecoration(context, labelText: language.hintAddress),
                  suffix: ic_location.iconImage(size: 10).paddingAll(14),
                  isValidationRequired: false,
                ),
                16.height,
                InkWell(
                  onTap: isLoginTypeApple ? null : () => _showLanguagePicker(),
                  child: InputDecorator(
                    decoration: inputDecoration(context,
                        labelText: 'Known languages',
                        hintText: selectedLanguages.isEmpty
                            ? 'Tap to select languages'
                            : null),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedLanguages.isEmpty
                                ? 'Select languages'
                                : selectedLanguages
                                    .map((k) =>
                                        profileLanguageOptions[k] ?? k)
                                    .join(', '),
                            style: selectedLanguages.isEmpty
                                ? secondaryTextStyle()
                                : primaryTextStyle(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.arrow_drop_down,
                            color: context.iconColor, size: 24),
                      ],
                    ),
                  ),
                ),
                16.height,
                AppTextField(
                  textFieldType: TextFieldType.OTHER,
                  controller: skillsCont,
                  focus: skillsFocus,
                  nextFocus: experienceFocus,
                  enabled: !isLoginTypeApple,
                  decoration: inputDecoration(context,
                      labelText: 'Essential skills',
                      hintText: 'e.g. Skill 1, Skill 2 (comma-separated)'),
                  isValidationRequired: false,
                ),
                16.height,
                AppTextField(
                  textFieldType: TextFieldType.MULTILINE,
                  controller: experienceCont,
                  focus: experienceFocus,
                  errorThisFieldRequired: language.requiredText,
                  nextFocus: aboutMeFocus,
                  enabled: !isLoginTypeApple,
                  minLines: 3,
                  maxLines: 5,
                  decoration: inputDecoration(context, labelText: 'Experience'),
                ),
                16.height,
                DropdownButtonFormField<CareerLevel>(
                  decoration: inputDecoration(context, labelText: 'Career level'),
                  isExpanded: true,
                  initialValue: CareerLevel.values.contains(selectedCareerLevel) ? selectedCareerLevel : CareerLevel.notSpecified,
                  dropdownColor: context.cardColor,
                  items: CareerLevel.values.map((CareerLevel e) {
                    return DropdownMenuItem<CareerLevel>(
                      value: e,
                      child: Text(e.displayName, style: primaryTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (CareerLevel? value) {
                    hideKeyboard(context);
                    if (value != null) {
                      selectedCareerLevel = value;
                      setState(() {});
                    }
                  },
                ),
                16.height,
                DropdownButtonFormField<EducationLevel>(
                  decoration: inputDecoration(context, labelText: 'Education'),
                  isExpanded: true,
                  initialValue: EducationLevel.values.contains(selectedEducation) ? selectedEducation : EducationLevel.notSpecified,
                  dropdownColor: context.cardColor,
                  items: EducationLevel.values.map((EducationLevel e) {
                    return DropdownMenuItem<EducationLevel>(
                      value: e,
                      child: Text(e.displayName, style: primaryTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (EducationLevel? value) {
                    hideKeyboard(context);
                    if (value != null) {
                      selectedEducation = value;
                      setState(() {});
                    }
                  },
                ),
                16.height,
                DropdownButtonFormField<YearsOfExperience>(
                  decoration: inputDecoration(context, labelText: 'Years of experience'),
                  isExpanded: true,
                  initialValue: selectedYearsOfExperience,
                  dropdownColor: context.cardColor,
                  items: YearsOfExperience.values.map((YearsOfExperience e) {
                    return DropdownMenuItem<YearsOfExperience>(
                      value: e,
                      child: Text(e.displayName, style: primaryTextStyle(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (YearsOfExperience? value) {
                    hideKeyboard(context);
                    if (value != null) {
                      selectedYearsOfExperience = value;
                      setState(() {});
                    }
                  },
                ),
                16.height,
                AppTextField(
                  textFieldType: TextFieldType.OTHER,
                  controller: certificationCont,
                  focus: certificationFocus,
                  nextFocus: aboutMeFocus,
                  enabled: !isLoginTypeApple,
                  decoration: inputDecoration(context,
                      labelText: 'Certification',
                      hintText: 'e.g. Cert 1, Cert 2 (comma-separated)'),
                  isValidationRequired: false,
                ),
                16.height,
                AppTextField(
                  textFieldType: TextFieldType.NAME,
                  controller: aboutMeCont,
                  focus: aboutMeFocus,
                  errorThisFieldRequired: language.requiredText,
                  enabled: !isLoginTypeApple,
                  maxLines: 4,
                  decoration: inputDecoration(context, labelText: 'About me'),
                ),
                40.height,
                GradientButton(
                  onPressed: () {
                    ifNotTester(() {
                      update();
                    });
                  },
                  child: Text(language.save, style: boldTextStyle(color: white)),
                ).withWidth(context.width() - context.navigationBarHeight),
                24.height,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
