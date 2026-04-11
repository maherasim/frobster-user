import 'dart:math' as math;

import 'package:booking_system_flutter/component/gradient_button.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/ugc_report_reason.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Report a review (POST /ugc/report-review); reasons from GET /ugc/report-reasons.
class ReportReviewDialog extends StatefulWidget {
  final int reviewId;
  final String reviewType;

  const ReportReviewDialog({
    super.key,
    required this.reviewId,
    this.reviewType = 'booking_rating',
  });

  @override
  State<ReportReviewDialog> createState() => _ReportReviewDialogState();
}

class _ReportReviewDialogState extends State<ReportReviewDialog> {
  List<UgcReportReason> _reasons = [];
  String? _selectedValue;
  final TextEditingController _details = TextEditingController();
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchReasons();
  }

  Future<void> _fetchReasons() async {
    try {
      final list = await getUgcReportReasons();
      if (!mounted) return;
      setState(() {
        _reasons = list;
        _selectedValue = list.isNotEmpty ? list.first.value : null;
        _loading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _selectedValue;
    if (reason == null || reason.isEmpty) {
      toast(language.somethingWentWrong);
      return;
    }
    hideKeyboard(context);
    appStore.setLoading(true);
    try {
      await ugcReportReview(
        reviewId: widget.reviewId,
        reviewType: widget.reviewType,
        reason: reason,
        details: _details.text,
      );
      appStore.setLoading(false);
      finish(context);
      toast(parseHtmlString(language.ugcReportReviewSuccess));
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
                        language.ugcReportReviewTitle,
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
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _loadError!,
                    style: secondaryTextStyle(size: 12, color: Colors.red),
                  ),
                )
              else if (_reasons.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    language.somethingWentWrong,
                    style: secondaryTextStyle(size: 12),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedValue,
                  isDense: true,
                  isExpanded: true,
                  decoration: inputDecoration(context).copyWith(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  items: _reasons
                      .map(
                        (r) => DropdownMenuItem(
                          value: r.value,
                          child: Text(
                            r.label,
                            overflow: TextOverflow.ellipsis,
                            style: primaryTextStyle(size: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedValue = v);
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
                    child: Text(
                      language.lblCancel,
                      style: primaryTextStyle(size: 13),
                    ),
                  ),
                  const Spacer(),
                  GradientButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    borderRadius: 8,
                    onPressed: () {
                      if (_loading || _reasons.isEmpty) return;
                      _submit();
                    },
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
