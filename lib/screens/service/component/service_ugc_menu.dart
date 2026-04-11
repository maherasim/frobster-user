import 'dart:math' as math;

import 'package:booking_system_flutter/component/gradient_button.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Overflow menu: report service (POST api/ugc/report) and block provider (POST api/ugc/block).
class ServiceUgcMenuButton extends StatelessWidget {
  final ServiceData serviceData;
  final bool isFavouriteService;
  final bool showMenu;

  const ServiceUgcMenuButton({
    super.key,
    required this.serviceData,
    required this.isFavouriteService,
    required this.showMenu,
  });

  int get _serviceId => isFavouriteService
      ? serviceData.serviceId.validate().toInt()
      : serviceData.id.validate().toInt();

  int? get _blockedUserId {
    final u = serviceData.userId?.toInt();
    if (u != null && u > 0) return u;
    final p = serviceData.providerId;
    if (p != null && p > 0) return p;
    return null;
  }

  Future<void> _openReport(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ReportServiceDialog(serviceId: _serviceId),
    );
  }

  Future<void> _openBlock(BuildContext context) async {
    final blockedId = _blockedUserId;
    if (blockedId == null) {
      toast(language.somethingWentWrong);
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(language.ugcBlockConfirmTitle),
        content: Text(language.ugcBlockConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(language.lblNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(language.lblYes),
          ),
        ],
      ),
    );
    if (go != true) return;
    appStore.setLoading(true);
    try {
      final res = await ugcBlockUser(blockedUserId: blockedId);
      await appStore.addBlockedUserId(blockedId);
      appStore.setLoading(false);
      LiveStream().emit(LIVESTREAM_UPDATE_DASHBOARD);
      toast(
        parseHtmlString(
          res['message']?.toString() ?? language.success,
        ),
      );
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!showMenu) return const SizedBox.shrink();

    return Material(
      elevation: 4,
      shadowColor: Colors.black,
      color: Colors.black.withValues(alpha: 0.65),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<String>(
        padding: const EdgeInsets.all(4),
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
        offset: const Offset(0, 40),
        onSelected: (value) async {
          if (value == 'report') {
            await _openReport(context);
          } else if (value == 'block') {
            await _openBlock(context);
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'report',
            child: Text(language.ugcReportService),
          ),
          PopupMenuItem(
            value: 'block',
            child: Text(language.ugcBlockProvider),
          ),
        ],
      ),
    );
  }
}

class _ReportServiceDialog extends StatefulWidget {
  final int serviceId;

  const _ReportServiceDialog({required this.serviceId});

  @override
  State<_ReportServiceDialog> createState() => _ReportServiceDialogState();
}

class _ReportServiceDialogState extends State<_ReportServiceDialog> {
  static const _reasonKeys = [
    'spam',
    'harassment',
    'inappropriate',
    'fraud',
    'other',
  ];

  late String _reason;
  final TextEditingController _details = TextEditingController();

  @override
  void initState() {
    super.initState();
    _reason = _reasonKeys.first;
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String _reasonLabel(String key) {
    switch (key) {
      case 'spam':
        return language.ugcReasonSpam;
      case 'harassment':
        return language.ugcReasonHarassment;
      case 'inappropriate':
        return language.ugcReasonInappropriate;
      case 'fraud':
        return language.ugcReasonFraud;
      case 'other':
        return language.ugcReasonOther;
      default:
        return key;
    }
  }

  Future<void> _submit() async {
    hideKeyboard(context);
    appStore.setLoading(true);
    try {
      final res = await ugcReportService(
        serviceId: widget.serviceId,
        reason: _reason,
        details: _details.text,
      );
      appStore.setLoading(false);
      finish(context);
      toast(
        parseHtmlString(
          res['message']?.toString() ?? language.success,
        ),
      );
    } catch (e) {
      appStore.setLoading(false);
      toast(e.toString(), print: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final maxW = math.min(300.0, size.width - 32);
    final maxH = math.min(420.0, size.height * 0.52);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: radius(12)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        language.ugcReportTitle,
                        style: boldTextStyle(size: 15),
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: context.iconColor,
                    ),
                    onPressed: () => finish(context),
                  ),
                ],
              ),
              4.height,
              Text(
                language.ugcSelectReason,
                style: secondaryTextStyle(size: 11),
              ),
              4.height,
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _reason,
                isDense: true,
                isExpanded: true,
                decoration: inputDecoration(context).copyWith(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                items: _reasonKeys
                    .map(
                      (k) => DropdownMenuItem(
                        value: k,
                        child: Text(
                          _reasonLabel(k),
                          overflow: TextOverflow.ellipsis,
                          style: primaryTextStyle(size: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _reason = v);
                },
              ),
              8.height,
              AppTextField(
                controller: _details,
                textFieldType: TextFieldType.MULTILINE,
                minLines: 1,
                maxLines: 3,
                maxLength: 2000,
                decoration: inputDecoration(
                  context,
                  labelText: language.ugcDetailsOptional,
                ).copyWith(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
              ),
              10.height,
              Row(
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => finish(context),
                    child:
                        Text(language.lblCancel, style: primaryTextStyle(size: 13)),
                  ),
                  const Spacer(),
                  GradientButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    borderRadius: 8,
                    onPressed: _submit,
                    child: Text(
                      language.ugcSubmitReport,
                      style: boldTextStyle(color: white, size: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
