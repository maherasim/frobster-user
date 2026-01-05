import 'dart:math';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/online_service_icon_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/component/gradient_button.dart';
import 'package:booking_system_flutter/model/package_data_model.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/slot_data.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/book_service_screen.dart';
import 'package:booking_system_flutter/screens/booking/component/booking_detail_provider_widget.dart';
import 'package:booking_system_flutter/screens/booking/component/provider_service_component.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/review/components/review_widget.dart';
import 'package:booking_system_flutter/screens/review/rating_view_all_screen.dart';
import 'package:booking_system_flutter/screens/service/component/service_detail_header_component.dart';
import 'package:booking_system_flutter/screens/service/component/service_faq_widget.dart';
import 'package:booking_system_flutter/screens/service/package/package_component.dart';
import 'package:booking_system_flutter/screens/service/shimmer/service_detail_shimmer.dart';
import 'package:booking_system_flutter/store/service_addon_store.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../utils/images.dart';
import 'addons/service_addons_component.dart';

ServiceAddonStore serviceAddonStore = ServiceAddonStore();

class ServiceDetailScreen extends StatefulWidget {
  final int serviceId;
  final ServiceData? service;
  final bool isFromProviderInfo;

  ServiceDetailScreen({
    required this.serviceId,
    this.service,
    this.isFromProviderInfo = false,
  });

  @override
  _ServiceDetailScreenState createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen>
    with TickerProviderStateMixin {
  PageController pageController = PageController();

  Future<ServiceDetailResponse>? future;

  BookingPackage? selectedPackage;

  @override
  void initState() {
    super.initState();
    serviceAddonStore.selectedServiceAddon.clear();
    setStatusBarColor(transparentColor);
    init();
  }

  void init() async {
    future = getServiceDetails(
        serviceId: widget.serviceId.validate(), customerId: appStore.userId);
  }

  Duration get getRandomDuration {
    final random = Random();
    int seconds = random.nextInt(3600); // Random duration up to 1 hour
    return Duration(seconds: seconds);
  }

  String serviceTypeLabel(String? type) {
    final t = type.validate();
    final lower = t.toLowerCase();
    if (lower == SERVICE_TYPE_HOURLY.toLowerCase()) return language.hourly;
    if (lower == SERVICE_TYPE_DAILY.toLowerCase()) return 'Daily';
    if (lower == SERVICE_TYPE_FIXED.toLowerCase()) return 'Fixed';
    return t.capitalizeFirstLetter();
  }

  String _titleCase(String input) {
    final normalized = input.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    if (normalized.isEmpty) return '';
    return normalized
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _formatVisitType(String value) {
    final upper = value.trim().toUpperCase();
    switch (upper) {
      case 'ON_SITE':
        return 'Onsite';
      case 'ONLINE':
        return 'Online';
      default:
        return _titleCase(value);
    }
  }

  String _formatRemoteLevel(String value) {
    final v = value.trim().toLowerCase();
    if (v == 'onsite') return 'Onsite (100%)';
    if (v.endsWith('_remote')) {
      final pct = v.split('_').first;
      final numOnly = pct.replaceAll(RegExp(r'[^0-9]'), '');
      if (numOnly.isNotEmpty) return '$numOnly% Remote';
    }
    return _titleCase(value);
  }

  String _formatTravelRequired(String value) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1') return 'Yes';
    if (v == 'false' || v == '0') return 'No';
    return _titleCase(value);
  }

  //region Widgets
  Widget availableWidget({required ServiceData data, UserData? provider}) {
    if (data.serviceAddressMapping.validate().isEmpty) return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        8.height,
        Text(language.lblAvailableAt,
            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        8.height,
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            alignment: WrapAlignment.start,
            spacing: 8,
            direction: Axis.vertical,
            runSpacing: 8,
            children: List.generate(
              data.serviceAddressMapping!.length,
              (index) {
                ServiceAddressMapping value =
                    data.serviceAddressMapping![index];
                if (value.providerAddressMapping == null) return Offstage();
                // Display only - no selection functionality
                return Container(
                  decoration: BoxDecoration(
                            gradient: appPrimaryGradient,
                            borderRadius: BorderRadius.circular(8),
                          ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 10),
                      child: Text(
                        (() {
                          final addr = value.providerAddressMapping?.address.validate() ?? '';
                          if (addr.trim().isNotEmpty) return addr;
                          final city = value.cityName.validate();
                          final country = value.countryName.validate();
                          if (city.isEmpty && country.isEmpty) return 'N/A';
                          return '$city${(city.isNotEmpty && country.isNotEmpty) ? ' - ' : ''}$country';
                        })(),
                        style: boldTextStyle(
                          color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        8.height,
      ],
    );
  }

  Widget providerWidget({required UserData data}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(language.lblAboutProvider,
            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        BookingDetailProviderWidget(providerData: data).onTap(() async {
          await ProviderInfoScreen(providerId: data.id).launch(context);
          setStatusBarColor(Colors.transparent);
        }),
      ],
    ).paddingAll(16);
  }

  Widget cancelationPolicyWidget(String policy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cancelation Policy', style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        HtmlWidget(
          policy.validate(),
          textStyle: primaryTextStyle(),
        ),
      ],
    ).paddingAll(16);
  }

  Widget serviceFaqWidget({required List<ServiceFaq> data}) {
    if (data.isEmpty) return Offstage();

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          8.height,
          ViewAllLabel(label: language.lblFaq, list: data),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: data.length,
            padding: EdgeInsets.all(0),
            itemBuilder: (_, index) =>
                ServiceFaqWidget(serviceFaq: data[index]),
          ),
          8.height,
        ],
      ),
    );
  }

  Widget slotsAvailable(
      {required List<SlotData> data, required bool isSlotAvailable}) {
    if (!isSlotAvailable ||
        data.where((element) => element.slot.validate().isNotEmpty).isEmpty)
      return Offstage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        8.height,
        Text(language.lblAvailableOnTheseDays,
            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        8.height,
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: List.generate(
              data
                  .where((element) => element.slot.validate().isNotEmpty)
                  .length, (index) {
            SlotData value = data
                .where((element) => element.slot.validate().isNotEmpty)
                .toList()[index];

            return Container(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
              decoration: boxDecorationDefault(
                color: context.cardColor,
                border: appStore.isDarkMode
                    ? Border.all(color: context.dividerColor)
                    : null,
              ),
              child: Text('${value.day.capitalizeFirstLetter()}',
                  style: secondaryTextStyle(
                      size: LABEL_TEXT_SIZE, color: gradientRed)),
            );
          }),
        ),
        8.height,
      ],
    );
  }

  Widget reviewWidget(
      {required List<RatingData> data,
      required ServiceDetailResponse serviceDetailResponse}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          //label: language.review,
          label:
              '${language.review} (${serviceDetailResponse.serviceDetail!.totalReview})',
          list: data,
          onTap: () {
            RatingViewAllScreen(serviceId: widget.serviceId).launch(context);
          },
        ),
        data.isNotEmpty
            ? Wrap(
                children: List.generate(
                  data.length,
                  (index) => ReviewWidget(data: data[index]),
                ),
              ).paddingTop(8)
            : Text(language.lblNoReviews, style: secondaryTextStyle()),
      ],
    ).paddingSymmetric(horizontal: 16);
  }

  Widget relatedServiceWidget(
      {required List<ServiceData> serviceList,
      required int serviceId,
      required ServiceDetailResponse serviceDetailResponse}) {
    if (serviceList.isEmpty) return Offstage();

    serviceList.removeWhere((element) => element.id == serviceId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (serviceList.isNotEmpty)
          Text(
            language.lblRelatedServices,
            style: boldTextStyle(size: LABEL_TEXT_SIZE),
          ).paddingSymmetric(horizontal: 16),
        8.height,
        if (serviceList.isNotEmpty)
          ListView.builder(
            padding: EdgeInsets.all(8),
            shrinkWrap: true,
            itemCount: serviceList.length,
            physics: NeverScrollableScrollPhysics(),
            // Replace RelatedServiceComponent with ProviderServiceComponent
            itemBuilder: (_, index) => ProviderServiceComponent(
              serviceData: serviceList[index],
              serviceDetailResponse: serviceDetailResponse,
              isFromServiceInfo: true,
              // width: appConfigurationStore.userDashboardType == DEFAULT_USER_DASHBOARD ? context.width() / 2 - 26 : 280,
            ).paddingOnly(bottom: 16, left: 8, right: 8),
          )
      ],
    );
  }

  //endregion

  void bookNow(ServiceDetailResponse serviceDetailResponse) {
    doIfLoggedIn(context, () {
      // Always set bookingAddressId to -1 (will be null in payload)
      serviceDetailResponse.serviceDetail!.bookingAddressId = -1;
      BookServiceScreen(
              data: serviceDetailResponse, selectedPackage: selectedPackage)
          .launch(context)
          .then((value) {
        setStatusBarColor(transparentColor);
      });
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    setStatusBarColor(
        widget.isFromProviderInfo ? primaryColor : transparentColor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget buildBodyWidget(AsyncSnapshot<ServiceDetailResponse> snap) {
      if (snap.hasError) {
        return Text(snap.error.toString()).center();
      } else if (snap.hasData) {
        return AppScaffold(
          appBarTitle: snap.data!.serviceDetail?.categoryName.validate() ?? '',
          showLoader: false,
          child: Column(
            children: [
              Expanded(
                child: AnimatedScrollView(
                  padding: EdgeInsets.only(bottom: 120),
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  onSwipeRefresh: () async {
                    appStore.setLoading(true);
                    init();
                    setState(() {});
                    return await 2.seconds.delay;
                  },
                  children: [
                    8.height,
                    ServiceDetailHeaderComponent(
                        serviceDetail: snap.data!.serviceDetail!),
                    4.height,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                if (snap
                                    .data!.serviceDetail!.isOnlineService) ...[
                                  OnlineServiceIconWidget(),
                                  10.width,
                                ],
                                Flexible(
                                    child: Container(
                                  decoration: BoxDecoration(
                                    color: appStore.isDarkMode
                                        ? Colors.black
                                        : lightPrimaryColor,
                                    borderRadius: radius(20),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  child: Text(
                                    (snap.data!.serviceDetail?.categoryName
                                            .validate() ??
                                        ' '),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: gradientRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  ),
                                )),
                              ],
                            ).expand(),
                            TextIcon(
                              suffix: Row(
                                children: [
                                  Image.asset(
                                    ic_star_fill,
                                    height: 18,
                                    color: getRatingBarColor(snap
                                        .data!.serviceDetail!.totalRating
                                        .validate()
                                        .toInt()),
                                  ),
                                  4.width,
                                  Text(
                                      "${snap.data!.serviceDetail!.totalRating.validate().toStringAsFixed(1)}",
                                      style: boldTextStyle()),
                                ],
                              ),
                            ),
                          ],
                        ),
                        12.height,
                        Text(
                          snap.data!.serviceDetail!.name.validate(),
                          style: primaryTextStyle(
                              weight: FontWeight.bold, size: 16),
                        ),
                        10.height,
                        if ((snap.data?.serviceDetail?.serviceCityName
                                    .validate()
                                    .isNotEmpty ??
                                false) ||
                            (snap.data?.serviceDetail?.serviceCountryName
                                    .validate()
                                    .isNotEmpty ??
                                false) ||
                            (snap.data?.serviceDetail?.cityName
                                    .validate()
                                    .isNotEmpty ??
                                false) ||
                            (snap.data?.serviceDetail?.countryName
                                    .validate()
                                    .isNotEmpty ??
                                false)) ...[
                          Text(
                            (() {
                              
                              final fallbackCity = snap.data?.serviceDetail?.cityName.validate() ?? '';
                              final fallbackCountry = snap.data?.serviceDetail?.countryName.validate() ?? '';
                              final city = fallbackCity.isNotEmpty ? fallbackCity : fallbackCity;
                              final country = fallbackCountry.isNotEmpty ? fallbackCountry : fallbackCountry;
                              return "$city${(city.isNotEmpty && country.isNotEmpty) ? ' - ' : ''}$country";
                            })(),
                            style:
                                secondaryTextStyle(size: 11, color: Colors.red),
                          ),
                          6.height,
                        ],
                        if (snap.data!.serviceDetail!.address
                            .validate()
                            .isNotEmpty) ...[
                          Builder(builder: (context) {
                            final primaryCity = snap.data?.serviceDetail?.serviceCityName.validate() ?? '';
                            final primaryCountry = snap.data?.serviceDetail?.serviceCountryName.validate() ?? '';
                            final fallbackCity = snap.data?.serviceDetail?.cityName.validate() ?? '';
                            final fallbackCountry = snap.data?.serviceDetail?.countryName.validate() ?? '';
                            final city = primaryCity.isNotEmpty ? primaryCity : fallbackCity;
                            final country = primaryCountry.isNotEmpty ? primaryCountry : fallbackCountry;
                            final label = (city.isEmpty && country.isEmpty)
                                ? 'N/A'
                                : "$city${(city.isNotEmpty && country.isNotEmpty) ? ' - ' : ''}$country";
                            return Text(
                              label,
                              style: secondaryTextStyle(
                                  weight: FontWeight.bold,
                                  color: textPrimaryColorGlobal,
                                  size: 11),
                            );
                          }),
                           10.height,
                         ],
                        // Price display
                        Row(
                          children: [
                            PriceWidget(
                              size: 16,
                              price: (snap.data!.serviceDetail!.discount.validate() > 0)
                                  ? snap.data!.serviceDetail!.getDiscountedPrice.validate()
                                  : snap.data!.serviceDetail!.price.validate(),
                              isHourlyService: snap.data!.serviceDetail!.isHourlyService,
                              isFixedService: snap.data!.serviceDetail!.isFixedService,
                              isFreeService: snap.data!.serviceDetail!.isFreeService,
                              isDailyService: snap.data!.serviceDetail!.isDailyService,
                            ),
                            if (snap.data!.serviceDetail!.discount.validate() > 0) ...[
                              8.width,
                              PriceWidget(
                                size: 13,
                                price: snap.data!.serviceDetail!.price.validate(),
                                isDiscountedPrice: true,
                                color: textSecondaryColorGlobal,
                                isLineThroughEnabled: true,
                              ),
                            ],
                          ],
                        ),
                        12.height,
                        // Attributes block: consistent fonts, spacing and layout
                        Builder(builder: (context) {
                          final labelStyle = secondaryTextStyle(size: 13);
                          final valueStyle = secondaryTextStyle(
                              size: 14,
                              weight: FontWeight.normal,
                              color: textPrimaryColorGlobal);

                          Widget attributeRow(String label, String value, {Color? valueColor}) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    label,
                                    style: labelStyle,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    value,
                                    style: valueStyle.copyWith(color: valueColor ?? textPrimaryColorGlobal),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (snap.data!.serviceDetail!.duration
                                    .validate()
                                    .isNotEmpty)
                                  attributeRow(language.duration,
                                      "${convertToHourMinute(snap.data!.serviceDetail!.duration.validate())}"),
                                if (snap.data!.serviceDetail!.duration
                                    .validate()
                                    .isNotEmpty)
                                10.height,
                              // Discount row
                                    if (snap.data!.serviceDetail!.discount
                                            .validate() >
                                        0)
                                attributeRow(
                                  'Discount',
                                  "${snap.data!.serviceDetail!.discount.validate()}%",
                                  valueColor: defaultActivityStatus, // green color
                                ),
                                    if (snap.data!.serviceDetail!.discount
                                            .validate() >
                                        0)
                                10.height,
                                attributeRow('Minimum Orders',
                                    '${snap.data?.serviceDetail?.minimumOrders ?? 0}'),
                              10.height,
                                attributeRow(
                                  'Job type',
                                  (() {
                                    final v = _formatVisitType(snap
                                            .data
                                            ?.serviceDetail
                                            ?.visitType
                                            .validate() ??
                                        '');
                                    return v.isEmpty ? 'N/A' : v;
                                  })(),
                                ),
                              10.height,
                                attributeRow(
                                  'Remote work level',
                                  (() {
                                    final v = _formatRemoteLevel(snap
                                            .data
                                            ?.serviceDetail
                                            ?.remoteWorkLevel
                                            .validate() ??
                                        '');
                                    return v.isEmpty ? 'N/A' : v;
                                  })(),
                                ),
                              10.height,
                                attributeRow(
                                  'Career level',
                                  (() {
                                    final v = _titleCase(snap
                                            .data
                                            ?.serviceDetail
                                            ?.careerLevel
                                            .validate() ??
                                        '');
                                    return v.isEmpty ? 'N/A' : v;
                                  })(),
                                ),
                              10.height,
                                attributeRow(
                                  'Travel required',
                                  (() {
                                    final raw = snap
                                            .data
                                            ?.serviceDetail
                                            ?.travelRequired
                                            .validate() ??
                                        '';
                                    final v = _formatTravelRequired(raw);
                                    return raw.trim().isEmpty ? 'N/A' : v;
                                  })(),
                                ),
                              ],
                          );
                        }),
                        16.height,
                        // Description right after attributes
                        Text('Description',
                                style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                        16.height,
                        (snap.data!.serviceDetail!.description
                                    .validate()
                                    .isNotEmpty
                            ? HtmlWidget(
                                snap.data!.serviceDetail!.description
                                    .validate(),
                                textStyle: secondaryTextStyle(),
                              )
                            : Text(language.lblNotDescription,
                                style: secondaryTextStyle())),
                        10.height,
                      ],
                    ).paddingSymmetric(horizontal: 16),
                    Container(
                      width: context.width(),
                      decoration: BoxDecoration(
                        color: context.cardColor,
                        borderRadius: radius(),
                        border: appStore.isDarkMode
                            ? Border.all(color: context.dividerColor)
                            : null,
                      ),
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          8.height,
                          slotsAvailable(
                            data: snap.data!.serviceDetail!.bookingSlots
                                .validate(),
                            isSlotAvailable:
                                snap.data!.serviceDetail!.isSlotAvailable,
                          ),
                          availableWidget(data: snap.data!.serviceDetail!, provider: snap.data!.provider),
                        ],
                      ),
                    ).paddingSymmetric(horizontal: 16, vertical: 8),
                    if (snap.data!.serviceDetail!.cancelationPolicy
                        .validate()
                        .isNotEmpty)
                      cancelationPolicyWidget(snap
                          .data!.serviceDetail!.cancelationPolicy
                          .validate()),
                    providerWidget(data: snap.data!.provider!),
                    if (snap.data!.serviceDetail!.servicePackage
                        .validate()
                        .isNotEmpty)
                      PackageComponent(
                        servicePackage:
                            snap.data!.serviceDetail!.servicePackage.validate(),
                        callBack: (v) {
                          if (v != null) {
                            selectedPackage = v;
                          } else {
                            selectedPackage = null;
                          }
                          bookNow(snap.data!);
                        },
                      ),
                    if (snap.data!.serviceaddon.validate().isNotEmpty)
                      AddonComponent(
                        serviceAddon: snap.data!.serviceaddon.validate(),
                        onSelectionChange: (v) {
                          serviceAddonStore.setSelectedServiceAddon(v);
                        },
                      ),
                    serviceFaqWidget(data: snap.data!.serviceFaq.validate())
                        .paddingSymmetric(horizontal: 16),
                    reviewWidget(
                        data: snap.data!.ratingData!,
                        serviceDetailResponse: snap.data!),
                    24.height,
                    if (snap.data!.relatedService.validate().isNotEmpty)
                      relatedServiceWidget(
                        serviceList: snap.data!.relatedService.validate(),
                        serviceId: snap.data!.serviceDetail!.id.validate(),
                        serviceDetailResponse: snap.data!,
                      ),
                  ],
                ),
              ),
              GradientButton(
                onPressed: () {
                  selectedPackage = null;
                  bookNow(snap.data!);
                },
                child: Text(language.lblBookNow, style: boldTextStyle(color: white)),
              ).withWidth(context.width()).paddingSymmetric(horizontal: 16.0, vertical: 10.0)
            ],
          ),
        );
      }
      return ServiceDetailShimmer();
    }

    return FutureBuilder<ServiceDetailResponse>(
      initialData: listOfCachedData
          .firstWhere((element) => element?.$1 == widget.serviceId.validate(),
              orElse: () => null)
          ?.$2,
      future: future,
      builder: (context, snap) {
        return Scaffold(
          body: Stack(
            children: [
              buildBodyWidget(snap),
              Observer(
                  builder: (context) =>
                      LoaderWidget().visible(appStore.isLoading)),
            ],
          ),
        );
      },
    );
  }
}
