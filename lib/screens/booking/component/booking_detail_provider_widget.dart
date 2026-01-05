import 'dart:convert';

import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/image_border_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../model/booking_data_model.dart';
import '../../../model/country_list_model.dart';
import '../../../network/rest_apis.dart';
import '../../../utils/model_keys.dart';
import '../../chat/user_chat_screen.dart';

class BookingDetailProviderWidget extends StatefulWidget {
  final UserData providerData;
  final bool canCustomerContact;
  final bool providerIsHandyman;
  final BookingData? bookingDetail;

  BookingDetailProviderWidget(
      {required this.providerData,
      this.canCustomerContact = false,
      this.providerIsHandyman = false,
      this.bookingDetail});

  @override
  BookingDetailProviderWidgetState createState() =>
      BookingDetailProviderWidgetState();
}

class BookingDetailProviderWidgetState
    extends State<BookingDetailProviderWidget> {
  UserData userData = UserData();

  bool isChattingAllow = false;

  int? flag;

  CountryListResponse? country;
  List<dynamic> myList = [];

  Future<void> getCountry(int countryId) async {
    await getCountryList().then((value) async {
      if (value.any((element) => element.id == countryId)) {
        country = value.firstWhere((element) => element.id == countryId);
      }

      setState(() {});
    }).catchError((e) {
      toast('$e', print: true);
    });
    appStore.setLoading(false);
    return null;
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    userData = widget.providerData;
    await getCountry(userData.countryId.validate());
    myList = jsonDecode(userData.knownLanguages.validate());
    setState(() {});
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: boxDecorationDefault(
        color: context.cardColor,
        border: appStore.isDarkMode
            ? Border.all(color: context.dividerColor)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImageBorder(
                  src: widget.providerData.profileImage.validate(), height: 60),
              16.width,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Verified/Not Verified Icon (dynamic from API - check bookingDetail first, then providerData)
                      if ((widget.bookingDetail?.verifiedStickerIcon.validate().isNotEmpty == true) ||
                          (widget.providerData.verifiedStickerIcon.validate().isNotEmpty))
                        CachedImageWidget(
                          url: (widget.bookingDetail?.verifiedStickerIcon.validate().isNotEmpty == true)
                              ? widget.bookingDetail!.verifiedStickerIcon.validate()
                              : widget.providerData.verifiedStickerIcon.validate(),
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
                      // Membership Icon (dynamic from API - check bookingDetail first, then providerData)
                      if ((widget.bookingDetail?.membershipIcon.validate().isNotEmpty == true) ||
                          (widget.providerData.membershipIcon.validate().isNotEmpty))
                        CachedImageWidget(
                          url: (widget.bookingDetail?.membershipIcon.validate().isNotEmpty == true)
                              ? widget.bookingDetail!.membershipIcon.validate()
                              : widget.providerData.membershipIcon.validate(),
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
                      Row(
                        children: [
                          Marquee(
                                  child: Text(
                                      widget.providerData.displayName
                                          .validate(),
                                      style: boldTextStyle()))
                              .flexible(),
                          16.width,
                          Image.asset(ic_verified,
                                  height: 16, color: Colors.green)
                              .visible(
                                  widget.providerData.isVerifyProvider == 1),
                        ],
                      ).expand(),
                      if (widget.providerIsHandyman &&
                          widget.providerData.isProvider)
                        GestureDetector(
                          onTap: () async {
                            String phoneNumber = "";
                            if (widget.providerData.contactNumber
                                .validate()
                                .contains('+')) {
                              phoneNumber =
                                  "${widget.providerData.contactNumber.validate().replaceAll('-', '')}";
                            } else {
                              phoneNumber =
                                  "+${widget.providerData.contactNumber.validate().replaceAll('-', '')}";
                            }
                            launchUrl(
                                Uri.parse(
                                    '${getSocialMediaLink(LinkProvider.WHATSAPP)}$phoneNumber'),
                                mode: LaunchMode.externalApplication);
                          },
                          child: CachedImageWidget(
                              url: ic_whatsapp, height: 22, width: 22),
                        ),
                    ],
                  ),
                  4.height,
                  Row(
                    children: [
                      Image.asset(ic_star_fill,
                          height: 14,
                          fit: BoxFit.fitWidth,
                          color: getRatingBarColor(widget
                              .providerData.providersServiceRating
                              .validate()
                              .toInt())),
                      4.width,
                      Text(
                          widget.providerData.providersServiceRating
                              .validate()
                              .toStringAsFixed(1)
                              .toString(),
                          style: boldTextStyle(
                              color: textSecondaryColor, size: 14)),
                    ],
                  ),
                  Text(
                    '${widget.providerData.cityName} - ${country?.name}',
                    style: primaryTextStyle(size: 12),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  4.height,
                  Row(
                    children: [
                      Text(
                        'Services : ${widget.providerData.totalServices.validate()}',
                        style: primaryTextStyle(size: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).flexible(),
                      12.width,
                      Text(
                        'Views: ${widget.providerData.totalBooking.validate()}',
                        style: primaryTextStyle(size: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ).flexible(),
                    ],
                  )
                ],
              ).expand(),
            ],
          ),
          if (!widget.providerIsHandyman)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${language.lblMemberSince}:',
                        style: boldTextStyle(
                            size: 12,
                            color: appStore.isDarkMode
                                ? textSecondaryColor
                                : textPrimaryColor),
                      ),
                      8.width,
                      Expanded(
                        flex: 4,
                        child: Text(
                          '${formatDate(widget.providerData.createdAt.validate())}',
                          style: boldTextStyle(
                              size: 12,
                              color: appStore.isDarkMode
                                  ? white
                                  : textSecondaryColor,
                              weight: FontWeight.w400),
                        ),
                      ),
                    ],
                  ),
                  8.height,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completed Jobs:',
                        style: boldTextStyle(
                            size: 12,
                            color: appStore.isDarkMode
                                ? textSecondaryColor
                                : textPrimaryColor),
                      ),
                      8.width,
                      Expanded(
                        flex: 4,
                        child: Text(
                          '${widget.providerData.totalBooking}',
                          style: boldTextStyle(
                            size: 12,
                            color: appStore.isDarkMode
                                ? white
                                : textSecondaryColor,
                            weight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  8.height,
                  if (widget.providerData.knownLanguages != null &&
                      widget.providerData.knownLanguages!.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Languages:',
                          style: boldTextStyle(
                              size: 12,
                              color: appStore.isDarkMode
                                  ? textSecondaryColor
                                  : textPrimaryColor),
                        ),
                        8.width,
                        Expanded(
                          flex: 4,
                          child: Text(
                            myList.join(", "),
                            style: boldTextStyle(
                                size: 12,
                                color: appStore.isDarkMode
                                    ? white
                                    : textSecondaryColor,
                                weight: FontWeight.w400),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          if (widget.providerIsHandyman)
            Row(
              children: [
                if (widget.providerData.contactNumber.validate().isNotEmpty)
                  AppButton(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ic_calling.iconImage(size: 18, color: Colors.white),
                        8.width,
                        Text(language.lblCall,
                            style: boldTextStyle(color: white)),
                      ],
                    ).fit(),
                    width: context.width(),
                    color: primaryColor,
                    elevation: 0,
                    onTap: () {
                      launchCall(widget.providerData.contactNumber.validate());
                    },
                  ).expand(),
                16.width,
                AppButton(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ic_chat.iconImage(size: 18),
                      8.width,
                      Text(language.lblChat, style: boldTextStyle()),
                    ],
                  ).fit(),
                  width: context.width(),
                  elevation: 0,
                  color: context.scaffoldBackgroundColor,
                  onTap: () async {
                    toast(language.pleaseWaitWhileWeLoadChatDetails);
                    UserData? user = await userService.getUserNull(
                        email: widget.providerData.email.validate());
                    if (user != null) {
                      Fluttertoast.cancel();
                      if (widget.bookingDetail != null) {
                        isChattingAllow = widget.bookingDetail!.status ==
                                BookingStatusKeys.complete ||
                            widget.bookingDetail!.status ==
                                BookingStatusKeys.cancelled;
                      }
                      UserChatScreen(
                              receiverUser: user,
                              isChattingAllow: isChattingAllow)
                          .launch(context);
                    } else {
                      Fluttertoast.cancel();
                      toast(
                          "${widget.providerData.firstName} ${language.isNotAvailableForChat}");
                    }
                  },
                ).expand(),
              ],
            ).paddingTop(8),
        ],
      ),
    );
  }
}
