import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';
import 'package:booking_system_flutter/model/post_job_detail_response.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
// removed old firebase chat import
import 'package:booking_system_flutter/screens/chat/api_chat_screen.dart';
import 'package:booking_system_flutter/model/chat_api_models.dart';
import 'package:booking_system_flutter/screens/jobRequest/components/payment_dialog.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class JobRequestDetailsScreen extends StatefulWidget {
  final num acceptedBidId;
  final VoidCallback? callback;

  const JobRequestDetailsScreen(
      {Key? key, required this.acceptedBidId, this.callback})
      : super(key: key);

  @override
  State<JobRequestDetailsScreen> createState() =>
      _JobRequestDetailsScreenState();
}

class _JobRequestDetailsScreenState extends State<JobRequestDetailsScreen> {
  Future<JobRequestDetailResponse?>? future;
  JobRequestDetailResponse? postJobDetail;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    future = getPostJobDetailByBid(widget.acceptedBidId);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBarTitle: 'Bid Details',
      child: SnapHelperWidget<JobRequestDetailResponse?>(
        future: future,
        onSuccess: (data) {
          postJobDetail = data;
          return _buildBody();
        },
        errorBuilder: (error) {
          return NoDataWidget(
            title: error,
            imageWidget: ErrorStateWidget(),
            retryText: language.reload,
            onRetry: () {
              appStore.setLoading(true);

              init();
              setState(() {});
            },
          );
        },
        loadingWidget: LoaderWidget(),
      ),
    );
  }

  String getStatusInfo(JobRequestDetailResponse job) {
    String message = '';
    switch (job.status) {
      case RequestStatus.requested:
        message = language.waitingForCustomerToAcceptTheBid;
        break;
      case RequestStatus.accepted:
        message = language.waitingForProviderToSplitPayment;
        break;
      case RequestStatus.pendingAdvance:
        message = language.waitingForCustomerToPayAdvancePercentage;
        break;
      case RequestStatus.advancePaid:
        message = language.waitingForProviderToStartWork;
        break;
      case RequestStatus.inProcess:
        message = language.waitingForCustomerToConfirm;
        break;
      case RequestStatus.inProgress:
        message = language.workInProgressWaitingForProvider;
        break;
      case RequestStatus.hold:
        message = language.waitingForProviderToResumeWork;
        break;
      case RequestStatus.done:
        message = language.waitingForCustomerToConfirmWorkDone;
        break;
      case RequestStatus.confirmDone:
        message = language.waitingForProviderToMarkBidAsCompleted;
        break;
      case RequestStatus.completed:
        message = language.jobCompletedWaitingForCustomer;
        break;
      case RequestStatus.remainingPaid:
        message = language.paymentCompletedDownloadInvoice;
        break;
      case RequestStatus.cancel:
        message = "This bid was cancelled";
        break;
    }

    return message;
  }

  num quantity = 1;
  num totalAmount = 0;
  num extraCharges = 0;
  num subTotal = 0;
  num tax = 0;
  num netAmount = 0;
  num advance = 0;
  num remaining = 0;
  Widget _buildBody() {
    if (postJobDetail == null) return SizedBox.shrink();

    quantity = getQuantityByPriceType(postJobDetail!.postRequest!);
    totalAmount = (postJobDetail!.price ?? 0) * quantity;
    extraCharges = postJobDetail!.extraCharges
        .fold(0, (sum, ec) => sum + ((ec.amount ?? 0) * (ec.quantity ?? 0)));
    subTotal = totalAmount + extraCharges;
    double taxPercent = 0.0;
    if ((postJobDetail!.taxPercent ?? '0%').split("%").length >= 2) {
      String taxPe =
          (postJobDetail!.taxPercent ?? '0%').split("%").first.validate();
      taxPercent = double.tryParse(taxPe) ?? 0;
    }
    print(taxPercent);
    print("taxPercent");
    tax = subTotal * (taxPercent / 100);
    netAmount = subTotal - tax;
    advance = (totalAmount * ((postJobDetail?.advancePercent ?? 0) / 100));
    remaining = subTotal - advance;

    return Column(
      children: [
        Expanded(
          child: AnimatedScrollView(
            padding: EdgeInsets.only(bottom: 60, top: 16, right: 16, left: 16),
            physics: AlwaysScrollableScrollPhysics(),
            listAnimationType: ListAnimationType.FadeIn,
            fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
            onSwipeRefresh: () async {
              init();
              setState(() {});

              return await 2.seconds.delay;
            },
            children: [
              // Status Info Card (hidden when awaiting bank transfer approval)
              if (getStatusInfo(postJobDetail!).isNotEmpty && !_isAwaitingBankTransferApproval())
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor:
                        context.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: context.primaryColor, size: 20),
                      8.width,
                      Expanded(
                        child: Text(
                          getStatusInfo(postJobDetail!),
                          style: secondaryTextStyle(
                              color: context.primaryColor, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              // Bank transfer pending approval banner
              if (_isAwaitingBankTransferApproval())
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: hold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_bottom, color: hold, size: 20),
                      8.width,
                      Expanded(
                        child: _MarqueeText(
                          text: language.waitingForPaymentApproval,
                          textStyle: secondaryTextStyle(color: hold, size: 14),
                          velocity: 40, // px per second
                          gap: 40,
                        ),
                      ),
                    ],
                  ),
                ).paddingTop(12),
              12.height,
              _buildProviderHeader(postJobDetail!).paddingBottom(16),
              _buildStatusProgress(postJobDetail!.status),
              if (postJobDetail!.holdReason.validate().isNotEmpty &&
                  postJobDetail?.status == RequestStatus.hold)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: hold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: hold, size: 20),
                      8.width,
                      Expanded(
                        child: Text(
                          "Hold Reason: ${postJobDetail?.holdReason ?? ""}",
                          style: secondaryTextStyle(color: hold, size: 14),
                        ),
                      ),
                    ],
                  ),
                ).paddingTop(12),
              24.height,

              // Job Details Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildInfoCard(
                    icon: Icons.h_mobiledata,
                    iconColor: context.primaryColor,
                    title: 'Title',
                    value: postJobDetail!.postRequest?.title?.validate() ?? '',
                  ),
                  _buildInfoCard(
                    icon: Icons.location_on,
                    iconColor: Colors.green,
                    title: 'Location',
                    value:
                        "${postJobDetail!.postRequest?.city?.name}${(postJobDetail!.postRequest?.country?.name ?? '').isEmpty ? '' : ', ${postJobDetail!.postRequest?.country?.name}'}",
                  ),
                  _buildInfoCard(
                    icon: Icons.business_center,
                    iconColor: Colors.orange,
                    title: 'Job Type',
                    value: postJobDetail!.postRequest?.type.displayName
                            .validate() ??
                        '',
                  ),
                  _buildInfoCard(
                    icon: Icons.attach_money,
                    iconColor: Colors.green[600]!,
                    title: 'Rate Type',
                    value: postJobDetail!.postRequest?.priceType.displayName
                            .validate() ??
                        '',
                  ),
                  _buildInfoCard(
                    icon: Icons.event_available,
                    iconColor: Colors.blue,
                    title: 'Start Date',
                    value: formatDate(
                        postJobDetail!.postRequest?.startDate
                            ?.toIso8601String()
                            .validate(),
                        showDateWithTime: true),
                    isDate: true,
                  ),
                  _buildInfoCard(
                    icon: Icons.event_busy,
                    iconColor: Colors.red,
                    title: 'End Date',
                    value: formatDate(
                        postJobDetail!.postRequest?.endDate
                            ?.toIso8601String()
                            .validate(),
                        showDateWithTime: true),
                    isDate: true,
                  ),
                  _buildInfoCard(
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.blue,
                    title: 'Total Budget',
                    value: postJobDetail!.postRequest?.totalBudget
                            ?.validate()
                            .toPriceFormat() ??
                        '0',
                  ),
                  _buildInfoCard(
                    icon: Icons.groups,
                    iconColor: Colors.grey,
                    title: 'Proposals',
                    value: (postJobDetail!.postRequest?.postBidList.length ?? 0)
                        .validate()
                        .toString(), // Simplified for now
                  ),
                  _buildInfoCard(
                    icon: Icons.person,
                    iconColor: Colors.indigo,
                    title: 'Provider',
                    value:
                        postJobDetail!.provider?.displayName.validate() ?? '',
                  ),
                  _buildInfoCard(
                    icon: Icons.person_outline,
                    iconColor: Colors.green,
                    title: 'Customer',
                    value:
                        postJobDetail!.customer?.displayName.validate() ?? '',
                  ),
                ],
              ),
              16.height,

              // Status Card - Full Width
              Container(
                padding: EdgeInsets.all(16),
                width: double.infinity,
                decoration: boxDecorationWithRoundedCorners(
                  backgroundColor: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag, color: context.primaryColor, size: 32),
                    8.height,
                    Text(
                      'Status',
                      style: secondaryTextStyle(size: 12),
                    ),
                    4.height,
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: postJobDetail!.status.bgColor
                            .withValues(alpha: 0.1),
                        borderRadius: radius(8),
                      ),
                      child: Text(
                        postJobDetail!.status.displayName,
                        style: boldTextStyle(
                          color: postJobDetail!.status.bgColor,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Price Breakdown Card
              _buildPriceBreakdown(postJobDetail!),

              // Extra Charges Breakdown
              _buildExtraChargesBreakdown(),
              24.height,
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Primary next-step actions by status
              if (postJobDetail!.status == RequestStatus.requested)
                AppButton(
                  text: 'Accept',
                  textStyle: boldTextStyle(color: white, size: 16),
                  color: primaryColor,
                  width: context.width(),
                  onTap: () async {
                    await confirmationRequestDialog(
                        context, RequestStatus.accepted);
                    if (postJobDetail?.status == RequestStatus.accepted) {
                      widget.callback?.call();
                    }
                  },
                ).paddingOnly(bottom: 24),
              if (postJobDetail!.status == RequestStatus.accepted)
                AppButton(
                  text: 'Cancel',
                  textStyle: boldTextStyle(color: white, size: 16),
                  color: cancelled,
                  width: context.width(),
                  onTap: () async {
                    confirmationRequestDialog(context, RequestStatus.cancel);
                  },
                ).paddingOnly(bottom: 24),
              if (postJobDetail!.status == RequestStatus.pendingAdvance && !_isAwaitingBankTransferApproval())
                AppButton(
                  text: 'Pay Advance (\$${advance})',
                  textStyle: boldTextStyle(color: white, size: 16),
                  color: defaultStatus,
                  width: context.width(),
                  onTap: () async {
                    bool? res = await showInDialog(
                      context,
                      contentPadding: EdgeInsets.zero,
                      hideSoftKeyboard: true,
                      backgroundColor: context.cardColor,
                      barrierDismissible: false,
                      builder: (_) => PaymentDialog(
                          amount: advance,
                          isAdvance: true,
                          bidId: postJobDetail!.id!),
                    );

                    if (res ?? false) {
                      init();
                      setState(() {});
                    }
                  },
                ).paddingOnly(bottom: 24),
              if (postJobDetail!.status == RequestStatus.inProcess && !_isAwaitingBankTransferApproval())
                Row(
                  children: [
                    Expanded(child: _chatActionButton()),
                    16.width,
                    Expanded(
                      child: AppButton(
                        text: "Let's Start Work",
                        textStyle: boldTextStyle(color: white, size: 16),
                        color: primaryColor,
                        width: context.width(),
                        onTap: () async {
                          confirmationRequestDialog(
                              context, RequestStatus.inProgress);
                        },
                      ),
                    ),
                  ],
                ).paddingOnly(bottom: 24),
              if (postJobDetail!.status == RequestStatus.done && !_isAwaitingBankTransferApproval())
                Row(
                  children: [
                    Expanded(child: _chatActionButton()),
                    16.width,
                    Expanded(
                      child: AppButton(
                        text: 'Confirm Done',
                        textStyle: boldTextStyle(color: white, size: 16),
                        color: primaryColor,
                        width: context.width(),
                        onTap: () async {
                          confirmationRequestDialog(
                              context, RequestStatus.confirmDone);
                        },
                      ),
                    ),
                  ],
                ).paddingOnly(bottom: 24),
              if (postJobDetail!.status == RequestStatus.completed && !_isAwaitingBankTransferApproval())
                Row(
                  children: [
                    Expanded(child: _chatActionButton()),
                    16.width,
                    Expanded(
                      child: AppButton(
                        text: 'Pay remaining (\$${remaining})',
                        textStyle: boldTextStyle(color: white, size: 16),
                        color: defaultStatus,
                        width: context.width(),
                        onTap: () async {
                          bool? res = await showInDialog(
                            context,
                            contentPadding: EdgeInsets.zero,
                            hideSoftKeyboard: true,
                            backgroundColor: context.cardColor,
                            barrierDismissible: false,
                            builder: (_) => PaymentDialog(
                                amount: remaining, bidId: postJobDetail!.id!),
                          );

                          if (res ?? false) {
                            init();
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ],
                ).paddingOnly(bottom: 24),

              // Conversation access: enabled from Advance Paid and later
              if (postJobDetail!.status == RequestStatus.remainingPaid)
                Row(
                  children: [
                    Expanded(child: _chatActionButton()),
                    16.width,
                    Expanded(
                      child: AppButton(
                        text: 'Download',
                        textStyle: boldTextStyle(color: white, size: 16),
                        color: completed,
                        width: context.width(),
                        onTap: () async {
                          if (postJobDetail!.id == null) {
                            toast(language.somethingWentWrong);
                            return;
                          }
                          appStore.setLoading(true);
                          downloadBidInvoice(postJobDetail!.id!).then((value) {
                            appStore.setLoading(false);
                            toast(value.message.validate());
                          }).catchError((e) {
                            appStore.setLoading(false);
                            toast(e.toString());
                          });
                        },
                      ),
                    ),
                  ],
                ).paddingOnly(bottom: 24),
              if (_canShowChat(postJobDetail!.status) &&
                  !_isAwaitingBankTransferApproval() &&
                  postJobDetail!.status != RequestStatus.remainingPaid &&
                  postJobDetail!.status != RequestStatus.inProcess &&
                  postJobDetail!.status != RequestStatus.done &&
                  postJobDetail!.status != RequestStatus.completed)
                _chatActionButton().paddingOnly(bottom: 24),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> confirmationRequestDialog(
      BuildContext context, RequestStatus status) async {
    await showConfirmDialogCustom(
      context,
      title: language.confirmationRequestTxt,
      primaryColor: status == BookingStatusKeys.rejected
          ? Colors.redAccent
          : primaryColor,
      positiveText: language.lblYes,
      negativeText: language.lblNo,
      onAccept: (context) async {
        appStore.setLoading(true);
        final request = {"status": status.backendValue};

        await bidUpdate(postJobDetail!.id.validate(), request)
            .then((res) async {
          init();
          setState(() {});
        }).catchError((e) {
          appStore.setLoading(false);
          toast(e.toString(), print: true);
        });
      },
    );
  }

  int getQuantityByPriceType(PostRequest post) {
    if (post.priceType == PriceType.fixed) {
      return 1;
    } else if (post.priceType == PriceType.hourly) {
      return post.totalHours ?? 1;
    } else {
      return post.totalDays ?? 1;
    }
  }

  Widget _buildPriceBreakdown(JobRequestDetailResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        24.height,
        Text('Price Details', style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        Container(
          padding: EdgeInsets.all(16),
          width: context.width(),
          decoration: boxDecorationDefault(color: context.cardColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Rate (Unit Price)', style: secondaryTextStyle(size: 14))
                      .expand(),
                  16.width,
                  PriceWidget(
                    price: data.price?.validate() ?? 0,
                    color: textPrimaryColorGlobal,
                    isBoldText: true,
                  ),
                ],
              ),
              16.height,

              // Quantity row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quantity', style: secondaryTextStyle(size: 14))
                      .flexible(fit: FlexFit.loose),
                  16.width,
                  Text(quantity.toString(), style: boldTextStyle(size: 16)),
                ],
              ),
              16.height,

              // Total calculation row
              Row(
                children: [
                  Text('Total Amount', style: secondaryTextStyle(size: 14))
                      .expand(),
                  16.width,
                  PriceWidget(
                    price: totalAmount,
                    color: textPrimaryColorGlobal,
                  ),
                ],
              ),
              16.height,

              Row(
                children: [
                  Text('Extra Charges', style: secondaryTextStyle(size: 14))
                      .expand(),
                  16.width,
                  PriceWidget(
                    price: extraCharges,
                    color: textPrimaryColorGlobal,
                  ),
                ],
              ),
              16.height,

              // Subtotal row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal', style: boldTextStyle(size: 14))
                      .flexible(fit: FlexFit.loose),
                  PriceWidget(
                    price: subTotal,
                    color: textPrimaryColorGlobal,
                    isBoldText: true,
                  ),
                ],
              ),
              16.height,

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Net Amount', style: boldTextStyle(size: 14)),
                      Text('(Subtotal - Tax)',
                          style: secondaryTextStyle(size: 12)),
                    ],
                  ).flexible(fit: FlexFit.loose),
                  PriceWidget(
                    price: netAmount,
                    color: textPrimaryColorGlobal,
                    isBoldText: true,
                  ),
                ],
              ),
              16.height,

              // Tax row (if applicable)
              if (data.price != null && data.price! > 0)
                Column(
                  children: [
                    Row(
                      children: [
                        Row(
                          children: [
                            Text('Tax', style: secondaryTextStyle(size: 14)),
                            Text('(${postJobDetail?.taxPercent ?? '0%'})',
                                    style: boldTextStyle(
                                        color: primaryColor, size: 14))
                                .expand()
                          ],
                        ).expand(),
                        16.width,
                        PriceWidget(
                          price: tax,
                          color: Colors.red,
                          isBoldText: true,
                        ),
                      ],
                    ),
                    16.height,
                  ],
                ),

              // Total Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Grand Total Amount', style: boldTextStyle(size: 14)),
                  16.width,
                  PriceWidget(
                    price: subTotal,
                    color: primaryColor,
                  ).flexible(flex: 3),
                ],
              ),
              16.height,

              // Advance Amount
              Column(
                children: [
                  Row(
                    children: [
                      Text('Advance Payment(${postJobDetail?.advancePercent ?? 0}%)',
                              style: secondaryTextStyle(size: 14))
                          .expand(),
                      16.width,
                      PriceWidget(
                        price: advance,
                        color: textPrimaryColorGlobal,
                      ),
                    ],
                  ),
                  16.height,
                ],
              ),
              Row(
                children: [
                  Text('Remaining Amount', style: boldTextStyle(size: 14))
                      .expand(),
                  16.width,
                  PriceWidget(
                    price: remaining,
                    color: textPrimaryColorGlobal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtraChargesBreakdown() {
    if (postJobDetail!.extraCharges.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        24.height,
        Text('Extra Charges Breakdown',
            style: boldTextStyle(size: LABEL_TEXT_SIZE)),
        16.height,
        Container(
          padding: EdgeInsets.all(16),
          width: context.width(),
          decoration: boxDecorationDefault(color: context.cardColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...postJobDetail!.extraCharges
                  .map((charge) => _extraChargesDetails(charge))
                  .toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _extraChargesDetails(ExtraChargesData charge) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(charge.title ?? '', style: secondaryTextStyle(size: 14))
              .expand(),
          Text('${charge.amount} × ', style: secondaryTextStyle(size: 14)),
          Text('${charge.quantity}', style: secondaryTextStyle(size: 14)),
          Text(' = ', style: secondaryTextStyle(size: 14)),
          PriceWidget(
            price: (charge.amount ?? 0) * (charge.quantity ?? 0),
            color: textPrimaryColorGlobal,
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool isDate = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 32),
          8.height,
          Text(
            title,
            style: secondaryTextStyle(size: 12),
            textAlign: TextAlign.center,
          ),
          4.height,
          Text(
            value,
            style: boldTextStyle(
              size: isDate ? 10 : 14,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _chatActionButton() {
    return AppButton(
      text: 'Chat',
      textStyle: boldTextStyle(color: white, size: 16),
      color: context.primaryColor,
      width: context.width(),
      onTap: () async {
        final providerId = postJobDetail?.provider?.id;
        if (providerId == null) {
          toast(language.somethingWentWrong);
          return;
        }
        if (appStore.userId == providerId.toInt()) {
          toast(language.lblNotValidUser);
          return;
        }
        String? avatarUrl;
        try {
          final displayName = postJobDetail?.provider?.displayName.validate() ?? '';
          if (displayName.isNotEmpty) {
            final matches = await chatSearchUsers(query: displayName, page: 1);
            if (matches.isNotEmpty) {
              ChatUserItem? exact;
              for (final u in matches) {
                if (u.id == providerId.toInt()) {
                  exact = u; break;
                }
              }
              avatarUrl = (exact ?? matches.first).avatarUrl;
            }
          }
        } catch (e) {
          // ignore avatar preload errors
        }
        toast(language.pleaseWaitWhileWeLoadChatDetails + providerId.toString());
        try {
          final open = await chatOpenWithUser(userId: providerId.toInt());
          Fluttertoast.cancel();
          ApiChatScreen(
            conversationId: open.conversationId,
            otherUserId: providerId.toInt(),
            otherUserName: postJobDetail?.provider?.displayName.validate() ?? '',
            otherUserAvatarUrl: avatarUrl,
          ).launch(context);
        } catch (e) {
          Fluttertoast.cancel();
          try {
            final displayName = postJobDetail?.provider?.displayName.validate() ?? '';
            if (displayName.isNotEmpty) {
              final matches = await chatSearchUsers(query: displayName, page: 1);
              if (matches.isNotEmpty) {
                final match = matches.first;
                final open2 = await chatOpenWithUser(userId: match.id);
                ApiChatScreen(
                  conversationId: open2.conversationId,
                  otherUserId: match.id,
                  otherUserName: match.displayName,
                  otherUserAvatarUrl: match.avatarUrl,
                ).launch(context);
                return;
              }
            }
            await Future.delayed(Duration(milliseconds: 500));
            toast(e.toString());
          } catch (e2) {
            await Future.delayed(Duration(milliseconds: 500));
            toast(e2.toString());
          }
        }
      },
    );
  }

  Widget _buildProviderHeader(JobRequestDetailResponse data) {
    final user = data.provider;
    return Container(
      padding: EdgeInsets.all(12),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.cardColor,
        borderRadius: radius(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: context.primaryColor.withValues(alpha: 0.1),
            child: Text(
              (user?.displayName.validate() ?? '-')
                  .trim()
                  .split(' ')
                  .where((p) => p.isNotEmpty)
                  .map((e) => e[0])
                  .take(2)
                  .join()
                  .toUpperCase(),
              style: boldTextStyle(color: context.primaryColor),
            ),
          ),
          12.width,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.displayName.validate() ?? '-', style: boldTextStyle()),
              4.height,
              Wrap(
                spacing: 8,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Bid:', style: secondaryTextStyle(size: 12)),
                  PriceWidget(
                    price: data.price.validate(),
                    color: textPrimaryColorGlobal,
                    size: 14,
                    isBoldText: true,
                  ),
                  if ((data.advancePercent ?? 0) > 0)
                    Text('• Advance ${data.advancePercent?.toString() ?? "0"}%',
                        style: secondaryTextStyle(size: 12)),
                ],
              ),
            ],
          ).expand(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: data.status.bgColor.withValues(alpha: 0.1),
                borderRadius: radius(20),
              ),
              child: Text(data.status.displayName,
                  style: boldTextStyle(color: data.status.bgColor, size: 12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusProgress(RequestStatus status) {
    final steps = <RequestStatus>[
      RequestStatus.accepted,
      RequestStatus.pendingAdvance,
      RequestStatus.advancePaid,
      RequestStatus.inProcess,
      RequestStatus.inProgress,
      RequestStatus.done,
      RequestStatus.completed,
      RequestStatus.remainingPaid,
    ];
    final activeIndex = steps.indexOf(status);

    return SizedBox(
      height: 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: steps.length,
        separatorBuilder: (_, __) => 12.width,
        itemBuilder: (context, i) {
          final bool isActive = i <= activeIndex && activeIndex >= 0;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive ? context.primaryColor : context.dividerColor,
                  borderRadius: radius(6),
                ),
              ),
              6.height,
              SizedBox(
                width: 64,
                child: Text(
                  _labelForStatus(steps[i]),
                  style: secondaryTextStyle(size: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    ).paddingBottom(16);
  }

  String _labelForStatus(RequestStatus s) {
    switch (s) {
      case RequestStatus.accepted:
        return 'Accept';
      case RequestStatus.pendingAdvance:
        return 'Advance';
      case RequestStatus.advancePaid:
        return 'Advance Paid';
      case RequestStatus.inProcess:
        return "Let's Start";
      case RequestStatus.inProgress:
        return 'Work';
      case RequestStatus.done:
        return 'Done';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.remainingPaid:
        return 'Paid';
      default:
        return '';
    }
  }

  bool _canShowChat(RequestStatus status) {
    return status == RequestStatus.advancePaid ||
        status == RequestStatus.inProcess ||
        status == RequestStatus.inProgress ||
        status == RequestStatus.hold ||
        status == RequestStatus.done ||
        status == RequestStatus.confirmDone ||
        status == RequestStatus.completed ||
        status == RequestStatus.remainingPaid;
  }

  bool _isAwaitingBankTransferApproval() {
    final bt = postJobDetail?.bankTransfer;
    if (bt == null) return false;
    if ((bt.isBankTransfer ?? 0) != 1) return false;
    // statusCode: 0 = pending approval
    return (bt.statusCode ?? -1) == 0;
  }
}

class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final double velocity; // pixels per second
  final double gap; // gap between duplicated texts

  const _MarqueeText({
    required this.text,
    this.textStyle,
    this.velocity = 40,
    this.gap = 30,
  });

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _position = 0;
  double _textWidth = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _position -= widget.velocity / 60; // approx 60fps
          if (_textWidth > 0 && -_position > _textWidth + widget.gap) {
            _position += _textWidth + widget.gap;
          }
        });
      });
    _controller.repeat(period: const Duration(milliseconds: 16));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Transform.translate(
                offset: Offset(_position, 0),
                child: _measure(
                  onWidth: (w) => _textWidth = w,
                  child: Row(
                    children: [
                      Text(widget.text, style: widget.textStyle),
                      SizedBox(width: widget.gap),
                      Text(widget.text, style: widget.textStyle),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _measure({required Widget child, required void Function(double) onWidth}) {
    return OverflowBox(
      maxWidth: double.infinity,
      child: _SizeReporter(onWidth: onWidth, child: child),
    );
  }
}

class _SizeReporter extends StatefulWidget {
  final Widget child;
  final void Function(double) onWidth;
  const _SizeReporter({required this.child, required this.onWidth});

  @override
  State<_SizeReporter> createState() => _SizeReporterState();
}

class _SizeReporterState extends State<_SizeReporter> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _key.currentContext;
      if (ctx != null) {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null) widget.onWidth(box.size.width);
      }
    });
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
