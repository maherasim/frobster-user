import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/my_post_request_item_component.dart';
import 'package:booking_system_flutter/screens/jobRequest/create_post_request_screen.dart';
import 'package:booking_system_flutter/screens/jobRequest/shimmer/my_post_job_shimmer.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:booking_system_flutter/utils/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../component/gradient_fab.dart';

class MyPostRequestListScreen extends StatefulWidget {
  final bool fromDashboard;
  const MyPostRequestListScreen({super.key,this.fromDashboard = false});
  @override
  _MyPostRequestListScreenState createState() =>
      _MyPostRequestListScreenState();
}

class _MyPostRequestListScreenState extends State<MyPostRequestListScreen> with SingleTickerProviderStateMixin {
  late Future<List<PostJobData>> future;
  List<PostJobData> postJobList = [];

  int page = 1;
  bool isLastPage = false;
  bool isApiCalled = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    init();
    getLocation();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> init() async {
    future =
        getPostJobList(page, postJobList: postJobList, lastPageCallBack: (val) {
      isLastPage = val;
    });
  }

  void getLocation() {
    Geolocator.requestPermission().then((value) {
      if (value == LocationPermission.whileInUse ||
          value == LocationPermission.always) {
        Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
            .then((value) {
          appStore.setLatitude(value.latitude);
          appStore.setLongitude(value.longitude);
          setState(() {});
        }).catchError(onError);
      }
    });
  }

  @override
  void dispose() {
    setStatusBarColor(Colors.transparent,
        statusBarIconBrightness:
            appStore.isDarkMode ? Brightness.light : Brightness.dark);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: widget.fromDashboard ? language.lblJob : language.myPostJobList,
      actions: [
        // Future: add filters sheet
      ],
      bottom: TabBar(
        controller: _tabController,
        isScrollable: false,
        labelStyle: boldTextStyle(size: 13, color: Colors.white),
        unselectedLabelStyle:
            secondaryTextStyle(size: 13, color: Colors.white70, weight: FontWeight.w600),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: Colors.white,
        tabs: [
          Tab(text: 'All'),
          Tab(text: 'Open'),
          Tab(text: language.inProgress.validate(value: 'In Progress')),
          Tab(text: language.completed.validate(value: 'Completed')),
        ],
      ),
      child: Stack(
        children: [
          SnapHelperWidget<List<PostJobData>>(
            future: future,
            initialData: cachedPostJobList,
            onSuccess: (data) {
              final filtered = _filterDataByTab(data);
              return AnimatedListView(
                itemCount: filtered.length,
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(top: 12, bottom: 70),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                itemBuilder: (_, i) {
                  PostJobData postJob = filtered[i];

                  return MyPostRequestItemComponent(
                    data: postJob,
                    callback: (v) {
                      appStore.setLoading(v);
                      if (v) {
                        page = 1;
                        init();
                        setState(() {});
                      }
                    },
                  );
                },
                emptyWidget: NoDataWidget(
                  title: language.noPostJobFound,
                  subTitle: language.noPostJobFoundSubtitle,
                  imageWidget: EmptyStateWidget(),
                ),
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
              );
            },
            loadingWidget: MyPostJobShimmer(),
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
          ),
          Observer(
              builder: (context) => LoaderWidget().visible(appStore.isLoading))
        ],
      ),
      floatingActionButton: GradientFAB(
        onPressed: () async {
          bool? res = await CreatePostRequestScreen().launch(context);

          if (res ?? false) {
            page = 1;
            init();
            setState(() {});
          }
        },
        icon: ic_add.iconImage(size: 18, color: white),
        label: language.requestNewJob,
      ),
    );
  }

  List<PostJobData> _filterDataByTab(List<PostJobData> data) {
    final index = _tabController.index;
    if (index == 0) return data;
    if (index == 1) {
      // Open
      return data.where((e) =>
      e.status == RequestStatus.requested ||
          e.status == RequestStatus.accepted ||
          e.status == RequestStatus.pendingAdvance).toList();
    } else if (index == 2) {
      // In Progress
      return data.where((e) =>
      e.status == RequestStatus.advancePaid ||
          e.status == RequestStatus.inProcess ||
          e.status == RequestStatus.inProgress ||
          e.status == RequestStatus.hold).toList();
    } else {
      // Completed
      return data.where((e) =>
      e.status == RequestStatus.done ||
          e.status == RequestStatus.confirmDone ||
          e.status == RequestStatus.completed ||
          e.status == RequestStatus.remainingPaid).toList();
    }
  }
}
