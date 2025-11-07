import 'package:mobx/mobx.dart';

part 'filter_store.g.dart';

class FilterStore = FilterStoreBase with _$FilterStore;

abstract class FilterStoreBase with Store {
  @observable
  List<int> serviceId = ObservableList();

  @observable
  List<int> customerId = ObservableList();

  @observable
  List<int> providerId = ObservableList();

  @observable
  List<int> countryId = ObservableList();

  @observable
  List<int> stateId = ObservableList();

  @observable
  List<int> cityId = ObservableList();

  @observable
  List<int> handymanId = ObservableList();

  @observable
  List<String> bookingStatus = ObservableList();

  @observable
  List<String> paymentStatus = ObservableList();

  @observable
  List<String> paymentType = ObservableList();

  @observable
  String startDate = '';

  @observable
  String endDate = '';

  @observable
  List<int> ratingId = ObservableList();

  @observable
  List<int> categoryId = ObservableList();

  @observable
  int selectedSubCategoryId = 0;

  @observable
  String isPriceMax = '';

  @observable
  String isPriceMin = '';

  @observable
  String search = '';

  @observable
  String latitude = '';

  @observable
  String longitude = '';

  @action
  void setStartDate(String val) {
    startDate = val;
  }

  @action
  void setEndDate(String val) {
    endDate = val;
  }

  @action
  Future<void> addToServiceList({required int serId}) async {
    serviceId.add(serId);
  }

  @action
  Future<void> removeFromServiceList({required int serId}) async {
    serviceId.removeWhere((element) => element == serId);
  }

  @action
  Future<void> addToCustomerList({required int cusId}) async {
    customerId.add(cusId);
  }

  @action
  Future<void> removeFromCustomerList({required int cusId}) async {
    customerId.removeWhere((element) => element == cusId);
  }

  @action
  Future<void> addToBookingStatusList(
      {required String bookingStatusList}) async {
    bookingStatus.add(bookingStatusList);
  }

  @action
  Future<void> removeFromBookingStatusList(
      {required String bookingStatusList}) async {
    bookingStatus.removeWhere((element) => element == bookingStatusList);
  }

  @action
  Future<void> addToPaymentStatusList(
      {required String paymentStatusList}) async {
    paymentStatus.add(paymentStatusList);
  }

  @action
  Future<void> removeFromPaymentStatusList(
      {required String paymentStatusList}) async {
    paymentStatus.removeWhere((element) => element == paymentStatusList);
  }

  @action
  Future<void> addToPaymentTypeList({required String paymentTypeList}) async {
    paymentType.add(paymentTypeList);
  }

  @action
  Future<void> removeFromPaymentTypeList(
      {required String paymentTypeList}) async {
    paymentType.removeWhere((element) => element == paymentTypeList);
  }

  @action
  Future<void> addToProviderList({required int prodId}) async {
    providerId.add(prodId);
  }

  @action
  Future<void> removeFromProviderList({required int prodId}) async {
    providerId.removeWhere((element) => element == prodId);
  }

  @action
  Future<void> addToCountryList({required int ctryId}) async {
    countryId.add(ctryId);
  }

  @action
  Future<void> removeFromCountryList({required int ctryId}) async {
    countryId.removeWhere((element) => element == ctryId);
  }

  @action
  Future<void> addToCityList({required int id}) async {
    cityId.add(id);
  }

  @action
  Future<void> removeFromCityList({required int id}) async {
    cityId.removeWhere((element) => element == id);
  }

  @action
  Future<void> addToStateList({required int id}) async {
    stateId.add(id);
  }

  @action
  Future<void> removeFromStateList({required int id}) async {
    stateId.removeWhere((element) => element == id);
  }

  @action
  Future<void> addToCategoryIdList({required int prodId}) async {
    categoryId.add(prodId);
  }

  @action
  Future<void> setSelectedSubCategory({required int catId}) async {
    selectedSubCategoryId = catId;
  }

  @action
  Future<void> removeFromCategoryIdList({required int prodId}) async {
    categoryId.removeWhere((element) => element == prodId);
  }

  @action
  Future<void> addToHandymanList({required int prodId}) async {
    handymanId.add(prodId);
  }

  @action
  Future<void> removeFromHandymanList({required int prodId}) async {
    handymanId.removeWhere((element) => element == prodId);
  }

  @action
  Future<void> addToRatingId({required List<int> prodId}) async {
    ratingId = ObservableList.of(prodId);
  }

  @action
  Future<void> removeFromRatingId({required int prodId}) async {
    ratingId.removeWhere((element) => element == prodId);
  }

  @action
  Future<void> clearFilters() async {
    customerId.clear();
    serviceId.clear();
    providerId.clear();
    countryId.clear();
    stateId.clear();
    cityId.clear();
    handymanId.clear();
    bookingStatus.clear();
    paymentType.clear();
    paymentStatus.clear();
    startDate = '';
    endDate = '';
    ratingId.clear();
    categoryId.clear();
    isPriceMax = "";
    isPriceMin = "";
  }

  @action
  void setMaxPrice(String val) => isPriceMax = val;

  @action
  void setMinPrice(String val) => isPriceMin = val;

  @action
  void setSearch(String val) => search = val;

  @action
  void setLatitude(String val) => latitude = val;

  @action
  void setLongitude(String val) => longitude = val;
}
