import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/user_info_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/provider_info_response.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/model/service_detail_response.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../utils/colors.dart';
import '../../utils/constant.dart';
import '../service/view_all_service_screen.dart';
import 'component/handyman_staff_members_component.dart';
import 'component/provider_service_component.dart';

class ProviderInfoScreen extends StatefulWidget {
  final int? providerId;
  final bool canCustomerContact;
  final VoidCallback? onUpdate;
  final ServiceData? serviceData;

  ProviderInfoScreen(
      {this.providerId,
      this.canCustomerContact = false,
      this.onUpdate,
      this.serviceData});

  @override
  ProviderInfoScreenState createState() => ProviderInfoScreenState();
}

class ProviderInfoScreenState extends State<ProviderInfoScreen> {
  Future<ProviderInfoResponse>? future;
  int page = 1;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    future = getProviderDetail(widget.providerId.validate(),
        userId: appStore.userId.validate());
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget servicesWidget(
      {required List<ServiceData> list,
      required int totalServicesCount,
      int? providerId,
      UserData? providerData}) {
    return Column(
      children: [
        ViewAllLabel(
          label: '${language.service} (${totalServicesCount})',
          list: list,
          onTap: () {
            ViewAllServiceScreen(providerId: providerId)
                .launch(context, pageRouteAnimation: PageRouteAnimation.Fade);
          },
        ),
        if (list.isEmpty)
          NoDataWidget(
              title: language.lblNoServicesFound,
              imageWidget: EmptyStateWidget()),
        if (list.isNotEmpty)
          AnimatedWrap(
            spacing: 16,
            runSpacing: 16,
            itemCount: list.length,
            listAnimationType: ListAnimationType.FadeIn,
            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
            scaleConfiguration: ScaleConfiguration(
                duration: 300.milliseconds, delay: 50.milliseconds),
            itemBuilder: (_, index) => ProviderServiceComponent(
              serviceData: list[index],
              isFromProviderInfo: true,
              serviceDetailResponse: ServiceDetailResponse(),
              providerData: providerData,
            ),
          ).paddingOnly(bottom: 50)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        finish(context);
        widget.onUpdate?.call();
        return Future.value(true);
      },
      child: AppScaffold(
        appBarTitle: language.lblAboutProvider,
        showLoader: false,
        child: Scaffold(
          body: SnapHelperWidget<ProviderInfoResponse>(
            future: future,
            initialData: cachedProviderList
                .firstWhere(
                    (element) => element?.$1 == widget.providerId.validate(),
                    orElse: () => null)
                ?.$2,
            onSuccess: (data) {
              // Clean skills - remove brackets, quotes, double commas
              final List<String> skills = data.userData?.skills != null
                  ? data.userData!.skillsArray
                      .map((e) => e
                          .replaceAll(RegExp(r'[\[\]"]'), '') // Remove brackets and quotes
                          .replaceAll(RegExp(r',+'), ',') // Remove double commas
                          .trim())
                      .where((e) => e.isNotEmpty)
                      .toList()
                  : [];
              final List<String> mobilityList = data.userData?.mobility != null
                  ? data.userData!.mobility!
                      .split(',')
                      .map((e) => e
                          .replaceAll(RegExp(r'[\[\]"]'), '')
                          .replaceAll(RegExp(r',+'), ',')
                          .trim())
                      .where((e) => e.isNotEmpty)
                      .toList()
                  : [];
              final List<String> experienceList =
                  data.userData?.experience != null
                      ? data.userData!.experience!
                          .split(',')
                          .map((e) => e
                              .replaceAll(RegExp(r'[\[\]"]'), '')
                              .replaceAll(RegExp(r',+'), ',')
                              .trim())
                          .where((e) => e.isNotEmpty)
                          .toList()
                      : [];
              final List<String> certifications =
                  data.userData?.certification != null
                      ? data.userData!.certification!
                          .split(',')
                          .map((e) => e
                              .replaceAll(RegExp(r'[\[\]"]'), '')
                              .replaceAll(RegExp(r',+'), ',')
                              .trim())
                          .where((e) => e.isNotEmpty)
                          .toList()
                      : [];

              return Stack(
                children: [
                  AnimatedScrollView(
                    listAnimationType: ListAnimationType.FadeIn,
                    physics: AlwaysScrollableScrollPhysics(),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserInfoWidget(
                        data: data.userData!,
                        isOnTapEnabled: true,
                        onUpdate: () {
                          widget.onUpdate?.call();
                        },
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          15.height,
                          Text(
                            language.personalInfo,
                            style: boldTextStyle(size: 18),
                          ).paddingSymmetric(horizontal: 16),
                          if (data
                              .userData!.knownLanguagesArray.isNotEmpty) ...[
                            15.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(language.knownLanguages,
                                        style: boldTextStyle(size: LABEL_TEXT_SIZE))
                                    .paddingSymmetric(horizontal: 16),
                                8.height,
                                Wrap(
                                  children: data.userData!.knownLanguagesArray
                                      .map((e) {
                                    return Container(
                                      decoration:
                                          boxDecorationWithRoundedCorners(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(20)),
                                        backgroundColor: appStore.isDarkMode
                                            ? cardDarkColor
                                            : primaryColor.withValues(
                                                alpha: 0.1),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      margin:
                                          EdgeInsets.only(right: 8, bottom: 8),
                                      child: Text(e,
                                          style: secondaryTextStyle(
                                              size: 12, weight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                ).paddingSymmetric(
                                  horizontal: 16,
                                ),
                              ],
                            ),
                            // 32.height
                          ],
                          if (skills.isNotEmpty) ...[
                            15.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(language.essentialSkills,
                                        style: boldTextStyle(size: LABEL_TEXT_SIZE))
                                    .paddingSymmetric(horizontal: 16),
                                8.height,
                                Wrap(
                                  children: skills.map((e) {
                                    return e.isNotEmpty
                                        ? Container(
                                            decoration:
                                                boxDecorationWithRoundedCorners(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20)),
                                              backgroundColor:
                                                  appStore.isDarkMode
                                                      ? cardDarkColor
                                                      : primaryColor.withValues(
                                                          alpha: 0.1),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            margin: EdgeInsets.only(
                                                right: 8, bottom: 8),
                                            child: Text(e,
                                                style: secondaryTextStyle(
                                                    size: 12, weight: FontWeight.bold)),
                                          )
                                        : SizedBox.shrink();
                                  }).toList(),
                                ).paddingSymmetric(horizontal: 16),
                              ],
                            ),
                          ],
                          if (experienceList.isNotEmpty) ...[
                            15.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Experiences', style: boldTextStyle(size: LABEL_TEXT_SIZE))
                                    .paddingSymmetric(horizontal: 16),
                                8.height,
                                Wrap(
                                  children: experienceList.map((e) {
                                    return e.isNotEmpty
                                        ? Container(
                                            decoration:
                                                boxDecorationWithRoundedCorners(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20)),
                                              backgroundColor:
                                                  appStore.isDarkMode
                                                      ? cardDarkColor
                                                      : primaryColor.withValues(
                                                          alpha: 0.1),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            margin: EdgeInsets.only(
                                                right: 8, bottom: 8),
                                            child: Text(e,
                                                style: secondaryTextStyle(
                                                    size: 12, weight: FontWeight.bold)),
                                          )
                                        : SizedBox.shrink();
                                  }).toList(),
                                ).paddingSymmetric(horizontal: 16),
                              ],
                            ),
                          ],
                          if (data.userData?.availability != null) ...[
                            15.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text('Availability: ', style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                                Text(data.userData!.availability.validate(),
                                    style: secondaryTextStyle(size: 12)),
                              ],
                            ).paddingSymmetric(horizontal: 16),
                          ],
                          if (mobilityList.isNotEmpty) ...[
                            15.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mobility', style: boldTextStyle(size: LABEL_TEXT_SIZE))
                                    .paddingSymmetric(horizontal: 16),
                                8.height,
                                Wrap(
                                  children: mobilityList.map((e) {
                                    return e.isNotEmpty
                                        ? Container(
                                            decoration:
                                                boxDecorationWithRoundedCorners(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20)),
                                              backgroundColor:
                                                  appStore.isDarkMode
                                                      ? cardDarkColor
                                                      : primaryColor.withValues(
                                                          alpha: 0.1),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            margin: EdgeInsets.only(
                                                right: 8, bottom: 8),
                                            child: Text(e,
                                                style: secondaryTextStyle(
                                                    size: 12, weight: FontWeight.bold)),
                                          )
                                        : SizedBox.shrink();
                                  }).toList(),
                                ).paddingSymmetric(horizontal: 16),
                              ],
                            ),
                          ],
                          if (certifications.isNotEmpty) ...[
                            15.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Certification', style: boldTextStyle(size: LABEL_TEXT_SIZE))
                                    .paddingSymmetric(horizontal: 16),
                                8.height,
                                Wrap(
                                  children: certifications.map((e) {
                                    return e.isNotEmpty
                                        ? Container(
                                            decoration:
                                                boxDecorationWithRoundedCorners(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20)),
                                              backgroundColor:
                                                  appStore.isDarkMode
                                                      ? cardDarkColor
                                                      : primaryColor.withValues(
                                                          alpha: 0.1),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 8),
                                            margin: EdgeInsets.only(
                                                right: 8, bottom: 8),
                                            child: Text(e,
                                                style: secondaryTextStyle(
                                                    size: 12, weight: FontWeight.bold)),
                                          )
                                        : SizedBox.shrink();
                                  }).toList(),
                                ).paddingSymmetric(horizontal: 16),
                              ],
                            ),
                          ],
                          if (data.userData?.education != null) ...[
                            15.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Education', style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                                5.height,
                                Text(data.userData!.education.validate(),
                                    style: secondaryTextStyle(size: 12)),
                              ],
                            ).paddingSymmetric(horizontal: 16),
                          ],
                          ...[
                            15.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking:',
                                  style: boldTextStyle(size: LABEL_TEXT_SIZE),
                                ),
                                8.width,
                                Container(
                                  decoration: boxDecorationWithRoundedCorners(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20)),
                                    backgroundColor: appStore.isDarkMode
                                        ? cardDarkColor
                                        : primaryColor.withValues(alpha: 0.1),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text(
                                    '${data.userData?.totalBooking.validate()}',
                                    style: secondaryTextStyle(
                                        size: 12, weight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ).paddingSymmetric(horizontal: 16),
                          ],
                          if (data.userData?.totalServices != null) ...[
                            15.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Services:',
                                  style: boldTextStyle(size: LABEL_TEXT_SIZE),
                                ),
                                8.width,
                                Container(
                                  decoration: boxDecorationWithRoundedCorners(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20)),
                                    backgroundColor: appStore.isDarkMode
                                        ? cardDarkColor
                                        : primaryColor.withValues(alpha: 0.1),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text(
                                    '${data.userData?.totalServices.validate()}',
                                    style: secondaryTextStyle(
                                        size: 12, weight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ).paddingSymmetric(horizontal: 16),
                          ],
                          if (data.completedJobs != null) ...[
                            15.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  'Completed Jobs:',
                                  style: boldTextStyle(size: LABEL_TEXT_SIZE),
                                ),
                                8.width,
                                Container(
                                  decoration: boxDecorationWithRoundedCorners(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(20)),
                                    backgroundColor: appStore.isDarkMode
                                        ? cardDarkColor
                                        : primaryColor.withValues(alpha: 0.1),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text(
                                    '${data.completedJobs.validate()}',
                                    style: secondaryTextStyle(
                                        size: 12, weight: FontWeight.bold),
                                  ),
                                )
                              ],
                            ).paddingSymmetric(horizontal: 16),
                          ],
                          // if (widget.canCustomerContact) ...[
                          //   26.height,
                          //   Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          // Text(language.personalInfo,
                          //         style: boldTextStyle())
                          //     .paddingSymmetric(horizontal: 16),
                          //       8.height,
                          //       TextIcon(
                          //         spacing: 10,
                          //         onTap: () {
                          //           launchMail(
                          //               "${data.userData!.email.validate()}");
                          //         },
                          //         prefix: Image.asset(ic_message,
                          //             width: 16,
                          //             height: 16,
                          //             color: appStore.isDarkMode
                          //                 ? Colors.white
                          //                 : context.primaryColor),
                          //         text: data.userData!.email.validate(),
                          //         textStyle: secondaryTextStyle(size: 14),
                          //         expandedText: true,
                          //       ).paddingSymmetric(horizontal: 16),
                          //       4.height,
                          //       TextIcon(
                          //         spacing: 10,
                          //         onTap: () {
                          //           launchCall(
                          //               "${data.userData!.contactNumber.validate()}");
                          //         },
                          //         prefix: Image.asset(ic_calling,
                          //             width: 16,
                          //             height: 16,
                          //             color: appStore.isDarkMode
                          //                 ? Colors.white
                          //                 : context.primaryColor),
                          //         text: data.userData!.contactNumber.validate(),
                          //         textStyle: secondaryTextStyle(size: 14),
                          //         expandedText: true,
                          //       ).paddingSymmetric(horizontal: 16),
                          //     ],
                          //   ),
                          // ],
                          15.height,
                          HandymanStaffMembersComponent(
                            handymanList: data.handymanStaffList.validate(),
                          ),
                          if (data.userData!.aboutMe != null &&
                              data.userData!.aboutMe.validate().isNotEmpty) ...[
                            15.height,
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('About Me', style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                                5.height,
                                Text(data.userData!.aboutMe.validate(),
                                    style: secondaryTextStyle(size: 12)),
                              ],
                            ).paddingSymmetric(horizontal: 16),
                          ],
                          32.height,
                          servicesWidget(
                            list: data.serviceList!.take(6).toList(),
                            totalServicesCount: data.serviceList!.length,
                            providerId: widget.providerId.validate(),
                            providerData: data.userData,
                          ).paddingSymmetric(horizontal: 16),
                        ],
                      ),
                    ],
                    onSwipeRefresh: () async {
                      page = 1;

                      init();
                      setState(() {});

                      return await 2.seconds.delay;
                    },
                  ),
                  Observer(
                      builder: (context) =>
                          LoaderWidget().visible(appStore.isLoading))
                ],
              );
            },
            loadingWidget: LoaderWidget(),
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
        ),
      ),
    );
  }
}
