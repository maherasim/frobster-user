import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/service_data_model.dart';

/// True if this listing belongs to a user blocked via [POST api/ugc/block].
/// Matches either [ServiceData.userId] or [ServiceData.providerId] against stored ids.
bool isServiceFromBlockedProvider(
  ServiceData s,
  Iterable<int> blockedIds,
) {
  if (blockedIds.isEmpty) return false;
  final uid = s.userId?.toInt();
  if (uid != null && uid > 0 && blockedIds.contains(uid)) return true;
  final pid = s.providerId;
  if (pid != null && pid > 0 && blockedIds.contains(pid)) return true;
  return false;
}

List<ServiceData> filterOutBlockedServices(
  List<ServiceData> list,
  Iterable<int> blockedIds,
) {
  if (list.isEmpty || blockedIds.isEmpty) return list;
  return list
      .where((s) => !isServiceFromBlockedProvider(s, blockedIds))
      .toList();
}

/// When logged in, block opening detail if this provider was blocked via UGC.
bool shouldBlockServiceTap(ServiceData s) {
  if (!appStore.isLoggedIn) return false;
  return isServiceFromBlockedProvider(s, appStore.blockedUserIds);
}
