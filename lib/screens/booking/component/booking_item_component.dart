import 'package:booking_system_flutter/component/app_common_dialog.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/dotted_line.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/booking_data_model.dart';
import 'package:booking_system_flutter/screens/booking/component/edit_booking_service_dialog.dart';
import 'package:booking_system_flutter/screens/booking/handyman_info_screen.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/disabled_rating_bar_widget.dart';
import '../../../model/service_detail_response.dart';
import '../../../network/rest_apis.dart';
import 'booking_slots.dart';

class BookingItemComponent extends StatefulWidget {
  final BookingData bookingData;

  BookingItemComponent({required this.bookingData});

  @override
  State<BookingItemComponent> createState() => _BookingItemComponentState();
}

class _BookingItemComponentState extends State<BookingItemComponent> {
  String? _providerCityCountryLabel;

  String _formatVisitType(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    final upper = trimmed.toUpperCase();
    switch (upper) {
      case 'ON_SITE':
        return 'Onsite';
      default:
        final normalized = trimmed.replaceAll('_', ' ').replaceAll('-', ' ');
        final parts = normalized.split(RegExp(r'\s+'));
        return parts
            .map((w) => w.isEmpty
                ? w
                : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
            .join(' ');
    }
  }

  @override
  void initState() {
    super.initState();
    _maybeFetchProviderLocation();
  }

  @override
  void didUpdateWidget(covariant BookingItemComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookingData.providerId != widget.bookingData.providerId ||
        oldWidget.bookingData.handyman?.isEmpty !=
            widget.bookingData.handyman?.isEmpty) {
      _providerCityCountryLabel = null;
      _maybeFetchProviderLocation();
    }
  }

  void _maybeFetchProviderLocation() async {
    // Always fetch provider's city/country from provider detail API
    // (bookingData.cityName/countryName are for service location, not provider location)
    // API: user-detail?id=$id&login_user_id=$userId
    if (_providerCityCountryLabel == null &&
        widget.bookingData.providerId != null) {
      try {
        final res = await getProviderDetail(
            widget.bookingData.providerId!.validate(),
            userId: appStore.userId.validate());
        final providerCity = res.userData?.cityName.validate() ?? '';
        final providerCountry = res.userData?.countryName.validate() ?? '';
        log('Provider Location - ID: ${widget.bookingData.providerId}, City: $providerCity, Country: $providerCountry');
        final label =
            "$providerCity${(providerCity.isNotEmpty && providerCountry.isNotEmpty) ? ' - ' : ''}$providerCountry";
        if (mounted) setState(() => _providerCityCountryLabel = label);
      } catch (e) {
        log('Error fetching provider location: $e');
        // Ignore fetching errors to keep list smooth
      }
    }
  }
  Widget _buildEditBookingWidget() {
    if (widget.bookingData.status == BookingStatusKeys.pending &&
        isDateTimeAfterNow) {
      return IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: ic_edit_square.iconImage(size: 16),
        visualDensity: VisualDensity.compact,
        onPressed: () async {
          ServiceDetailResponse res = await getServiceDetails(
              serviceId: widget.bookingData.serviceId.validate(),
              customerId: appStore.userId,
              fromBooking: true);

          if (widget.bookingData.isSlotBooking) {
            showModalBottomSheet(
              backgroundColor: Colors.transparent,
              context: context,
              isScrollControlled: true,
              isDismissible: true,
              shape: RoundedRectangleBorder(
                  borderRadius: radiusOnly(
                      topLeft: defaultRadius, topRight: defaultRadius)),
              builder: (_) {
                return DraggableScrollableSheet(
                  initialChildSize: 0.65,
                  minChildSize: 0.65,
                  maxChildSize: 1,
                  builder: (context, scrollController) => BookingSlotsComponent(
                    data: res,
                    bookingData: widget.bookingData,
                    showAppbar: true,
                    scrollController: scrollController,
                    onApplyClick: (selectedSlot) {
                      setState(() {});
                    },
                  ),
                );
              },
            );
          } else {
            showInDialog(
              context,
              contentPadding: EdgeInsets.zero,
              hideSoftKeyboard: true,
              backgroundColor: context.cardColor,
              builder: (p0) {
                return AppCommonDialog(
                  title: language.lblUpdateDateAndTime,
                  child: EditBookingServiceDialog(data: widget.bookingData),
                );
              },
            );
          }
        },
      );
    }
    return Offstage();
  }

  String buildTimeWidget({required BookingData bookingDetail}) {
    if (bookingDetail.bookingSlot == null) {
      return formatDate(bookingDetail.date.validate(), isTime: true);
    }
    return formatDate(
        getSlotWithDate(
            date: bookingDetail.date.validate(),
            slotTime: bookingDetail.bookingSlot.validate()),
        isTime: true);
  }

  Widget _buildProviderCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ProviderInfoScreen(
          providerId: widget.bookingData.providerId.validate(),
        ).launch(context);
      },
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                    color: context.dividerColor, width: 1),
                shape: BoxShape.circle,
              ),
              child: CachedImageWidget(
                url: widget.bookingData.providerImage.validate(),
                circle: true,
                height: 40,
                width: 40,
                fit: BoxFit.cover,
              ),
            ),
            16.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    // Verified/Not Verified Icon (dynamic from API)
                    if (widget.bookingData.verifiedStickerIcon.validate().isNotEmpty)
                      CachedImageWidget(
                        url: widget.bookingData.verifiedStickerIcon.validate(),
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      )
                    else
                      Image.asset(
                        'assets/icons/verified_badge.jpg',
                        width: 20,
                        height: 20,
                      ),
                    SizedBox(width: 6),
                    // Membership Icon (dynamic from API)
                    if (widget.bookingData.membershipIcon.validate().isNotEmpty)
                      CachedImageWidget(
                        url: widget.bookingData.membershipIcon.validate(),
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                      )
                    else
                      Image.asset(
                        'assets/icons/free-membership.jpg',
                        width: 20,
                        height: 20,
                      ),
                  ],
                ),
                5.height,
                Row(
                  children: [
                    Marquee(
                      child: Text(
                        widget.bookingData.providerName.validate(),
                        style: boldTextStyle(size: 14),
                      ),
                    ).flexible(),
                    4.width,
                    ImageIcon(
                      AssetImage(ic_verified),
                      size: 14,
                      color: Colors.green,
                    ).visible(
                      widget.bookingData.providerIsVerified.validate() == 1,
                    ),
                  ],
                ),
                Text(
                  language.textProvider,
                  style: secondaryTextStyle(size: 12),
                ),
                // City - Country label (provider's location, fetched from API)
                Text(
                  (_providerCityCountryLabel?.isNotEmpty ?? false)
                      ? _providerCityCountryLabel!
                      : 'N/A',
                  style: secondaryTextStyle(size: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ).expand(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // address not used here; we show city/country from provider/handyman

    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 16),
      width: context.width(),
      decoration: BoxDecoration(
          color: appStore.isDarkMode ? context.cardColor : cardLightColor,
          borderRadius: radius()),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.bookingData.isPackageBooking)
                CachedImageWidget(
                  url: widget.bookingData.bookingPackage!.imageAttachments
                          .validate()
                          .isNotEmpty
                      ? widget.bookingData.bookingPackage!.imageAttachments
                          .validate()
                          .first
                          .validate()
                      : "",
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                  radius: defaultRadius,
                )
              else
                CachedImageWidget(
                  url: widget.bookingData.serviceAttachments
                          .validate()
                          .isNotEmpty
                      ? widget.bookingData.serviceAttachments!.first.validate()
                      : '',
                  fit: BoxFit.cover,
                  width: 80,
                  height: 80,
                  radius: defaultRadius,
                ),
              16.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            margin: EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              color:
                                  gradientRed.withValues(alpha: 0.1),
                              borderRadius: radius(16),
                              border: Border.all(color: gradientRed),
                            ),
                            child: Text(
                              '#${widget.bookingData.id.validate()}',
                              style: boldTextStyle(
                                  color: gradientRed, size: 12),
                            ),
                          ).flexible(),
                          5.width,
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.bookingData.status
                                  .validate()
                                  .getPaymentStatusBackgroundColor
                                  .withValues(alpha: 0.1),
                              borderRadius: radius(16),
                              border: Border.all(
                                  color: widget.bookingData.status
                                      .validate()
                                      .getPaymentStatusBackgroundColor),
                            ),
                            child: Marquee(
                              child: Text(
                                widget.bookingData.status ==
                                            BookingStatusKeys.accept &&
                                        (widget.bookingData.paymentStatus ==
                                                null ||
                                            widget.bookingData.paymentStatus ==
                                                '' ||
                                            widget.bookingData.paymentStatus ==
                                                'pending')
                                    ? 'Waiting for advance payment'
                                    : widget.bookingData.status
                                        .validate()
                                        .toBookingStatus(),
                                style: boldTextStyle(
                                  color: widget.bookingData.status
                                      .validate()
                                      .getPaymentStatusBackgroundColor,
                                  size: 12,
                                ),
                              ),
                            ),
                          ).flexible(),
                          if (widget.bookingData.isPostJob)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              margin: EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color:
                                    gradientRed.withValues(alpha: 0.1),
                                border: Border.all(color: gradientRed),
                                borderRadius: radius(16),
                              ),
                              child: Text(
                                language.postJob,
                                style: boldTextStyle(
                                    color: gradientRed, size: 12),
                              ),
                            ),
                          if (widget.bookingData.isPackageBooking)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              margin: EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color:
                                    gradientRed.withValues(alpha: 0.1),
                                border: Border.all(color: gradientRed),
                                borderRadius: radius(16),
                              ),
                              child: Text(
                                language.package,
                                style: boldTextStyle(
                                    color: gradientRed, size: 12),
                              ),
                            ),
                        ],
                      ).flexible(),
                    ],
                  ),
                  12.height,
                  Marquee(
                    child: Text(
                      widget.bookingData.isPackageBooking
                          ? '${widget.bookingData.bookingPackage!.name.validate()}'
                          : '${widget.bookingData.serviceName.validate()}',
                      style: boldTextStyle(size: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  5.height,
                  Builder(builder: (context) {
                    final city = widget.bookingData.cityName.validate();
                    final country = widget.bookingData.countryName.validate();
                    final label = (city.isEmpty && country.isEmpty)
                        ? 'N/A'
                        : "${city}${(city.isNotEmpty && country.isNotEmpty) ? ' - ' : ''}${country}";
                    return Text(
                      label,
                      style: primaryTextStyle(size: 10),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    );
                  }),
                  8.height,
                if (widget.bookingData.bookingPackage != null)
                  PriceWidget(
                      price: widget.bookingData.amount.validate(),
                      color: gradientRed,
                      isHourlyService: widget.bookingData.isHourlyService,
                      isFixedService: widget.bookingData.isFixedService,
                      isFreeService: widget.bookingData.isFreeService,
                      isDailyService: widget.bookingData.type == 'Daily',
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Marquee(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              PriceWidget(
                                isFreeService: widget.bookingData.type ==
                                    SERVICE_TYPE_FREE,
                                price:
                                    widget.bookingData.amount.validate(),
                                color: gradientRed,
                                isHourlyService:
                                    widget.bookingData.isHourlyService,
                                isFixedService:
                                    widget.bookingData.isFixedService,
                                isDailyService:
                                    widget.bookingData.isDailyService,
                              ),
                              if (widget.bookingData.discount.validate() != 0)
                                Text(
                                  '(${widget.bookingData.discount!}% ${language.lblOff})',
                                  style: boldTextStyle(
                                      size: 12, color: Colors.green),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ).paddingLeft(4),
                            ],
                          ),
                        ).expand(),
                        _buildEditBookingWidget(),
                      ],
                    ),
                  6.height,
                  if (widget.bookingData.visitType.validate().isNotEmpty)
                    Text(
                      'Job type: ${_formatVisitType(widget.bookingData.visitType.validate())}',
                      style: primaryTextStyle(size: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ).expand(),
            ],
          ).paddingAll(8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor:
                  appStore.isDarkMode ? context.cardColor : whiteColor,
              border: Border.all(color: context.dividerColor),
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            margin: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location (City - Country) Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${language.hintAddress}:',
                      style: secondaryTextStyle(),
                    ).expand(flex: 2),
                    8.width,
                    Builder(builder: (context) {
                      final city = widget.bookingData.cityName.validate();
                      final country = widget.bookingData.countryName.validate();
                      final label = (city.isEmpty && country.isEmpty)
                          ? 'N/A'
                          : "${city}${(city.isNotEmpty && country.isNotEmpty) ? ' - ' : ''}${country}";
                      return Marquee(
                        child: Text(
                          label,
                          maxLines: 2,
                          style: boldTextStyle(size: 12),
                          textAlign: TextAlign.left,
                        ),
                      ).expand(flex: 5);
                    }),
                  ],
                ).paddingAll(8),

                // Date & Time Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${language.lblDate} & ${language.lblTime}:',
                      style: secondaryTextStyle(),
                    ).expand(flex: 2),
                    8.width,
                    Marquee(
                      child: Text(
                        "${formatDate(widget.bookingData.date.validate())} ${language.at} ${buildTimeWidget(bookingDetail: widget.bookingData)}",
                        style: boldTextStyle(size: 12),
                        textAlign: TextAlign.left,
                      ),
                    ).expand(flex: 5),
                  ],
                ).paddingOnly(left: 8, bottom: 8, right: 8),
                // Start Date Section
                if (widget.bookingData.startAt.validate().isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Start Date',
                        style: secondaryTextStyle(),
                      ).expand(flex: 2),
                      8.width,
                      Marquee(
                        child: Text(
                          widget.bookingData.startAt.validate(),
                          style: boldTextStyle(size: 12),
                          textAlign: TextAlign.left,
                        ),
                      ).expand(flex: 5),
                    ],
                  ).paddingAll(8),

                // Start Date Section
                if (widget.bookingData.startAt.validate().isNotEmpty)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'End Date',
                        style: secondaryTextStyle(),
                      ).expand(flex: 2),
                      8.width,
                      Marquee(
                        child: Text(
                          widget.bookingData.endAt.validate(),
                          style: boldTextStyle(size: 12),
                          textAlign: TextAlign.left,
                        ),
                      ).expand(flex: 5),
                    ],
                  ).paddingAll(8),

                if (widget.bookingData.paymentStatus != null &&
                    (widget.bookingData.status == BookingStatusKeys.complete ||
                        widget.bookingData.status ==
                            BookingStatusKeys.cancelled ||
                        widget.bookingData.status ==
                            BookingStatusKeys.pending ||
                        widget.bookingData.paymentStatus ==
                            SERVICE_PAYMENT_STATUS_ADVANCE_PAID ||
                        widget.bookingData.paymentStatus ==
                            SERVICE_PAYMENT_STATUS_PAID ||
                        widget.bookingData.paymentStatus == PENDING_BY_ADMIN))
                  if ((widget.bookingData.paymentStatus ==
                              SERVICE_PAYMENT_STATUS_PAID ||
                          widget.bookingData.paymentStatus ==
                              PENDING_BY_ADMIN) ||
                      getPaymentStatusText(widget.bookingData.paymentStatus,
                              widget.bookingData.paymentMethod)
                          .isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${language.paymentStatus}:',
                          style: secondaryTextStyle(),
                        ).expand(flex: 2),
                        3.width,
                        Marquee(
                          child: Text(
                            buildPaymentStatusWithMethod(
                              widget.bookingData.paymentStatus.validate(),
                              widget.bookingData.paymentMethod.validate(),
                            ),
                            style: boldTextStyle(
                              size: 12,
                              color: widget.bookingData.status
                                  .validate()
                                  .getPaymentStatusBackgroundColor,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ).expand(flex: 5),
                      ],
                    ).paddingOnly(left: 8, bottom: 8, right: 8)
                  else if (widget.bookingData.paymentStatus == null &&
                      (widget.bookingData.status == BookingStatusKeys.pending ||
                          widget.bookingData.status ==
                              BookingStatusKeys
                                  .cancelled || // Handle null payment status for cancellation
                          widget.bookingData.status ==
                              BookingStatusKeys.complete))
                    Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment:
                              MainAxisAlignment.start, // Align items to start
                          children: [
                            Text(
                              '${language.paymentStatus}:',
                              style: secondaryTextStyle(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ).expand(flex: 2),
                            SizedBox(width: 8),
                            Marquee(
                              child: Text(
                                widget.bookingData.status
                                    .validate()
                                    .toBookingStatus(),
                                style: boldTextStyle(
                                  size: 12,
                                  color: widget.bookingData.status
                                      .validate()
                                      .getPaymentStatusBackgroundColor,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ).expand(flex: 5),
                          ],
                        ).paddingOnly(left: 8, bottom: 8, right: 8)
                      ],
                    ),
                Column(
                  children: [
                    // Dotted line
                    DottedLine(
                      dashColor: appStore.isDarkMode
                          ? lightGray.withValues(alpha: 0.4)
                          : lightGray,
                      dashGapLength: 5,
                      dashLength: 8,
                    ).paddingAll(8),

                    // Provider card - always show
                    _buildProviderCard(),
                    
                    // Handyman/Worker card - show if handyman exists and is different from provider
                    if (widget.bookingData.handyman!.isNotEmpty &&
                        !widget.bookingData.isProviderAndHandymanSame) ...[
                      // Dotted line separator between provider and handyman
                      DottedLine(
                        dashColor: appStore.isDarkMode
                            ? lightGray.withValues(alpha: 0.4)
                            : lightGray,
                        dashGapLength: 5,
                        dashLength: 8,
                      ).paddingAll(8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HandymanInfoScreen(
                            handymanId: widget.bookingData.handyman!.first
                                .handyman!.id.validate(),
                          ).launch(context);
                        },
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: context.dividerColor, width: 1),
                                  shape: BoxShape.circle,
                                ),
                                child: CachedImageWidget(
                                  url: widget.bookingData.handyman!.first
                                      .handyman!.handymanImage
                                      .validate(),
                                  circle: true,
                                  height: 40,
                                  width: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              16.width,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      // Verified/Not Verified Icon (dynamic from API)
                                      if (widget.bookingData.verifiedStickerIcon.validate().isNotEmpty)
                                        CachedImageWidget(
                                          url: widget.bookingData.verifiedStickerIcon.validate(),
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.contain,
                                        )
                                      else
                                        Image.asset(
                                          'assets/icons/verified_badge.jpg',
                                          width: 20,
                                          height: 20,
                                        ),
                                      SizedBox(width: 6),
                                      // Membership Icon (dynamic from API)
                                      if (widget.bookingData.membershipIcon.validate().isNotEmpty)
                                        CachedImageWidget(
                                          url: widget.bookingData.membershipIcon.validate(),
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.contain,
                                        )
                                      else
                                        Image.asset(
                                          'assets/icons/free-membership.jpg',
                                          width: 20,
                                          height: 20,
                                        ),
                                    ],
                                  ),
                                  5.height,
                                  Row(
                                    children: [
                                      Marquee(
                                        child: Text(
                                          widget.bookingData.handyman!.first
                                              .handyman!.displayName
                                              .validate(),
                                          style: boldTextStyle(size: 14),
                                        ),
                                      ).flexible(),
                                      4.width,
                                      ImageIcon(
                                        AssetImage(ic_verified),
                                        size: 14,
                                        color: Colors.green,
                                      ).visible(
                                        widget.bookingData.handyman!.first
                                                .handyman!.isVerifyHandyman
                                                .validate() ==
                                            1,
                                      ),
                                    ],
                                  ),
                                  DisabledRatingBarWidget(
                                    rating: widget.bookingData.handyman!.first
                                            .handyman?.handymanRating
                                            .validate() ??
                                        0.0,
                                    size: 14,
                                  ),
                                  Text(
                                    language.textHandyman,
                                    style: secondaryTextStyle(size: 12),
                                  ),
                                  // City - Country label
                                  Builder(builder: (context) {
                                    final h = widget
                                        .bookingData.handyman!.first.handyman;
                                    final city = h?.cityName.validate() ?? '';
                                    final country =
                                        h?.countryName.validate() ?? '';
                                    final label = (city.isEmpty && country.isEmpty)
                                        ? 'N/A'
                                        : "${city}${(city.isNotEmpty && country.isNotEmpty) ? ' - ' : ''}${country}";
                                    return Text(
                                      label,
                                      style: secondaryTextStyle(size: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }),
                                ],
                              ).expand(),
                            ],
                          ),
                        ),
                                      ),
                                  ],
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  bool get isDateTimeAfterNow {
    try {
      if (widget.bookingData.bookingSlot != null) {
        final bookingDateTimeForTimeSlots =
            widget.bookingData.date.validate().split(" ").isNotEmpty
                ? widget.bookingData.date.validate().split(" ").first
                : "";
        final bookingTimeForTimeSlots =
            widget.bookingData.bookingSlot.validate();
        return DateTime.parse(
                bookingDateTimeForTimeSlots + " " + bookingTimeForTimeSlots)
            .isAfter(DateTime.now());
      } else {
        return DateTime.parse(widget.bookingData.date.validate())
            .isAfter(DateTime.now());
      }
    } catch (e) {
      log('E: $e');
    }
    return false;
  }
}
