import 'package:booking_system_flutter/component/base_scaffold_body.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/time_slots_model.dart';
import 'package:booking_system_flutter/screens/booking/component/confirm_booking_dialog.dart';
import 'package:booking_system_flutter/screens/booking/component/time_slot_component.dart';
import 'package:booking_system_flutter/screens/map/map_screen.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../component/wallet_balance_component.dart';
import '../../../model/booking_amount_model.dart';
import '../../../utils/booking_calculations_logic.dart';
import '../../component/back_widget.dart';
import '../../component/chat_gpt_loder.dart';
import '../../services/location_service.dart';
import '../../utils/permissions.dart';
import '../service/addons/service_addons_component.dart';
import 'component/applied_tax_list_bottom_sheet.dart';
import 'component/coupon_list_screen.dart';
import 'component/service_booking_slot.dart';

class BookServiceScreen extends StatefulWidget {
  final ServiceDetailResponse data;
  final BookingPackage? selectedPackage;

  BookServiceScreen({required this.data, this.selectedPackage});

  @override
  _BookServiceScreenState createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  CouponData? appliedCouponData;

  final List<TimeSlotModel> timeSlots = [];

  BookingAmountModel bookingAmountModel = BookingAmountModel();
  num advancePaymentAmount = 0;

  int itemCount = 1;

  //Service add-on
  double imageHeight = 60;

  TextEditingController addressCont = TextEditingController();
  TextEditingController descriptionCont = TextEditingController();

  TextEditingController dateTimeCont = TextEditingController();
  DateTime currentDateTime = DateTime.now();
  DateTime? selectedDate;
  DateTime? finalDate;
  DateTime? packageExpiryDate;
  TimeOfDay? pickedTime;
  num? initialPrice;

  int? serviceQuantity;

  @override
  void initState() {
    super.initState();
    initialPrice = widget.data.serviceDetail?.price;
    init();

    if (widget.selectedPackage != null &&
        widget.selectedPackage!.endDate.validate().isNotEmpty) {
      packageExpiryDate =
          DateTime.parse(widget.selectedPackage!.endDate.validate());
    }
  }

  void init() async {
    setPrice();
    // try {
    //   if (widget.data.serviceDetail != null) {
    //     if (widget.data.serviceDetail!.isSlotAvailable.validate()) {
    //       //TODO: Change the below line
    //       dateTimeCont.text = formatBookingDate(
    //           widget.data.serviceDetail!.dateTimeVal.first.validate(),
    //           format: DATE_FORMAT_1);
    //       selectedDate = DateTime.parse(
    //           widget.data.serviceDetail!.dateTimeVal.first.validate());
    //       pickedTime = TimeOfDay.fromDateTime(selectedDate!);
    //     }
    //     addressCont.text = widget.data.serviceDetail!.address.validate();
    //   }
    // } catch (e) {}
  }

  void _handleSetLocationClick() {
    Permissions.cameraFilesAndLocationPermissionsGranted().then((value) async {
      await setValue(PERMISSION_STATUS, value);

      if (value) {
        String? res = await MapScreen(
                latitude: getDoubleAsync(LATITUDE),
                latLong: getDoubleAsync(LONGITUDE))
            .launch(context);

        addressCont.text = res.validate();
        setState(() {});
      }
    });
  }

  void _handleCurrentLocationClick() {
    Permissions.cameraFilesAndLocationPermissionsGranted().then((value) async {
      await setValue(PERMISSION_STATUS, value);

      if (value) {
        appStore.setLoading(true);

        await getUserLocation().then((value) {
          addressCont.text = value;
          widget.data.serviceDetail!.address = value.toString();
          setState(() {});
        }).catchError((e) {
          log(e);
          // toast(e.toString());
        });

        appStore.setLoading(false);
      }
    }).catchError((e) {
      //
    }).whenComplete(() => appStore.setLoading(false));
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void setPrice() {
    bookingAmountModel = finalCalculations(
      servicePrice: widget.data.serviceDetail!.price.validate(),
      appliedCouponData: appliedCouponData,
      serviceAddons: serviceAddonStore.selectedServiceAddon,
      discount: widget.data.serviceDetail!.discount.validate(),
      taxes: widget.data.taxes,
      quantity: itemCount,
      selectedPackage: widget.selectedPackage,
      couponBasePrice: widget.selectedPackage != null
          ? widget.selectedPackage!.price.validate()
          : initialPrice.validate(),
    );

    if (bookingAmountModel.finalSubTotal.isNegative) {
      appliedCouponData = null;
      setPrice();

      toast(language.youCannotApplyThisCoupon);
    } else {
      advancePaymentAmount = (bookingAmountModel.finalGrandTotalAmount *
          (widget.data.serviceDetail!.advancePaymentPercentage.validate() / 100)
              .toStringAsFixed(appConfigurationStore.priceDecimalPoint)
              .toDouble());
    }
    setState(() {});
  }

  void applyCoupon({bool isApplied = false}) async {
    hideKeyboard(context);
    if (widget.data.serviceDetail != null &&
        widget.data.serviceDetail!.id != null) {
      var value = await CouponsScreen(
              serviceId: widget.data.serviceDetail!.id!.toInt(),
              servicePrice: bookingAmountModel.finalTotalServicePrice,
              appliedCouponData: appliedCouponData)
          .launch(context);
      if (value != null) {
        if (value is bool && !value) {
          appliedCouponData = null;
        } else if (value is CouponData) {
          appliedCouponData = value;
        } else {
          appliedCouponData = null;
        }
        setPrice();
      }
    }
  }

  void updatePrice(TimeSlotModel timeSlot) {
    if (widget.data.serviceDetail!.isHourlyService) {
      final hourlyRate = initialPrice.validate();
      final totalHours = timeSlots
          .map((slot) => slot.totalHours.validate())
          .fold(0, (prev, hours) => prev + hours);
      widget.data.serviceDetail!.price = hourlyRate * totalHours;
    }

    if (widget.data.serviceDetail!.isFixedService ||
        widget.data.serviceDetail!.isDailyService) {
      widget.data.serviceDetail!.price =
          initialPrice.validate() * timeSlots.length;
    }
    setPrice();
  }

  void addTimeSlot(TimeSlotModel timeSlot) {
    timeSlots.add(timeSlot);
    if (widget.data.serviceDetail!.isHourlyService) {
      final totalHours = timeSlots
          .map((slot) => slot.totalHours.validate())
          .fold(0, (prev, hours) => prev + hours);
      serviceQuantity = totalHours == 0 ? 1 : totalHours;
    }
    updatePrice(timeSlot);
    setState(() {});
  }

  void removeTimeSlot(index) {
    final timeSlot = timeSlots[index];
    timeSlots.removeAt(index);
    if (widget.data.serviceDetail!.isHourlyService) {
      final totalHours = timeSlots
          .map((slot) => slot.totalHours.validate())
          .fold(0, (prev, hours) => prev + hours);
      serviceQuantity = totalHours == 0 ? 1 : totalHours;
    }
    if (timeSlots.isNotEmpty) {
      updatePrice(timeSlot);
    } else {
      widget.data.serviceDetail!.price = initialPrice.validate();
      setPrice();
    }
    setState(() {});
  }

  void selectServiceSlot() {
    hideKeyboard(context);
    // if (widget.data.serviceDetail!.isSlot == 1) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(
          borderRadius:
              radiusOnly(topLeft: defaultRadius, topRight: defaultRadius)),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.65,
          maxChildSize: 1,
          builder: (context, scrollController) => ServiceBookingSlot(
            data: widget.data,
            showAppbar: true,
            isHourlyService: widget.data.serviceDetail!.isHourlyService,
            isDailyService: widget.data.serviceDetail!.isDailyService,
            isFixedService: widget.data.serviceDetail!.isFixedService,
            scrollController: scrollController,
            onApplyClick: (selectedSlot) {
              addTimeSlot(selectedSlot);
              pop(context);
            },
          ),
        );
      },
    );
    // } else {
    //   // selectDateAndTime(context);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.data.serviceDetail!.price = initialPrice;
          setPrice();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              widget.selectedPackage == null
                  ? language.bookTheService
                  : language.bookPackage,
              style:
                  boldTextStyle(color: Colors.white, size: APP_BAR_TEXT_SIZE)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: BackWidget(),
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: appPrimaryGradient),
          ),
        ),
        body: Body(
          showLoader: true,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.selectedPackage == null)
                  Text(language.service,
                      style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                if (widget.selectedPackage == null) 8.height,
                if (widget.selectedPackage == null) serviceWidget(context),

                packageWidget(),

                addressAndDescriptionWidget(context),

                Text("${language.hintDescription}",
                    style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                8.height,
                AppTextField(
                  textFieldType: TextFieldType.MULTILINE,
                  controller: descriptionCont,
                  maxLines: 10,
                  minLines: 3,
                  isValidationRequired: false,
                  enableChatGPT: appConfigurationStore.chatGPTStatus,
                  promptFieldInputDecorationChatGPT:
                      inputDecoration(context).copyWith(
                    hintText: language.writeHere,
                    fillColor: context.scaffoldBackgroundColor,
                    filled: true,
                    hintStyle: primaryTextStyle(),
                  ),
                  testWithoutKeyChatGPT: appConfigurationStore.testWithoutKey,
                  loaderWidgetForChatGPT: const ChatGPTLoadingWidget(),
                  onFieldSubmitted: (s) {
                    widget.data.serviceDetail!.bookingDescription = s;
                  },
                  onChanged: (s) {
                    widget.data.serviceDetail!.bookingDescription = s;
                  },
                  decoration: inputDecoration(context).copyWith(
                    fillColor: context.cardColor,
                    filled: true,
                    hintText: language.lblEnterDescription,
                    hintStyle: secondaryTextStyle(),
                  ),
                ),

                /// Only active status package display
                if (serviceAddonStore.selectedServiceAddon
                    .validate()
                    .isNotEmpty)
                  AddonComponent(
                    isFromBookingLastStep: true,
                    serviceAddon: serviceAddonStore.selectedServiceAddon,
                    onSelectionChange: (v) {
                      serviceAddonStore.setSelectedServiceAddon(v);
                      setPrice();
                    },
                  ),

                buildBookingSummaryWidget(),

                16.height,

                priceWidget(),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Observer(builder: (context) {
                      return WalletBalanceComponent().visible(
                          appConfigurationStore.isEnableUserWallet &&
                              widget.data.serviceDetail!.isFixedService);
                    }),
                    16.height,
                    Text(language.disclaimer,
                        style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                    Text(language.disclaimerContent,
                        style: secondaryTextStyle()),
                  ],
                ).paddingSymmetric(vertical: 16),

                36.height,

                Row(
                  children: [
                    AppButton(
                      color: context.primaryColor,
                      text:
                          // widget.data.serviceDetail!.isAdvancePayment &&
                          //         !widget.data.serviceDetail!.isFreeService &&
                          //         widget.data.serviceDetail!.isFixedService
                          //     ?
                          language.lblBookNow,

                      // : language.confirm,
                      textColor: Colors.white,
                      onTap: () {
                        if (widget.data.serviceDetail!.isOnSiteService &&
                            addressCont.text.isEmpty &&
                            timeSlots.isEmpty) {
                          toast(language.pleaseEnterAddressAnd);
                        } else if (widget.data.serviceDetail!.isOnSiteService &&
                            addressCont.text.isEmpty) {
                          toast(language.pleaseEnterYourAddress);
                        } else if (timeSlots.isEmpty) {
                          toast(language.pleaseSelectBookingDate);
                        } else {
                          widget.data.serviceDetail!.address = addressCont.text;
                          
                          showInDialog(
                            context,
                            barrierDismissible: false,
                            insetPadding: EdgeInsets.symmetric(horizontal: 10),
                            builder: (p0) {
                              return ConfirmBookingDialog(
                                data: widget.data,
                                servicePrice: initialPrice.validate(),
                                quantity: serviceQuantity ??
                                    (timeSlots.length == 0
                                        ? 1
                                        : timeSlots.length),
                                timeSlots: timeSlots,
                                bookingPrice:
                                    bookingAmountModel.finalGrandTotalAmount,
                                selectedPackage: widget.selectedPackage,
                                qty: itemCount,
                                couponCode: appliedCouponData?.code,
                                bookingAmountModel: BookingAmountModel(
                                  finalCouponDiscountAmount: bookingAmountModel
                                      .finalCouponDiscountAmount,
                                  finalDiscountAmount:
                                      bookingAmountModel.finalDiscountAmount,
                                  finalSubTotal:
                                      bookingAmountModel.finalSubTotal,
                                  finalTotalServicePrice:
                                      bookingAmountModel.finalTotalServicePrice,
                                  finalTotalTax:
                                      !widget.data.serviceDetail!.isFreeService
                                          ? bookingAmountModel.finalTotalTax
                                          : 0,
                                ),
                              );
                            },
                          );
                        }
                      },
                    ).expand(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget addressFieldWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        Text(language.lblYourAddress,
            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        8.height,
        AppTextField(
          textFieldType: TextFieldType.MULTILINE,
          controller: addressCont,
          maxLines: 3,
          minLines: 3,
          onFieldSubmitted: (s) {
            widget.data.serviceDetail!.address = s;
          },
          decoration: inputDecoration(
            context,
            prefixIcon: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ic_location.iconImage(size: 22).paddingOnly(top: 0),
              ],
            ),
          ).copyWith(
            fillColor: context.cardColor,
            filled: true,
            hintText: language.lblEnterYourAddress,
            hintStyle: secondaryTextStyle(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              child: Text(language.lblChooseFromMap,
                  style: boldTextStyle(color: primaryColor, size: 13)),
              onPressed: () {
                _handleSetLocationClick();
              },
            ).flexible(),
            TextButton(
              onPressed: _handleCurrentLocationClick,
              child: Text(language.lblUseCurrentLocation,
                  style: boldTextStyle(color: primaryColor, size: 13),
                  textAlign: TextAlign.right),
            ).flexible(),
          ],
        ),
      ],
    );
  }

  Widget addressAndDescriptionWidget(BuildContext context) {
    return Column(
      children: [
        if (widget.data.serviceDetail!.isOnSiteService)
          addressFieldWidget()
        else if ((widget.selectedPackage != null &&
            !widget.selectedPackage!.isAllServiceOnline))
          addressFieldWidget()
        else if ((widget.selectedPackage != null &&
                widget.selectedPackage!.isAllServiceOnline) &&
            widget.data.serviceDetail!.isOnlineService)
          Text(language.noteAddressIsNot, style: secondaryTextStyle())
              .paddingTop(16),
        16.height.visible(!widget.data.serviceDetail!.isOnSiteService),
      ],
    );
  }

  Widget serviceWidget(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: boxDecorationDefault(color: context.cardColor),
      width: context.width(),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.data.serviceDetail!.name.validate(),
                  style: boldTextStyle()),
              4.height,
              Text(
                  '${language.duration} (${convertToHourMinute(widget.data.serviceDetail!.duration.validate())})',
                  style: secondaryTextStyle()),
              16.height,
              if (widget.data.serviceDetail!.isFixedService)
                Container(
                  height: 40,
                  padding: EdgeInsets.all(8),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: context.scaffoldBackgroundColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_drop_down_sharp, size: 24).onTap(
                        () {
                          if (itemCount != 1) itemCount--;
                          setPrice();
                        },
                      ),
                      16.width,
                      Text(itemCount.toString(), style: primaryTextStyle()),
                      16.width,
                      Icon(Icons.arrow_drop_up_sharp, size: 24).onTap(
                        () {
                          itemCount++;
                          setPrice();
                        },
                      ),
                    ],
                  ),
                )
            ],
          ).expand(),
          CachedImageWidget(
            url: widget.data.serviceDetail!.attachments.validate().isNotEmpty
                ? widget.data.serviceDetail!.attachments!.first.validate()
                : '',
            height: 80,
            width: 80,
            fit: BoxFit.cover,
          ).cornerRadiusWithClipRRect(defaultRadius)
        ],
      ),
    );
  }

  Widget priceWidget() {
    if (!widget.data.serviceDetail!.isFreeService)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.selectedPackage == null) 16.height,
          if (widget.selectedPackage == null)
            Container(
              padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
              decoration: boxDecorationDefault(color: context.cardColor),
              child: Row(
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ic_coupon_prefix.iconImage(color: Colors.green, size: 20),
                      Text(language.lblCoupon, style: primaryTextStyle()),
                    ],
                  ).expand(),
                  16.width,
                  TextButton(
                    onPressed: () {
                      if (appliedCouponData != null) {
                        showConfirmDialogCustom(
                          context,
                          dialogType: DialogType.DELETE,
                          title: language.doYouWantTo,
                          positiveText: language.lblDelete,
                          negativeText: language.lblCancel,
                          onAccept: (p0) {
                            appliedCouponData = null;
                            setPrice();
                            setState(() {});
                          },
                        );
                      } else {
                        applyCoupon();
                      }
                    },
                    child: Text(
                      appliedCouponData != null
                          ? language.lblRemoveCoupon
                          : language.applyCoupon,
                      style: primaryTextStyle(color: context.primaryColor),
                    ),
                  )
                ],
              ),
            ),
          24.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.priceDetail,
                  style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            ],
          ),
          16.height,
          // PriceCommonWidget(
          //   bookingDetail: widget.,
          //   serviceDetail: widget.data.serviceDetail!,
          //   taxes: snap.data!.bookingDetail!.taxes.validate(),
          //   couponData: snap.data!.couponData,
          //   bookingPackage: snap.data!.bookingDetail!.bookingPackage != null
          //       ? snap.data!.bookingDetail!.bookingPackage
          //       : null,
          // ),
          Container(
            padding: EdgeInsets.all(16),
            width: context.width(),
            decoration: boxDecorationDefault(color: context.cardColor),
            child: Column(
              children: [
                /// Service or Package Price
                Row(
                  children: [
                    Text(language.lblPrice, style: secondaryTextStyle(size: 14))
                        .expand(),
                    16.width,
                    if (widget.selectedPackage != null)
                      PriceWidget(
                          price: initialPrice.validate(),
                          color: textPrimaryColorGlobal,
                          isBoldText: true)
                    else if (!widget.data.serviceDetail!.isHourlyService)
                      Marquee(
                        child: Row(
                          children: [
                            PriceWidget(
                                price: initialPrice.validate(),
                                color: textPrimaryColorGlobal),
                          ],
                        ),
                      )
                    else
                      PriceWidget(
                          price: initialPrice.validate(),
                          color: textPrimaryColorGlobal,
                          isBoldText: true)
                  ],
                ),

                /// Quantity

                Column(
                  children: [
                    Divider(height: 26, color: context.dividerColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Quantity', style: secondaryTextStyle(size: 14))
                            .flexible(fit: FlexFit.loose),
                        // 16.width,
                        Text(
                            '${serviceQuantity ?? (timeSlots.length == 0 ? 1 : timeSlots.length)}',
                            style: boldTextStyle(size: 16)),
                      ],
                    ),
                  ],
                ),
                Divider(height: 26, color: context.dividerColor),
                Row(
                  children: [
                    Text('Total', style: secondaryTextStyle(size: 14)).expand(),
                    16.width,
                    Marquee(
                      child: Row(
                        children: [
                          PriceWidget(
                              price: initialPrice.validate(),
                              size: 12,
                              isBoldText: false,
                              color: textSecondaryColorGlobal),
                          Text(
                              ' x ${serviceQuantity ?? (timeSlots.length == 0 ? 1 : timeSlots.length)} = ',
                              style: secondaryTextStyle()),
                          PriceWidget(
                              price:
                                  (bookingAmountModel.finalTotalServicePrice),
                              color: textPrimaryColorGlobal),
                        ],
                      ),
                    )
                  ],
                ),

                /// Fix Discount on Base Price
                if (widget.data.serviceDetail!.discount.validate() != 0 &&
                    widget.selectedPackage == null)
                  Column(
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        children: [
                          Text(language.lblDiscount,
                              style: secondaryTextStyle(size: 14)),
                          Text(
                            " (${widget.data.serviceDetail!.discount.validate()}% ${language.lblOff.toLowerCase()})",
                            style: boldTextStyle(color: Colors.green),
                          ).expand(),
                          16.width,
                          PriceWidget(
                            price: bookingAmountModel.finalDiscountAmount,
                            color: Colors.green,
                            isBoldText: true,
                          ),
                        ],
                      ),
                    ],
                  ),

                /// Coupon Discount on Base Price
                if (widget.selectedPackage == null)
                  Column(
                    children: [
                      if (appliedCouponData != null)
                        Divider(height: 26, color: context.dividerColor),
                      if (appliedCouponData != null)
                        Row(
                          children: [
                            Row(
                              children: [
                                Text(language.lblCoupon,
                                    style: secondaryTextStyle(size: 14)),
                                Text(
                                  " (${appliedCouponData!.code})",
                                  style: boldTextStyle(
                                      color: primaryColor, size: 14),
                                ).onTap(() {
                                  applyCoupon(
                                      isApplied: appliedCouponData!.code
                                          .validate()
                                          .isNotEmpty);
                                }).expand(),
                              ],
                            ).expand(),
                            PriceWidget(
                              price:
                                  bookingAmountModel.finalCouponDiscountAmount,
                              color: Colors.green,
                              isBoldText: true,
                            ),
                          ],
                        ),
                    ],
                  ),

                /// Show Service Add-on Price
                if (serviceAddonStore.selectedServiceAddon
                    .validate()
                    .isNotEmpty)
                  Column(
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(language.serviceAddOns,
                                  style: secondaryTextStyle(size: 14))
                              .flexible(fit: FlexFit.loose),
                          16.width,
                          PriceWidget(
                              price: bookingAmountModel.finalServiceAddonAmount,
                              color: textPrimaryColorGlobal)
                        ],
                      ),
                    ],
                  ),

                /// Show Subtotal, Total Amount and Apply Discount, Coupon if service is Fixed or Hourly
                if (widget.selectedPackage == null)
                  Column(
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        children: [
                          Text(language.lblSubTotal,
                                  style: secondaryTextStyle(size: 14))
                              .expand(),
                          16.width,
                          Marquee(
                            child: Row(
                              children: [
                                PriceWidget(
                                    price: bookingAmountModel.finalSubTotal,
                                    color: textPrimaryColorGlobal),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),

                /// Tax Amount Applied on Price

                Column(
                  children: [
                    Divider(height: 26, color: context.dividerColor),
                    Row(
                      children: [
                        Row(
                          children: [
                            Row(
                              children: [
                                Text(language.lblTax,
                                    style: secondaryTextStyle(size: 14)),
                                Text(
                                  " (${(bookingAmountModel.finalTotalTax / bookingAmountModel.finalSubTotal * 100).toInt()}%)",
                                  style: boldTextStyle(
                                      color: primaryColor, size: 14),
                                ).expand()
                              ],
                            ).expand(),
                            if (widget.data.taxes.validate().isNotEmpty)
                              Icon(Icons.info_outline_rounded,
                                      size: 20, color: context.primaryColor)
                                  .onTap(
                                () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (_) {
                                      return AppliedTaxListBottomSheet(
                                          taxes: widget.data.taxes.validate(),
                                          subTotal:
                                              bookingAmountModel.finalSubTotal);
                                    },
                                  );
                                },
                              ),
                          ],
                        ).expand(),
                        16.width,
                        PriceWidget(
                            price: bookingAmountModel.finalTotalTax,
                            color: Colors.red,
                            isBoldText: true),
                      ],
                    ),
                  ],
                ),

                /// Final Amount
                Column(
                  children: [
                    Divider(height: 26, color: context.dividerColor),
                    Row(
                      children: [
                        Text(language.totalAmount,
                                style: boldTextStyle(size: 14))
                            .expand(),
                        PriceWidget(
                          price: bookingAmountModel.finalGrandTotalAmount,
                          color: primaryColor,
                        )
                      ],
                    ),
                  ],
                ),

                /// Advance Payable Amount if it is required by Service Provider
                if (widget.data.serviceDetail!.isAdvancePayment
                    // &&
                    // widget.data.serviceDetail!.isFixedService &&
                    // widget.data.serviceDetail!.isFreeService
                    )
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        children: [
                          Row(
                            children: [
                              Text(language.advancePayAmount,
                                  style: secondaryTextStyle(size: 14)),
                              Text(
                                  " (${widget.data.serviceDetail!.advancePaymentPercentage.validate().toString()}%) ",
                                  style: boldTextStyle(color: Colors.green)),
                            ],
                          ).expand(),
                          PriceWidget(
                              price: advancePaymentAmount, color: primaryColor),
                        ],
                      ),
                    ],
                  ),

                /// Remaining Amount if Advance Payment
                // if (widget.data.serviceDetail!.isAdvancePayment &&
                //     !widget.data.serviceDetail!.isFreeService &&
                //     widget.selectedPackage?.status.validate() !=
                //         BOOKING_STATUS_CANCELLED)
                Column(
                  children: [
                    Divider(height: 26, color: context.dividerColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextIcon(
                          prefix: Row(
                            children: [
                              Text(
                                '${language.remainingAmount}',
                                style: secondaryTextStyle(size: 14),
                              ),
                            ],
                          ),
                          textStyle: secondaryTextStyle(size: 14),
                          edgeInsets: EdgeInsets.zero,
                        ).expand(),
                        8.width,
                        PriceWidget(
                            price: getRemainingAmount, color: primaryColor),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

    return Offstage();
  }

  num get getRemainingAmount {
    if (bookingAmountModel.finalTotalServicePrice.validate() != 0) {
      return (bookingAmountModel.finalGrandTotalAmount - advancePaymentAmount);
    } else {
      return 0;
    }
  }

  Widget buildBookingSummaryWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        Text(language.bookingDateAndSlot,
            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        timeSlots.isEmpty
            ? GestureDetector(
                onTap: () async {
                  selectServiceSlot();
                },
                child: DottedBorderWidget(
                  color: context.primaryColor,
                  radius: defaultRadius,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    alignment: Alignment.center,
                    decoration: boxDecorationWithShadow(
                        blurRadius: 0,
                        backgroundColor: context.cardColor,
                        borderRadius: radius()),
                    child: Column(
                      children: [
                        ic_calendar.iconImage(size: 26),
                        8.height,
                        Text(language.chooseDateTime,
                            style: secondaryTextStyle()),
                      ],
                    ),
                  ),
                ),
              )
            : ListView.separated(
                itemCount: timeSlots.length,
                separatorBuilder: (context, index) => 10.height,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) => TimeSlotComponent(
                  timeSlotModel: timeSlots[index],
                  onClose: () {
                    removeTimeSlot(index);
                  },
                ),
              ),
        if (timeSlots.isNotEmpty)
          GestureDetector(
            onTap: () async => selectServiceSlot(),
            child: Row(
              spacing: 6,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 20),
                Text(
                  'Add more Dates',
                  style: secondaryTextStyle(),
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget packageWidget() {
    if (widget.selectedPackage != null)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.package, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          16.height,
          Container(
            padding: EdgeInsets.all(16),
            decoration: boxDecorationDefault(color: context.cardColor),
            width: context.width(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Marquee(
                            child: Text(widget.selectedPackage!.name.validate(),
                                style: boldTextStyle())),
                        4.height,
                        Text(
                            "${language.services}: ${widget.selectedPackage!.serviceList.validate().map((e) => e.name).join(", ")}",
                            style: secondaryTextStyle()),
                      ],
                    ).expand(),
                    16.width,
                    CachedImageWidget(
                      url: widget.selectedPackage!.imageAttachments
                              .validate()
                              .isNotEmpty
                          ? widget.selectedPackage!.imageAttachments!.first
                              .validate()
                          : '',
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ).cornerRadiusWithClipRRect(defaultRadius),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

    return Offstage();
  }
}
