import 'dart:async';
import 'dart:convert';
import 'package:booking_system_flutter/component/add_review_dialog.dart';
import 'package:booking_system_flutter/component/app_common_dialog.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_data_model.dart';
import 'package:booking_system_flutter/model/booking_detail_model.dart';
import 'package:booking_system_flutter/model/extra_charges_model.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/update_location_response.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_detail_handyman_widget.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_detail_provider_widget.dart';
import 'package:booking_system_flutter/screens/booking/component/countdown_component.dart';
import 'package:booking_system_flutter/screens/booking/component/invoice_request_dialog_component.dart';
import 'package:booking_system_flutter/screens/booking/component/price_common_widget.dart';
import 'package:booking_system_flutter/screens/booking/component/reason_dialog.dart';
import 'package:booking_system_flutter/screens/booking/component/service_proof_list_widget.dart';
import 'package:booking_system_flutter/screens/booking/handyman_info_screen.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/booking/shimmer/booking_detail_shimmer.dart';
import 'package:booking_system_flutter/screens/booking/time_slots_list.dart';
import 'package:booking_system_flutter/screens/booking/track_location.dart';
import 'package:booking_system_flutter/screens/payment/payment_screen.dart';
import 'package:booking_system_flutter/screens/review/components/review_widget.dart';
import 'package:booking_system_flutter/screens/review/rating_view_all_screen.dart';
import 'package:booking_system_flutter/screens/chat/api_chat_screen.dart';
import 'package:booking_system_flutter/model/chat_api_models.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/component/gradient_button.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../service/addons/service_addons_component.dart';
import 'booking_history_component.dart';
import 'component/cancellations_booking_charge_dialog.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;

  BookingDetailScreen({required this.bookingId});

  @override
  _BookingDetailScreenState createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen>
    with WidgetsBindingObserver {
  Future<BookingDetailResponse>? future;
  bool isSentInvoiceOnEmail = false;
  UpdateLocationResponse? providerLocation;
  BitmapDescriptor? customIcon;
  Timer? _locationUpdateTimer;
  GoogleMapController? mapController;
  LatLng? _currentPosition;
  bool isLocationLoader = false;
  LatLng _initialLocation = const LatLng(0.0, 0.0);
  String bookingStatus = "";
  int providerLocationRefreshPeriodInSeconds = 30;

  @override
  void initState() {
    super.initState();
    init(isLoading: false);
    createCustomIcon();
    WidgetsBinding.instance.addObserver(this);
  }

  void init({isLoading = true}) async {
    appStore.setLoading(isLoading);
    future = getBookingDetail(
      {
        CommonKeys.bookingId: widget.bookingId.toString(),
        CommonKeys.customerId: appStore.userId
      },
      callbackForStatus: (status) {
        bookingStatus = status;
        if (bookingStatus == BookingStatusKeys.onGoing) {
          refreshProviderLocation();
          startLocationUpdates();
        } else {
          stopLocationUpdates();
        }
      },
    );
    if (isLoading) setState(() {});
  }

  //region Widgets
  Widget _buildReasonWidget({required BookingDetailResponse snap}) {
    if (((snap.bookingDetail!.status == BookingStatusKeys.cancelled ||
            snap.bookingDetail!.status == BookingStatusKeys.rejected ||
            snap.bookingDetail!.status == BookingStatusKeys.failed ||
            snap.bookingDetail!.status == BookingStatusKeys.hold) &&
        ((snap.bookingDetail!.reason != null &&
            snap.bookingDetail!.reason!.isNotEmpty))))
      return Container(
        padding: EdgeInsets.only(top: 14, left: 14, bottom: 14),
        color: cancellationsBgColor,
        width: context.width(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${language.reason}: ",
                style: boldTextStyle(size: 12, color: black)),
            Marquee(
                    child: Text(snap.bookingDetail!.reason.validate(),
                        style: boldTextStyle(color: redColor, size: 12)))
                .expand(),
          ],
        ),
      );
    return SizedBox();
  }

  Widget _completeMessage({required BookingDetailResponse snap}) {
    if (snap.bookingDetail!.status == BookingStatusKeys.complete &&
        snap.customerReview == null)
      return Container(
        padding: EdgeInsets.all(14),
        width: context.width(),
        decoration: BoxDecoration(
          color: payment_message_status.withValues(alpha: 0.2),
          border: Border.all(color: gold, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: gold,
              ),
              child: Center(
                child: Image.asset(
                  ic_star1,
                  height: 35,
                  width: 35,
                ),
              ),
            ),
            16.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(language.rateYourExperience, style: boldTextStyle()),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        showInDialog(
                          context,
                          contentPadding: EdgeInsets.zero,
                          builder: (p0) {
                            return AddReviewDialog(
                              serviceId:
                                  snap.bookingDetail!.serviceId.validate(),
                              bookingId: snap.bookingDetail!.id.validate(),
                            );
                          },
                        ).then((value) {
                          if (value) {
                            init();
                            setState(() {});
                          }
                        }).catchError((e) {
                          log(e.toString());
                        });
                      },
                      child: Text(
                        language.btnRate,
                        style: TextStyle(
                          color: gradientRed,
                          decoration: TextDecoration.underline,
                          decorationColor: gradientRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                8.height,
                Text(
                  language.weValueYourFeedback,
                  style: boldTextStyle(color: textSecondaryColor, size: 12),
                ),
              ],
            ).expand(),
          ],
        ),
      );

    return SizedBox();
  }

  Widget _pendingMessage({required BookingDetailResponse snap}) {
    if (snap.bookingDetail!.status == BookingStatusKeys.pending)
      return Container(
        padding: EdgeInsets.only(top: 14, left: 14, bottom: 14),
        color: cancellationsBgColor,
        width: context.width(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (snap.bookingDetail!.status ==
                    BookingStatusKeys.waitingAdvancedPayment &&
                (snap.service != null && snap.service!.isAdvancePayment) &&
                (snap.bookingDetail!.paymentStatus == null ||
                    snap.bookingDetail!.paymentStatus != PAYMENT_STATUS_PAID))
              Text(language.advancePaymentMessage,
                  style: boldTextStyle(color: redColor, size: 12))
            else
              Text(language.lblWaitingForProviderApproval,
                  style: boldTextStyle(color: redColor, size: 12)),
          ],
        ),
      );

    return SizedBox();
  }

  Widget bookingIdWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          language.lblBookingID,
          style: boldTextStyle(size: LABEL_TEXT_SIZE, color: Colors.white),
        ),
        Text(
          '#' + widget.bookingId.validate().toString(),
          style: boldTextStyle(color: Colors.white, size: 16),
        ),
      ],
    );
  }

  String buildTimeString({required BookingData bookingDetail}) {
    if (bookingDetail.bookingSlot == null) {
      return formatDate(bookingDetail.date.validate(), isTime: true);
    }
    return formatDate(
      getSlotWithDate(
        date: bookingDetail.date.validate(),
        slotTime: bookingDetail.bookingSlot.validate(),
      ),
      isTime: true,
    );
  }

  Widget serviceDetailWidget({
    required BookingData bookingDetail,
    required ServiceData serviceDetail,
    // required PostJobData postJobData,
  }) {
    return GestureDetector(
      onTap: () {
        if (bookingDetail.isPostJob || bookingDetail.isPackageBooking) {
          //
        } else {
          ServiceDetailScreen(serviceId: bookingDetail.serviceId.validate())
              .launch(context);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image section
              CachedImageWidget(
                url: serviceDetail.attachments!.isNotEmpty &&
                        !bookingDetail.isPackageBooking
                    ? serviceDetail.attachments!.first
                    : bookingDetail.bookingPackage != null
                        ? bookingDetail.bookingPackage!.imageAttachments
                                .validate()
                                .isNotEmpty
                            ? bookingDetail.bookingPackage!.imageAttachments
                                .validate()
                                .first
                                .validate()
                            : ''
                        : '',
                height: 70,
                width: 70,
                fit: BoxFit.cover,
                radius: 8,
              ),
              16.width,
              // Service Name section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (bookingDetail.isPackageBooking)
                    Text(
                      bookingDetail.bookingPackage!.name.validate(),
                      style: boldTextStyle(size: LABEL_TEXT_SIZE),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      bookingDetail.serviceName.validate(),
                      style: boldTextStyle(size: LABEL_TEXT_SIZE),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Builder(builder: (context) {
                    final String city = bookingDetail.cityName.validate();
                    final String country = bookingDetail.countryName.validate();
                    final String label = (city.isEmpty && country.isEmpty)
                        ? 'N/A'
                        : '$city${(city.isNotEmpty && country.isNotEmpty) ? ' - ' : ''}$country';
                    return Text(
                      label,
                      style: primaryTextStyle(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    );
                  }),

                  /// Pricing Section
                  8.height,
                  if (bookingDetail.bookingPackage != null)
                    PriceWidget(
                      price: bookingDetail.totalAmount.validate(),
                      color: gradientRed,
                      isHourlyService: bookingDetail.isHourlyService,
                      isFixedService: bookingDetail.isFixedService,
                      isFreeService: bookingDetail.isFreeService,
                      isDailyService: bookingDetail.type == 'Daily',
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PriceWidget(
                          isFreeService:
                              bookingDetail.type == SERVICE_TYPE_FREE,
                          price: bookingDetail.amount.validate(),
                          color: gradientRed,
                          isHourlyService: bookingDetail.isHourlyService,
                        ),
                        if (bookingDetail.discount.validate() != 0)
                          Text(
                            '(${bookingDetail.discount!}% ${language.lblOff})',
                            style: boldTextStyle(size: 12, color: Colors.green),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ).paddingLeft(4).expand(),
                      ],
                    ),
                ],
              ).expand(),
            ],
          ),
          if (bookingDetail.description.validate().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                16.height,
                ReadMoreText(
                  trimLength: 65,
                  bookingDetail.description.validate(),
                  style: secondaryTextStyle(),
                  colorClickableText: gradientRed,
                )
              ],
            ),
          // Date and Time section
          if (bookingDetail.date.validate().isNotEmpty)
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: appStore.isDarkMode ? context.cardColor : whiteColor,
                border: Border.all(color: context.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 5,
                children: [
                  if ((bookingDetail.paymentStatus.validate() ==
                          SERVICE_PAYMENT_STATUS_ADVANCE_PAID ||
                      bookingDetail.isAdvancePaymentDone) &&
                      bookingDetail.address.validate().isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          'Working Address: ',
                          style: secondaryTextStyle(),
                        ),
                        8.width,
                        Expanded(
                          child: Marquee(
                            directionMarguee: DirectionMarguee.oneDirection,
                            child: Text(
                              bookingDetail.address.validate(),
                              style: boldTextStyle(size: 12),
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                      ],
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(
                        '${language.lblDate} & ${language.lblTime}:',
                        style: secondaryTextStyle(),
                      ),
                      Marquee(
                        child: Text(
                          "${formatDate(bookingDetail.date.validate())} ${language.at} ${buildTimeString(bookingDetail: bookingDetail)}",
                          style: boldTextStyle(size: 12),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  if ((bookingDetail.paymentStatus.validate() ==
                              SERVICE_PAYMENT_STATUS_PAID ||
                          bookingDetail.paymentStatus.validate() ==
                              PENDING_BY_ADMIN) ||
                      (getPaymentStatusText(
                              bookingDetail.paymentStatus.validate(),
                              bookingDetail.paymentMethod.validate())
                          .isNotEmpty))
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        Text(
                          "${language.paymentStatus}:",
                          style: secondaryTextStyle(),
                        ),
                        Marquee(
                          child: Text(
                            buildPaymentStatusWithMethod(
                              bookingDetail.paymentStatus.validate(),
                              bookingDetail.paymentMethod.validate(),
                            ),
                            style: boldTextStyle(
                              size: 12,
                              color: bookingDetail.paymentStatus ==
                                          SERVICE_PAYMENT_STATUS_ADVANCE_PAID ||
                                      bookingDetail.paymentStatus ==
                                          SERVICE_PAYMENT_STATUS_PAID
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ListView.separated(
                    itemCount: bookingDetail.timeSlots!.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: 4),
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final timeSlotModel = bookingDetail.timeSlots![index];
                      return TimeSlotsList(timeSlotModel: timeSlotModel);
                    },
                    separatorBuilder: (context, index) => 10.height,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Price: ',
                        style: secondaryTextStyle(),
                      ),
                      PriceWidget(
                        price: bookingDetail.totalAmount.validate(),
                        color: textPrimaryColorGlobal,
                        isBoldText: true,
                        size: 12,
                      ),
                    ],
                  ),
                ],
              ).paddingOnly(left: 8, right: 8),
            ).paddingTop(16)
        ],
      ),
    );
  }

  Widget counterWidget({required BookingDetailResponse value}) {
    if (value.bookingDetail!.isHourlyService &&
        (value.bookingDetail!.status == BookingStatusKeys.inProgress ||
            value.bookingDetail!.status == BookingStatusKeys.hold ||
            value.bookingDetail!.status == BookingStatusKeys.complete ||
            value.bookingDetail!.status == BookingStatusKeys.onGoing))
      return Column(
        children: [
          16.height,
          CountdownWidget(bookingDetailResponse: value),
        ],
      );
    else
      return Offstage();
  }

  Widget serviceProofListWidget({required List<ServiceProof> list}) {
    if (list.isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        Text(language.lblServiceProof,
            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        Container(
          decoration: boxDecorationWithRoundedCorners(
            backgroundColor: context.cardColor,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: ListView.separated(
            itemBuilder: (context, index) =>
                ServiceProofListWidget(data: list[index]),
            itemCount: list.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            separatorBuilder: (BuildContext context, int index) {
              return Divider(height: 0, color: context.dividerColor);
            },
          ),
        ),
      ],
    );
  }

  Widget handymanWidget(
      {required List<UserData> handymanList,
      required BookingDetailResponse res,
      required ServiceData serviceDetail,
      required BookingData bookingDetail}) {
    if (handymanList.isEmpty) return Offstage();

    if (res.providerData!.id != handymanList.first.id)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          24.height,
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Space between items
            children: [
              Text(
                language.lblAboutHandyman,
                style: boldTextStyle(size: LABEL_TEXT_SIZE),
              ),
              GestureDetector(
                onTap: () {
                  HandymanInfoScreen(handymanId: handymanList.first.id)
                      .launch(context)
                      .then((value) => null);
                },
                child: Text(
                  language.viewDetail,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: gradientRed, // Adjust color as needed
                  ),
                ),
              ),
            ],
          ),
          16.height,
          Column(
            children: handymanList.map((e) {
              return BookingDetailHandymanWidget(
                handymanData: e,
                serviceDetail: serviceDetail,
                bookingDetail: bookingDetail,
                onUpdate: () {
                  init();
                  setState(() {});
                },
              ).onTap(
                () {
                  HandymanInfoScreen(handymanId: e.id)
                      .launch(context)
                      .then((value) => null);
                },
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
              );
            }).toList(),
          ),
        ],
      );
    else
      return Offstage();
  }

  Widget providerWidget({required BookingDetailResponse res}) {
    if (res.providerData == null) return Offstage();
    bool canCustomerContact = res.bookingDetail!.canCustomerContact;
    bool providerIsHandyman = res.handymanData.validate().isNotEmpty &&
        (res.providerData!.id == res.handymanData!.first.id.validate());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        24.height,
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Space between items
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: language.lblAboutProvider,
                    style: boldTextStyle(size: LABEL_TEXT_SIZE),
                  ),
                  if (res.handymanData.validate().isNotEmpty &&
                      (res.providerData!.id ==
                          res.handymanData!.first.id.validate()))
                    TextSpan(
                      text: ' (${language.asHandyman})',
                      style: secondaryTextStyle(size: LABEL_TEXT_SIZE),
                    ),
                ],
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                ProviderInfoScreen(
                        providerId: res.providerData!.id.validate(),
                        canCustomerContact: canCustomerContact)
                    .launch(context)
                    .then((value) {
                  setStatusBarColor(gradientRed);
                });
              },
              child: Text(
                language.viewDetail,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: gradientRed, // Adjust color as needed
                ),
              ),
            ),
          ],
        ),
        16.height,
        BookingDetailProviderWidget(
          providerData: res.providerData!,
          canCustomerContact: canCustomerContact,
          providerIsHandyman: providerIsHandyman,
          bookingDetail: res.bookingDetail,
        ).onTap(
          () {
            ProviderInfoScreen(
              providerId: res.providerData!.id.validate(),
              canCustomerContact: canCustomerContact,
            ).launch(context).then((value) {
              setStatusBarColor(context.primaryColor);
            });
          },
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
      ],
    );
  }

  Widget refundPaymentDetailsWidget({required BookingDetailResponse snap}) {
    if (((snap.bookingDetail!.status == BookingStatusKeys.cancelled ||
            snap.bookingDetail!.status == BookingStatusKeys.rejected ||
            snap.bookingDetail!.status == BookingStatusKeys.failed) &&
        (snap.service!.isEnableAdvancePayment != 0) &&
        (snap.bookingDetail!.isAdvancePaymentDone)))
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          24.height,
          Text(language.refundPaymentDetails,
              style: boldTextStyle(size: LABEL_TEXT_SIZE)),
          16.height,
          Container(
            decoration: boxDecorationDefault(color: context.cardColor),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${language.refundOf} ${snap.bookingDetail!.refundAmount!.toPriceFormat()}',
                            style: boldTextStyle(size: LABEL_TEXT_SIZE))
                        .expand(),
                    16.width,
                    Text(
                        snap.bookingDetail!.refundStatus
                            .validate()
                            .toBookingStatus(),
                        style: boldTextStyle(
                            size: 14,
                            color: snap.bookingDetail!.refundStatus
                                .validate()
                                .getPaymentStatusBackgroundColor)),
                  ],
                ),
                8.height,
                Row(
                  children: [
                    Text('${language.paymentMethod}: ',
                        style: secondaryTextStyle()),
                    Text(language.wallet,
                        style: boldTextStyle(size: 12, color: gradientRed)),
                  ],
                ),
                8.height,
                Container(
                  decoration: boxDecorationDefault(
                      color: appStore.isDarkMode ? black : Colors.white),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(language.price,
                                  style: secondaryTextStyle(size: 14))
                              .expand(),
                          16.width,
                          PriceWidget(
                              price: snap.service!.price!,
                              color: textPrimaryColorGlobal,
                              isBoldText: true),
                        ],
                      ),
                      16.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(language.advancedPayment,
                                  style: secondaryTextStyle(size: 14))
                              .expand(),
                          16.width,
                          PriceWidget(
                              price: getAdvancePaymentAmount(bookingInfo: snap),
                              color: textPrimaryColorGlobal,
                              isBoldText: true),
                        ],
                      ),
                      16.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(language.cancellationFee,
                                  style: secondaryTextStyle(size: 14))
                              .expand(),
                          16.width,
                          PriceWidget(
                              price:
                                  snap.bookingDetail!.cancellationChargeAmount!,
                              color: textPrimaryColorGlobal,
                              isBoldText: true),
                        ],
                      ),
                      Divider(height: 26, color: context.dividerColor),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(language.refundAmount,
                                  style: boldTextStyle(size: LABEL_TEXT_SIZE))
                              .expand(),
                          16.width,
                          PriceWidget(
                              price: snap.bookingDetail!.refundAmount!,
                              color: gradientRed,
                              isBoldText: true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    return SizedBox();
  }

  getAdvancePaymentAmount({required BookingDetailResponse bookingInfo}) {
    if (bookingInfo.bookingDetail!.paidAmount.validate() != 0) {
      return bookingInfo.bookingDetail!.paidAmount!;
    } else {
      return bookingInfo.bookingDetail!.totalAmount.validate() *
          bookingInfo.service!.advancePaymentPercentage.validate() /
          100;
    }
  }

  Widget extraChargesWidget(
      {required List<ExtraChargesModel> extraChargesList}) {
    if (extraChargesList.isEmpty) return Offstage();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        24.height,
        Text(language.extraCharges,
            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        Container(
          decoration: boxDecorationWithRoundedCorners(
              backgroundColor: context.cardColor, borderRadius: radius()),
          padding: EdgeInsets.all(16),
          child: ListView.separated(
            itemCount: extraChargesList.length,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => 8.height,
            itemBuilder: (_, i) {
              ExtraChargesModel data = extraChargesList[i];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(data.title.validate(),
                              style: secondaryTextStyle(size: 14))
                          .expand(),
                      16.width,
                      Row(
                        children: [
                          Text('${data.qty} * ${data.price.validate()} = ',
                              style: secondaryTextStyle()),
                          4.width,
                          PriceWidget(
                              price:
                                  '${data.price.validate() * data.qty.validate()}'
                                      .toDouble(),
                              color: textPrimaryColorGlobal,
                              isBoldText: true),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget paymentDetailCard(BookingData bookingData) {
    if (bookingData.paymentId != null && bookingData.paymentStatus != null)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          16.height,
          ViewAllLabel(label: language.paymentDetail, list: []),
          8.height,
          Container(
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: context.cardColor,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(language.lblId, style: secondaryTextStyle(size: 14)),
                    Text("#" + bookingData.paymentId.toString(),
                        style: boldTextStyle()),
                  ],
                ),
                16.height,
                if (bookingData.paymentMethod.validate().isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(language.lblMethod,
                          style: secondaryTextStyle(size: 14)),
                      Text(
                        (bookingData.paymentMethod != null
                                ? bookingData.paymentMethod.toString()
                                : language.notAvailable)
                            .capitalizeFirstLetter(),
                        style: boldTextStyle(),
                      ),
                    ],
                  ),
                16.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(language.lblStatus,
                        style: secondaryTextStyle(size: 14)),
                    Text(
                      getPaymentStatusText(
                          bookingData.paymentStatus, bookingData.paymentMethod),
                      style: boldTextStyle(),
                    ),
                  ],
                ),
                if (bookingData.txnId.validate().isNotEmpty &&
                    (bookingData.paymentMethod != PAYMENT_METHOD_COD ||
                        bookingData.paymentMethod !=
                            PAYMENT_METHOD_FROM_WALLET))
                  Row(
                    children: [
                      Text(language.transactionId,
                          style: secondaryTextStyle(size: 14)),
                      8.width,
                      Row(
                        children: [
                          Text(bookingData.txnId.validate(),
                                  textAlign: TextAlign.right,
                                  style: boldTextStyle(color: redColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)
                              .expand(),
                          4.width,
                          InkWell(
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(
                                  text: bookingData.txnId.validate()));
                              toast(language.copied);
                            },
                            child: SizedBox(
                                width: 23,
                                height: 23,
                                child: Icon(Icons.copy, size: 18)),
                          ),
                        ],
                      ).expand(),
                    ],
                  ).paddingTop(16),
              ],
            ),
          ),
        ],
      );

    return Offstage();
  }

  Widget customerReviewWidget(
      {required List<RatingData> ratingList,
      required RatingData? customerReview,
      required BookingData bookingDetail,
      required BookingDetailResponse bookingDetailResponse}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (bookingDetail.status == BookingStatusKeys.complete)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              24.height,
              if (customerReview != null)
                    Text(language.myReviews,
                            style: boldTextStyle(size: LABEL_TEXT_SIZE))
                    .paddingSymmetric(horizontal: 16),
              16.height,
              if (customerReview != null) ReviewWidget(data: customerReview),
              // Handyman Rating Button - Show if handyman exists, is different from provider, and no review exists yet
              if (bookingDetailResponse.handymanData.validate().isNotEmpty &&
                  bookingDetailResponse.providerData != null &&
                  bookingDetailResponse.handymanData!.first.id.validate() != 
                      bookingDetailResponse.providerData!.id.validate() &&
                  bookingDetailResponse.handymanData!.first.handymanReview == null) ...[
                24.height,
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: context.cardColor,
                    borderRadius: radius(),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: ClipOval(
                          child: CachedImageWidget(
                            url: bookingDetailResponse.handymanData!.first.profileImage.validate(),
                            height: 50,
                            width: 50,
                            fit: BoxFit.cover,
                            circle: true,
                          ),
                        ),
                      ),
                      16.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language.lblRateHandyman,
                              style: boldTextStyle(size: LABEL_TEXT_SIZE),
                            ),
                            4.height,
                            Text(
                              bookingDetailResponse.handymanData!.first.displayName.validate(),
                              style: secondaryTextStyle(size: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final handymanData = bookingDetailResponse.handymanData!.first;
                      showInDialog(
                        context,
                        contentPadding: EdgeInsets.zero,
                        builder: (p0) {
                          return AddReviewDialog(
                                serviceId: bookingDetail.serviceId.validate(),
                                bookingId: bookingDetail.id.validate(),
                                handymanId: handymanData.id.validate(),
                              );
                        },
                      ).then((value) {
                        if (value ?? false) {
                          init();
                          setState(() {});
                        }
                      }).catchError((e) {
                        toast(e.toString());
                      });
                        },
                        child: Text(
                          language.btnRate,
                          style: TextStyle(
                            color: gradientRed,
                            decoration: TextDecoration.underline,
                            decorationColor: gradientRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                ),
              ],
            ],
          ),
        16.height,
        if (ratingList.isNotEmpty)
          ViewAllLabel(
            label: '${language.review} (${bookingDetail.totalReview})',
            list: ratingList,
            onTap: () {
              RatingViewAllScreen(
                      ratingData: ratingList,
                      serviceId: bookingDetail.serviceId)
                  .launch(context);
            },
          ),
        8.height,
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: ratingList.length,
          itemBuilder: (context, index) =>
              ReviewWidget(data: ratingList[index]),
        ),
      ],
    );
  }

  Widget locationTrackWidget(
    List<UserData> handymanList,
    BookingDetailResponse res,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        12.height,
        Text(
          handymanList.isEmpty
              ? language.providerLocation
              : res.providerData!.id != handymanList.first.id
                  ? language.handymanLocation
                  : language.providerLocation,
          style: boldTextStyle(),
        ),
        4.height,
        Row(
          children: [
            Text("${language.lastUpdatedAt} ",
                style: secondaryTextStyle(size: 10)),
            Text(
              "${DateTime.parse(providerLocation?.data.datetime.toString() ?? DateTime.now().toString()).timeAgo}",
              style: primaryTextStyle(size: 10),
            ).visible(providerLocation?.data.datetime.isNotEmpty ?? false),
          ],
        ).visible(providerLocation?.data.datetime.isNotEmpty ?? false),
        8.height,
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              GoogleMap(
                zoomControlsEnabled: true,
                initialCameraPosition: CameraPosition(
                  target: _initialLocation,
                  zoom: 14.0,
                ),
                mapType: MapType.normal,
                minMaxZoomPreference: MinMaxZoomPreference(1, 40),
                gestureRecognizers: Set()
                  ..add(Factory<OneSequenceGestureRecognizer>(
                      () => new EagerGestureRecognizer()))
                  ..add(Factory<PanGestureRecognizer>(
                      () => PanGestureRecognizer()))
                  ..add(Factory<ScaleGestureRecognizer>(
                      () => ScaleGestureRecognizer()))
                  ..add(Factory<TapGestureRecognizer>(
                      () => TapGestureRecognizer()))
                  ..add(Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer())),
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                  setState(() {});
                },
                markers: Set<Marker>.from(
                  [
                    if (providerLocation != null)
                      Marker(
                        markerId: MarkerId('Location'),
                        position: LatLng(
                          double.parse(
                              providerLocation?.data.latitude.toString() ??
                                  "0.0"),
                          double.parse(
                              providerLocation?.data.longitude.toString() ??
                                  "0.0"),
                        ),
                        icon: customIcon ?? BitmapDescriptor.defaultMarker,
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: CupertinoActivityIndicator(color: black)
                    .visible(isLocationLoader),
              ),
            ],
          ),
        ),
        10.height,
        Row(
          children: [
            SizedBox(
              height: 42,
              child: GradientButton(
                onPressed: () {
                  TrackLocation(
                    bookingId: widget.bookingId,
                    isHandyman: res.providerData!.id != handymanList.first.id,
                  ).launch(context);
                },
                child: Text(language.track),
              ),
            ).expand(),
            16.width,
            Container(
              width: 42,
              height: 42,
              padding: EdgeInsets.all(12),
              decoration: boxDecorationDefault(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(6)),
              ),
              child: CachedImageWidget(
                url: ic_refresh,
                color: textSecondaryColor,
                height: 42,
              ),
            ).onTap(() {
              refreshProviderLocation();
            }),
            16.width,
            Container(
              width: 42,
              height: 42,
              padding: EdgeInsets.all(12),
              decoration: boxDecorationDefault(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(6),
                ),
              ),
              child: CachedImageWidget(
                url: ic_share,
                color: textSecondaryColor,
                height: 22,
              ),
            ).onTap(
              () {
                shareComponent();
              },
            ),
          ],
        ),
        16.height,
        Text(
          handymanList.isEmpty
              ? language.providerReached
              : res.providerData!.id != handymanList.first.id
                  ? language.handymanReached
                  : language.providerReached,
          style: secondaryTextStyle(),
        ),
      ],
    );
  }

  Widget packageWidget({required BookingPackage? package}) {
    if (package == null) return Offstage();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        Text(language.includedInThisPackage, style: boldTextStyle()),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: package.serviceList!.length,
          padding: EdgeInsets.symmetric(vertical: 8),
          itemBuilder: (_, i) {
            ServiceData data = package.serviceList![i];
            return Container(
              padding: EdgeInsets.all(8),
              margin: EdgeInsets.symmetric(vertical: 8),
              decoration: boxDecorationWithRoundedCorners(
                borderRadius: radius(),
                backgroundColor: context.cardColor,
                border: appStore.isDarkMode
                    ? Border.all(color: context.dividerColor)
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedImageWidget(
                    url: data.attachments!.isNotEmpty
                        ? data.attachments!.first.validate()
                        : "",
                    height: 70,
                    width: 70,
                    fit: BoxFit.cover,
                    radius: 8,
                  ),
                  16.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.name.validate(),
                          style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                      4.height,
                      if (data.subCategoryName.validate().isNotEmpty)
                        Marquee(
                          child: Row(
                            children: [
                              Text('${data.categoryName}',
                                  style: boldTextStyle(
                                      size: 12,
                                      color: textSecondaryColorGlobal)),
                              Text('  >  ',
                                  style: boldTextStyle(
                                      size: 14,
                                      color: textSecondaryColorGlobal)),
                              Text('${data.subCategoryName}',
                                  style: boldTextStyle(
                                      size: 12, color: gradientRed)),
                            ],
                          ),
                        )
                      else
                        Text('${data.categoryName}',
                            style: boldTextStyle(
                                size: 12, color: gradientRed)),
                      4.height,
                      PriceWidget(
                        price: data.price.validate(),
                        hourlyTextColor: Colors.white,
                      ),
                    ],
                  ).flexible()
                ],
              ),
            ).onTap(
              () {
                ServiceDetailScreen(serviceId: data.id!).launch(context);
              },
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
            );
          },
        )
      ],
    );
  }

  Widget myServiceList({required List<ServiceData> serviceList}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        24.height,
        Text(language.myServices, style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        8.height,
        AnimatedListView(
          itemCount: serviceList.length,
          shrinkWrap: true,
          listAnimationType: ListAnimationType.FadeIn,
          itemBuilder: (_, i) {
            ServiceData data = serviceList[i];

            return Container(
              width: context.width(),
              margin: EdgeInsets.symmetric(vertical: 8),
              padding: EdgeInsets.all(8),
              decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: context.cardColor,
                  borderRadius:
                      BorderRadius.all(Radius.circular(defaultRadius))),
              child: Row(
                children: [
                  CachedImageWidget(
                    url: data.attachments.validate().isNotEmpty
                        ? data.attachments!.first.validate()
                        : "",
                    fit: BoxFit.cover,
                    height: 50,
                    width: 50,
                    radius: defaultRadius,
                  ),
                  16.width,
                  Text(data.name.validate(),
                          style: primaryTextStyle(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis)
                      .expand(),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _action({required BookingDetailResponse bookingResponse}) {
    if ((bookingResponse.service != null &&
            bookingResponse.service!.isAdvancePayment &&
            !bookingResponse.service!.isFreeService &&
            bookingResponse.bookingDetail!.bookingPackage == null) &&
        (((bookingResponse.bookingDetail!.paymentStatus == null ||
                    bookingResponse.bookingDetail!.paymentStatus == '' ||
                    bookingResponse.bookingDetail!.paymentStatus ==
                        'pending') &&
                bookingResponse.bookingDetail!.status ==
                    BookingStatusKeys.accept) ||
            (bookingResponse.bookingDetail!.paymentStatus ==
                    SERVICE_PAYMENT_STATUS_ADVANCE_PAID &&
                bookingResponse.bookingDetail!.status ==
                    BookingStatusKeys.complete))) {
      final bool showPayNow = bookingResponse.bookingDetail!.paymentStatus ==
              SERVICE_PAYMENT_STATUS_ADVANCE_PAID &&
          bookingResponse.bookingDetail!.status == BookingStatusKeys.complete;

      return GradientButton(
        child: showPayNow
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(language.lblPayNow,
                      style: boldTextStyle(color: Colors.white, size: 16)),
                  8.width,
                  PriceWidget(
                    price: (bookingResponse.bookingDetail!.totalAmount
                            .validate() -
                        getAdvancePaymentAmount(
                            bookingInfo: bookingResponse))
                        .toDouble(),
                    color: Colors.white,
                    isBoldText: true,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(language.payAdvance,
                      style: boldTextStyle(color: Colors.white, size: 16)),
                  8.width,
                  PriceWidget(
                    price:
                        getAdvancePaymentAmount(bookingInfo: bookingResponse),
                    color: Colors.white,
                    isBoldText: true,
                  ),
                ],
              ),
        onPressed: () {
          if (bookingResponse.bookingDetail!.paymentStatus ==
                  SERVICE_PAYMENT_STATUS_ADVANCE_PAID &&
              bookingResponse.bookingDetail!.status ==
                  BookingStatusKeys.complete) {
            PaymentScreen(bookings: bookingResponse, isForAdvancePayment: true)
                .launch(context);
          } else {
            PaymentScreen(
              bookings: bookingResponse,
              isFromBookService: true,
              isForAdvancePayment: true,
            ).launch(context);
          }
        },
      );
    } else if (bookingResponse.bookingDetail!.status ==
        BookingStatusKeys.pending) {
      return GradientButton(
        onPressed: () {
          _handleCancelClick(
            status: bookingResponse,
            isDurationMode: checkTimeDifference(
              inputDateTime: DateTime.parse(
                  bookingResponse.bookingDetail!.date.validate()),
            ),
          );
        },
        child: Text(language.lblCancelBooking),
      );
    } else if (bookingResponse.bookingDetail!.status ==
        BookingStatusKeys.onGoing) {
      return GradientButton(
        onPressed: () {
          _handleStartClick(status: bookingResponse);
        },
        child: Text(language.lblStart),
      );
    } else if (bookingResponse.bookingDetail!.status ==
        BookingStatusKeys.inProgress) {
      return AppButton(
        text: language.lblHold,
        color: hold,
        textColor: Colors.white,
        onTap: () {
                _handleHoldClick(status: bookingResponse);
              },
      );
    } else if (bookingResponse.bookingDetail!.status ==
        BookingStatusKeys.hold) {
      return Row(
        children: [
          GradientButton(
            onPressed: () {
              _handleResumeClick(status: bookingResponse);
            },
            child: Text(language.lblResume),
          ).expand(),
          // 16.width,
          // AppButton(
          //   text: language.lblCancel,
          //   textColor: Colors.white,
          //   color: cancelled,
          //   onTap: () {
          //     _handleCancelClick(
          //         status: bookingResponse,
          //         isDurationMode: checkTimeDifference(
          //             inputDateTime: DateTime.parse(
          //                 bookingResponse.bookingDetail!.date.validate())));
          //   },
          // ).expand(),
        ],
      ).paddingOnly(bottom: 16);
    } else if (bookingResponse.bookingDetail!.status ==
        BookingStatusKeys.doneByProvider) {
      return GradientButton(
        onPressed: () {
          _handleDoneClick(status: bookingResponse);
        },
        child: Text(language.lblConfirmJobDone),
      );
    } else if (bookingResponse.bookingDetail!.status ==
        BookingStatusKeys.pendingApproval) {
      return Container(
        width: context.width(),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.cardColor),
        child: Text(language.lblWaitingForResponse, style: boldTextStyle())
            .center(),
      );
    } else if (bookingResponse.bookingDetail!.status ==
            BookingStatusKeys.complete &&
        (bookingResponse.bookingDetail!.type != SERVICE_TYPE_FREE ||
            bookingResponse.bookingDetail!.paymentMethod ==
                PAYMENT_METHOD_COD) &&
        bookingResponse.bookingDetail!.paymentId == null) {
      return GradientButton(
        onPressed: () {
          PaymentScreen(bookings: bookingResponse, isForAdvancePayment: false)
              .launch(context);
        },
        child: Text(language.lblPayNow),
      );
    } else if (!bookingResponse.bookingDetail!.isFreeService &&
        bookingResponse.bookingDetail!.status == BookingStatusKeys.complete &&
        bookingResponse.bookingDetail!.paymentStatus == SERVICE_PAYMENT_STATUS_PAID &&
        !isSentInvoiceOnEmail) {
      return GradientButton(
        onPressed: () async {
          bool? res = await showInDialog(
            context,
            contentPadding: EdgeInsets.zero,
            dialogAnimation: DialogAnimation.SLIDE_TOP_BOTTOM,
            barrierDismissible: false,
            builder: (_) => InvoiceRequestDialogComponent(
                bookingId: bookingResponse.bookingDetail!.id.validate()),
          );

          if (res ?? false) {
            isSentInvoiceOnEmail = res.validate();

            init();
            setState(() {});
          }
        },
        child: Text(language.requestInvoice),
      );
    } else if (bookingResponse.bookingDetail!.status ==
            BookingStatusKeys.complete &&
        isSentInvoiceOnEmail) {
      return Container(
        width: context.width(),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.cardColor),
        child: Text(language.sentInvoiceText,
                style: boldTextStyle(), textAlign: TextAlign.center)
            .center(),
      );
    }

    return Offstage();
  }

  Future<void> _openChatWithUser({
    required int userId, 
    required String displayName,
    String? profileImageUrl, // Profile image from booking detail data
  }) async {
    if (userId == 0 || appStore.userId == userId) {
      toast(language.lblNotValidUser);
      return;
    }
    String? avatarUrl;
    try {
      if (displayName.isNotEmpty) {
        final matches = await chatSearchUsers(query: displayName, page: 1);
        if (matches.isNotEmpty) {
          ChatUserItem? exact;
          for (final u in matches) {
            if (u.id == userId) {
              exact = u; break;
            }
          }
          avatarUrl = (exact ?? matches.first).avatarUrl;
        }
      }
    } catch (e) {
      // ignore avatar preload errors
    }
    
    // Use profile image from booking detail as fallback if chatSearchUsers didn't return avatar
    if (avatarUrl == null || avatarUrl.isEmpty) {
      avatarUrl = profileImageUrl;
    }
    
    try {
      final open = await chatOpenWithUser(userId: userId);
      ApiChatScreen(
        conversationId: open.conversationId,
        otherUserId: userId,
        otherUserName: displayName,
        otherUserAvatarUrl: avatarUrl,
      ).launch(context);
    } catch (e) {
      toast(e.toString());
    }
  }

  Widget buildBodyWidget(AsyncSnapshot<BookingDetailResponse> snap) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            AnimatedScrollView(
              padding: EdgeInsets.only(bottom: 60),
              physics: AlwaysScrollableScrollPhysics(),
              listAnimationType: ListAnimationType.FadeIn,
              children: [
                _buildReasonWidget(snap: snap.data!),
                _pendingMessage(snap: snap.data!),
                _completeMessage(snap: snap.data!),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking Date & Slot',
                        style: boldTextStyle(size: LABEL_TEXT_SIZE),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      8.height,
                      Container(
                        decoration: BoxDecoration(
                          gradient: appPrimaryGradient,
                          borderRadius: radiusOnly(topLeft: 8, topRight: 8),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8), // Space around content
                        child: bookingIdWidget(),
                      ),
                      if (snap.data!.bookingDetail!.paymentStatus ==
                          PENDING_BY_ADMIN)
                        Container(
                          width: context.width(),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                gradientRed.withValues(alpha: 0.10),
                                gradientBlue.withValues(alpha: 0.10),
                              ],
                            ),
                            borderRadius: radius(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                decoration: const BoxDecoration(
                                    gradient: appPrimaryGradient,
                                    shape: BoxShape.circle),
                                padding: EdgeInsets.all(8),
                                child: const Icon(Icons.info_outline,
                                    color: Colors.white, size: 18),
                              ),
                              8.width,
                              Expanded(
                                child: Marquee(
                                  child: Text(
                                    'Payment submitted via Bank Transfer. Awaiting admin confirmation.',
                                    style: boldTextStyle(size: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).paddingTop(12),
                      Container(
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius:
                              radiusOnly(bottomLeft: 8, bottomRight: 8),
                        ),
                        padding: EdgeInsets.only(left: 16, right: 16, top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            serviceDetailWidget(
                              bookingDetail: snap.data!.bookingDetail!,
                              serviceDetail: snap.data!.service!,
                              // postJobData: snap.data!.postRequestDetail!,
                            ),
                            if (snap.hasData)
                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      backgroundColor: Colors.transparent,
                                      context: context,
                                      isScrollControlled: true,
                                      isDismissible: true,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      builder: (_) {
                                        return DraggableScrollableSheet(
                                          initialChildSize: 0.50,
                                          minChildSize: 0.2, // Minimum height
                                          maxChildSize: 1, // Full-screen height
                                          builder: (context, scrollController) {
                                            return BookingHistoryComponent(
                                              data: snap.data!.bookingActivity!
                                                  .reversed
                                                  .toList(),
                                              scrollController:
                                                  scrollController, // Pass scrollController
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: Text(
                                    language.viewStatus,
                                    style: boldTextStyle(
                                        color: gradientRed, size: 14),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      8.height,

                      /// Service Counter Time Widget
                      counterWidget(value: snap.data!),

                      /// My Service List
                      if (snap.data!.postRequestDetail != null &&
                          snap.data!.postRequestDetail!.service != null)
                        myServiceList(
                            serviceList:
                                snap.data!.postRequestDetail!.service!),

                      /// Package Info if User selected any Package
                      packageWidget(
                          package: snap.data!.bookingDetail!.bookingPackage),

                      /// Location
                      locationTrackWidget(
                        snap.data!.handymanData.validate(),
                        snap.data!,
                      ).visible(BookingStatusKeys.onGoing ==
                          snap.data!.bookingDetail!.status),

                      /// Service Proof
                      serviceProofListWidget(
                          list: snap.data!.serviceProof.validate()),

                      /// About Provider Card
                      providerWidget(res: snap.data!),

                      /// About Handyman Card
                      handymanWidget(
                        handymanList: snap.data!.handymanData.validate(),
                        res: snap.data!,
                        serviceDetail: snap.data!.service!,
                        bookingDetail: snap.data!.bookingDetail!,
                      ),

                      /// Chat buttons after Accept + Advance Paid
                      Builder(builder: (context) {
                        final isAdvanceDone = snap.data!.bookingDetail!.isAdvancePaymentDone;
                        // Show chat buttons once any advance is recorded (includes bank transfer pending)
                        if (!isAdvanceDone) return Offstage();

                        final provider = snap.data!.providerData;
                        final handymen = snap.data!.handymanData.validate();

                        List<Widget> buttons = [];
                        if (provider != null && provider.id != null) {
                          buttons.add(
                            GradientButton(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline, color: white, size: 18),
                                      8.width,
                                      Text(
                                        provider.displayName.validate(),
                                        style: boldTextStyle(color: white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  4.height,
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: white.withValues(alpha: 0.15),
                                      borderRadius: radius(12),
                                    ),
                                    child: Text(
                                      'Provider',
                                      style: secondaryTextStyle(color: white, size: 10),
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: () => _openChatWithUser(
                                userId: provider.id!.toInt(),
                                displayName: provider.displayName.validate(),
                                profileImageUrl: provider.profileImage.validate(),
                              ),
                            ).expand(),
                          );
                        }
                        if (handymen.isNotEmpty && handymen.first.id != null) {
                          if (buttons.isNotEmpty) buttons.add(16.width);
                          buttons.add(
                            GradientButton(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.chat_bubble_outline, color: white, size: 18),
                                      8.width,
                                      Flexible(
                                        child: Text(
                                          handymen.first.displayName.validate(),
                                          style: boldTextStyle(color: white),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  4.height,
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: white.withValues(alpha: 0.15),
                                      borderRadius: radius(12),
                                    ),
                                    child: Text(
                                      'Handyman',
                                      style: secondaryTextStyle(color: white, size: 10),
                                    ),
                                  ),
                                ],
                              ),
                              onPressed: () => _openChatWithUser(
                                userId: handymen.first.id!.toInt(),
                                displayName: handymen.first.displayName.validate(),
                                profileImageUrl: handymen.first.profileImage.validate(),
                              ),
                            ).expand(),
                          );
                        }

                        if (buttons.isEmpty) return Offstage();
                        return Row(children: buttons)
                            .paddingOnly(top: 8, bottom: 8);
                      }),

                      /// Refund Payment Details
                      refundPaymentDetailsWidget(snap: snap.data!),

                      ///Add-ons
                      if (snap.data!.bookingDetail!.serviceaddon
                          .validate()
                          .isNotEmpty)
                        AddonComponent(
                          isFromBookingDetails: true,
                          showDoneBtn: snap.data!.bookingDetail!.status ==
                              BookingStatusKeys.inProgress,
                          serviceAddon:
                              snap.data!.bookingDetail!.serviceaddon.validate(),
                          onDoneClick: (p0) {
                            showInDialog(
                              context,
                              contentPadding: EdgeInsets.zero,
                              backgroundColor: context.scaffoldBackgroundColor,
                              builder: (context) {
                                return AppCommonDialog(
                                  title: language.confirmationRequestTxt,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      24.height,
                                      Row(
                                        children: [
                                          AppButton(
                                            text: language.lblNo,
                                            color: context.scaffoldBackgroundColor,
                                            textColor: context.iconColor,
                                            onTap: () {
                                              finish(context);
                                            },
                                          ).expand(),
                                          16.width,
                                          GradientButton(
                                            onPressed: () {
                                              finish(context);
                                _handleAddonDoneClick(
                                    status: snap.data!, serviceAddon: p0);
                              },
                                            child: Text(language.lblYes),
                                          ).expand(),
                                        ],
                                      ).paddingSymmetric(horizontal: 16),
                                      16.height,
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),

                      /// Price Details
                      PriceCommonWidget(
                        bookingDetail: snap.data!.bookingDetail!,
                        serviceDetail: snap.data!.service!,
                        taxes: snap.data!.bookingDetail!.taxes.validate(),
                        couponData: snap.data!.couponData,
                        bookingPackage:
                            snap.data!.bookingDetail!.bookingPackage != null
                                ? snap.data!.bookingDetail!.bookingPackage
                                : null,
                      ),

                      /// Extra charges
                      extraChargesWidget(
                          extraChargesList: snap
                              .data!.bookingDetail!.extraCharges
                              .validate()),

                      /// Payment Detail Card
                      if (snap.data!.service!.type.validate() !=
                          SERVICE_TYPE_FREE)
                        paymentDetailCard(snap.data!.bookingDetail!),

                      /// Customer Review widget
                      customerReviewWidget(
                          ratingList: snap.data!.ratingData.validate(),
                          customerReview: snap.data!.customerReview,
                          bookingDetail: snap.data!.bookingDetail!,
                          bookingDetailResponse: snap.data!),
                    ],
                  ),
                ),
              ],
            ).expand(),
            SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: _action(bookingResponse: snap.data!))
                .paddingSymmetric(horizontal: 16.0, vertical: 12.0)
          ],
        ),
      ],
    );
  }

  //endregion

  //region Methods
  void commonStartTimer(
      {required bool isHourlyService,
      required String status,
      required int timeInSec}) {
    if (isHourlyService) {
      Map<String, dynamic> liveStreamRequest = {
        "inSeconds": timeInSec,
        "status": status,
      };
      LiveStream().emit(LIVESTREAM_START_TIMER, liveStreamRequest);
    }
  }

  void _handleAddonDoneClick(
      {required BookingDetailResponse status,
      required Serviceaddon serviceAddon}) async {
    Map request = {
      CommonKeys.id: status.bookingDetail!.id.validate(),
      BookingUpdateKeys.serviceAddon: [serviceAddon.id],
      BookingUpdateKeys.type: BookingUpdateKeys.serviceAddon,
    };

    appStore.setLoading(true);
    await updateBooking(request).then((res) async {
      toast(res.message!);
      appStore.setLoading(false);
      init();
      setState(() {});
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  void _handleDoneClick({required BookingDetailResponse status}) {
    bool isAnyServiceAddonUnCompleted = status.bookingDetail!.serviceaddon
        .validate()
        .any((element) => element.status.getBoolInt() == false);
    showInDialog(
      context,
      contentPadding: EdgeInsets.zero,
      backgroundColor: context.scaffoldBackgroundColor,
      builder: (context) {
        return AppCommonDialog(
      title: isAnyServiceAddonUnCompleted
          ? language.confirmation
          : language.lblEndServicesMsg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAnyServiceAddonUnCompleted) ...[
                24.height,
                Text(
                  language.pleaseNoteThatAllServiceMarkedCompleted,
                  style: secondaryTextStyle(),
                  textAlign: TextAlign.center,
                ).paddingSymmetric(horizontal: 16),
              ],
              24.height,
              Row(
                children: [
                  AppButton(
                    text: language.lblNo,
                    color: context.scaffoldBackgroundColor,
                    textColor: context.iconColor,
                    onTap: () {
                      finish(context);
                    },
                  ).expand(),
                  16.width,
                  GradientButton(
                    onPressed: () async {
                      finish(context);
        final startAt = status.bookingDetail!.startAt == null
            ? null
            : DateTime.parse(status.bookingDetail!.startAt!);
        final endAt = DateTime.now();
        final currentDurationDiff =
            startAt == null ? 0 : endAt.difference(startAt).inSeconds;

        String endDateTime = DateFormat(BOOKING_SAVE_FORMAT).format(endAt);

        final prevDiff = status.bookingDetail!.durationDiff.toInt();
        num durationDiff = currentDurationDiff;

        log('Current DIFF: $currentDurationDiff');
        log('Previous DIFF: $prevDiff');
        log('DURATION DIFF: $durationDiff');
        log('START AT: $startAt ');
        log('END AT: $endDateTime');

        Map request = {
          CommonKeys.id: status.bookingDetail!.id.validate(),
          BookingUpdateKeys.startAt: formatBookingDate(
            startAt.toString(),
            format: BOOKING_SAVE_FORMAT,
            isLanguageNeeded: false,
          ),
          BookingUpdateKeys.endAt: formatBookingDate(
            endAt.toString(),
            format: BOOKING_SAVE_FORMAT,
            isLanguageNeeded: false,
          ),
          BookingUpdateKeys.durationDiff: durationDiff,
          BookingUpdateKeys.reason: DONE,
          CommonKeys.status: BookingStatusKeys.pendingApproval,
          BookingUpdateKeys.paymentStatus:
              status.bookingDetail!.isAdvancePaymentDone
                  ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                  : status.bookingDetail!.paymentStatus.validate(),
        };
        //
        // print(request);
        // return;

        //TODO Complete all service addon on booking
        if (status.bookingDetail!.serviceaddon.validate().isNotEmpty) {
          request.putIfAbsent(
              BookingUpdateKeys.serviceAddon,
              () => status.bookingDetail!.serviceaddon
                  .validate()
                  .map((e) => e.id)
                  .toList());
        }

        /// Perform new calculations if service hourly
        // if (status.bookingDetail!.isHourlyService) {
        //   BookingAmountModel bookingAmountModel = finalCalculations(
        //     servicePrice: status.bookingDetail!.amount.validate(),
        //     appliedCouponData: status.couponData,
        //     discount: status.service!.discount.validate(),
        //     serviceAddons: serviceAddonStore.selectedServiceAddon,
        //     taxes: status.bookingDetail!.taxes,
        //     quantity: status.bookingDetail!.quantity.validate(),
        //     selectedPackage: status.bookingDetail!.bookingPackage,
        //     extraCharges: status.bookingDetail!.extraCharges,
        //     serviceType: status.service!.type!,
        //     bookingType: status.bookingDetail!.bookingType!,
        //     durationDiff: durationDiff.toInt(),
        //   );

        //   request.addAll(bookingAmountModel.toBookingUpdateJson());
        // }

        appStore.setLoading(true);

        log('RES: ${jsonEncode(request)}');
        await updateBooking(request).then((res) async {
          toast(res.message!);
          commonStartTimer(
              isHourlyService: status.bookingDetail!.isHourlyService,
              status: BookingStatusKeys.complete,
              timeInSec: status.bookingDetail!.durationDiff.validate().toInt());

          appStore.setLoading(false);
          init();
          setState(() {});
        }).catchError((e) {
          appStore.setLoading(false);
          toast(e.toString(), print: true);
        });
                    },
                    child: Text(
                      language.lblYes,
                      style: boldTextStyle(color: Colors.white),
                    ),
                  ).expand(),
                ],
              ).paddingAll(16),
            ],
          ),
        );
      },
    );
  }

  void startClick({required BookingDetailResponse status}) async {
    Map request = {
      CommonKeys.id: status.bookingDetail!.id.validate(),
      BookingUpdateKeys.startAt: formatBookingDate(
        DateTime.now().toString(),
        format: BOOKING_SAVE_FORMAT,
        isLanguageNeeded: false,
      ),
      BookingUpdateKeys.endAt: '',
      BookingUpdateKeys.durationDiff: 0,
      BookingUpdateKeys.reason: "",
      CommonKeys.status: BookingStatusKeys.inProgress,
      BookingUpdateKeys.paymentStatus:
          status.bookingDetail!.isAdvancePaymentDone
              ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
              : status.bookingDetail!.paymentStatus.validate(),
    };

    appStore.setLoading(true);

    await updateBooking(request).then((res) async {
      toast(res.message!);
      stopLocationUpdates();
      commonStartTimer(
          isHourlyService: status.bookingDetail!.isHourlyService,
          status: BookingStatusKeys.inProgress,
          timeInSec: status.bookingDetail!.durationDiff.validate().toInt());

      init();
      setState(() {});
    }).catchError((e) {
      toast(e.toString(), print: true);
    });

    appStore.setLoading(false);
  }

  void _handleStartClick({required BookingDetailResponse status}) {
    showInDialog(
      context,
      contentPadding: EdgeInsets.zero,
      backgroundColor: context.scaffoldBackgroundColor,
      builder: (context) {
        return AppCommonDialog(
      title: language.confirmationRequestTxt,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              24.height,
              Row(
                children: [
                  AppButton(
                    text: language.lblNo,
                    color: context.scaffoldBackgroundColor,
                    textColor: context.iconColor,
                    onTap: () {
                      finish(context);
                    },
                  ).expand(),
                  16.width,
                  GradientButton(
                    onPressed: () {
                      finish(context);
        startClick(status: status);
                    },
                    child: Text(language.lblYes),
                  ).expand(),
                ],
              ).paddingSymmetric(horizontal: 16),
              16.height,
            ],
          ),
        );
      },
    );
  }

  void _handleResumeClick({required BookingDetailResponse status}) {
    showInDialog(
      context,
      contentPadding: EdgeInsets.zero,
      backgroundColor: context.scaffoldBackgroundColor,
      builder: (context) {
        return AppCommonDialog(
      title: language.lblConFirmResumeService,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              24.height,
              Row(
                children: [
                  AppButton(
                    text: language.lblNo,
                    color: context.scaffoldBackgroundColor,
                    textColor: context.iconColor,
                    onTap: () {
                      finish(context);
                    },
                  ).expand(),
                  16.width,
                  GradientButton(
                    onPressed: () async {
                      finish(context);
        Map request = {
          CommonKeys.id: status.bookingDetail!.id.validate(),
          BookingUpdateKeys.startAt: formatBookingDate(
            DateTime.now().toString(),
            format: BOOKING_SAVE_FORMAT,
            isLanguageNeeded: false,
          ),
          BookingUpdateKeys.endAt: '',
          BookingUpdateKeys.durationDiff:
              status.bookingDetail!.durationDiff.toInt(),
          BookingUpdateKeys.reason: "",
          CommonKeys.status: BookingStatusKeys.inProgress,
          BookingUpdateKeys.paymentStatus:
              status.bookingDetail!.isAdvancePaymentDone
                  ? SERVICE_PAYMENT_STATUS_ADVANCE_PAID
                  : status.bookingDetail!.paymentStatus.validate(),
        };

        appStore.setLoading(true);

        await updateBooking(request).then((res) async {
          toast(res.message!);
          commonStartTimer(
              isHourlyService: status.bookingDetail!.isHourlyService,
              status: BookingStatusKeys.inProgress,
              timeInSec: status.bookingDetail!.durationDiff.validate().toInt());
          init();
          setState(() {});
        }).catchError((e) {
          appStore.setLoading(false);
          toast(e.toString(), print: true);
        });
                    },
                    child: Text(language.lblYes),
                  ).expand(),
                ],
              ).paddingSymmetric(horizontal: 16),
              16.height,
            ],
          ),
        );
      },
    );
  }

  void _handleHoldClick({required BookingDetailResponse status}) {
    if (status.bookingDetail!.status == BookingStatusKeys.inProgress) {
      showInDialog(
        context,
        contentPadding: EdgeInsets.zero,
        backgroundColor: context.scaffoldBackgroundColor,
        builder: (context) {
          return AppCommonDialog(
            title: language.lblConfirmService,
            child: ReasonDialog(
              status: status,
              currentStatus: BookingStatusKeys.hold,
            ),
          );
        },
      ).then((value) async {
        if (value != null) {
          init();
          setState(() {});
        }
      });
    }
  }

  void _handleCancelClick(
      {required BookingDetailResponse status, required bool isDurationMode}) {
    if (status.bookingDetail!.status == BookingStatusKeys.pending ||
        status.bookingDetail!.status == BookingStatusKeys.accept ||
        status.bookingDetail!.status == BookingStatusKeys.hold) {
      showInDialog(
        context,
        contentPadding: EdgeInsets.zero,
        insetPadding: isDurationMode &&
                !status.service!.isFreeService &&
                appConfigurationStore.cancellationCharge
            ? EdgeInsets.symmetric(horizontal: 10)
            : null,
        builder: (context) {
          if (isDurationMode &&
              !status.service!.isFreeService &&
              appConfigurationStore.cancellationCharge) {
            return CancellationsBookingChargeDialog(
                status: status, isDurationMode: isDurationMode);
          } else {
            return AppCommonDialog(
              title: language.lblCancelReason,
              child: ReasonDialog(status: status),
            );
          }
        },
      ).then((value) {
        if (value != null) {
          init();
          setState(() {});
        }
      });
    }
  }

  void refreshProviderLocation() async {
    isLocationLoader = true;
    setState(() {});
    getProviderLocation(widget.bookingId).then((value) {
      providerLocation = value;
      _currentPosition = LatLng(
        double.parse(providerLocation?.data.latitude.toString() ?? "0.0"),
        double.parse(providerLocation?.data.longitude.toString() ?? "0.0"),
      );
      _initialLocation = _currentPosition!;
      mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition!,
          zoom: 15.0,
        ),
      ));
      setState(() {});
    }).catchError((error) {
      log(error.toString());
    }).whenComplete(() {
      isLocationLoader = false;
      setState(() {});
    });
  }

  void startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(
      Duration(seconds: providerLocationRefreshPeriodInSeconds),
      (Timer timer) async {
        if (bookingStatus == BookingStatusKeys.onGoing) {
          refreshProviderLocation();
        }
      },
    );
  }

  void stopLocationUpdates() {
    _locationUpdateTimer?.cancel();
  }

  Future<void> createCustomIcon() async {
    final ImageConfiguration imageConfiguration =
        ImageConfiguration(size: Size(24, 24));
    customIcon = await BitmapDescriptor.asset(
      imageConfiguration,
      indicator_2,
    );
  }

  void shareComponent() {
    String url;
    url =
        'https://www.google.com/maps/search/?api=1&query=${providerLocation?.data.latitude},${providerLocation?.data.longitude}';
    share(url: url, context: context);
  }

  //endregion

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      stopLocationUpdates();
    } else if (state == AppLifecycleState.resumed) {
      refreshProviderLocation();
      startLocationUpdates();
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    stopLocationUpdates();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<BookingDetailResponse>(
          future: future,
          initialData: cachedBookingDetailList
              .firstWhere(
                  (element) => element?.$1 == widget.bookingId.validate(),
                  orElse: () => null)
              ?.$2,
          builder: (context, snap) {
            if (snap.hasData) {
              return RefreshIndicator(
                onRefresh: () async {
                  init();
                  setState(() {});

                  return await 2.seconds.delay;
                },
                child: AppScaffold(
                  appBarTitle: snap.hasData
                      ? snap.data!.bookingDetail!.status
                          .validate()
                          .toBookingStatus()
                      : "",
                  child: buildBodyWidget(snap),
                ),
              );
            }

            return Scaffold(
              body: snapWidgetHelper(
                snap,
                errorBuilder: (error) {
                  return NoDataWidget(
                    title: error,
                    imageWidget: ErrorStateWidget(),
                    retryText: language.reload,
                    onRetry: () {
                      init();
                      setState(() {});
                    },
                  );
                },
                loadingWidget: BookingDetailShimmer(),
              ),
            );
          },
        ),
      ],
    );
  }
}
