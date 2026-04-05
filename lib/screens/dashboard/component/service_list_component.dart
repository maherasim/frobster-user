import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/screens/service/component/service_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../utils/ugc_blocked_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../service/view_all_service_screen.dart';

class ServiceListComponent extends StatelessWidget {
  final List<ServiceData> serviceList;

  ServiceListComponent({required this.serviceList});

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (_) {
      final list =
          filterOutBlockedServices(serviceList, appStore.blockedUserIds);
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        16.height,
        ViewAllLabel(
          label: language.service,
          list: list,
          onTap: () {
            ViewAllServiceScreen().launch(context);
          },
        ).paddingSymmetric(horizontal: 16),
        8.height,
        list.isNotEmpty
            ? Column(
                children: List.generate(list.length, (index) {
                  return ServiceComponent(
                    isFromService: true,
                    isSmallGrid: true,
                    serviceData: list[index],
                    isBorderEnabled: true,
                    width: context.width() - 32, // full width inside 16px padding
                  ).paddingOnly(bottom: 16);
                }),
              ).paddingSymmetric(horizontal: 16, vertical: 8)
            : Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                child: NoDataWidget(
                  title: language.lblNoServicesFound,
                  imageWidget: EmptyStateWidget(),
                ),
              ).center(),
      ],
    );
    });
  }
}
