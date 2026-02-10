import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../component/cached_image_widget.dart';
import '../../../component/price_widget.dart';
import '../../../main.dart';
import '../../../model/package_data_model.dart';
import '../../../model/post_job_detail_response.dart';
import '../../../model/service_data_model.dart';
import '../../../model/service_detail_response.dart';
import '../../../model/user_data_model.dart';
import '../../../utils/colors.dart';
import '../../../utils/common.dart';
import '../../../utils/constant.dart';
import '../../../utils/images.dart';
import '../../service/service_detail_screen.dart';
import '../book_service_screen.dart';

class ProviderServiceComponent extends StatefulWidget {
  final ServiceData? serviceData;
  final ServiceDetailResponse? serviceDetailResponse;
  final BookingPackage? selectedPackage;
  final bool? isBorderEnabled;
  final VoidCallback? onUpdate;
  final bool isFavouriteService;
  final bool isFromProviderInfo;
  final bool isFromServiceInfo;
  final UserData? providerData;

  ProviderServiceComponent({
    this.serviceData,
    this.selectedPackage,
    this.isBorderEnabled,
    this.onUpdate,
    this.isFavouriteService = false,
    this.isFromProviderInfo = false,
    this.serviceDetailResponse,
    this.isFromServiceInfo = false,
    this.providerData,
  });

  @override
  _ProviderServiceComponentState createState() =>
      _ProviderServiceComponentState();
}

class _ProviderServiceComponentState extends State<ProviderServiceComponent> {
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

  String visitTypeLabel(String? visitType) {
    final v = visitType.validate().trim().toUpperCase();
    if (v == 'ONLINE') return 'Remote';
    if (v == 'ON_SITE') return 'Onsite';
    if (v == 'HYBRID') return 'Hybrid';
    return _titleCase(visitType.validate());
  }
  String serviceTypeLabel(String? type) {
    final t = type.validate();
    final lower = t.toLowerCase();
    if (lower == SERVICE_TYPE_HOURLY.toLowerCase()) return language.hourly;
    if (lower == SERVICE_TYPE_DAILY.toLowerCase()) return 'Daily';
    if (lower == SERVICE_TYPE_FIXED.toLowerCase()) return 'Fixed';
    return t.capitalizeFirstLetter();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void bookNow(ServiceDetailResponse serviceDetailResponse) {
    if (widget.isFromServiceInfo) {
      doIfLoggedIn(context, () {
        // serviceDetailResponse.serviceDetail!.bookingAddressId =
        //     selectedBookingAddressId;
        BookServiceScreen(
                data: serviceDetailResponse,
                selectedPackage: widget.selectedPackage)
            .launch(context)
            .then((value) {
          setStatusBarColor(transparentColor);
        });
      });
    }
  }

  Future<PostJobDetailResponse>? future;

  void init() async {
    // future = getPostJobDetail(
    //     {PostJob.postRequestId: widget.selectedPackage.i});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    // Street address is not shown for associated services; city/country renders below
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : context.width();
        return GestureDetector(
          onTap: () {
            hideKeyboard(context);
            ServiceDetailScreen(
                    serviceId: widget.isFavouriteService
                        ? widget.serviceData!.serviceId.validate().toInt()
                        : widget.serviceData!.id.validate())
                .launch(context)
                .then((value) {
              setStatusBarColor(context.primaryColor);
            });
          },
          child: Container(
            width: cardWidth,
        padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: boxDecorationWithRoundedCorners(
          borderRadius: radius(),
          backgroundColor: context.cardColor,
          border: widget.isBorderEnabled.validate(value: false)
              ? appStore.isDarkMode
                  ? Border.all(color: context.dividerColor)
                  : null
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedImageWidget(
              url: widget.isFavouriteService
                  ? widget.serviceData!.serviceAttachments.validate().isNotEmpty
                      ? widget.serviceData!.serviceAttachments!.first.validate()
                      : ''
                  : widget.serviceData!.attachments.validate().isNotEmpty
                      ? widget.serviceData!.attachments!.first.validate()
                      : '',
              fit: BoxFit.cover,
              height: 80,
              width: 80,
              circle: false,
              radius: defaultRadius,
            ),
            8.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                            color: appStore.isDarkMode
                                ? Colors.black
                                : lightPrimaryColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            widget.serviceData!.categoryName.validate(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      TextIcon(
                        suffix: Row(
                          children: [
                            Image.asset(ic_star_fill,
                                height: 12,
                                color: getRatingBarColor(widget
                                    .serviceData!.totalRating
                                    .validate()
                                    .toInt())),
                            4.width,
                            Text(
                                "${widget.serviceData!.totalRating.validate().toStringAsFixed(1)}",
                                style: boldTextStyle()),
                          ],
                        ),
                      ),
                    ],
                  ),
                  10.height,
                  Text(
                    widget.serviceData!.name.validate(),
                    style: primaryTextStyle(weight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  10.height,
                  Row(
                    children: [
                      PriceWidget(
                        size: 14,
                        price: widget.serviceData!.discount.validate() > 0
                            ? widget.serviceData!.getDiscountedPrice
                            : widget.serviceData!.price.validate(),
                        isHourlyService: widget.serviceData!.isHourlyService,
                        isFixedService: widget.serviceData!.isFixedService,
                      ),
                      6.width,
                      if (widget.serviceData!.discount.validate() > 0)
                        Flexible(
                          child: PriceWidget(
                            size: 11,
                            price: widget.serviceData!.price.validate(),
                            isDiscountedPrice: true,
                            color: textSecondaryColorGlobal,
                            isLineThroughEnabled: true,
                          ),
                        ),
                      6.width,
                      if (widget.serviceData!.discount.validate() > 0)
                        Flexible(
                          child: Text(
                            "${widget.serviceData!.discount.validate()}% off", //Todo translate
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                                color: defaultActivityStatus,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  // Street address removed as per requirement
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Builder(builder: (context) {
                        final String primaryCity = widget.serviceData?.serviceCityName.validate() ?? '';
                        final String primaryCountry = widget.serviceData?.serviceCountryName.validate() ?? '';
                        final String fallbackCity = widget.serviceData?.cityName.validate() ?? '';
                        final String fallbackCountry = widget.serviceData?.countryName.validate() ?? '';
                        final String city = primaryCity.isNotEmpty ? primaryCity : fallbackCity;
                        final String country = primaryCountry.isNotEmpty ? primaryCountry : fallbackCountry;
                        if (city.isEmpty && country.isEmpty) return Offstage();
                        return Text(
                          "$city${(city.isNotEmpty && country.isNotEmpty) ? ' - ' : ''}$country",
                          style: secondaryTextStyle(size: 10, color: defaultActivityStatus),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                      Text(
                        'Job Type : ${visitTypeLabel(widget.serviceData?.visitType)}',
                        style: secondaryTextStyle(
                            size: 10, color: defaultActivityStatus),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Bookings: ${widget.serviceData!.completedBookings.validate()}',
                              style: secondaryTextStyle(
                                  size: 9, color: defaultActivityStatus),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          8.width,
                          Flexible(
                            child: Text(
                              'Views: ${widget.serviceData!.totalViews.validate()}',
                              style: secondaryTextStyle(
                                  size: 9, color: defaultActivityStatus),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (widget.isFromServiceInfo) ...[
                    4.height,
                    SizedBox(
                      height: 24,
                      child: ElevatedButton(
                        onPressed: () {
                          bookNow(widget.serviceDetailResponse!);
                        },
                        style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            backgroundColor: darkBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            )),
                        child: Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 12,
                            color: white,
                            inherit: true,
                          ),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
            if (widget.isFavouriteService)
              Container(
                margin: EdgeInsets.only(left: 4),
                padding: EdgeInsets.all(4),
                decoration: boxDecorationWithShadow(
                    boxShape: BoxShape.circle,
                    backgroundColor: context.cardColor),
                child: widget.serviceData!.isFavourite == 1
                    ? ic_fill_heart.iconImage(color: favouriteColor, size: 16)
                    : ic_heart.iconImage(color: unFavouriteColor, size: 16),
              ).onTap(() async {
                if (widget.serviceData!.isFavourite == 1) {
                  // Currently favorited, so remove it
                  widget.serviceData!.isFavourite = 0;
                  setState(() {});

                  await removeToWishList(
                          serviceId:
                              widget.serviceData!.serviceId.validate().toInt())
                      .then((value) {
                    if (!value) {
                      // Revert on error
                      widget.serviceData!.isFavourite = 1;
                      setState(() {});
                    }
                  });
                } else {
                  // Currently not favorited, so add it
                  widget.serviceData!.isFavourite = 1;
                  setState(() {});

                  await addToWishList(
                          serviceId:
                              widget.serviceData!.serviceId.validate().toInt())
                      .then((value) {
                    if (!value) {
                      // Revert on error
                      widget.serviceData!.isFavourite = 0;
                      setState(() {});
                    }
                  });
                }
                widget.onUpdate?.call();
              }),
          ],
        ),
      ),
        );
      },
    );
  }
}
