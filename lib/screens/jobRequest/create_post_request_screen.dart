import 'dart:io';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
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
  List<String> get _steps => [language.stepBasics, language.stepLocation, language.stepSchedule, language.stepDetails];

  TextEditingController postTitleCont = TextEditingController();

  TextEditingController priceCont = TextEditingController();
  TextEditingController totalBudgetCont = TextEditingController();
  TextEditingController startDateCont = TextEditingController();
  String? selStartDate;
  TextEditingController endDateCont = TextEditingController();
  String? selEndDate;
  TextEditingController totalDaysCont = TextEditingController();
  TextEditingController totalHoursCont = TextEditingController();


  TextEditingController streetAddressCont = TextEditingController();
  TextEditingController poboxAddressCont = TextEditingController();

  // Rich-text controllers (output HTML on save)
  QuillController descriptionController = QuillController.basic();
  QuillController requirementsController = QuillController.basic();
  QuillController dutiesController = QuillController.basic();
  QuillController benefitsController = QuillController.basic();

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
  CareerLevel selectedCareerLevel = CareerLevel.notSpecified;
  TravelRequirement selectedTravelRequirement = TravelRequirement.no;
  EducationLevel selectedEducationLevel = EducationLevel.notSpecified;


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
        selectedCareerLevel = details.careerLevel ?? CareerLevel.notSpecified;
        selectedRemoteWorkLevel = details.remoteWorkLevel ?? RemoteWorkLevel.onsite0;
        selectedTravelRequirement = details.travelRequired ?? TravelRequirement.no;
        selectedEducationLevel = details.educationLevel ?? EducationLevel.notSpecified;
        if (!EducationLevel.values.contains(selectedEducationLevel)) {
          selectedEducationLevel = EducationLevel.notSpecified;
        }
        _setControllerText(descriptionController, details.description.validate());
        streetAddressCont.text = details.streetAddress.validate();
        poboxAddressCont.text = details.houseNumber.validate();
        _setControllerText(requirementsController, details.requirement.validate());
        _setControllerText(dutiesController, details.duties.validate());
        _setControllerText(benefitsController, details.benefits.validate());
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
      description: _controllerToHtml(descriptionController),
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

      requirement: _controllerToHtml(requirementsController),

      priceType: selectedPriceType,
      jobSchedule: selectedJobSchedule,
      remoteWorkLevel: selectedRemoteWorkLevel,
      careerLevel: selectedCareerLevel,
      travelRequired: selectedTravelRequirement,
      educationLevel: selectedEducationLevel,
      streetAddress: streetAddressCont.text.validate(),
      houseNumber: poboxAddressCont.text.validate(),
      duties: _controllerToHtml(dutiesController),
      benefits: _controllerToHtml(benefitsController),
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
                                        child: Text(
                                          switch (e) {
                                            PriceType.hourly => language.lblPriceHourly,
                                            PriceType.fixed => language.lblPriceFixed,
                                            PriceType.daily => language.lblPriceDaily,
                                          },
                                          style: primaryTextStyle(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                        child: Text(
                                          switch (e) {
                                            JobType.onSite => language.visitTypeOnsite,
                                            JobType.hybrid => language.visitTypeHybrid,
                                            JobType.remote => language.visitTypeRemote,
                                          },
                                          style: primaryTextStyle(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                      if (totalHoursCont.text.isEmpty)
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
                                        child: Text(
                                          switch (e) {
                                            JobSchedule.fullTime => language.lblScheduleFullTime,
                                            JobSchedule.partTime => language.lblSchedulePartTime,
                                            JobSchedule.contract => language.lblScheduleContract,
                                            JobSchedule.temporary => language.lblScheduleTemporary,
                                            JobSchedule.internship => language.lblScheduleInternship,
                                          },
                                          style: primaryTextStyle(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                        child: Text(
                                          switch (e) {
                                            RemoteWorkLevel.onsite0 => language.onsiteFullPresenceLabel,
                                            RemoteWorkLevel.remote25 => '25% ${language.remoteWorkShareSuffix}',
                                            RemoteWorkLevel.remote50 => '50% ${language.remoteWorkShareSuffix}',
                                            RemoteWorkLevel.remote75 => '75% ${language.remoteWorkShareSuffix}',
                                            RemoteWorkLevel.remote100 => '100% ${language.remoteWorkShareSuffix}',
                                          },
                                          style: primaryTextStyle(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                        child: Text(
                                          switch (e) {
                                            CareerLevel.notSpecified => language.lblCareerNotSpecified,
                                            CareerLevel.entryLevel => language.lblCareerEntryLevel,
                                            CareerLevel.intermediateLevel => language.lblCareerIntermediateLevel,
                                            CareerLevel.experienced => language.lblCareerExperienced,
                                            CareerLevel.professional => language.lblCareerProfessional,
                                            CareerLevel.middleManagement => language.lblCareerMiddleManagement,
                                            CareerLevel.executiveManagement => language.lblCareerExecutiveManagement,
                                            CareerLevel.seniorManagement => language.lblCareerSeniorManagement,
                                            CareerLevel.director => language.lblCareerDirector,
                                            CareerLevel.technician => language.lblCareerTechnician,
                                            CareerLevel.leader => language.lblCareerLeader,
                                            CareerLevel.manager => language.lblCareerManager,
                                          },
                                          style: primaryTextStyle(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                        child: Text(
                                          switch (e) {
                                            TravelRequirement.no => language.lblNo,
                                            TravelRequirement.yes => language.lblYes,
                                          },
                                          style: primaryTextStyle(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                    initialValue: EducationLevel.values.contains(selectedEducationLevel)
                                        ? selectedEducationLevel
                                        : EducationLevel.notSpecified,
                                    dropdownColor: context.cardColor,
                                    items: EducationLevel.values.map((EducationLevel e) {
                                      return DropdownMenuItem<EducationLevel>(
                                        value: e,
                                        child: Text(
                                          switch (e) {
                                            EducationLevel.notSpecified => language.lblEduNotSpecified,
                                            EducationLevel.anyGraduate => language.lblEduAnyGraduate,
                                            EducationLevel.apprenticeshipDegree => language.lblEduApprenticeship,
                                            EducationLevel.traineeshipDegree => language.lblEduTraineeship,
                                            EducationLevel.secondaryDegree => language.lblEduSecondaryDegree,
                                            EducationLevel.undergraduateDiploma => language.lblEduUndergraduate,
                                            EducationLevel.highSchoolGraduate => language.lblEduHighSchool,
                                            EducationLevel.associateDegree => language.lblEduAssociate,
                                            EducationLevel.collegeDegree => language.lblEduCollege,
                                            EducationLevel.universityDegree => language.lblEduUniversity,
                                            EducationLevel.bachelorsDegree => language.lblEduBachelors,
                                            EducationLevel.mastersDegree => language.lblEduMasters,
                                            EducationLevel.doctorateDegree => language.lblEduDoctorate,
                                            EducationLevel.professionalDegree => language.lblEduProfessional,
                                            EducationLevel.notSpecified2 => language.lblEduNotSpecified2,
                                            EducationLevel.anyGraduate2 => language.lblEduAnyGraduate2,
                                            EducationLevel.apprenticeshipDegree2 => language.lblEduApprenticeship2,
                                            EducationLevel.traineeshipDegree2 => language.lblEduTraineeship2,
                                            EducationLevel.secondaryDegree2 => language.lblEduSecondaryDegree2,
                                            EducationLevel.undergraduateDiploma2 => language.lblEduUndergraduate2,
                                          },
                                          style: primaryTextStyle(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                            _buildRichField(
                              label: language.postJobDescription,
                              controller: descriptionController,
                              focusNode: descriptionFocus,
                            ),
                          16.height,
                          if (currentStep == 3)
                            _buildRichField(
                              label: language.skillsAndRequirements,
                              controller: requirementsController,
                              focusNode: requirementsFocus,
                              isRequired: true,
                            ),
                          16.height,
                          if (currentStep == 3)
                            _buildRichField(
                              label: language.dutiesAndResponsibilities,
                              controller: dutiesController,
                              focusNode: dutiesFocus,
                            ),
                          16.height,
                          if (currentStep == 3)
                            _buildRichField(
                              label: language.benefits,
                              controller: benefitsController,
                              focusNode: benefitsFocus,
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
      bottom: 16 + MediaQuery.of(context).padding.bottom,
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
                      child: Text(language.back, style: boldTextStyle(color: gradientRed)),
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
              child: Text(currentStep == _steps.length - 1 ? language.publish : language.next),
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
        return language.stepBasicsHint;
      case 1:
        return language.stepLocationHint;
      case 2:
        return language.stepScheduleHint;
      case 3:
        return language.stepDetailsHint;
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
        toast(language.selectCategory);
        return false;
      }
      return true;
    } else if (step == 1) {
      if (selectedCountry == null) {
        toast(language.selectCountry);
        return false;
      }
      if (stateList.isNotEmpty && selectedState == null) {
        toast(language.selectState);
        return false;
      }
      if (cityList.isNotEmpty && selectedCity == null) {
        toast(language.selectCity);
        return false;
      }
      return true;
    } else if (step == 2) {
      if (priceCont.text.trim().isEmpty) {
        toast(language.requiredText);
        return false;
      }
      if (selStartDate.validate().isEmpty || selEndDate.validate().isEmpty) {
        toast(language.lblSelectStartEndDates);
        return false;
      }
      if (totalHoursCont.text.trim().isEmpty) {
        toast(language.requiredText);
        return false;
      }
      return true;
    } else {
      if (requirementsController.document.toPlainText().trim().isEmpty) {
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

  @override
  void dispose() {
    descriptionController.dispose();
    requirementsController.dispose();
    dutiesController.dispose();
    benefitsController.dispose();
    super.dispose();
  }

  // ── Rich-text helpers ─────────────────────────────────────────────────────

  /// Strip HTML to plain text and load into a QuillController.
  void _setControllerText(QuillController ctrl, String content) {
    if (content.isEmpty) {
      ctrl.clear();
      return;
    }
    final delta = _htmlToDelta(content);
    ctrl.document = Document.fromDelta(delta);
    ctrl.updateSelection(
      TextSelection.collapsed(offset: 0),
      ChangeSource.local,
    );
  }

  Delta _htmlToDelta(String html) {
    final doc = html_parser.parse(html);
    final delta = Delta();
    _processDeltaNodes(doc.body?.nodes ?? [], delta, {});
    final ops = delta.toJson() as List;
    if (ops.isEmpty || !(ops.last['insert'] as String? ?? '').endsWith('\n')) {
      delta.insert('\n');
    }
    return delta;
  }

  void _processDeltaNodes(Iterable<dom.Node> nodes, Delta delta, Map<String, dynamic> inlineAttrs) {
    for (final node in nodes) {
      _processDeltaNode(node, delta, inlineAttrs);
    }
  }

  void _processDeltaNode(dom.Node node, Delta delta, Map<String, dynamic> inlineAttrs) {
    if (node is dom.Text) {
      final text = node.text;
      if (text.isEmpty) return;
      if (inlineAttrs.isEmpty) {
        delta.insert(text);
      } else {
        delta.insert(text, Map.from(inlineAttrs));
      }
    } else if (node is dom.Element) {
      final tag = node.localName ?? '';
      switch (tag) {
        case 'ul':
          for (final child in node.nodes) {
            if (child is dom.Element && child.localName == 'li') {
              _processDeltaNodes(child.nodes, delta, inlineAttrs);
              delta.insert('\n', {'list': 'bullet'});
            }
          }
          break;
        case 'ol':
          for (final child in node.nodes) {
            if (child is dom.Element && child.localName == 'li') {
              _processDeltaNodes(child.nodes, delta, inlineAttrs);
              delta.insert('\n', {'list': 'ordered'});
            }
          }
          break;
        case 'p':
          _processDeltaNodes(node.nodes, delta, inlineAttrs);
          delta.insert('\n');
          break;
        case 'br':
          delta.insert('\n');
          break;
        case 'strong':
        case 'b':
          _processDeltaNodes(node.nodes, delta, {...inlineAttrs, 'bold': true});
          break;
        case 'em':
        case 'i':
          _processDeltaNodes(node.nodes, delta, {...inlineAttrs, 'italic': true});
          break;
        case 'u':
          _processDeltaNodes(node.nodes, delta, {...inlineAttrs, 'underline': true});
          break;
        case 's':
        case 'strike':
          _processDeltaNodes(node.nodes, delta, {...inlineAttrs, 'strike': true});
          break;
        default:
          _processDeltaNodes(node.nodes, delta, inlineAttrs);
      }
    }
  }

  /// Convert a QuillController's document to HTML for API submission.
  String _controllerToHtml(QuillController ctrl) {
    final plainText = ctrl.document.toPlainText();
    if (plainText.trim().isEmpty) return '';

    final ops = ctrl.document.toDelta().toJson() as List<dynamic>;
    final html = StringBuffer();
    final lineBuf = StringBuffer();
    bool inUl = false, inOl = false;

    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    void flushLine(String? listType) {
      final content = lineBuf.toString();
      lineBuf.clear();
      if (listType == 'bullet') {
        if (inOl) { html.write('</ol>'); inOl = false; }
        if (!inUl) { html.write('<ul>'); inUl = true; }
        html.write('<li>$content</li>');
      } else if (listType == 'ordered') {
        if (inUl) { html.write('</ul>'); inUl = false; }
        if (!inOl) { html.write('<ol>'); inOl = true; }
        html.write('<li>$content</li>');
      } else {
        if (inUl) { html.write('</ul>'); inUl = false; }
        if (inOl) { html.write('</ol>'); inOl = false; }
        html.write('$content<br>');
      }
    }

    String applyInline(String text, Map<String, dynamic>? attrs) {
      String result = esc(text);
      if (attrs == null) return result;
      if (attrs['bold'] == true) result = '<strong>$result</strong>';
      if (attrs['italic'] == true) result = '<em>$result</em>';
      if (attrs['underline'] == true) result = '<u>$result</u>';
      if (attrs['strike'] == true) result = '<s>$result</s>';
      return result;
    }

    for (final rawOp in ops) {
      final op = rawOp as Map<String, dynamic>;
      final insert = op['insert'];
      if (insert is! String) continue;
      final attrs = op['attributes'] as Map<String, dynamic>?;
      final listType = attrs?['list'] as String?;

      final segments = insert.split('\n');
      for (int i = 0; i < segments.length; i++) {
        if (segments[i].isNotEmpty) {
          lineBuf.write(applyInline(segments[i], attrs));
        }
        if (i < segments.length - 1) {
          flushLine(listType);
        }
      }
    }

    if (lineBuf.isNotEmpty) {
      if (inUl) { html.write('</ul>'); inUl = false; }
      if (inOl) { html.write('</ol>'); inOl = false; }
      html.write(lineBuf.toString());
    } else {
      if (inUl) html.write('</ul>');
      if (inOl) html.write('</ol>');
    }

    String result = html.toString();
    while (result.endsWith('<br>')) {
      result = result.substring(0, result.length - 4);
    }
    return result;
  }

  /// A labelled rich-text editing field with a compact formatting toolbar.
  Widget _buildRichField({
    required String label,
    required QuillController controller,
    required FocusNode focusNode,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: primaryTextStyle(size: 12)),
            if (isRequired)
              Text(' *', style: primaryTextStyle(size: 12, color: Colors.red)),
          ],
        ),
        6.height,
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuillSimpleToolbar(
                controller: controller,
                config: QuillSimpleToolbarConfig(
                  multiRowsDisplay: false,
                  showBoldButton: true,
                  showItalicButton: true,
                  showUnderLineButton: true,
                  showStrikeThrough: false,
                  showListBullets: true,
                  showListNumbers: true,
                  showUndo: true,
                  showRedo: false,
                  showFontFamily: false,
                  showFontSize: false,
                  showColorButton: false,
                  showBackgroundColorButton: false,
                  showClearFormat: false,
                  showLink: false,
                  showSearchButton: false,
                  showHeaderStyle: false,
                  showIndent: false,
                  showCodeBlock: false,
                  showInlineCode: false,
                  showQuote: false,
                  showAlignmentButtons: false,
                  showDirection: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showDividers: false,
                  showSmallButton: false,
                  showListCheck: false,
                  showLineHeightButton: false,
                ),
              ),
              Divider(height: 1, color: context.dividerColor),
              // Wrap in a Container to enforce minimum visible height
              Container(
                constraints: const BoxConstraints(minHeight: 100),
                child: QuillEditor.basic(
                  controller: controller,
                  focusNode: focusNode,
                  config: QuillEditorConfig(
                    placeholder: language.writeHere,
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
