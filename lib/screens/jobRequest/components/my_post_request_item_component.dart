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
import '../../../utils/colors.dart';
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
          borderRadius: radius(16),
          backgroundColor: context.cardColor,
        ),
        width: context.width(),
        margin: EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with overlays
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedImageWidget(
                      url: widget.data.images.isNotEmpty ? widget.data.images.first : "",
                      fit: BoxFit.cover,
                      height: double.infinity,
                      width: double.infinity,
                      circle: false,
                    ),
                  ),
                ),
                // Top gradient to improve legibility of overlays
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .55),
                      borderRadius: radius(20),
                    ),
                    child: Text(
                      widget.data.status.displayName,
                      style: boldTextStyle(color: white, size: 12),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: gradientRed,
                      borderRadius: radius(20),
                    ),
                    child: Row(
                      children: [
                        PriceWidget(
                          price: widget.data.price.validate(),
                          color: white,
                          isFreeService: false,
                          size: 14,
                        ),
                        6.width,
                        Text(
                          '/ ${widget.data.priceType?.displayName ?? ''}',
                          style: primaryTextStyle(color: white, size: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.title.validate(),
                    style: boldTextStyle(size: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  6.height,
                  if(widget.data.cityName.validate().isNotEmpty || widget.data.countryName.validate().isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: textSecondaryColorGlobal),
                        4.width,
                        Expanded(
                          child: Text(
                            "${widget.data.cityName ?? ''}${widget.data.countryName.validate().isEmpty ? "" : "${widget.data.cityName.validate().isEmpty ? "" :  " - "}${widget.data.countryName}"}",
                            style: secondaryTextStyle(size: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  8.height,
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: gradientRed.withValues(alpha: 0.08),
                          borderRadius: radius(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.work_outline, size: 14, color: gradientRed),
                            6.width,
                            Text(widget.data.type?.displayName ?? '', style: boldTextStyle(size: 12, color: gradientRed)),
                          ],
                        ),
                      ),
                      12.width,
                      Row(
                        children: [
                          Icon(Icons.remove_red_eye_outlined, size: 14, color: textSecondaryColorGlobal),
                          4.width,
                          Text("Views: ${widget.data.totalViews ?? 0}", style: secondaryTextStyle(size: 12)),
                        ],
                      ),
                      12.width,
                      Row(
                        children: [
                          Icon(Icons.how_to_reg_outlined, size: 14, color: textSecondaryColorGlobal),
                          4.width,
                          Text("Proposals: ${widget.data.bidCount ?? 0}", style: secondaryTextStyle(size: 12)),
                        ],
                      ),
                    ],
                  ),
                  8.height,
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: textSecondaryColorGlobal),
                      4.width,
                      Text(formatDate(widget.data.createdAt.validate()), style: secondaryTextStyle(size: 12)),
                    ],
                  ),
                  8.height,
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
