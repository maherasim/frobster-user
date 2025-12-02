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
import 'package:booking_system_flutter/utils/configs.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
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

  /// Get service data for sharing
  Map<String, String> _getServiceDataForSharing() {
    // Get service image URL
    final String serviceImageUrl = widget.isFavouriteService
        ? (widget.serviceData.serviceAttachments.validate().isNotEmpty
            ? widget.serviceData.serviceAttachments!.first.validate()
            : '')
        : (widget.serviceData.attachments.validate().isNotEmpty
            ? widget.serviceData.attachments!.first.validate()
            : '');

    // Construct service detail URL
    final int serviceId = widget.isFavouriteService
        ? widget.serviceData.serviceId.validate().toInt()
        : widget.serviceData.id.validate();
    final String serviceLink = '$DOMAIN_URL/service-detail/$serviceId';

    // Format price
    String priceText = '';
    if (widget.serviceData.type.validate() == SERVICE_TYPE_FREE) {
      priceText = language.lblFree;
    } else {
      priceText = widget.serviceData.price.validate().toPriceFormat();
      if (widget.serviceData.isHourlyService) {
        priceText += '/Hour';
      } else if (widget.serviceData.isDailyService) {
        priceText += '/Day';
      } else if (widget.serviceData.isFixedService) {
        priceText += '/Fix';
      }
    }

    // Get city and country
    final String city = widget.serviceData.cityName.validate();
    final String country = widget.serviceData.countryName.validate();

    // Get provider name
    final String providerName = widget.serviceData.providerName.validate();

    // Get service name
    final String serviceName = widget.serviceData.name.validate();

    return {
      'serviceImageUrl': serviceImageUrl,
      'serviceLink': serviceLink,
      'price': priceText,
      'city': city,
      'country': country,
      'providerName': providerName,
      'serviceName': serviceName,
    };
  }

  /// Handle Facebook sharing
  Future<void> _handleFacebookShare() async {
    try {
      final data = _getServiceDataForSharing();
      await shareToFacebook(
        serviceImageUrl: data['serviceImageUrl']!,
        serviceLink: data['serviceLink']!,
        price: data['price']!,
        city: data['city']!,
        country: data['country']!,
        providerName: data['providerName']!,
        serviceName: data['serviceName']!,
      );
    } catch (e) {
      log('Error sharing to Facebook: $e');
      toast('Failed to share to Facebook. Please try again.');
    }
  }

  /// Handle Instagram sharing
  Future<void> _handleInstagramShare() async {
    try {
      final data = _getServiceDataForSharing();
      await shareToInstagram(
        serviceImageUrl: data['serviceImageUrl']!,
        serviceLink: data['serviceLink']!,
        price: data['price']!,
        city: data['city']!,
        country: data['country']!,
        providerName: data['providerName']!,
        serviceName: data['serviceName']!,
      );
    } catch (e) {
      log('Error sharing to Instagram: $e');
      toast('Failed to share to Instagram. Please try again.');
    }
  }

  /// Handle Twitter sharing
  Future<void> _handleTwitterShare() async {
    try {
      final data = _getServiceDataForSharing();
      await shareToTwitter(
        serviceImageUrl: data['serviceImageUrl']!,
        serviceLink: data['serviceLink']!,
        price: data['price']!,
        city: data['city']!,
        country: data['country']!,
        providerName: data['providerName']!,
        serviceName: data['serviceName']!,
      );
    } catch (e) {
      log('Error sharing to Twitter: $e');
      toast('Failed to share to Twitter. Please try again.');
    }
  }

  /// Handle LinkedIn sharing
  Future<void> _handleLinkedInShare() async {
    try {
      final data = _getServiceDataForSharing();
      await shareToLinkedIn(
        serviceImageUrl: data['serviceImageUrl']!,
        serviceLink: data['serviceLink']!,
        price: data['price']!,
        city: data['city']!,
        country: data['country']!,
        providerName: data['providerName']!,
        serviceName: data['serviceName']!,
      );
    } catch (e) {
      log('Error sharing to LinkedIn: $e');
      toast('Failed to share to LinkedIn. Please try again.');
    }
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
    final double cardWidth = widget.width ?? double.infinity;
    // Removed free-form address parsing as we now rely on mapped city/country

    // Prefer city/country coming directly from the service payload if present.
    final ServiceAddressMapping? firstMapping =
        (widget.serviceData.serviceAddressMapping?.isNotEmpty ?? false)
            ? widget.serviceData.serviceAddressMapping!.first
            : null;
    final String mappedCity = firstMapping?.cityName.validate() ?? '';
    final String mappedCountry = firstMapping?.countryName.validate() ?? '';
    final String cityCountry = (mappedCity.isEmpty && mappedCountry.isEmpty)
        ? 'N/A'
        : (mappedCity.isNotEmpty && mappedCountry.isNotEmpty
            ? '${mappedCity} - ${mappedCountry}'
            : '${mappedCity}${mappedCountry}');
    final String locationLabel = cityCountry;
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
            width: cardWidth,
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
                  width: double.infinity,
                  circle: false,
                ).cornerRadiusWithClipRRectOnly(
                    topRight: defaultRadius.toInt(),
                    topLeft: defaultRadius.toInt()),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    constraints: BoxConstraints(
                        maxWidth: (cardWidth.isFinite ? cardWidth : context.width()) * 0.5),
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
                    decoration: BoxDecoration(
                      gradient: appPrimaryGradient,
                      borderRadius: radius(24),
                      boxShadow: defaultBoxShadow(shadowColor: Colors.black12),
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
              if (locationLabel.isNotEmpty)
                Marquee(
                  directionMarguee: DirectionMarguee.oneDirection,
                  child:
                      Text(locationLabel, style: primaryTextStyle(size: 10))
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
                            // Verified/Not Verified Icon (dynamic from API)
                            if (widget.serviceData.verifiedStickerIcon.validate().isNotEmpty)
                              CachedImageWidget(
                                url: widget.serviceData.verifiedStickerIcon.validate(),
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
                            if (widget.serviceData.membershipIcon.validate().isNotEmpty)
                              CachedImageWidget(
                                url: widget.serviceData.membershipIcon.validate(),
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
                        if (widget.serviceData.providerName
                            .validate()
                            .isNotEmpty)
                          Text(
                            widget.serviceData.providerName.validate(),
                            style: secondaryTextStyle(
                                size: 12,
                                color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        // Removed service city/country under provider details to avoid duplication.
                        Builder(builder: (context) {
                          final String providerCity =
                              widget.serviceData.cityName.validate();
                          final String providerCountry =
                              widget.serviceData.countryName.validate();
                          if (providerCity.isEmpty && providerCountry.isEmpty) {
                            return Offstage();
                          }
                          final String providerLabel = providerCity.isNotEmpty && providerCountry.isNotEmpty
                              ? '${providerCity} - ${providerCountry}'
                              : providerCity + providerCountry;

                          return Text(
                            providerLabel,
                            style: secondaryTextStyle(
                                size: 10,
                                color: Theme.of(context).colorScheme.onSurface),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Services: ${widget.serviceData.completedBookings ?? 0}',
                              style: secondaryTextStyle(
                                  size: 10,
                                  color: Theme.of(context).colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Views: ${widget.serviceData.totalViews ?? NumberFormat("#,###").format(randomNumber)}',
                              style: secondaryTextStyle(
                                  size: 10,
                                  color: Theme.of(context).colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        4.height,
                        if (widget.isSmallGrid && widget.isFromService)
                          SocialIconsList(
                            mainAxisAlignment: MainAxisAlignment.start,
                            onFacebookTap: () => _handleFacebookShare(),
                            onInstagramTap: () => _handleInstagramShare(),
                            onTwitterTap: () => _handleTwitterShare(),
                            onLinkedInTap: () => _handleLinkedInShare(),
                          ),
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
