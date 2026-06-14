import 'dart:async';

import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/disabled_rating_bar_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
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
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
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

  // Helper method to get background color for job type
  Color _getJobTypeBgColor(JobType? type) {
    if (type == null) return gradientRed.withValues(alpha: 0.08);
    switch (type) {
      case JobType.onSite:
        return Colors.blue.withValues(alpha: 0.12); // Blue for On Site
      case JobType.remote:
        return Colors.green.withValues(alpha: 0.12); // Green for Remote
      case JobType.hybrid:
        return Colors.orange.withValues(alpha: 0.12); // Orange for Hybrid
    }
  }

  // Helper method to get text color for job type
  Color _getJobTypeColor(JobType? type) {
    if (type == null) return gradientRed;
    switch (type) {
      case JobType.onSite:
        return Colors.blue.shade700; // Blue for On Site
      case JobType.remote:
        return Colors.green.shade700; // Green for Remote
      case JobType.hybrid:
        return Colors.orange.shade700; // Orange for Hybrid
    }
  }

  Widget postJobDetailWidget({required PostJobData data}) {
    // Simple attribute row helper - matching reference design
    Widget attributeRow(String label, String value, {Color? valueColor, Widget? customValueWidget}) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label:',
              style: boldTextStyle(size: 14),
            ),
            if (customValueWidget != null)
              customValueWidget
            else
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: valueColor ?? textPrimaryColorGlobal,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Job Title - Simple text, no card, no icon
        Text(
          data.title.validate(),
          style: boldTextStyle(size: 22, color: textPrimaryColorGlobal),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        24.height,

        // Location - Simple text
        if (data.cityName.validate().isNotEmpty || data.countryName.validate().isNotEmpty)
          Text(
            "${data.cityName ?? ''}${data.countryName.validate().isEmpty ? "" : "${data.cityName.validate().isEmpty ? "" : " - "}${data.countryName}"}",
            style: secondaryTextStyle(size: 14, color: gradientRed),
          ),
        24.height,

        // Simple attribute rows - matching reference design
        attributeRow(
          "Job Type",
          data.type?.displayName ?? 'N/A',
          customValueWidget: data.type != null
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getJobTypeBgColor(data.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data.type!.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getJobTypeColor(data.type),
                    ),
                  ),
                )
              : null,
        ),
        attributeRow(language.startDate, formatDate(data.startDate.validate())),
        attributeRow(language.endDate, formatDate(data.endDate.validate())),
        attributeRow(
          "Budget/Price",
          (data.price.validate()).toPriceFormat(),
        ),
        attributeRow("Total Budget", (data.totalBudget.validate()).toPriceFormat()),
        attributeRow("Total Days", data.totalDays?.toString() ?? '0'),
        attributeRow("Total Hours", data.totalHours?.toString() ?? '0'),
        attributeRow("Remote Work Level", data.remoteWorkLevel?.displayName ?? 'N/A'),
        attributeRow("Travel Required", data.travelRequired?.displayName ?? 'N/A'),
        attributeRow("Career Level", data.careerLevel?.displayName ?? 'N/A'),
        attributeRow("Education Level", data.educationLevel?.displayName ?? 'N/A'),

        // Description Section - Simple and Clean (like service detail screen)
        if (data.description.validate().isNotEmpty) ...[
          24.height,
          Text('Description',
              style: boldTextStyle(size: 18)),
          16.height,
          HtmlWidget(
            data.description.validate(),
            textStyle: secondaryTextStyle(),
          ),
        ],

        // Skills & Requirements Section - Simple and Clean
        if (data.requirement.validate().isNotEmpty) ...[
          24.height,
          Text('Skills & Requirements',
              style: boldTextStyle(size: 18)),
          16.height,
          HtmlWidget(
            data.requirement.validate(),
            textStyle: secondaryTextStyle(),
          ),
        ],

        // Duties & Responsibilities Section - Simple and Clean
        if (data.duties.validate().isNotEmpty) ...[
          24.height,
          Text('Duties & Responsibilities',
              style: boldTextStyle(size: 18)),
          16.height,
          HtmlWidget(
            data.duties.validate(),
            textStyle: secondaryTextStyle(),
          ),
        ],

        // Benefits Section - Simple and Clean
        if (data.benefits.validate().isNotEmpty) ...[
          24.height,
          Text('Benefits',
              style: boldTextStyle(size: 18)),
          16.height,
          HtmlWidget(
            data.benefits.validate(),
            textStyle: secondaryTextStyle(),
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
    // Filter out cancelled bids - they should not be shown
    final activeBids = bidderList.where((bid) => 
      bid.status == null || bid.status != RequestStatus.cancel
    ).toList();
    
    if (activeBids.isEmpty) return SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ViewAllLabel(
          label: language.bidder,
          list: activeBids,
          onTap: () {
            //
          },
        ).paddingSymmetric(horizontal: 16),
        AnimatedListView(
          itemCount: activeBids.length,
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          listAnimationType: ListAnimationType.FadeIn,
          fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
          itemBuilder: (_, i) {
            return BidderItemComponent(
              data: activeBids[i],
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
      // Filter out cancelled bids before finding the provider
      final activeBids = bidderList.where((bid) => 
        bid.status == null || bid.status != RequestStatus.cancel
      ).toList();
      
      BidderData? bidderData =
          activeBids.firstWhere((element) => element.providerId == providerId);
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
