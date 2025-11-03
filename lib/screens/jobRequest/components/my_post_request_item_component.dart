import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/screens/jobRequest/create_post_request_screen.dart';
import 'package:booking_system_flutter/screens/jobRequest/job_request_details_screen.dart';
import 'package:booking_system_flutter/screens/jobRequest/my_post_detail_screen.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../main.dart';
import '../../../network/rest_apis.dart';
import '../../../utils/images.dart';

class MyPostRequestItemComponent extends StatefulWidget {
  final PostJobData data;
  final Function(bool) callback;

  MyPostRequestItemComponent({required this.data, required this.callback});

  @override
  _MyPostRequestItemComponentState createState() =>
      _MyPostRequestItemComponentState();
}

class _MyPostRequestItemComponentState
    extends State<MyPostRequestItemComponent> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  void deletePost(num id) {
    widget.callback.call(true);

    deletePostRequest(id: id.validate()).then((value) {
      appStore.setLoading(false);
      toast(value.message.validate());

      widget.callback.call(false);
    }).catchError((e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if(widget.data.acceptedBidId != null) {
          JobRequestDetailsScreen(
            acceptedBidId: widget.data.acceptedBidId!,
            callback: () {
              widget.callback.call(true);
            },
          ).launch(context);
        } else {
          MyPostDetailScreen(
            postRequestId: widget.data.id.validate().toInt(),
            postJobData: widget.data,
            callback: () {
              widget.callback.call(true);
            },
          ).launch(context);
        }
      },
      child: Container(
        decoration: boxDecorationWithRoundedCorners(
          borderRadius: radius(),
          backgroundColor: context.cardColor,
        ),
        width: context.width(),
        margin: EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
        padding: EdgeInsets.only(top: 12, bottom: 12, left: 16, right: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedImageWidget(
              url: widget.data.images.isNotEmpty ? widget.data.images.first : "",
              fit: BoxFit.cover,
              height: 60,
              width: 60,
              circle: false,
            ).cornerRadiusWithClipRRect(defaultRadius),
            16.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                        widget.data.title.validate(),
                      style: boldTextStyle(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ).expand(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.data.status.bgColor.withValues(alpha: .1),
                        borderRadius: radius(8),
                      ),
                      child: Text(
                        widget.data.status.displayName,
                        style: boldTextStyle(
                          color: widget.data.status.bgColor,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                4.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PriceWidget(
                      price: widget.data.price.validate(),
                      isHourlyService: widget.data.priceType == PriceType.hourly,
                      isDailyService: widget.data.priceType == PriceType.daily,
                      isFixedService: widget.data.priceType == PriceType.fixed,
                      color: textPrimaryColorGlobal,
                      isFreeService: false,
                      size: 14,
                    ),
                    Text(
                      "Proposals: ${widget.data.bidCount ?? 0}",
                      style: secondaryTextStyle(),
                    ),
                  ],
                ),
                4.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.data.type?.displayName ?? '',
                      style: boldTextStyle(),
                    ),
                    Text(
                      "Views:${widget.data.totalViews ?? 0}",
                      style: secondaryTextStyle(),
                    ),
                  ],
                ),
                4.height,
                if (widget.data.remoteWorkLevel != null)
                  Text(
                    widget.data.remoteWorkLevel!.displayName,
                    style: secondaryTextStyle(size: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                4.height,
                if(widget.data.cityName.validate().isNotEmpty || widget.data.countryName.validate().isNotEmpty) Text(
                "${widget.data.cityName ?? ''}${widget.data.countryName.validate().isEmpty ? "" : "${widget.data.cityName.validate().isEmpty ? "" :  " - "}${widget.data.countryName}"}",
                  style: secondaryTextStyle(size: 12),
                ),
                4.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        formatDate(widget.data.createdAt.validate()),
                        style: secondaryTextStyle(),
                      ),
                    ),
                    Row(
                      children: [
                        if(widget.data.status == RequestStatus.requested) GestureDetector(
                          child: ic_edit_square.iconImage(size: 16),
                          onTap: () async {
                            bool? res = await CreatePostRequestScreen(editJob: widget.data).launch(context);

                            if (res ?? false) {
                              widget.callback.call(true);
                            }
                          },
                        ),
                        // if(widget.data.status == RequestStatus.requested) IconButton(
                        //   icon: ic_delete.iconImage(size: 16),
                        //   visualDensity: VisualDensity.compact,
                        //   onPressed: () {
                        //     showConfirmDialogCustom(
                        //       context,
                        //       dialogType: DialogType.DELETE,
                        //       title: '${language.deleteMessage}?',
                        //       positiveText: language.lblYes,
                        //       negativeText: language.lblNo,
                        //       onAccept: (p0) {
                        //         ifNotTester(() {
                        //           deletePost(widget.data.id.validate());
                        //         });
                        //       },
                        //     );
                        //   },
                        // ),
                      ],
                    )
                  ],
                ),

              ],
            ).expand(),
          ],
        ),
      ),
    );
  }
}
