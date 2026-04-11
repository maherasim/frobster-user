/// Reason row from GET /ugc/report-reasons (`value` for POST, `label` for UI).
class UgcReportReason {
  final String value;
  final String label;

  UgcReportReason({required this.value, required this.label});

  factory UgcReportReason.fromJson(Map<String, dynamic> json) {
    final v = json['value']?.toString() ?? '';
    final l = json['label']?.toString();
    return UgcReportReason(
      value: v,
      label: (l != null && l.isNotEmpty) ? l : v,
    );
  }
}
