import 'dart:async';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/disabled_rating_bar_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/model/post_job_detail_response.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/provider_info_screen.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/bidder_item_component.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../component/empty_error_state_widget.dart';

class MyPostDetailScreen extends StatefulWidget {
  final int postRequestId;
  final PostJobData? postJobData;
  final VoidCallback callback;

  MyPostDetailScreen({
    this.postJobData,
    required this.callback,
    required this.postRequestId,
  });

  @override
  _MyPostDetailScreenState createState() => _MyPostDetailScreenState();
}

class _MyPostDetailScreenState extends State<MyPostDetailScreen> {
  Future<PostJobDetailResponse>? future;

  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    LiveStream().on(LIVESTREAM_UPDATE_BIDER, (p0) {
      init();
      setState(() {});
    });

    init();
  }

  void init() async {
    future = getPostJobDetail(
        {PostJob.postRequestId: widget.postRequestId.validate()});
  }

  Widget titleWidget({
    required String title,
    required String detail,
    Widget? detailWidget,
    bool isReadMore = false,
    bool isLeftAlign = true,
    required TextStyle detailTextStyle,
  }) {
    final String plainText = parseHtmlString(detail);
    return Column(
      crossAxisAlignment:
          isLeftAlign ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          title.validate(),
          textAlign: isLeftAlign ? TextAlign.left : TextAlign.right,
          style: boldTextStyle(size: LABEL_TEXT_SIZE),
        ),
        8.height,
        if (detailWidget != null)
          detailWidget
        else if (isReadMore)
          ReadMoreText(
            plainText,
            style: detailTextStyle,
            colorClickableText: gradientRed,
          )
        else
          Text(
            plainText.validate(),
            textAlign: isLeftAlign ? TextAlign.left : TextAlign.right,
            style: detailTextStyle,
          ),
        16.height,
      ],
    );
  }

  // Modern Info Card Widget
  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: boxDecorationDefault(
        color: context.cardColor,
        borderRadius: radius(12),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: boxDecorationDefault(
              color: (iconColor ?? context.primaryColor).withOpacity(0.1),
              borderRadius: radius(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? context.primaryColor,
              size: 20,
            ),
          ),
          16.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: boldTextStyle(
                    size: 14,
                    color: textPrimaryColorGlobal,
                  ),
                ),
                6.height,
                Text(
                  value,
                  style: secondaryTextStyle(
                    size: 12,
                    color: textSecondaryColorGlobal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Price Card Widget
  Widget _priceCard({
    required IconData icon,
    required String label,
    required Widget priceWidget,
    Color? iconColor,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 12),
      decoration: boxDecorationDefault(
        color: context.cardColor,
        borderRadius: radius(12),
        border: Border.all(color: context.dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: boxDecorationDefault(
              color: (iconColor ?? Colors.green).withOpacity(0.1),
              borderRadius: radius(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Colors.green,
              size: 20,
            ),
          ),
          16.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: boldTextStyle(
                    size: 14,
                    color: textPrimaryColorGlobal,
                  ),
                ),
                6.height,
                priceWidget,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section Card Widget for Rich Content
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String content,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    return Container(
      width: context.width(),
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: boxDecorationDefault(
        color: backgroundColor ?? context.cardColor,
        borderRadius: radius(16),
        border: Border.all(
          color: (iconColor ?? context.primaryColor).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: boxDecorationDefault(
                  color: (iconColor ?? context.primaryColor).withOpacity(0.15),
                  borderRadius: radius(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? context.primaryColor,
                  size: 24,
                ),
              ),
              12.width,
              Expanded(
                child: Text(
                  title,
                  style: boldTextStyle(
                    size: 18,
                    color: textPrimaryColorGlobal,
                  ),
                ),
              ),
            ],
          ),
          16.height,
          Divider(color: context.dividerColor),
          12.height,
          ReadMoreText(
            parseHtmlString(content),
            style: secondaryTextStyle(size: 14, height: 1.6),
            colorClickableText: iconColor ?? context.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget postJobDetailWidget({required PostJobData data}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Job Title Header Card
        Container(
          width: context.width(),
          padding: EdgeInsets.all(20),
          decoration: boxDecorationDefault(
            color: context.primaryColor.withOpacity(0.1),
            borderRadius: radius(16),
            border: Border.all(
              color: context.primaryColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.work_outline,
                    color: context.primaryColor,
                    size: 28,
                  ),
                  12.width,
                  Expanded(
                    child: Text(
                      data.title.validate(),
                      style: boldTextStyle(
                        size: 22,
                        color: textPrimaryColorGlobal,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        20.height,

        // Quick Info Grid
        Container(
          padding: EdgeInsets.all(16),
          decoration: boxDecorationDefault(
            color: context.cardColor,
            borderRadius: radius(16),
            border: Border.all(color: context.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Job Details",
                style: boldTextStyle(size: 18, color: textPrimaryColorGlobal),
              ),
              16.height,
              _infoCard(
                icon: Icons.location_on_outlined,
                label: "Location",
                value:
                    "${data.cityName ?? ''}${data.countryName.validate().isEmpty ? "" : "${data.cityName.validate().isEmpty ? "" : " - "}${data.countryName}"}",
                iconColor: Colors.red,
              ),
              _infoCard(
                icon: Icons.business_center_outlined,
                label: "Job Type",
                value: data.type?.displayName ?? 'N/A',
                iconColor: Colors.blue,
              ),
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      icon: Icons.calendar_today_outlined,
                      label: language.startDate,
                      value: formatDate(data.startDate.validate()),
                      iconColor: Colors.orange,
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: _infoCard(
                      icon: Icons.event_outlined,
                      label: language.endDate,
                      value: formatDate(data.endDate.validate()),
                      iconColor: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        16.height,

        // Budget Section
        Container(
          padding: EdgeInsets.all(16),
          decoration: boxDecorationDefault(
            color: context.cardColor,
            borderRadius: radius(16),
            border: Border.all(color: context.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Budget & Duration",
                style: boldTextStyle(size: 18, color: textPrimaryColorGlobal),
              ),
              16.height,
              _priceCard(
                icon: Icons.attach_money,
                label: "Budget/Price",
                priceWidget: PriceWidget(
                  size: 14,
                  price: data.price.validate(),
                  color: textSecondaryColorGlobal,
                  isHourlyService: data.priceType == PriceType.hourly,
                  isDailyService: data.priceType == PriceType.daily,
                ),
                iconColor: Colors.green,
              ),
              _priceCard(
                icon: Icons.account_balance_wallet_outlined,
                label: "Total Budget",
                priceWidget: PriceWidget(
                  size: 14,
                  price: data.totalBudget.validate(),
                  color: textSecondaryColorGlobal,
                ),
                iconColor: Colors.teal,
              ),
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      icon: Icons.calendar_view_week_outlined,
                      label: "Total Days",
                      value: data.totalDays?.toString() ?? '0',
                      iconColor: Colors.indigo,
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: _infoCard(
                      icon: Icons.access_time_outlined,
                      label: "Total Hours",
                      value: data.totalHours?.toString() ?? '0',
                      iconColor: Colors.cyan,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        16.height,

        // Work Details Section
        Container(
          padding: EdgeInsets.all(16),
          decoration: boxDecorationDefault(
            color: context.cardColor,
            borderRadius: radius(16),
            border: Border.all(color: context.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Work Details",
                style: boldTextStyle(size: 18, color: textPrimaryColorGlobal),
              ),
              16.height,
              _infoCard(
                icon: Icons.home_work_outlined,
                label: "Remote Work Level",
                value: data.remoteWorkLevel?.displayName ?? 'N/A',
                iconColor: Colors.deepOrange,
              ),
              _infoCard(
                icon: Icons.flight_takeoff_outlined,
                label: "Travel Required",
                value: data.travelRequired?.displayName ?? 'N/A',
                iconColor: Colors.blueGrey,
              ),
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      icon: Icons.trending_up_outlined,
                      label: "Career Level",
                      value: data.careerLevel?.displayName ?? 'N/A',
                      iconColor: Colors.pink,
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: _infoCard(
                      icon: Icons.school_outlined,
                      label: "Education Level",
                      value: data.educationLevel?.displayName ?? 'N/A',
                      iconColor: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Description Section
        if (data.description.validate().isNotEmpty) ...[
          16.height,
          _sectionCard(
            icon: Icons.description_outlined,
            title: language.postJobDescription,
            content: data.description.validate(),
            iconColor: Colors.blue,
            backgroundColor: Colors.blue.withOpacity(0.05),
          ),
        ],

        // Skills & Requirements Section
        if (data.requirement.validate().isNotEmpty) ...[
          _sectionCard(
            icon: Icons.stars_outlined,
            title: "Skills & Requirements",
            content: data.requirement.validate(),
            iconColor: Colors.orange,
            backgroundColor: Colors.orange.withOpacity(0.05),
          ),
        ],

        // Duties & Responsibilities Section
        if (data.duties.validate().isNotEmpty) ...[
          _sectionCard(
            icon: Icons.checklist_outlined,
            title: "Duties & Responsibilities",
            content: data.duties.validate(),
            iconColor: Colors.purple,
            backgroundColor: Colors.purple.withOpacity(0.05),
          ),
        ],

        // Benefits Section - Special Design
        if (data.benefits.validate().isNotEmpty) ...[
          Container(
            width: context.width(),
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(20),
            decoration: boxDecorationDefault(
              color: Colors.green.withOpacity(0.08),
              borderRadius: radius(16),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: boxDecorationDefault(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: radius(12),
                      ),
                      child: Icon(
                        Icons.card_giftcard,
                        color: Colors.green.shade700,
                        size: 28,
                      ),
                    ),
                    12.width,
                    Expanded(
                      child: Text(
                        "Benefits",
                        style: boldTextStyle(
                          size: 20,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                16.height,
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: boxDecorationDefault(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: radius(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.celebration,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      8.width,
                      Expanded(
                        child: ReadMoreText(
                          parseHtmlString(data.benefits.validate()),
                          style: secondaryTextStyle(
                            size: 14,
                            height: 1.6,
                            color: textPrimaryColorGlobal,
                          ),
                          colorClickableText: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget postJobServiceWidget({required List<ServiceData> serviceList}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(language.services, style: boldTextStyle(size: LABEL_TEXT_SIZE))
            .paddingOnly(left: 16, right: 16),
        8.height,
        AnimatedListView(
          itemCount: serviceList.length,
          padding: EdgeInsets.all(8),
          shrinkWrap: true,
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemBuilder: (_, i) {
            ServiceData data = serviceList[i];

            return Container(
              width: context.width(),
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(8),
              decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: context.cardColor,
                  borderRadius: BorderRadius.all(Radius.circular(16))),
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

  Widget bidderWidget(List<BidderData> bidderList,
      {required PostJobDetailResponse postJobDetailResponse}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          label: language.bidder,
          list: bidderList,
          onTap: () {
            //
          },
        ).paddingSymmetric(horizontal: 16),
        AnimatedListView(
          itemCount: bidderList.length,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemBuilder: (_, i) {
            return BidderItemComponent(
              data: bidderList[i],
              postJobData: postJobDetailResponse.postRequestDetail!,
              callback: widget.callback,
            );
          },
        ),
      ],
    );
  }

  Widget providerWidget(List<BidderData> bidderList, num? providerId) {
    try {
      BidderData? bidderData =
          bidderList.firstWhere((element) => element.providerId == providerId);
      UserData? user = bidderData.provider;

      if (user != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.height,
            Text(language.assignedProvider,
                style: boldTextStyle(size: LABEL_TEXT_SIZE)),
            16.height,
            InkWell(
              onTap: () {
                ProviderInfoScreen(providerId: user.id.validate())
                    .launch(context);
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: context.cardColor,
                    borderRadius: BorderRadius.all(Radius.circular(16))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CachedImageWidget(
                          url: user.profileImage.validate(),
                          fit: BoxFit.cover,
                          height: 60,
                          width: 60,
                          circle: true,
                        ),
                        8.width,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Marquee(
                                  directionMarguee:
                                      DirectionMarguee.oneDirection,
                                  child: Text(
                                    user.displayName.validate(),
                                    style: boldTextStyle(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ).expand(),
                              ],
                            ),
                            4.height,
                            if (user.designation.validate().isNotEmpty)
                              Marquee(
                                directionMarguee: DirectionMarguee.oneDirection,
                                child: Text(
                                  user.designation.validate(),
                                  style: primaryTextStyle(size: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            6.height,
                            if (user.providersServiceRating != null)
                              DisabledRatingBarWidget(
                                  rating:
                                      user.providersServiceRating.validate(),
                                  size: 14),
                          ],
                        ).expand(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).paddingOnly(left: 16, right: 16);
      } else {
        return SizedBox();
      }
    } catch (e) {
      log(e);
      return Offstage();
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    LiveStream().dispose(LIVESTREAM_UPDATE_BIDER);
    super.dispose();
  }

  String image = '';

  jobImagesSection(List<String> images) {
    if (images.isEmpty) return Offstage();
    image = images.first;
    return StatefulBuilder(
      builder: (context, set) {
        return Column(
          children: [
            if (images.isNotEmpty)
              CachedImageWidget(
                url: image,
                fit: BoxFit.cover,
                height: 250,
                width: context.width(),
                radius: defaultRadius,
              ).paddingOnly(left: 16, right: 16, top: 16),
            if (images.length > 1)
              SizedBox(
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () {
                      image = images[index];
                      set(() {});
                    },
                    child: CachedImageWidget(
                      url: images[index],
                      fit: BoxFit.cover,
                      height: 60,
                      width: 60,
                      radius: defaultRadius,
                    ),
                  ),
                  separatorBuilder: (context, index) => 16.width,
                  itemCount: images.length,
                ),
              ).paddingOnly(left: 16, right: 16, top: 16),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: language.myPostDetail,
      child: SnapHelperWidget<PostJobDetailResponse>(
        future: future,
        onSuccess: (data) {
          return Stack(
            children: [
              AnimatedScrollView(
                padding: EdgeInsets.only(bottom: 60),
                physics: AlwaysScrollableScrollPhysics(),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  jobImagesSection(data.postRequestDetail!.images),
                  postJobDetailWidget(data: data.postRequestDetail!)
                      .paddingAll(16),
                  if (data.postRequestDetail!.service.validate().isNotEmpty)
                    postJobServiceWidget(
                        serviceList:
                            data.postRequestDetail!.service.validate()),
                  if (data.postRequestDetail!.providerId != null)
                    providerWidget(
                      data.biderData.validate(),
                      data.postRequestDetail!.providerId.validate(),
                    ),
                  16.height,
                  if (data.biderData.validate().isNotEmpty)
                    bidderWidget(data.biderData.validate(),
                        postJobDetailResponse: data),
                ],
                onSwipeRefresh: () async {
                  page = 1;

                  init();
                  setState(() {});

                  return await 2.seconds.delay;
                },
              ),
              // if (data.postRequestDetail!.status ==
              //     JOB_REQUEST_STATUS_ASSIGNED)
              //   Positioned(
              //     bottom: 16,
              //     left: 16,
              //     right: 16,
              //     child: AppButton(
              //       child: Text(language.bookTheService,
              //           style: boldTextStyle(color: white)),
              //       color: context.primaryColor,
              //       width: context.width(),
              //       onTap: () async {
              //         BookPostJobRequestScreen(
              //           postJobDetailResponse: data,
              //           providerId:
              //               data.postRequestDetail!.providerId.validate(),
              //           jobPrice: data.postRequestDetail!.price.validate(),
              //         ).launch(context);
              //       },
              //     ),
              //   ),
              Observer(
                  builder: (context) =>
                      LoaderWidget().visible(appStore.isLoading))
            ],
          );
        },
        errorBuilder: (error) {
          return NoDataWidget(
            title: error,
            imageWidget: ErrorStateWidget(),
            retryText: language.reload,
            onRetry: () {
              page = 1;
              appStore.setLoading(true);

              init();
              setState(() {});
            },
          );
        },
        loadingWidget: LoaderWidget(),
      ),
    );
  }
}
