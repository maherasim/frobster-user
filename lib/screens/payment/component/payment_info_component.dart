import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../component/empty_error_state_widget.dart';
import '../../../component/price_widget.dart';
import '../../../main.dart';
import '../../../model/payment_list_reasponse.dart';
import '../../../network/rest_apis.dart';
import '../../../utils/common.dart';

class PaymentInfoComponent extends StatefulWidget {
  final int bookingId;

  PaymentInfoComponent(this.bookingId);

  @override
  State<PaymentInfoComponent> createState() => _PaymentInfoComponentState();
}

class _PaymentInfoComponentState extends State<PaymentInfoComponent> {
  List<PaymentData> list = [];
  Future<List<PaymentData>>? future;
  int page = 1;
  bool isLastPage = false;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    future = getPaymentList(page, widget.bookingId, list, (p0) {
      isLastPage = p0;
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.height() * 0.7,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(language.paymentHistory, style: boldTextStyle())
                .paddingAll(16),
            SnapHelperWidget<List<PaymentData>>(
              future: future,
              onSuccess: (data) {
                if (list.isEmpty) {
                  return NoDataWidget(
                    title: language.noDataAvailable,
                    imageWidget: EmptyStateWidget(),
                  ).paddingSymmetric(vertical: 24);
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: context.width() - 32,
                    ),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        context.scaffoldBackgroundColor,
                      ),
                      dataRowMinHeight: 52,
                      headingTextStyle: boldTextStyle(size: 12),
                      dataTextStyle: primaryTextStyle(size: 12),
                      columnSpacing: 16,
                      horizontalMargin: 12,
                      columns: [
                        DataColumn(
                          label: Text(
                            language.transactionId,
                            style: boldTextStyle(size: 12),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            language.amountLabel,
                            style: boldTextStyle(size: 12),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            language.paymentMethod,
                            style: boldTextStyle(size: 12),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            language.lblDate,
                            style: boldTextStyle(size: 12),
                          ),
                        ),
                      ],
                      rows: list.map((PaymentData data) {
                        return DataRow(
                          cells: [
                            DataCell(
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 160),
                                child: Text(
                                  data.txnId.validate(),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              PriceWidget(
                                price: data.totalAmount.validate(),
                              ),
                            ),
                            DataCell(
                              Text(
                                data.paymentMethod
                                    .validate()
                                    .capitalizeFirstLetter(),
                              ),
                            ),
                            DataCell(
                              Text(
                                formatDate(
                                  data.date.validate().toString(),
                                ),
                                style: secondaryTextStyle(size: 12),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ).paddingSymmetric(horizontal: 8);
              },
            ),
          ],
        ),
      ),
    );
  }
}
