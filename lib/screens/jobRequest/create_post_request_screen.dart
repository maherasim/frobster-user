import 'dart:io';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/custom_image_picker.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/state_list_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/category_sub_cat_drop_down.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/component/gradient_button.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../app_theme.dart';
import '../../component/chat_gpt_loder.dart';
import '../../model/city_list_model.dart';
import '../../model/country_list_model.dart';
import '../../model/get_my_post_job_list_response.dart';
import '../../utils/configs.dart';
import '../../utils/colors.dart';
import '../../utils/getImage.dart';

class CreatePostRequestScreen extends StatefulWidget {
  final PostJobData? editJob;

  const CreatePostRequestScreen({super.key, this.editJob});
  @override
  _CreatePostRequestScreenState createState() => _CreatePostRequestScreenState();
}

class _CreatePostRequestScreenState extends State<CreatePostRequestScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  int currentStep = 0;
  final List<String> _steps = const ['Basics', 'Location', 'Schedule', 'Details'];

  TextEditingController postTitleCont = TextEditingController();

  TextEditingController priceCont = TextEditingController();
  TextEditingController totalBudgetCont = TextEditingController();
  TextEditingController startDateCont = TextEditingController();
  String? selStartDate;
  TextEditingController endDateCont = TextEditingController();
  String? selEndDate;
  TextEditingController totalDaysCont = TextEditingController();
  TextEditingController totalHoursCont = TextEditingController();


  TextEditingController descriptionCont = TextEditingController();
  TextEditingController streetAddressCont = TextEditingController();
  TextEditingController poboxAddressCont = TextEditingController();
  TextEditingController requirementsCont = TextEditingController();
  TextEditingController dutiesCont = TextEditingController();
  TextEditingController benefitsCont = TextEditingController();

  FocusNode descriptionFocus = FocusNode();
  FocusNode streetAddressFocus = FocusNode();
  FocusNode poboxAddressFocus = FocusNode();
  FocusNode requirementsFocus = FocusNode();
  FocusNode dutiesFocus = FocusNode();
  FocusNode benefitsFocus = FocusNode();
  FocusNode priceFocus = FocusNode();

  int? categoryId = -1;
  int? subCategoryId = -1;
  PriceType selectedPriceType = PriceType.hourly;
  JobType selectedJobType = JobType.onSite;
  JobSchedule selectedJobSchedule = JobSchedule.fullTime;
  RemoteWorkLevel selectedRemoteWorkLevel = RemoteWorkLevel.onsite0;
  CareerLevel selectedCareerLevel = CareerLevel.intern;
  TravelRequirement selectedTravelRequirement = TravelRequirement.no;
  EducationLevel selectedEducationLevel = EducationLevel.highSchool;


  // List<ServiceData> myServiceList = [];
  // List<ServiceData> selectedServiceList = [];

  Country selectedCountryCode = defaultCountry();

  CountryListResponse? selectedCountry;
  StateListResponse? selectedState;
  CityListResponse? selectedCity;

  int countryId = 0;
  int stateId = 0;
  int cityId = 0;

  List<CountryListResponse> countryList = [];
  List<StateListResponse> stateList = [];
  List<CityListResponse> cityList = [];
  List<XFile> _images = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> pickImages() async {
    GetMultipleImage(
      path: (List<XFile> pickedFiles) {
        if (pickedFiles.isNotEmpty) {
          setState(() {
            _images = pickedFiles;
          });
        }
      },
    );
  }

  Future<void> removeImage(int index) async {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate,
      {String? initialDate}) async {
    DateTime today = DateTime.now(); // Get today's date
    DateTime? pickedDate = await showDatePicker(
      context: context,
      builder: (_, child) {
        return Theme(
          data: appStore.isDarkMode ? ThemeData.dark() : AppTheme.lightTheme(),
          child: child!,
        );
      },
      initialDate: initialDate != null && initialDate.validate().isNotEmpty
          ? DateTime.parse(initialDate)
          : today, // Set initial date to today
      firstDate: today, // Prevent selecting past dates
      lastDate: DateTime(2100), // Set an upper limit
    );

    if (pickedDate != null && pickedDate != today) {
      if (isStartDate) {
        selStartDate = pickedDate.toIso8601String();
        startDateCont.text = DateFormat("MM/dd/yy").format(pickedDate);
      } else {
        selEndDate = pickedDate.toIso8601String();
        endDateCont.text = DateFormat("MM/dd/yy").format(pickedDate);
      }
      if ((selStartDate != null && selStartDate.validate().isNotEmpty) &&
          (selEndDate != null && selEndDate.validate().isNotEmpty)) {
        DateTime startDate = DateTime.parse(selStartDate.validate());
        DateTime endDate = DateTime.parse(selEndDate.validate());
        final Duration duration = endDate.difference(startDate) + Duration(days: 1);
        totalDaysCont.text = '${duration.inDays}';
        // totalHoursCont.text = '${8 * duration.inDays}';
        setTotalBudget();
      }
      print("Selected Date: ${pickedDate.toLocal()}");
    }
  }

  bool isLoading = true;

  Future<void> init() async {
    appStore.setLoading(true);
    if(widget.editJob != null) {
      final postJobDetails = await getEditPostJobDetail(widget.editJob!.id.validate());
      print(postJobDetails.postRequestDetail);
      print(postJobDetails.postRequestDetail!=null);
      print("postJobDetails.postRequestDetail");
      if(postJobDetails.postRequestDetail != null) {
        final details = postJobDetails.postRequestDetail!;
        imageFiles = details.images
            .validate()
            .map((e) => File(e.toString()))
            .toList();
        postTitleCont.text = details.title ?? '';
        countryId = details.countryId ?? 0;
        stateId = details.stateId ?? 0;
        cityId = details.cityId ?? 0;
        categoryId = details.categoryId;
        subCategoryId = details.subCategoryId;
        priceCont.text = details.price.validate().toString();
        selectedPriceType = details.priceType ?? PriceType.hourly;
        final startDate = DateTime.tryParse(details.startDate.validate());
        if(startDate != null) {
          selStartDate = startDate.toIso8601String();
          startDateCont.text = DateFormat("MM/dd/yy").format(startDate);
        }
        final endDate = DateTime.tryParse(details.endDate.validate());
        if(endDate != null) {
          selEndDate = endDate.toIso8601String();
          endDateCont.text = DateFormat("MM/dd/yy").format(endDate);
        }
        totalDaysCont.text = details.totalDays.validate().toString();
        totalHoursCont.text = details.totalHours.validate().toString();
        totalBudgetCont.text = details.totalBudget.validate().toString();
        selectedJobType = details.type ?? JobType.onSite;
        selectedJobSchedule = details.jobSchedule ?? JobSchedule.fullTime;
        selectedCareerLevel = details.careerLevel ?? CareerLevel.intern;
        selectedRemoteWorkLevel = details.remoteWorkLevel ?? RemoteWorkLevel.onsite0;
        selectedTravelRequirement = details.travelRequired ?? TravelRequirement.no;
        selectedEducationLevel = details.educationLevel ?? EducationLevel.highSchool;
        descriptionCont.text = details.description.validate();
        streetAddressCont.text = details.streetAddress.validate();
        poboxAddressCont.text = details.houseNumber.validate();
        requirementsCont.text = details.requirement.validate();
        dutiesCont.text = details.duties.validate();
        benefitsCont.text = details.benefits.validate();
      }
    }
    await getCountryStateCityData();
    isLoading = false;
    appStore.setLoading(false);
    setState(() {});
  }

  getCountryStateCityData() async {
    if (countryId != 0) {
      await getCountry();
      await getStates(countryId);
      if (stateId != 0) {
        await getCity(stateId);
      }
      setState(() {});
    } else {
      await getCountry();
    }
  }

  Future<void> getCountry() async {
    appStore.setLoading(true);
    await getUpdatedCountryList().then((value) async {
      countryList.clear();
      countryList.addAll(value);

      if (value.any((element) => element.id == countryId)) {
        selectedCountry = value.firstWhere((element) => element.id == countryId);
      }
      setState(() {});
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> getStates(int countryId) async {
    appStore.setLoading(true);
    await getUpdatedStateList(countryId).then((value) async {
      stateList.clear();
      stateList.addAll(value);

      if (value.any((element) => element.id == stateId)) {
        selectedState =
            value.firstWhere((element) => element.id == stateId);
      }
      setState(() {});
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }

  Future<void> getCity(int stateId) async {
    appStore.setLoading(true);

    await getUpdatedCityList(stateId).then((value) async {
      cityList.clear();
      cityList.addAll(value);

      if (value.any((element) => element.id == cityId)) {
        selectedCity =
            value.firstWhere((element) => element.id == cityId);
      }
      setState(() {});
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
  }


  void createPostJobClick() {
    appStore.setLoading(true);
    // List<int> serviceList = [];

    // if (selectedServiceList.isNotEmpty) {
    //   selectedServiceList.forEach((element) {
    //     serviceList.add(element.id.validate());
    //   });
    // }

    final totalHours = num.tryParse(totalHoursCont.text.split(' ').first);
    final totalDays = num.tryParse(totalDaysCont.text.split(' ').first);
    num? totalBudget = num.tryParse(priceCont.text);
    if(selectedPriceType == PriceType.hourly){
      totalBudget = totalBudget! * (totalHours.validate().toInt());
    } else if(selectedPriceType == PriceType.daily) {
      totalBudget = totalBudget! * (totalDays.validate().toInt());
    } else {
      totalBudget = totalBudget;
    }

    PostJobData request = PostJobData(
      id: widget.editJob?.id,
      title: postTitleCont.text.validate(),
      description: descriptionCont.text.validate(),
      price: priceCont.text.validate().toDouble(),
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      type: selectedJobType, // On Site, Hybrid, Remote

      images: [],
      countryId: selectedCountry?.id.validate(),
      stateId: selectedState?.id.validate(),
      cityId: selectedCity?.id.validate(),

      status: RequestStatus.requested,
      latitude: appStore.latitude,
      longitude: appStore.longitude,

      startDate: selStartDate.validate(),
      endDate: selEndDate.validate(),
      totalDays: totalDays,
      totalHours: totalHours,

      requirement: requirementsCont.text.validate(),

      priceType: selectedPriceType,
      jobSchedule: selectedJobSchedule,
      remoteWorkLevel: selectedRemoteWorkLevel,
      careerLevel: selectedCareerLevel,
      travelRequired: selectedTravelRequirement,
      educationLevel: selectedEducationLevel,
      streetAddress: streetAddressCont.text.validate(),
      houseNumber: poboxAddressCont.text.validate(),
      duties: dutiesCont.text.validate(),
      benefits: benefitsCont.text.validate(),
      totalBudget: totalBudget,

      service: [],
    );


    savePostJob(request.toJsonForCreate(),imageFiles: imageFiles);
  }

  void deleteService(ServiceData data) {
    appStore.setLoading(true);

    deleteServiceRequest(data.id.validate()).then((value) {
      appStore.setLoading(false);
      toast(value.message.validate());
      init();
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }


  setTotalBudget() {
    final totalHours = num.tryParse(totalHoursCont.text.split(' ').first);
    final totalDays = num.tryParse(totalDaysCont.text.split(' ').first);

    num? totalBudget = num.tryParse(priceCont.text);

    if(selectedPriceType == PriceType.hourly){
      totalBudget = totalBudget! * (totalHours.validate(value: 1).toInt());
    } else if(selectedPriceType == PriceType.daily) {
      totalBudget = totalBudget! * (totalDays.validate(value: 1).toInt());
    } else {
      totalBudget = totalBudget;
    }

    totalBudgetCont.text = totalBudget.toString();
  }

  List<File> imageFiles = [];

  UniqueKey uniqueKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hideKeyboard(context),
      child: AppScaffold(
        appBarTitle: language.newPostJobRequest,
        child: isLoading ? Loader() : Stack(
          children: [
            AnimatedScrollView(
              listAnimationType: ListAnimationType.FadeIn,
              fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
              padding: EdgeInsets.only(bottom: 60),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStepper().paddingAll(16),
                    Text(_stepHint(), style: secondaryTextStyle())
                        .paddingSymmetric(horizontal: 16),
                    Form(
                      key: formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          16.height,
                          if (currentStep == 3)
                            CustomImagePicker(
                              key: uniqueKey,
                              isMultipleImages: true,
                              canEdit: widget.editJob == null,
                              onRemoveClick: (value) {
                                showConfirmDialogCustom(
                                  context,
                                  dialogType: DialogType.DELETE,
                                  positiveText: language.lblDelete,
                                  negativeText: language.lblCancel,
                                  onAccept: (p0) {
                                    imageFiles.removeWhere((element) => element.path == value);
                                    setState(() {});
                                  },
                                );
                              },
                              selectedImages:  imageFiles.validate().map((e) => e.path.validate()).toList(),
                              onFileSelected: (List<File> files) async {
                                imageFiles = files;
                                setState(() {});
                              },
                            ),
                          16.height,
                          if (currentStep == 0)
                            AppTextField(
                              controller: postTitleCont,
                              textFieldType: TextFieldType.NAME,
                              errorThisFieldRequired: language.requiredText,
                              nextFocus: priceFocus,
                              decoration: inputDecoration(
                                context,
                                labelText: language.postJobTitle,
                              ),
                            ),
                          16.height,
                          if (currentStep == 1)
                            Row(
                              children: [
                                DropdownButtonFormField<CountryListResponse>(
                                  decoration: inputDecoration(
                                    context,
                                    labelText: language.country,
                                  ),
                                  isExpanded: true,
                                  menuMaxHeight: 300,
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
                                    if (value == null) return;
                                    countryId = value.id!;
                                    selectedCountry = value;
                                    selectedState = null;
                                    selectedCity = null;
                                    setState(() {});

                                    getStates(value.id!);
                                  },
                                ).expand(),
                                8.width.visible(stateList.isNotEmpty),
                                if (stateList.isNotEmpty) DropdownButtonFormField<StateListResponse>(
                                  decoration: inputDecoration(
                                    context,
                                    labelText: language.state,
                                  ),
                                  isExpanded: true,
                                  dropdownColor: context.cardColor,
                                  menuMaxHeight: 300,
                                  initialValue: selectedState,
                                  items: stateList.map((StateListResponse e) {
                                    return DropdownMenuItem<StateListResponse>(
                                      value: e,
                                      child: Text(e.name!,
                                          style: primaryTextStyle(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (StateListResponse? value) async {
                                    selectedCity = null;
                                    selectedState = value;
                                    stateId = value!.id!;
                                    setState(() {});

                                    getCity(value.id!);
                                  },
                                ).expand(),
                              ],
                            ),
                          16.height,
                          if (currentStep == 1 && cityList.isNotEmpty)
                            Column(
                              children: [
                                DropdownButtonFormField<CityListResponse>(
                                  decoration: inputDecoration(
                                    context,
                                    labelText: language.city,
                                  ),
                                  isExpanded: true,
                                  menuMaxHeight: 400,
                                  initialValue: selectedCity,
                                  dropdownColor: context.cardColor,
                                  items: cityList.map(
                                        (CityListResponse e) {
                                      return DropdownMenuItem<CityListResponse>(
                                        value: e,
                                        child: Text(
                                          e.name!,
                                          style: primaryTextStyle(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    },
                                  ).toList(),
                                  onChanged: (CityListResponse? value) async {
                                    selectedCity = value;
                                    cityId = value!.id!;
                                    setState(() {});
                                  },
                                ),
                                16.height,
                              ],
                            ),
                          if (currentStep == 0)
                            CategorySubCatDropDown(
                              categoryId: categoryId == -1 ? null : categoryId,
                              subCategoryId: subCategoryId == -1 ? null : subCategoryId,
                              isCategoryValidate: true,
                              onCategorySelect: (int? val) {
                                categoryId = val!;
                                setState(() {});
                              },
                              onSubCategorySelect: (int? val) {
                                subCategoryId = val!;
                                setState(() {});
                              },
                            ),
                          16.height,
                          if (currentStep == 2)
                            Row(
                              children: [
                                Flexible(
                                  child: DropdownButtonFormField<PriceType>(
                                    decoration: inputDecoration(context, labelText: language.priceType),
                                    isExpanded: true,
                                    initialValue: selectedPriceType,
                                    dropdownColor: context.cardColor,
                                    items: PriceType.values.map((PriceType e) {
                                      return DropdownMenuItem<PriceType>(
                                        value: e,
                                        child: Text(e.displayName,
                                            style: primaryTextStyle(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (PriceType? value) async {
                                      hideKeyboard(context);
                                      if(value == null) return;
                                      selectedPriceType = value;
                                      setTotalBudget();
                                      setState(() {});
                                    },
                                  ),
                                ),
                                8.width,
                                Expanded(
                                  child: DropdownButtonFormField<JobType>(
                                    decoration: inputDecoration(
                                      context,
                                      labelText:  language.jobType,
                                    ),
                                    isExpanded: true,
                                    initialValue: selectedJobType,
                                    dropdownColor: context.cardColor,
                                    items: JobType.values.map((JobType e) {
                                      return DropdownMenuItem<JobType>(
                                        value: e,
                                        child: Text(e.displayName,
                                            style: primaryTextStyle(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (JobType? value) async {
                                      hideKeyboard(context);
                                      if(value == null) return;
                                      selectedJobType = value;
                                      setState(() {});
                                    },
                                  ),
                                )
                              ],
                            ),
                          16.height,
                          if (currentStep == 2)
                            AppTextField(
                              textFieldType: TextFieldType.PHONE,
                              controller: priceCont,
                              focus: priceFocus,
                              errorThisFieldRequired: language.requiredText,
                              decoration: inputDecoration(context,
                                  labelText: language.price).copyWith(
                                prefix: Text('${appConfigurationStore.currencySymbol} '),
                              ),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                              onChanged: (value) {
                                setTotalBudget();
                              },
                              validator: (s) {
                                if (s!.isEmpty)
                                  return errorThisFieldRequired;

                                if (s.toDouble() <= 0)
                                  return language
                                      .priceAmountValidationMessage;
                                return null;
                              },
                            ),
                          16.height,
                          // 16.height,
                          // Align(
                          //   alignment: Alignment.topLeft,
                          //   child: Text(
                          //     'Select Date:',
                          //     textAlign: TextAlign.start,
                          //     style: primaryTextStyle(size: 16),
                          //   ),
                          // ),
                          if (currentStep == 2)
                            Row(
                              children: [
                                Flexible(
                                  child: AppTextField(
                                    textFieldType: TextFieldType.OTHER,
                                    controller: startDateCont,
                                    readOnly: true,
                                    onTap: () => _selectDate(context, true,
                                        initialDate: selStartDate),
                                    errorThisFieldRequired: language.requiredText,
                                    decoration: inputDecoration(
                                      context,
                                      prefixIcon:
                                      Icon(Icons.calendar_month_rounded),
                                      labelText: language.startDate,
                                    ),
                                    keyboardType: TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                    validator: (s) {
                                      if (selStartDate == null ||
                                          selStartDate!.isEmpty)
                                        return errorThisFieldRequired;

                                      return null;
                                    },
                                    onChanged: (value) {
                                      setTotalBudget();
                                    },
                                  ),
                                ),
                                8.width,
                                Flexible(
                                  child: AppTextField(
                                    textFieldType: TextFieldType.OTHER,
                                    controller: endDateCont,
                                    readOnly: true,
                                    onTap: () => _selectDate(context, false, initialDate: selEndDate),
                                    errorThisFieldRequired: language.requiredText,
                                    decoration: inputDecoration(
                                      context,
                                      prefixIcon:
                                      Icon(Icons.calendar_month_rounded),
                                      labelText: language.endDate,
                                    ),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                                    validator: (s) {
                                      if (selEndDate == null || selEndDate!.isEmpty)
                                        return errorThisFieldRequired;

                                      return null;
                                    },
                                    onChanged: (value) {
                                      setTotalBudget();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          16.height,
                          if (currentStep == 2)
                            Row(
                              children: [
                                Flexible(
                                  child: AppTextField(
                                    textFieldType: TextFieldType.NUMBER,
                                    controller: totalDaysCont,
                                    errorThisFieldRequired: language.requiredText,
                                    decoration: inputDecoration(
                                      context,
                                      prefixIcon: Icon(Icons.timelapse_rounded),
                                      labelText: language.totalDays,
                                    ),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                                    validator: (s) {
                                      if (totalDaysCont.text.isEmpty)
                                        return errorThisFieldRequired;
                                      return null;
                                    },
                                    onChanged: (_) {
                                      setTotalBudget();
                                    },
                                  ),
                                ),
                                8.width,
                                Flexible(
                                  child: AppTextField(
                                    textFieldType: TextFieldType.NUMBER,
                                    controller: totalHoursCont,
                                    errorThisFieldRequired: language.requiredText,
                                    decoration: inputDecoration(
                                      context,
                                      prefixIcon: Icon(Icons.timer_outlined),
                                      labelText: language.totalHours,
                                    ),
                                    keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                                    validator: (s) {
                                      if (totalDaysCont.text.isEmpty)
                                        return errorThisFieldRequired;
                                      return null;
                                    },
                                    onChanged: (_) {
                                      setTotalBudget();
                                    },
                                  ),
                                ),
                              ],
                            ),

                          16.height,
                          if (currentStep == 2)
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    textFieldType: TextFieldType.PHONE,
                                    controller: totalBudgetCont,
                                    isValidationRequired: false,
                                    readOnly: true,
                                    errorThisFieldRequired: language.requiredText,
                                    decoration: inputDecoration(context, labelText: language.totalBudget).copyWith(
                                      prefix: Text('${appConfigurationStore.currencySymbol} '),
                                    ),
                                    keyboardType: TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    ),
                                  ),
                                ),
                                8.width,
                                Expanded(
                                  child: DropdownButtonFormField<JobSchedule>(
                                    decoration: inputDecoration(
                                      context,
                                      labelText: language.jobSchedule,
                                    ),
                                    isExpanded: true,
                                    initialValue: selectedJobSchedule,
                                    dropdownColor: context.cardColor,
                                    items: JobSchedule.values.map((JobSchedule e) {
                                      return DropdownMenuItem<JobSchedule>(
                                        value: e,
                                        child: Text(e.displayName,
                                            style: primaryTextStyle(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (JobSchedule? value) async {
                                      hideKeyboard(context);
                                      if(value == null) return;
                                      selectedJobSchedule = value;
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          16.height,
                          if (currentStep == 2)
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<RemoteWorkLevel>(
                                    decoration: inputDecoration(
                                      context,
                                      labelText: language.remoteWorkLevel,
                                    ),
                                    isExpanded: true,
                                    initialValue: selectedRemoteWorkLevel,
                                    dropdownColor: context.cardColor,
                                    items: RemoteWorkLevel.values.map((RemoteWorkLevel e) {
                                      return DropdownMenuItem<RemoteWorkLevel>(
                                        value: e,
                                        child: Text(e.displayName,
                                            style: primaryTextStyle(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (RemoteWorkLevel? value) async {
                                      hideKeyboard(context);
                                      if(value == null) return;
                                      selectedRemoteWorkLevel = value;
                                      setState(() {});
                                    },
                                  ),
                                ),
                                8.width,
                                Expanded(
                                  child: DropdownButtonFormField<CareerLevel>(
                                    decoration: inputDecoration(
                                      context,
                                      labelText: language.careerLevel,
                                    ),
                                    isExpanded: true,
                                    initialValue: selectedCareerLevel,
                                    dropdownColor: context.cardColor,
                                    items: CareerLevel.values.map((CareerLevel e) {
                                      return DropdownMenuItem<CareerLevel>(
                                        value: e,
                                        child: Text(e.displayName,
                                            style: primaryTextStyle(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (CareerLevel? value) async {
                                      hideKeyboard(context);
                                      if(value == null) return;
                                      selectedCareerLevel = value;
                                      setState(() {});
                                    },
                                  ),
                                ),

                              ],
                            ),
                          16.height,
                          if (currentStep == 2)
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<TravelRequirement>(
                                    decoration: inputDecoration(
                                      context,
                                      labelText: language.travelRequirements,
                                    ),
                                    isExpanded: true,
                                    initialValue: selectedTravelRequirement,
                                    dropdownColor: context.cardColor,
                                    items: TravelRequirement.values.map((TravelRequirement e) {
                                      return DropdownMenuItem<TravelRequirement>(
                                        value: e,
                                        child: Text(e.displayName,
                                            style: primaryTextStyle(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (TravelRequirement? value) async {
                                      hideKeyboard(context);
                                      if(value == null) return;
                                      selectedTravelRequirement = value;
                                      setState(() {});
                                    },
                                  ),
                                ),

                                8.width,
                                Expanded(
                                  child:  DropdownButtonFormField<EducationLevel>(
                                    decoration: inputDecoration(
                                      context,
                                      labelText: language.educationLevel,
                                    ),
                                    isExpanded: true,
                                    initialValue: selectedEducationLevel,
                                    dropdownColor: context.cardColor,
                                    items: EducationLevel.values.map((EducationLevel e) {
                                      return DropdownMenuItem<EducationLevel>(
                                        value: e,
                                        child: Text(e.displayName,
                                            style: primaryTextStyle(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                      );
                                    }).toList(),
                                    onChanged: (EducationLevel? value) async {
                                      hideKeyboard(context);
                                      if(value == null) return;
                                      selectedEducationLevel = value;
                                      setState(() {});
                                    },
                                  ),
                                )
                              ],
                            ),
                          16.height,
                          if (currentStep == 1)
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                language.workingAddress,
                                textAlign: TextAlign.start,
                                style: primaryTextStyle(size: 16),
                              ),
                            ),
                          16.height,
                          if (currentStep == 1)
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: streetAddressCont,
                                    textFieldType: TextFieldType.NAME,
                                    isValidationRequired: false,
                                    maxLines: 1,
                                    focus: streetAddressFocus,
                                    nextFocus: poboxAddressFocus,
                                    decoration: inputDecoration(
                                      context,
                                      labelText: language.streetAndHouseNr,
                                    ),
                                  ),
                                ),
                                16.width,
                                Expanded(
                                  child: AppTextField(
                                    controller: poboxAddressCont,
                                    textFieldType: TextFieldType.NAME,
                                    isValidationRequired: false,
                                    maxLines: 1,
                                    focus: poboxAddressFocus,
                                    nextFocus: requirementsFocus,
                                    decoration: inputDecoration(
                                      context,
                                      labelText: language.poboxAndCityCountry,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          16.height,
                          if (currentStep == 3)
                            AppTextField(
                              controller: descriptionCont,
                              textFieldType: TextFieldType.MULTILINE,
                              isValidationRequired: false,
                              maxLines: 2,
                              focus: descriptionFocus,
                              nextFocus: streetAddressFocus,
                              enableChatGPT: appConfigurationStore.chatGPTStatus,
                              promptFieldInputDecorationChatGPT: inputDecoration(context).copyWith(
                                hintText: language.writeHere,
                                fillColor: context.scaffoldBackgroundColor,
                                filled: true,
                              ),
                              testWithoutKeyChatGPT: false,
                              loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
                              decoration: inputDecoration(
                                context,
                                labelText: language.postJobDescription,
                              ),

                            ),
                          16.height,
                          if (currentStep == 3)
                            AppTextField(
                              controller: requirementsCont,
                              focus: requirementsFocus,
                              nextFocus: dutiesFocus,
                              textFieldType: TextFieldType.MULTILINE,
                              errorThisFieldRequired: language.requiredText,
                              maxLines: 2,
                              enableChatGPT: appConfigurationStore.chatGPTStatus,
                              promptFieldInputDecorationChatGPT: inputDecoration(context).copyWith(
                                hintText: language.writeHere,
                                fillColor: context.scaffoldBackgroundColor,
                                filled: true,
                              ),
                              testWithoutKeyChatGPT: false,
                              loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
                              decoration: inputDecoration(
                                context,
                                labelText: language.skillsAndRequirements,
                              ),
                            ),
                          16.height,
                          if (currentStep == 3)
                            AppTextField(
                              controller: dutiesCont,
                              textFieldType: TextFieldType.MULTILINE,
                              isValidationRequired: false,
                              maxLines: 2,
                              focus: dutiesFocus,
                              nextFocus: benefitsFocus,
                              enableChatGPT: appConfigurationStore.chatGPTStatus,
                              promptFieldInputDecorationChatGPT: inputDecoration(context).copyWith(
                                hintText: language.writeHere,
                                fillColor: context.scaffoldBackgroundColor,
                                filled: true,
                              ),
                              testWithoutKeyChatGPT: false,
                              loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
                              decoration: inputDecoration(
                                context,
                                labelText: language.dutiesAndResponsibilities,
                              ),
                            ),
                          16.height,
                          if (currentStep == 3)
                            AppTextField(
                              controller: benefitsCont,
                              textFieldType: TextFieldType.MULTILINE,
                              isValidationRequired: false,
                              maxLines: 2,
                              focus: benefitsFocus,
                              enableChatGPT: appConfigurationStore.chatGPTStatus,
                              promptFieldInputDecorationChatGPT: inputDecoration(context).copyWith(
                                hintText: language.writeHere,
                                fillColor: context.scaffoldBackgroundColor,
                                filled: true,
                              ),
                              testWithoutKeyChatGPT: false,
                              loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
                              decoration: inputDecoration(
                                context,
                                labelText: language.benefits,
                              ),
                            ),

                        ],
                      ).paddingAll(16),
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //   children: [
                    //     Text(language.services,
                    //         style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                    //     AppButton(
                    //       child: Text(language.addNewService,
                    //           style:
                    //               boldTextStyle(color: context.primaryColor)),
                    //       onTap: () async {
                    //         hideKeyboard(context);

                    //         bool? res =
                    //             await CreateServiceScreen().launch(context);
                    //         if (res ?? false) init();
                    //       },
                    //     ),
                    //   ],
                    // ).paddingOnly(right: 8, left: 16),
                    // if (myServiceList.isNotEmpty)
                    //   AnimatedListView(
                    //     itemCount: myServiceList.length,
                    //     shrinkWrap: true,
                    //     physics: NeverScrollableScrollPhysics(),
                    //     padding: EdgeInsets.all(8),
                    //     listAnimationType: ListAnimationType.FadeIn,
                    //     itemBuilder: (_, i) {
                    //       ServiceData data = myServiceList[i];

                    //       return Container(
                    //         padding: EdgeInsets.all(8),
                    //         margin: EdgeInsets.all(8),
                    //         width: context.width(),
                    //         decoration: boxDecorationWithRoundedCorners(backgroundColor: context.cardColor),
                    //         child: Row(
                    //           children: [
                    //             CachedImageWidget(
                    //               url: data.attachments.validate().isNotEmpty ? data.attachments!.first.validate() : "",
                    //               fit: BoxFit.cover,
                    //               height: 60,
                    //               width: 60,
                    //               radius: defaultRadius,
                    //             ),
                    //             16.width,
                    //             Column(
                    //               crossAxisAlignment: CrossAxisAlignment.start,
                    //               children: [
                    //                 Text(data.name.validate(), style: boldTextStyle()),
                    //                 4.height,
                    //                 Text(data.categoryName.validate(), style: secondaryTextStyle()),
                    //               ],
                    //             ).expand(),
                    //             Column(
                    //               children: [
                    //                 IconButton(
                    //                   icon: ic_edit_square.iconImage(size: 14),
                    //                   visualDensity: VisualDensity.compact,
                    //                   onPressed: () async {
                    //                     bool? res = await CreateServiceScreen(data: data).launch(context);
                    //                     if (res ?? false) init();
                    //                   },
                    //                 ),
                    //                 IconButton(
                    //                   icon: ic_delete.iconImage(size: 14),
                    //                   visualDensity: VisualDensity.compact,
                    //                   onPressed: () {
                    //                     showConfirmDialogCustom(
                    //                       context,
                    //                       dialogType: DialogType.DELETE,
                    //                       positiveText: language.lblDelete,
                    //                       negativeText: language.lblCancel,
                    //                       onAccept: (p0) {
                    //                         // ifNotTester(() {
                    //                         deleteService(data);
                    //                         //});
                    //                       },
                    //                     );
                    //                   },
                    //                 ),
                    //               ],
                    //             ),
                    //             selectedServiceList.any((e) => e.id == data.id)
                    //                 ? AppButton(
                    //                     child: Text(language.remove, style: boldTextStyle(color: redColor, size: 14)),
                    //                     onTap: () {
                    //                       selectedServiceList.remove(data);
                    //                       setState(() {});
                    //                     },
                    //                   )
                    //                 : AppButton(
                    //                     child: Text(language.add, style: boldTextStyle(size: 14, color: context.primaryColor)),
                    //                     onTap: () {
                    //                       selectedServiceList.add(data);
                    //                       setState(() {});
                    //                     },
                    //                   ),
                    //           ],
                    //         ),
                    //       );
                    //     },
                    //   ),
                    // if (myServiceList.isEmpty && !appStore.isLoading)
                    //   NoDataWidget(
                    //     imageWidget: EmptyStateWidget(),
                    //     title: language.noServiceAdded,
                    //     imageSize: Size(90, 90),
                    //   ).paddingOnly(top: 16),
                  ],
                ),
              ],
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Positioned _buildBottomBar() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: Material(
                color: gradientRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      currentStep -= 1;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Center(
                      child: Text('Back', style: boldTextStyle(color: gradientRed)),
                    ),
                  ),
                ),
              ),
            ),
          if (currentStep > 0) 16.width,
          Expanded(
            child: GradientButton(
              onPressed: () {
                hideKeyboard(context);
                if (currentStep == _steps.length - 1) {
                  if (_validateAll()) {
                    createPostJobClick();
                  }
                  return;
                }
                if (_validateStep(currentStep)) {
                  setState(() {
                    currentStep += 1;
                  });
                }
              },
              child: Text(currentStep == _steps.length - 1 ? language.publish : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: List.generate(_steps.length, (i) {
        final bool active = i == currentStep;
        return Expanded(
          child: Column(
            children: [
              Container(
                height: 4,
                decoration: boxDecorationDefault(
                  color: active ? gradientRed : context.dividerColor,
                  borderRadius: radius(12),
                ),
              ),
              6.height,
              Text(_steps[i],
                  style: active ? boldTextStyle(size: 12) : secondaryTextStyle(size: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ).paddingRight(i == _steps.length - 1 ? 0 : 8),
        );
      }),
    );
  }

  String _stepHint() {
    switch (currentStep) {
      case 0:
        return 'Add a clear title and choose category.';
      case 1:
        return 'Set where the work will happen and your address.';
      case 2:
        return 'Choose rate type, dates, and budget. We auto-calc totals.';
      case 3:
        return 'Describe the job and attach images if helpful.';
      default:
        return '';
    }
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (postTitleCont.text.trim().isEmpty) {
        toast(language.requiredText);
        return false;
      }
      if (categoryId == null || categoryId == -1) {
        toast('Please select category');
        return false;
      }
      return true;
    } else if (step == 1) {
      if (selectedCountry == null) {
        toast('Please select country');
        return false;
      }
      if (stateList.isNotEmpty && selectedState == null) {
        toast('Please select state');
        return false;
      }
      if (cityList.isNotEmpty && selectedCity == null) {
        toast('Please select city');
        return false;
      }
      return true;
    } else if (step == 2) {
      if (priceCont.text.trim().isEmpty) {
        toast(language.requiredText);
        return false;
      }
      if (selStartDate.validate().isEmpty || selEndDate.validate().isEmpty) {
        toast('Please select start and end dates');
        return false;
      }
      return true;
    } else {
      if (requirementsCont.text.trim().isEmpty) {
        toast(language.requiredText);
        return false;
      }
      return true;
    }
  }

  bool _validateAll() {
    for (int i = 0; i < _steps.length; i++) {
      if (!_validateStep(i)) {
        setState(() {
          currentStep = i;
        });
        return false;
      }
    }
    return true;
  }
}
