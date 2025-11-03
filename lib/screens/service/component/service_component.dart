import 'dart:math';

import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/disabled_rating_bar_widget.dart';
import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/newDashboard/dashboard_4/component/service_dashboard_component_4.dart';
import 'package:booking_system_flutter/screens/service/service_detail_screen.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../component/social_icons_list.dart';
import '../../../model/city_list_model.dart';
import '../../newDashboard/dashboard_1/component/service_dashboard_component_1.dart';
import '../../newDashboard/dashboard_2/component/service_dashboard_component_2.dart';
import '../../newDashboard/dashboard_3/component/service_dashboard_component_3.dart';

class ServiceComponent extends StatefulWidget {
  final ServiceData serviceData;
  final double? width;
  final bool? isBorderEnabled;
  final VoidCallback? onUpdate;
  final bool isFavouriteService;
  final bool isFromDashboard;
  final bool isFromViewAllService;
  final bool isFromServiceDetail;
  final bool isFromService;
  final bool isFromFeatured;
  final bool isSmallGrid;

  ServiceComponent({
    required this.serviceData,
    this.width,
    this.isBorderEnabled,
    this.isFavouriteService = false,
    this.onUpdate,
    this.isFromDashboard = false,
    this.isFromViewAllService = false,
    this.isFromServiceDetail = false,
    this.isFromService = false,
    this.isFromFeatured = false,
    this.isSmallGrid = false,
  });

  @override
  ServiceComponentState createState() => ServiceComponentState();
}

class ServiceComponentState extends State<ServiceComponent> {
  CityListResponse? selectedCity;

  @override
  void initState() {
    super.initState();
    init();
  }

  int get randomNumber => Random().nextInt(20001);

  Future<void> init() async {
    // Initialize any required data
  }

  @override
  Widget build(BuildContext context) {
    Widget buildServiceComponent() {
      return Observer(builder: (context) {
        switch (appConfigurationStore.userDashboardType) {
          case DEFAULT_USER_DASHBOARD:
            return _buildDefaultDashboard(context);
          case DASHBOARD_1:
            return ServiceDashboardComponent1(serviceData: widget.serviceData);
          case DASHBOARD_2:
            return ServiceDashboardComponent2(serviceData: widget.serviceData);
          case DASHBOARD_3:
            return ServiceDashboardComponent3(serviceData: widget.serviceData);
          case DASHBOARD_4:
            return ServiceDashboardComponent4(serviceData: widget.serviceData);
          default:
            return Center(child: Text("Invalid Dashboard Type"));
        }
      });
    }

    return GestureDetector(
      onTap: () {
        hideKeyboard(context);
        ServiceDetailScreen(
          serviceId: widget.isFavouriteService
              ? widget.serviceData.serviceId.validate().toInt()
              : widget.serviceData.id.validate(),
        ).launch(context).then((value) {
          setStatusBarColor(context.primaryColor);
          widget.onUpdate?.call();
        });
      },
      child: buildServiceComponent(),
    );
  }

  Widget _buildDefaultDashboard(BuildContext context) {
    final String address =
        (widget.serviceData.serviceAddressMapping ?? []).isEmpty
            ? ''
            : (widget.serviceData.serviceAddressMapping ?? [])
                .first
                .providerAddressMapping!
                .address
                .validate();

    // Derive a compact City - Country label from a free-form provider address.
    // Handles common formats like:
    //  - "Street, City, Country"
    //  - multiline addresses where the last line looks like "CA-56234 Montreal"
    //  - values separated by hyphens (e.g., "F-75000 Paris")
    String deriveCityCountryLabel(String rawAddress) {
      if (rawAddress.isEmpty) return '';

      // Normalize newlines/extra spaces and split into chunks
      final normalized = rawAddress
          .replaceAll('\n', ',')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final chunks = normalized
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Prefer the last meaningful chunk (often contains city/country code)
      final tail = chunks.isNotEmpty ? chunks.last : normalized;

      // Try to parse ISO country code + postal code + city e.g. "CA-56234 Montreal"
      final isoMatch =
          RegExp(r'^([A-Z]{2})[-\s]?\d*\s*(.+)$').firstMatch(tail);
      if (isoMatch != null) {
        final code = isoMatch.group(1)!.trim();
        var rest = isoMatch.group(2)!.trim();
        // If there is a hyphenated remainder, keep the first city-like token
        rest = rest.split(RegExp(r'\s*-\s*')).first.trim();
        if (rest.isNotEmpty) return [rest, code].join(' - ');
        return code; // fallback to country code only
      }

      // Fallbacks: if we have multiple chunks, pick the last two as city/country
      if (chunks.length >= 2) {
        final city = chunks.last;
        final country = chunks[chunks.length - 2];
        return [city, country].where((e) => e.isNotEmpty).join(' - ');
      }

      return tail; // last resort, show tail as-is
    }

    final String compactLocation = deriveCityCountryLabel(address);
    return Container(
      decoration: boxDecorationWithRoundedCorners(
        borderRadius: radius(),
        backgroundColor: context.cardColor,
        border: widget.isBorderEnabled.validate(value: false)
            ? appStore.isDarkMode
                ? Border.all(color: context.dividerColor)
                : null
            : null,
      ),
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 205,
            width: context.width(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CachedImageWidget(
                  url: widget.isFavouriteService
                      ? widget.serviceData.serviceAttachments
                              .validate()
                              .isNotEmpty
                          ? widget.serviceData.serviceAttachments!.first
                              .validate()
                          : ''
                      : widget.serviceData.attachments.validate().isNotEmpty
                          ? widget.serviceData.attachments!.first.validate()
                          : '',
                  fit: BoxFit.cover,
                  height: 180,
                  width: widget.width ?? context.width(),
                  circle: false,
                ).cornerRadiusWithClipRRectOnly(
                    topRight: defaultRadius.toInt(),
                    topLeft: defaultRadius.toInt()),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    constraints:
                        BoxConstraints(maxWidth: context.width() * 0.3),
                    decoration: boxDecorationWithShadow(
                      backgroundColor: context.cardColor.withValues(alpha: 0.9),
                      borderRadius: radius(24),
                    ),
                    child: Marquee(
                      directionMarguee: DirectionMarguee.oneDirection,
                      child: Text(
                        "${widget.serviceData.subCategoryName.validate().isNotEmpty ? widget.serviceData.subCategoryName.validate() : widget.serviceData.categoryName.validate()}"
                            .toUpperCase(),
                        style: boldTextStyle(
                            color: appStore.isDarkMode ? white : primaryColor,
                            size: 12),
                      ).paddingSymmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
                if (widget.serviceData.isOnlineService)
                  Positioned(
                    top: 20,
                    right: 12,
                    child: Icon(Icons.circle, color: Colors.green, size: 12),
                  ),
                if (widget.isFavouriteService)
                  Positioned(
                    top: 8,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      margin: EdgeInsets.only(right: 8),
                      decoration: boxDecorationWithShadow(
                          boxShape: BoxShape.circle,
                          backgroundColor: context.cardColor),
                      child: widget.serviceData.isFavourite == 1
                          ? ic_fill_heart.iconImage(
                              color: favouriteColor, size: 18)
                          : ic_heart.iconImage(
                              color: unFavouriteColor, size: 18),
                    ).onTap(() async {
                      if (widget.serviceData.isFavourite != 0) {
                        widget.serviceData.isFavourite = 1;
                        setState(() {});

                        await removeToWishList(
                                serviceId: widget.serviceData.serviceId
                                    .validate()
                                    .toInt())
                            .then((value) {
                          if (!value) {
                            widget.serviceData.isFavourite = 1;
                            setState(() {});
                          }
                        });
                      } else {
                        widget.serviceData.isFavourite = 0;
                        setState(() {});

                        await addToWishList(
                                serviceId: widget.serviceData.serviceId
                                    .validate()
                                    .toInt())
                            .then((value) {
                          if (!value) {
                            widget.serviceData.isFavourite = 1;
                            setState(() {});
                          }
                        });
                      }
                      widget.onUpdate?.call();
                    }),
                  ),
                Positioned(
                  bottom: 12,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: boxDecorationWithShadow(
                      backgroundColor: primaryColor,
                      borderRadius: radius(24),
                      border: Border.all(color: context.cardColor, width: 2),
                    ),
                    child: PriceWidget(
                      price: widget.serviceData.price.validate(),
                      isHourlyService: widget.serviceData.isHourlyService,
                      color: Colors.white,
                      hourlyTextColor: Colors.white,
                      size: 14,
                      isDailyService: widget.serviceData.isDailyService,
                      isFixedService: widget.serviceData.isFixedService,
                      isFreeService: widget.serviceData.type.validate() ==
                          SERVICE_TYPE_FREE,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DisabledRatingBarWidget(
                      rating: widget.serviceData.totalRating.validate(),
                      size: 14)
                  .paddingSymmetric(horizontal: 16),
              8.height,
              Marquee(
                directionMarguee: DirectionMarguee.oneDirection,
                child: Text(widget.serviceData.name.validate(),
                        style: boldTextStyle())
                    .paddingSymmetric(horizontal: 16),
              ),
              4.height,
              if (compactLocation.isNotEmpty)
                Marquee(
                  directionMarguee: DirectionMarguee.oneDirection,
                  child:
                      Text(compactLocation, style: primaryTextStyle(size: 10))
                          .paddingSymmetric(horizontal: 16),
                ),
              8.height,
              Row(
                children: [
                  ImageBorder(
                      src: widget.serviceData.providerImage.validate(),
                      height: 30),
                  8.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/verified_badge.jpg',
                              width: 15,
                              height: 15,
                            ),
                            SizedBox(width: 6),
                            Image.asset(
                              'assets/icons/free-membership.jpg',
                              width: 15,
                              height: 15,
                            ),
                          ],
                        ),
                        if (widget.serviceData.providerName
                            .validate()
                            .isNotEmpty)
                          Text(
                            widget.serviceData.providerName.validate(),
                            style: secondaryTextStyle(
                                size: 12,
                                color: appStore.isDarkMode
                                    ? Colors.white
                                    : appTextSecondaryColor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (compactLocation.isNotEmpty)
                          Text(
                            compactLocation,
                            style: secondaryTextStyle(
                                size: 9,
                                color: appStore.isDarkMode
                                    ? Colors.white
                                    : appTextSecondaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (!widget.isSmallGrid)
                          Text(
                            'Member Since: ${(widget.serviceData.serviceAddressMapping ?? []).isEmpty ? '' : formatDate(widget.serviceData.serviceAddressMapping?.first.providerAddressMapping?.createdAt)}',
                            style: secondaryTextStyle(
                                size: 10,
                                color: appStore.isDarkMode
                                    ? Colors.white
                                    : appTextSecondaryColor),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Services: ${widget.serviceData.completedBookings ?? 0}',
                              style: secondaryTextStyle(
                                  size: 10,
                                  color: appStore.isDarkMode
                                      ? Colors.white
                                      : appTextSecondaryColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Views: ${widget.serviceData.totalViews ?? NumberFormat("#,###").format(randomNumber)}',
                              style: secondaryTextStyle(
                                  size: 10,
                                  color: appStore.isDarkMode
                                      ? Colors.white
                                      : appTextSecondaryColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        4.height,
                        if (widget.isSmallGrid && widget.isFromService)
                          SocialIconsList(
                              mainAxisAlignment: MainAxisAlignment.start),
                      ],
                    ),
                  ),
                ],
              ).onTap(() async {
                if (widget.serviceData.providerId !=
                    appStore.userId.validate()) {
                  await ProviderInfoScreen(
                          providerId: widget.serviceData.providerId.validate())
                      .launch(context);
                  setStatusBarColor(Colors.transparent);
                }
              }).paddingSymmetric(horizontal: 16),
              16.height,
            ],
          ),
        ],
      ),
    );
  }
}
