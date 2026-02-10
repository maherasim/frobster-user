import 'package:booking_system_flutter/component/base_scaffold_widget.dart';
import 'package:booking_system_flutter/component/empty_error_state_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/component/price_widget.dart';
import 'package:booking_system_flutter/component/gradient_button.dart';
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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:booking_system_flutter/utils/extensions/num_extenstions.dart';
import 'package:booking_system_flutter/utils/model_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
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
    setState(() {
      future = getPostJobDetailByBid(widget.acceptedBidId);
      postJobDetail = null; // Reset data when refreshing
    });
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
          if (data != null) {
            postJobDetail = data;
          }
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

  // Helper method to get icon color for job type
  Color _getJobTypeIconColor(JobType? type) {
    if (type == null) return Colors.orange;
    switch (type) {
      case JobType.onSite:
        return Colors.blue.shade700; // Blue for On Site
      case JobType.remote:
        return Colors.green.shade700; // Green for Remote
      case JobType.hybrid:
        return Colors.orange.shade700; // Orange for Hybrid
    }
  }

  // Helper method to get background color for job type
  Color _getJobTypeBgColor(JobType? type) {
    if (type == null) return gradientRed.withValues(alpha: 0.08);
    switch (type) {
      case JobType.onSite:
        return Colors.blue.withValues(alpha: 0.12); // Blue for On Site
      case JobType.remote:
        return Colors.green.withValues(alpha: 0.12); // Green for Remote
      case JobType.hybrid:
        return Colors.orange.withValues(alpha: 0.12); // Orange for Hybrid
    }
  }

  // Helper method to get text color for job type
  Color _getJobTypeColor(JobType? type) {
    if (type == null) return gradientRed;
    switch (type) {
      case JobType.onSite:
        return Colors.blue.shade700; // Blue for On Site
      case JobType.remote:
        return Colors.green.shade700; // Green for Remote
      case JobType.hybrid:
        return Colors.orange.shade700; // Orange for Hybrid
    }
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
      case RequestStatus.advancePaymentPending:
        message = 'Waiting for admin approval';
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
      case RequestStatus.remainingPaymentPending:
        message = 'Waiting for customer to pay remaining amount';
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

    // Always render the body if we have postJobDetail data
    // We'll handle missing postRequest gracefully in the UI by showing "N/A" values
    // Only show error if we truly have no useful data (very rare case)
    // This ensures the page always renders when we have bid information

    // For cancelled bids without postRequest, use default values
    quantity = postJobDetail!.postRequest != null 
        ? getQuantityByPriceType(postJobDetail!.postRequest!)
        : 1;
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
            onSwipeRefresh: () async {
              init();
              setState(() {});

              return await 2.seconds.delay;
            },
            children: [
              // Status Info Card (shown for all statuses including cancelled, hidden when awaiting bank transfer approval)
              if (getStatusInfo(postJobDetail!).isNotEmpty && !_isAwaitingBankTransferApproval())
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        gradientRed.withValues(alpha: 0.12),
                        gradientBlue.withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Gradient accent icon
                      Container(
                        decoration: const BoxDecoration(
                          gradient: appPrimaryGradient,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
                      ),
                      8.width,
                      Expanded(
                        child: Text(
                          getStatusInfo(postJobDetail!),
                          style: secondaryTextStyle(
                              color: Theme.of(context).colorScheme.onSurface, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              // Show "waiting for admin approval" message when status is advancePaymentPending (advance_payment_pending)
              if (postJobDetail!.status == RequestStatus.advancePaymentPending)
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
                          text: 'Waiting for admin approval',
                          textStyle: secondaryTextStyle(color: hold, size: 14),
                          velocity: 40, // px per second
                          gap: 40,
                        ),
                      ),
                    ],
                  ),
                ).paddingTop(12),
              // Bank transfer pending approval banner (for pendingAdvance with bank transfer)
              if (_isAwaitingBankTransferApproval() && 
                  (postJobDetail!.status == RequestStatus.pendingAdvance))
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

              // Job Details Grid - Reduced to essential cards only
              // Always show grid when postRequest is available OR when status is inProcess, pendingAdvance, or advancePaymentPending
              if (postJobDetail!.postRequest != null || 
                  postJobDetail!.status == RequestStatus.inProcess ||
                  postJobDetail!.status == RequestStatus.pendingAdvance ||
                  postJobDetail!.status == RequestStatus.advancePaymentPending)
                Padding(
                  padding: EdgeInsets.zero,
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    children: [
                      _buildInfoCard(
                        icon: Icons.h_mobiledata,
                        iconColor: gradientRed,
                        title: 'Title',
                        value: postJobDetail!.postRequest?.title?.validate() ?? 'N/A',
                      ),
                      _buildInfoCard(
                        icon: Icons.location_on,
                        iconColor: Colors.green,
                        title: 'Location',
                        value: postJobDetail!.postRequest != null
                            ? "${postJobDetail!.postRequest?.city?.name}${(postJobDetail!.postRequest?.country?.name ?? '').isEmpty ? '' : ', ${postJobDetail!.postRequest?.country?.name}'}"
                            : 'N/A',
                      ),
                      _buildInfoCard(
                        icon: Icons.business_center,
                        iconColor: _getJobTypeIconColor(postJobDetail!.postRequest?.type),
                        title: 'Job Type nice',
                        value: (postJobDetail!.postRequest?.type != null)
                            ? postJobDetail!.postRequest!.type.displayName.validate()
                            : 'N/A',
                        customValueWidget: (postJobDetail!.postRequest?.type != null)
                            ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getJobTypeBgColor(postJobDetail!.postRequest?.type),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  postJobDetail!.postRequest!.type.displayName.validate(),
                                  style: boldTextStyle(
                                    size: 11,
                                    color: _getJobTypeColor(postJobDetail!.postRequest?.type),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : null,
                      ),
                      _buildInfoCard(
                        icon: Icons.event_available,
                        iconColor: Colors.blue,
                        title: 'Start Date',
                        value: postJobDetail!.postRequest?.startDate != null
                            ? formatDate(
                                postJobDetail!.postRequest?.startDate
                                    ?.toIso8601String()
                                    .validate(),
                                showDateWithTime: true)
                            : 'N/A',
                        isDate: true,
                      ),
                      _buildInfoCard(
                        icon: Icons.event_busy,
                        iconColor: Colors.red,
                        title: 'End Date',
                        value: postJobDetail!.postRequest?.endDate != null
                            ? formatDate(
                                postJobDetail!.postRequest?.endDate
                                    ?.toIso8601String()
                                    .validate(),
                                showDateWithTime: true)
                            : 'N/A',
                        isDate: true,
                      ),
                      _buildInfoCard(
                        icon: Icons.person,
                        iconColor: Colors.indigo,
                        title: 'Employer',
                        value:
                            postJobDetail!.provider?.displayName.validate() ?? 'N/A',
                      ),
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        iconColor: Colors.green,
                        title: 'Customer',
                        value:
                            postJobDetail!.customer?.displayName.validate() ?? 'N/A',
                      ),
                    ],
                  ),
                )
              else if (postJobDetail!.status == RequestStatus.cancel)
                Container(
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: boxDecorationWithRoundedCorners(
                    backgroundColor: context.cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      16.height,
                      Text(
                        'This bid was cancelled. Job details are no longer available.',
                        style: secondaryTextStyle(),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
                    // Gradient status icon
                    Container(
                      decoration: const BoxDecoration(
                        gradient: appPrimaryGradient,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.flag, color: Colors.white, size: 20),
                    ),
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

              // Description Section - Simple and Clear (like service detail screen)
              // Only show description if postRequest is available
              if (postJobDetail!.postRequest != null && 
                  (postJobDetail!.postRequest?.description.validate().isNotEmpty ?? false)) ...[
                24.height,
                Text('Description',
                    style: boldTextStyle(size: LABEL_TEXT_SIZE)),
                16.height,
                HtmlWidget(
                  postJobDetail!.postRequest?.description.validate() ?? 'No description available',
                  textStyle: secondaryTextStyle(),
                ),
              ],

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
                GradientButton(
                  onPressed: () async {
                    await confirmationRequestDialog(
                        context, RequestStatus.accepted);
                    if (postJobDetail?.status == RequestStatus.accepted) {
                      widget.callback?.call();
                    }
                  },
                  child: Text('Accept', style: boldTextStyle(color: white, size: 16)),
                ).withWidth(context.width()).paddingOnly(bottom: 24),
              if (postJobDetail!.status == RequestStatus.accepted)
                GradientButton(
                  onPressed: () async {
                    confirmationRequestDialog(context, RequestStatus.cancel);
                  },
                  child: Text('Cancel', style: boldTextStyle(color: white, size: 16)),
                ).withWidth(context.width()).paddingOnly(bottom: 24),
              // Show Pay Advance button when status is pendingAdvance ("Advance Payment Pending" with spaces)
              // Do NOT show for advancePaymentPending ("advance_payment_pending" - waiting for admin approval)
              if (postJobDetail!.status == RequestStatus.pendingAdvance)
                GradientButton(
                  onPressed: () async {
                    // Don't allow payment if bank transfer is awaiting approval
                    if (_isAwaitingBankTransferApproval()) {
                      toast('Waiting for admin approval. Please wait.');
                      return;
                    }
                    final bidId = postJobDetail?.id;
                    if (bidId == null) {
                      toast(language.somethingWentWrong);
                      return;
                    }
                    bool? res = await showInDialog(
                      context,
                      contentPadding: EdgeInsets.zero,
                      hideSoftKeyboard: true,
                      backgroundColor: context.cardColor,
                      barrierDismissible: false,
                      builder: (_) => PaymentDialog(
                          amount: advance,
                          isAdvance: true,
                          bidId: bidId is int ? bidId : (bidId as num).toInt()),
                    );

                    if (res ?? false) {
                      init();
                      setState(() {});
                    }
                  },
                  child: Text('Pay Advance (\$${advance})', style: boldTextStyle(color: white, size: 16)),
                ).withWidth(context.width()).paddingOnly(bottom: 24),
              // Show "Let's Start Work" button when status is inProcess
              // Only hide if bank transfer is awaiting approval (for advance payment, not for inProcess)
              if (postJobDetail!.status == RequestStatus.inProcess)
                Row(
                  children: [
                    Expanded(child: _chatActionButton()),
                    16.width,
                    Expanded(
                      child: GradientButton(
                        onPressed: () async {
                          confirmationRequestDialog(context, RequestStatus.inProgress);
                        },
                        child: Text("Let's Start Work", style: boldTextStyle(color: white, size: 16)),
                      ).withWidth(context.width()),
                    ),
                  ],
                ).paddingOnly(bottom: 24),
              // Always show chat button for done status
              if (postJobDetail!.status == RequestStatus.done)
                Row(
                  children: [
                    Expanded(child: _chatActionButton()),
                    16.width,
                    Expanded(
                      child: GradientButton(
                        onPressed: () async {
                          confirmationRequestDialog(context, RequestStatus.confirmDone);
                        },
                        child: Text('Confirm Done', style: boldTextStyle(color: white, size: 16)),
                      ).withWidth(context.width()),
                    ),
                  ],
                ).paddingOnly(bottom: 24),
              // Always show chat button for completed status
              if (postJobDetail!.status == RequestStatus.completed)
                Row(
                  children: [
                    Expanded(child: _chatActionButton()),
                    16.width,
                    Expanded(
                      child: GradientButton(
                        onPressed: () async {
                          final bidId = postJobDetail?.id;
                          if (bidId == null) {
                            toast(language.somethingWentWrong);
                            return;
                          }
                          bool? res = await showInDialog(
                            context,
                            contentPadding: EdgeInsets.zero,
                            hideSoftKeyboard: true,
                            backgroundColor: context.cardColor,
                            barrierDismissible: false,
                            builder: (_) => PaymentDialog(
                                amount: remaining,
                                bidId: bidId is int ? bidId : (bidId as num).toInt()),
                          );

                          if (res ?? false) {
                            init();
                            setState(() {});
                          }
                        },
                        child: Text('Pay remaining (\$${remaining})', style: boldTextStyle(color: white, size: 16)),
                      ).withWidth(context.width()),
                    ),
                  ],
                ).paddingOnly(bottom: 24),
              // Always show chat button for remainingPaymentPending status (no payment button needed)
              if (postJobDetail!.status == RequestStatus.remainingPaymentPending)
                _chatActionButton().paddingOnly(bottom: 24),

              // Conversation access: enabled from Advance Paid and later
              if (postJobDetail!.status == RequestStatus.remainingPaid)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _chatActionButton()),
                        16.width,
                        Expanded(
                          child: GradientButton(
                            onPressed: () async {
                              final bidId = postJobDetail?.id;
                              if (bidId == null) {
                                toast(language.somethingWentWrong);
                                return;
                              }
                              appStore.setLoading(true);
                              final id = bidId is int ? bidId : (bidId as num).toInt();
                              downloadBidInvoice(id).then((value) {
                                appStore.setLoading(false);
                                toast(value.message.validate());
                              }).catchError((e) {
                                appStore.setLoading(false);
                                toast(e.toString());
                              });
                            },
                            child: Text('Download', style: boldTextStyle(color: white, size: 16)),
                          ).withWidth(context.width()),
                        ),
                      ],
                    ),
                    // Only show "Rate Employer" button if rating doesn't exist yet
                    if (postJobDetail!.providerRatingExists != true) ...[
                      16.height,
                      GradientButton(
                        onPressed: () {
                          _showEmployerRatingDialog();
                        },
                        child: Text('Rate Employer', style: boldTextStyle(color: white, size: 16)),
                      ).withWidth(context.width()),
                    ],
                  ],
                ).paddingOnly(bottom: 24),
              // Always show chat button for: hold, inProgress
              // Note: inProcess, done, completed, remainingPaymentPending, and remainingPaid already have chat button in their Row widgets above
              if (postJobDetail!.status == RequestStatus.hold ||
                  postJobDetail!.status == RequestStatus.inProgress)
                _chatActionButton().paddingOnly(bottom: 24),
              // Show chat for other statuses (like advancePaid) if not awaiting bank transfer approval
              // Only show if not already shown above
              if (!(postJobDetail!.status == RequestStatus.hold ||
                  postJobDetail!.status == RequestStatus.inProgress ||
                  postJobDetail!.status == RequestStatus.inProcess ||
                  postJobDetail!.status == RequestStatus.done ||
                  postJobDetail!.status == RequestStatus.completed ||
                  postJobDetail!.status == RequestStatus.remainingPaymentPending ||
                  postJobDetail!.status == RequestStatus.remainingPaid) &&
                  _canShowChat(postJobDetail!.status) &&
                  !_isAwaitingBankTransferApproval())
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
          : gradientRed,
      positiveText: language.lblYes,
      negativeText: language.lblNo,
      onAccept: (context) async {
        final bidId = postJobDetail?.id;
        if (bidId == null) {
          appStore.setLoading(false);
          toast(language.somethingWentWrong);
          return;
        }
        appStore.setLoading(true);
        final request = {"status": status.backendValue};
        final id = bidId is int ? bidId : (bidId as num).toInt();

        await bidUpdate(id, request)
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
                                        color: gradientRed, size: 14))
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
                    color: gradientRed,
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
    Widget? customValueWidget,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: boxDecorationWithRoundedCorners(
        backgroundColor: context.cardColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          4.height,
          Text(
            title,
            style: secondaryTextStyle(
              size: 9,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          2.height,
          Flexible(
            child: customValueWidget ?? Text(
              value,
              style: boldTextStyle(
                size: isDate ? 9 : 11,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatActionButton() {
    return GradientButton(
      onPressed: () async {
        final providerId = postJobDetail?.provider?.id;
        if (providerId == null) {
          toast(language.somethingWentWrong);
          return;
        }
        if (appStore.userId == providerId) {
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
                if (u.id == providerId) {
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
          final open = await chatOpenWithUser(userId: providerId!);
          Fluttertoast.cancel();
          ApiChatScreen(
            conversationId: open.conversationId,
            otherUserId: providerId!,
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
      child: Text('Chat', style: boldTextStyle(color: white, size: 16)),
    ).withWidth(context.width());
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
            backgroundColor: gradientRed.withValues(alpha: 0.1),
            child: Text(
              (user?.displayName.validate() ?? '-')
                  .trim()
                  .split(' ')
                  .where((p) => p.isNotEmpty)
                  .map((e) => e[0])
                  .take(2)
                  .join()
                  .toUpperCase(),
              style: boldTextStyle(color: gradientRed),
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
      RequestStatus.advancePaymentPending,
      RequestStatus.advancePaid,
      RequestStatus.inProcess,
      RequestStatus.inProgress,
      RequestStatus.done,
      RequestStatus.completed,
      RequestStatus.remainingPaymentPending,
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
                  gradient: isActive ? appPrimaryGradient : null,
                  color: isActive ? null : context.dividerColor,
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
      case RequestStatus.advancePaymentPending:
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
      case RequestStatus.remainingPaymentPending:
        return 'Remaining';
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
        status == RequestStatus.remainingPaymentPending ||
        status == RequestStatus.remainingPaid;
  }

  bool _isAwaitingBankTransferApproval() {
    final bt = postJobDetail?.bankTransfer;
    if (bt == null) return false;
    if ((bt.isBankTransfer ?? 0) != 1) return false;
    // statusCode: 0 = pending approval
    return (bt.statusCode ?? -1) == 0;
  }

  void _showEmployerRatingDialog() {
    double selectedRating = 0;
    TextEditingController reviewCont = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: context.width(),
                        padding: EdgeInsets.only(left: 16, top: 4, bottom: 4),
                        decoration: BoxDecoration(
                          gradient: appPrimaryGradient,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            topLeft: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text('Rate Employer',
                                    style: boldTextStyle(color: Colors.white))
                                .expand(),
                            IconButton(
                              icon: Icon(Icons.clear, color: Colors.white, size: 16),
                              onPressed: () {
                                finish(context);
                              },
                            )
                          ],
                        ),
                      ),
                      Container(
                        color: context.scaffoldBackgroundColor,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Your Rating', style: boldTextStyle()),
                                Text("*", style: secondaryTextStyle(color: Colors.red)),
                              ],
                            ),
                            16.height,
                            Container(
                              padding: EdgeInsets.all(16),
                              width: context.width(),
                              decoration: boxDecorationDefault(
                                  color: appStore.isDarkMode
                                      ? context.dividerColor
                                      : context.cardColor),
                              child: RatingBarWidget(
                                onRatingChanged: (rating) {
                                  selectedRating = rating;
                                  setDialogState(() {});
                                },
                                activeColor: getRatingBarColor(selectedRating.toInt()),
                                inActiveColor: ratingBarColor,
                                rating: selectedRating,
                                size: 18,
                              ),
                            ),
                            16.height,
                            Text('Your Comment', style: boldTextStyle()),
                            16.height,
                            AppTextField(
                              controller: reviewCont,
                              textFieldType: TextFieldType.OTHER,
                              minLines: 5,
                              maxLines: 10,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: inputDecoration(
                                context,
                                labelText: 'Write your review here...',
                              ).copyWith(
                                  fillColor: appStore.isDarkMode
                                      ? context.dividerColor
                                      : context.cardColor,
                                  filled: true),
                            ),
                            32.height,
                            GradientButton(
                              onPressed: () async {
                                if (selectedRating == 0) {
                                  toast('Please select a rating');
                                  return;
                                }

                                if (postJobDetail == null) {
                                  toast(language.somethingWentWrong);
                                  return;
                                }

                                final bidId = postJobDetail!.id?.validate();
                                final providerId = postJobDetail!.provider?.id?.validate();
                                final customerId = appStore.userId;

                                if (bidId == null || providerId == null || customerId == null) {
                                  toast(language.somethingWentWrong);
                                  return;
                                }

                                hideKeyboard(context);
                                appStore.setLoading(true);
                                try {
                                  final request = {
                                    "post_job_bid_id": (bidId is int ? bidId : (bidId as num).toInt()),
                                    "provider_id": (providerId is int ? providerId : (providerId as num).toInt()),
                                    "customer_id": customerId,
                                    "rating": selectedRating.toInt(),
                                    "review": reviewCont.text.validate(),
                                  };

                                  await saveBidRating(request).then((value) {
                                    appStore.setLoading(false);
                                    final message = value.message.validate();
                                    if (message.isNotEmpty) {
                                      toast(message);
                                    } else {
                                      toast('Rating submitted successfully');
                                    }
                                    Future.delayed(Duration(milliseconds: 500), () {
                                      finish(context, true);
                                      init();
                                      setState(() {});
                                    });
                                  }).catchError((e) {
                                    appStore.setLoading(false);
                                    toast(e.toString());
                                  });
                                } catch (e) {
                                  appStore.setLoading(false);
                                  toast(e.toString());
                                }
                              },
                              child: Text(
                                'Submit',
                                style: boldTextStyle(color: Colors.white),
                              ),
                            ).withWidth(context.width()),
                          ],
                        ).paddingAll(16),
                      ),
                    ],
                  ),
                ),
                Observer(
                    builder: (context) => LoaderWidget()
                        .visible(appStore.isLoading)
                        .withSize(height: 80, width: 80))
              ],
            ),
          ),
        ),
      ),
    ).then((value) {
      if (value == true) {
        // Rating was submitted successfully
      }
    });
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
        if (mounted) {
          setState(() {
            _position -= widget.velocity / 60; // approx 60fps
            if (_textWidth > 0 && -_position > _textWidth + widget.gap) {
              _position += _textWidth + widget.gap;
            }
          });
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.repeat(period: const Duration(milliseconds: 16));
      }
    });
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
          if (constraints.maxWidth.isInfinite || constraints.maxWidth == 0) {
            // If constraints are unbounded, use a simple Text widget
            return Text(widget.text, style: widget.textStyle);
          }
          
          // If height is unbounded, use a simple Text widget to avoid Stack issues
          if (constraints.maxHeight.isInfinite) {
            return Text(
              widget.text,
              style: widget.textStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
          }
          
          // Ensure we have finite height for Stack
          final height = constraints.maxHeight.isFinite && constraints.maxHeight > 0 
              ? constraints.maxHeight 
              : null;
          
          if (height == null) {
            // If we still don't have a valid height, use simple Text
            return Text(
              widget.text,
              style: widget.textStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            );
          }
          
          return SizedBox(
            width: constraints.maxWidth,
            height: height,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Transform.translate(
                  offset: Offset(_position, 0),
                  child: _measure(
                    onWidth: (w) => _textWidth = w,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.text, style: widget.textStyle),
                        SizedBox(width: widget.gap),
                        Text(widget.text, style: widget.textStyle),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _measure({required Widget child, required void Function(double) onWidth}) {
    return OverflowBox(
      alignment: Alignment.centerLeft,
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
