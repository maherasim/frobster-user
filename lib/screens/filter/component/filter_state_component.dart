import 'package:booking_system_flutter/component/selected_item_widget.dart';
import 'package:booking_system_flutter/model/state_list_model.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';

class FilterStateComponent extends StatefulWidget {
  final List<StateListResponse> stateList;
  final Set<int> selectedStateIds;
  final ValueChanged<int>? onStateToggle;

  const FilterStateComponent({
    required this.stateList,
    required this.selectedStateIds,
    this.onStateToggle,
    super.key,
  });

  @override
  State<FilterStateComponent> createState() => _FilterStateComponentState();
}

class _FilterStateComponentState extends State<FilterStateComponent> {
  @override
  Widget build(BuildContext context) {
    if (widget.stateList.isEmpty) {
      return NoDataWidget(
        title: 'No State Found',
        imageWidget: EmptyStateWidget(),
      );
    }

    return AnimatedListView(
      itemCount: widget.stateList.length,
      slideConfiguration: SlideConfiguration(duration: 400.milliseconds),
      listAnimationType: ListAnimationType.FadeIn,
      fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
      itemBuilder: (context, index) {
        final data = widget.stateList[index];
        final bool isSelected = widget.selectedStateIds.contains(data.id);
        return Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Text(data.name.validate(), style: boldTextStyle()).expand(),
              SelectedItemWidget(isSelected: isSelected),
            ],
          ),
        ).onTap(() {
          if (widget.onStateToggle != null) {
            widget.onStateToggle!.call(data.id.validate());
          }
          setState(() {});
        });
      },
    );
  }
}


