import 'package:booking_system_flutter/component/selected_item_widget.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../component/empty_error_state_widget.dart';
import '../../../model/city_list_model.dart';

class FilterCityComponent extends StatefulWidget {
  final List<CityListResponse> cityList;

  FilterCityComponent({required this.cityList});

  @override
  State<FilterCityComponent> createState() => _FilterCountryComponentState();
}

class _FilterCountryComponentState extends State<FilterCityComponent> {
  int? isSelected;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    //
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cityList.isEmpty)
      return NoDataWidget(
        title: 'No City Found',
        imageWidget: EmptyStateWidget(),
      );

    return AnimatedListView(
      itemCount: widget.cityList.length,
      slideConfiguration: sliderConfigurationGlobal,
      listAnimationType: ListAnimationType.FadeIn,
      fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
      itemBuilder: (context, index) {
        CityListResponse data = widget.cityList[index];
        return Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.name.validate(), style: boldTextStyle()),
                ],
              ).expand(),
              SelectedItemWidget(isSelected: data.isSelected),
            ],
          ),
        ).onTap(() {
          if (data.isSelected) {
            data.isSelected = false;
          } else {
            data.isSelected = true;
          }
          setState(() {});
        });
      },
    );
  }
}
