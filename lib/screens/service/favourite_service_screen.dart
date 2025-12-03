import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/booking/component/provider_service_component.dart';
import 'package:booking_system_flutter/model/provider_info_response.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/screens/service/shimmer/favourite_service_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/empty_error_state_widget.dart';
import '../../utils/constant.dart';
import '../../utils/colors.dart';

class FavouriteServiceScreen extends StatefulWidget {
  const FavouriteServiceScreen({Key? key}) : super(key: key);

  @override
  _FavouriteServiceScreenState createState() => _FavouriteServiceScreenState();
}

class _FavouriteServiceScreenState extends State<FavouriteServiceScreen> {
  Future<List<ServiceData>>? future;

  List<ServiceData> services = [];

  int page = 1;

  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    future = getWishlist(page, services: services, lastPageCallBack: (p0) {
      isLastPage = p0;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.lblFavorite, style: boldTextStyle(color: Colors.white, size: APP_BAR_TEXT_SIZE)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackWidget(),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: appPrimaryGradient),
        ),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<ServiceData>>(
            future: future,
            initialData: cachedServiceFavList,
            builder: (context, snap) {
              if (snap.hasData) {
                if (snap.data.validate().isEmpty)
                  return NoDataWidget(
                    title: language.lblNoServicesFound,
                    subTitle: language.noFavouriteSubTitle,
                    imageWidget: EmptyStateWidget(),
                  );

                return AnimatedScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 60),
                  listAnimationType: ListAnimationType.FadeIn,
                  fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                  physics: AlwaysScrollableScrollPhysics(),
                  onNextPage: () {
                    if (!isLastPage) {
                      page++;
                      appStore.setLoading(true);

                      init();
                      setState(() {});
                    }
                  },
                  onSwipeRefresh: () async {
                    page = 1;

                    init();
                    setState(() {});

                    return await 2.seconds.delay;
                  },
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snap.data!.length,
                      separatorBuilder: (_, __) => 16.height,
                      itemBuilder: (_, index) {
                        final service = snap.data![index];
                        return FutureBuilder<ProviderInfoResponse>(
                          future:
                              getProviderDetail(service.providerId.validate()),
                          builder: (context, providerSnap) {
                            final UserData? providerData = providerSnap.hasData
                                ? providerSnap.data!.userData
                                : null;
                            return ProviderServiceComponent(
                              serviceData: service,
                              isFromProviderInfo: true,
                              serviceDetailResponse: ServiceDetailResponse(),
                              isFavouriteService: true,
                              providerData: providerData,
                              onUpdate: () async {
                                page = 1;
                                await init();
                                setState(() {});
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              }

              return snapWidgetHelper(
                snap,
                loadingWidget: FavouriteServiceShimmer(),
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
              );
            },
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }
}
