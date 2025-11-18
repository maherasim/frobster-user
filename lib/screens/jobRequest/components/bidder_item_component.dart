import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/screens/jobRequest/job_request_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/disabled_rating_bar_widget.dart';
import '../../../component/price_widget.dart';

class BidderItemComponent extends StatefulWidget {
  final BidderData data;
  final PostJobData postJobData;
  final VoidCallback callback;

  BidderItemComponent({
    required this.data,
    required this.postJobData,
    required this.callback,
  });

  @override
  _BidderItemComponentState createState() => _BidderItemComponentState();
}

class _BidderItemComponentState extends State<BidderItemComponent> {
  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }
  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

   bool isAccepted = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
          backgroundColor: context.cardColor,
          borderRadius: BorderRadius.all(Radius.circular(16))),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedImageWidget(
                url: widget.data.provider!.profileImage.validate(),
                fit: BoxFit.cover,
                height: 60,
                width: 60,
                circle: true,
              ),
              8.width,
              Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Marquee(
                    directionMarguee: DirectionMarguee.oneDirection,
                    child: Text(widget.data.provider!.displayName.validate(),
                        style: boldTextStyle()),
                  ),
                  if (widget.data.provider!.designation.validate().isNotEmpty)
                    Marquee(
                      directionMarguee: DirectionMarguee.oneDirection,
                      child: Text(widget.data.provider!.designation.validate(),
                          style: primaryTextStyle(size: 12)),
                    ),
                  if(widget.data.provider != null && (widget.data.provider!.cityName.validate().isNotEmpty || widget.data.provider!.countryName.validate().isNotEmpty)) Marquee(
                    directionMarguee: DirectionMarguee.oneDirection,
                    child: Text(
                      "${widget.data.provider!.cityName ?? ''}${widget.data.provider!.countryName.validate().isEmpty ? "" : "${widget.data.provider!.cityName.validate().isEmpty ? "" :  " - "}${widget.data.provider?.countryName}"}",
                      style: primaryTextStyle(size: 12),
                    ),
                  ),
                  DisabledRatingBarWidget(
                    rating: widget.data.provider!.providersServiceRating.validate(),
                    size: 14,
                  ),
                  Marquee(
                    directionMarguee: DirectionMarguee.oneDirection,
                    child: Row(
                      children: [
                        Text('${language.bidPrice}: ', style: secondaryTextStyle()),
                        PriceWidget(
                          price: widget.data.price.validate(),
                          isHourlyService: widget.postJobData.priceType == PriceType.hourly,
                          isDailyService: widget.postJobData.priceType == PriceType.daily,
                          isFixedService: widget.postJobData.priceType == PriceType.fixed,
                          color: textPrimaryColorGlobal,
                          isFreeService: false,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                  if (widget.data.whyChooseMe.validate().isNotEmpty) 8.height,
                  if (widget.data.whyChooseMe.validate().isNotEmpty)
                    InkWell(
                      onTap: () {
                        showInDialog(
                          context,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                language.whyChooseMe,
                                style: primaryTextStyle(),
                              ),
                              GestureDetector(
                                onTap: () => finish(context),
                                child: Icon(Icons.close),
                              )
                            ],
                          ),
                          builder: (context) => Text(
                            widget.data.whyChooseMe.validate(),
                            style: secondaryTextStyle(size: 12,color: textPrimaryColorGlobal),
                          ),
                        );
                      },
                      child: Text(language.whyChooseMe, style: primaryTextStyle(color: context.primaryColor, size: 12)),
                    ),
                ],
              ).expand(),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  padding: EdgeInsets.zero,
                  child: Text("View Proposal", style: boldTextStyle(color: white, size: 12)),
                  color: context.primaryColor,
                  onTap: () async {
                    final id = widget.data.id.validate();
                    await JobRequestDetailsScreen(
                        acceptedBidId: id,
                        callback: () {
                          widget.callback();
                          isAccepted = true;
                          setState(() {});
                        },
                      ).launch(context);
                    if(isAccepted) {
                      finish(context);
                    }
                  },
                ),
              ),
              16.width,
              Expanded(
                child: AppButton(
                  padding: EdgeInsets.zero,
                  child: Text('Hire', style: boldTextStyle(color: white, size: 12)),
                  color: context.primaryColor,
                  onTap: () {
                    _showHireSheet(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHireSheet(BuildContext context) {
    num unitPrice = widget.data.price.validate();
    int quantity = _getQuantityByPriceType(widget.postJobData);
    num subTotal = unitPrice * quantity;
    // Optional: could be provided by API on bid detail

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: radiusOnly(topLeft: 20, topRight: 20)),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Hire Provider', style: boldTextStyle(size: 18)).expand(),
                  IconButton(icon: Icon(Icons.close), onPressed: () => finish(ctx)),
                ],
              ),
              8.height,
              Row(
                children: [
                  Text('Rate (unit)', style: secondaryTextStyle()).expand(),
                  PriceWidget(price: unitPrice, color: textPrimaryColorGlobal),
                ],
              ),
              8.height,
              Row(
                children: [
                  Text('Quantity', style: secondaryTextStyle()).expand(),
                  Text(quantity.toString(), style: primaryTextStyle()),
                ],
              ),
              8.height,
              Row(
                children: [
                  Text('Subtotal', style: boldTextStyle()).expand(),
                  PriceWidget(price: subTotal, color: textPrimaryColorGlobal),
                ],
              ),
              12.height,
              AppButton(
                width: context.width(),
                color: context.primaryColor,
                child: Text('Hire & Continue', style: boldTextStyle(color: white)),
                onTap: () async {
                  final id = widget.data.id.validate();
                  finish(ctx);
                  await JobRequestDetailsScreen(
                    acceptedBidId: id,
                    callback: () {
                      widget.callback();
                      isAccepted = true;
                      setState(() {});
                    },
                  ).launch(context);
                  if (isAccepted) {
                    finish(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  int _getQuantityByPriceType(PostJobData post) {
    if (post.priceType == PriceType.fixed) {
      return 1;
    } else if (post.priceType == PriceType.hourly) {
      return post.totalHours?.toInt() ?? 1;
    } else {
      return post.totalDays?.toInt() ?? 1;
    }
  }
}
