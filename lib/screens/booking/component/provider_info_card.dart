import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:nb_utils/nb_utils.dart';

class ProviderInfoCard extends StatelessWidget {
  final UserData userData;
  const ProviderInfoCard({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    Widget titleWidget(
        {required String title,
        required String detail,
        bool isReadMore = false,
        required TextStyle detailTextStyle}) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.validate(), style: secondaryTextStyle()),
          4.height,
          if (isReadMore)
            ReadMoreText(
              detail,
              style: detailTextStyle,
              colorClickableText: context.primaryColor,
            )
          else
            Text(detail.validate(), style: boldTextStyle(size: 12)),
          20.height,
        ],
      );
    }

    return Column(
      // mainAxisSize: MainAxisSize,
      children: [
        Text(
          'Personal Info',
          style: boldTextStyle(),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: radius(),
          ),
          child: Column(
            children: [
              titleWidget(
                title: 'Skills',
                detail: userData.skills.validate(),
                detailTextStyle: boldTextStyle(),
              ),
            ],
          ),
        ),
      ],
    ).paddingSymmetric(horizontal: 16);
  }
}
