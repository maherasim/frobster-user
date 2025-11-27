import 'package:booking_system_flutter/component/back_widget.dart';
import 'dart:async';
import 'package:booking_system_flutter/component/cached_image_widget.dart';
import 'package:booking_system_flutter/component/loader_widget.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/category/shimmer/category_shimmer.dart';
import 'package:booking_system_flutter/screens/dashboard/component/category_widget.dart';
import 'package:booking_system_flutter/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/empty_error_state_widget.dart';
import '../../utils/constant.dart';
import '../service/view_all_service_screen.dart';

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<List<CategoryData>> future;
  List<CategoryData> categoryList = [];

  int page = 1;
  bool isLastPage = false;
  bool isApiCalled = false;

  UniqueKey key = UniqueKey();

  // Enhanced UX state
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String _searchQuery = '';
  bool _isGridView = true;
  int _gridCount = 2; // 2 or 3 columns
  String _sortMode = 'popular'; // 'popular' | 'az'

  void initState() {
    super.initState();
    init();
  }

  void init() async {
    future = getCategoryListWithPagination(page, categoryList: categoryList,
        lastPageCallBack: (val) {
      isLastPage = val;
    });
    if (page == 1) {
      key = UniqueKey();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(language.category,
            style: boldTextStyle(color: Colors.white, size: APP_BAR_TEXT_SIZE)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness:
                appStore.isDarkMode ? Brightness.light : Brightness.light),
        leading: Navigator.canPop(context) ? BackWidget() : null,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: appPrimaryGradient),
        ),
      ),
      body: Stack(
        children: [
          SnapHelperWidget<List<CategoryData>>(
            initialData: cachedCategoryList,
            future: future,
            loadingWidget: CategoryShimmer(),
            onSuccess: (snap) {
              if (snap.isEmpty) {
                return NoDataWidget(
                  title: language.noCategoryFound,
                  imageWidget: EmptyStateWidget(),
                );
              }

              // Build list with sorting and local search
              List<CategoryData> items = List<CategoryData>.from(snap);
              if (_sortMode == 'popular') {
                items.sort((a, b) => (b.services ?? 0).compareTo(a.services ?? 0));
              } else {
                items.sort((a, b) => a.name.validate(value: '').toLowerCase().compareTo(b.name.validate(value: '').toLowerCase()));
              }
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                items = items.where((c) {
                  final name = c.name.validate(value: '').toLowerCase();
                  final desc = c.description.validate(value: '').toLowerCase();
                  return name.contains(q) || desc.contains(q);
                }).toList();
              }

              return AnimatedScrollView(
                onSwipeRefresh: () async {
                  page = 1;

                  init();
                  setState(() {});

                  return await 2.seconds.delay;
                },
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(16),
                listAnimationType: ListAnimationType.FadeIn,
                fadeInConfiguration: FadeInConfiguration(duration: 2.seconds),
                onNextPage: () {
                  if (!isLastPage) {
                    page++;
                    appStore.setLoading(true);

                    init();
                    setState(() {});
                  }
                },
                children: [
                  // Search + controls
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextField(
                        controller: _searchController,
                        textFieldType: TextFieldType.OTHER,
                        decoration: InputDecoration(
                          hintText: language.search,
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: radius(12)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: context.dividerColor),
                            borderRadius: radius(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 1.2),
                            borderRadius: radius(12),
                          ),
                          filled: true,
                          fillColor: context.cardColor,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (val) {
                          _searchDebounce?.cancel();
                          _searchDebounce = Timer(300.milliseconds, () {
                            _searchQuery = val.trim();
                            setState(() {});
                          });
                        },
                      ),
                      12.height,
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: radius(8),
                              border: Border.all(color: context.dividerColor),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.grid_view_rounded,
                                    color: _isGridView ? primaryColor : appTextSecondaryColor,
                                  ),
                                  onPressed: () {
                                    _isGridView = true;
                                    setState(() {});
                                  },
                                  tooltip: 'Grid',
                                ),
                                VerticalDivider(width: 1, thickness: 1).withWidth(1),
                                IconButton(
                                  icon: Icon(
                                    Icons.view_list_rounded,
                                    color: !_isGridView ? primaryColor : appTextSecondaryColor,
                                  ),
                                  onPressed: () {
                                    _isGridView = false;
                                    setState(() {});
                                  },
                                  tooltip: 'List',
                                ),
                              ],
                            ),
                          ),
                          12.width,
                          if (_isGridView)
                            Container(
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: radius(8),
                                border: Border.all(color: context.dividerColor),
                              ),
                              child: Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      _gridCount = 2;
                                      setState(() {});
                                    },
                                    child: Text(
                                      '2x',
                                      style: primaryTextStyle(color: _gridCount == 2 ? primaryColor : textPrimaryColorGlobal),
                                    ),
                                  ),
                                  VerticalDivider(width: 1, thickness: 1).withWidth(1),
                                  TextButton(
                                    onPressed: () {
                                      _gridCount = 3;
                                      setState(() {});
                                    },
                                    child: Text(
                                      '3x',
                                      style: primaryTextStyle(color: _gridCount == 3 ? primaryColor : textPrimaryColorGlobal),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Spacer(),
                          PopupMenuButton<String>(
                            tooltip: 'Sort',
                            onSelected: (v) {
                              _sortMode = v;
                              setState(() {});
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'popular',
                                child: Row(
                                  children: [
                                    Icon(Icons.trending_up, size: 18),
                                    8.width,
                                    Text('Popular'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'az',
                                child: Row(
                                  children: [
                                    Icon(Icons.sort_by_alpha, size: 18),
                                    8.width,
                                    Text('A - Z'),
                                  ],
                                ),
                              ),
                            ],
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: radius(8),
                                border: Border.all(color: context.dividerColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sort_rounded),
                                  6.width,
                                  Text('Sort'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      8.height,
                      if (_searchQuery.isNotEmpty)
                        Text(
                          '${language.search}: "$_searchQuery" • ${items.length}',
                          style: secondaryTextStyle(),
                        ),
                    ],
                  ),
                  16.height,

                  if (items.isEmpty)
                    NoDataWidget(
                      title: language.lblNoServicesFound,
                      imageWidget: EmptyStateWidget(),
                    )
                  else if (_isGridView)
                    AnimatedWrap(
                      key: key,
                      runSpacing: 16,
                      spacing: 16,
                      itemCount: items.length,
                      listAnimationType: ListAnimationType.FadeIn,
                      fadeInConfiguration:
                          FadeInConfiguration(duration: 2.seconds),
                      scaleConfiguration: ScaleConfiguration(
                          duration: 300.milliseconds, delay: 50.milliseconds),
                      itemBuilder: (_, index) {
                        final data = items[index];
                        final tileWidth = (context.width() - 16 * 2 - 16 * (_gridCount - 1)) / _gridCount;
                        return SizedBox(
                          width: tileWidth,
                          child: GestureDetector(
                            onTap: () {
                              ViewAllServiceScreen(
                                      categoryId: data.id.validate(),
                                      categoryName: data.name,
                                      isFromCategory: true)
                                  .launch(context);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                color: context.cardColor,
                                borderRadius: radius(14),
                                border: Border.all(color: context.dividerColor.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CategoryWidget(categoryData: data, width: tileWidth - 24),
                                  6.height,
                                  Text(
                                    '${(data.services ?? 0)} ${language.services}',
                                    style: secondaryTextStyle(size: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => 8.height,
                      itemBuilder: (_, index) {
                        final data = items[index];
                        return InkWell(
                          borderRadius: radius(12),
                          onTap: () {
                            ViewAllServiceScreen(
                                    categoryId: data.id.validate(),
                                    categoryName: data.name,
                                    isFromCategory: true)
                                .launch(context);
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.cardColor,
                              borderRadius: radius(12),
                              border: Border.all(color: context.dividerColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.scaffoldBackgroundColor,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: (data.categoryImage.validate().endsWith('.svg'))
                                      ? Icon(Icons.category, color: primaryColor)
                                      : CachedImageWidget(
                                          url: data.categoryImage.validate(),
                                          height: 44,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                12.width,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.name.validate(),
                                        style: primaryTextStyle(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      4.height,
                                      Text(
                                        '${(data.services ?? 0)} ${language.services}',
                                        style: secondaryTextStyle(),
                                      ),
                                    ],
                                  ),
                                ),
                                8.width,
                                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: appTextSecondaryColor),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
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
              builder: (BuildContext context) =>
                  LoaderWidget().visible(appStore.isLoading.validate())),
        ],
      ),
    );
  }
}
