import 'package:booking_system_flutter/component/shimmer_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class FavouriteServiceShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget buildFavouriteServiceShimmer() {
      // Always show list-style shimmer to match list UI
      return ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: 8,
        separatorBuilder: (_, __) => 16.height,
        itemBuilder: (context, index) {
          return ShimmerWidget(
            child: Container(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 16),
              decoration: boxDecorationWithRoundedCorners(
                borderRadius: radius(),
                backgroundColor: context.cardColor,
                border: appStore.isDarkMode
                    ? Border.all(color: context.dividerColor)
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerWidget(
                    child: Container(
                      height: 85,
                      width: 110,
                      decoration: boxDecorationWithRoundedCorners(
                        borderRadius: radius(8),
                        backgroundColor: context.cardColor,
                      ),
                    ),
                  ),
                  12.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerWidget(height: 12, width: context.width() * 0.4),
                        10.height,
                        ShimmerWidget(height: 12, width: context.width() * 0.6),
                        8.height,
                        ShimmerWidget(height: 10, width: context.width() * 0.3),
                        6.height,
                        ShimmerWidget(height: 10, width: context.width() * 0.5),
                        6.height,
                        Row(
                          children: [
                            ShimmerWidget(
                                height: 10, width: context.width() * 0.2),
                            12.width,
                            ShimmerWidget(
                                height: 10, width: context.width() * 0.2),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 60),
      child: buildFavouriteServiceShimmer(),
    );
  }
}
