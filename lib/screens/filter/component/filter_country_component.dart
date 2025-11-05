import 'package:booking_system_flutter/component/selected_item_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../component/empty_error_state_widget.dart';
import '../../../model/country_list_model.dart';

class FilterCountryComponent extends StatefulWidget {
  final List<CountryListResponse> countryList;
  final ValueChanged<int>? onCountryToggle;

  FilterCountryComponent({required this.countryList, this.onCountryToggle});

  @override
  State<FilterCountryComponent> createState() => _FilterCountryComponentState();
}

class _FilterCountryComponentState extends State<FilterCountryComponent> {
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
    if (widget.countryList.isEmpty)
      return NoDataWidget(
        title: language.noCategoryFound,
        imageWidget: EmptyStateWidget(),
      );

    return AnimatedListView(
      itemCount: widget.countryList.length,
      slideConfiguration: sliderConfigurationGlobal,
      listAnimationType: ListAnimationType.FadeIn,
      fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
      itemBuilder: (context, index) {
        CountryListResponse data = widget.countryList[index];
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
          if (widget.onCountryToggle != null) {
            widget.onCountryToggle!.call(data.id.validate());
          }
          setState(() {});
        });
      },
    );
  }
}
