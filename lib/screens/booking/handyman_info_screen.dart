import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:booking_system_flutter/component/back_widget.dart';
import 'package:booking_system_flutter/component/view_all_label_component.dart';
import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/provider_info_response.dart';
import 'package:booking_system_flutter/model/user_data_model.dart';
import 'package:booking_system_flutter/model/country_list_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/screens/review/components/review_widget.dart';
import 'package:booking_system_flutter/screens/review/rating_view_all_screen.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:booking_system_flutter/utils/images.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../component/base_scaffold_widget.dart';
import '../../component/empty_error_state_widget.dart';
import '../../component/loader_widget.dart';
import '../../component/disabled_rating_bar_widget.dart';
import '../../utils/colors.dart';
import '../../utils/common.dart';

// NOTE: This screen is READ-ONLY. No edit/update functionality should be added.
// CustomImagePicker or any upload components should NEVER be used here.

class HandymanInfoScreen extends StatefulWidget {
  final int? handymanId;

  HandymanInfoScreen({this.handymanId});

  @override
  HandymanInfoScreenState createState() => HandymanInfoScreenState();
}

class HandymanInfoScreenState extends State<HandymanInfoScreen> {
  Future<ProviderInfoResponse>? future;
  CountryListResponse? country;

  int page = 1;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    future = getProviderDetail(widget.handymanId.validate(),
        userId: appStore.userId.validate());
    // Load country data
    if (future != null) {
      future!.then((data) {
        if (data.userData?.countryId != null) {
          getCountry(data.userData!.countryId.validate());
        }
      });
    }
  }

  Future<void> getCountry(int countryId) async {
    await getCountryList().then((value) async {
      if (value.any((element) => element.id == countryId)) {
        country = value.firstWhere((element) => element.id == countryId);
        setState(() {});
      }
    }).catchError((e) {
      // Ignore country loading errors
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Stack(
        children: [
          SnapHelperWidget<ProviderInfoResponse>(
            future: future,
            onSuccess: (data) {
              final userData = data.userData!;
              return AnimatedScrollView(
                listAnimationType: ListAnimationType.FadeIn,
                physics: AlwaysScrollableScrollPhysics(),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Container(
                    margin: EdgeInsets.only(top: context.statusBarHeight),
                    decoration: BoxDecoration(
                      gradient: appPrimaryGradient,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        BackWidget(),
                        16.width,
                        Text(
                          language.lblAboutHandyman,
                          style: boldTextStyle(color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                  
                  // Profile Image Header
                  _buildProfileHeader(userData),
                  
                  // Main Content Card
                  Container(
                    margin: EdgeInsets.all(16),
                    padding: EdgeInsets.all(20),
                    decoration: boxDecorationWithRoundedCorners(
                      borderRadius: radius(defaultRadius),
                      backgroundColor: context.cardColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and Badges
                        _buildNameSection(userData),
                        16.height,
                        
                        // Rating
                        if (userData.handymanRating != null)
                          _buildRatingSection(userData),
                        
                        // Location and Member Since
                        if (userData.cityName != null || country != null) ...[
                          16.height,
                          _buildLocationSection(userData),
                        ],
                        
                        8.height,
                        _buildMemberSinceSection(userData),
                        
                        // Known Languages
                        if (userData.knownLanguagesArray.isNotEmpty) ...[
                          24.height,
                          _buildLanguagesSection(userData),
                        ],
                        
                        // Skills
                        if (userData.skillsArray.isNotEmpty) ...[
                          24.height,
                          _buildSkillsSection(userData),
                        ],
                        
                        // Description
                        if (userData.description.validate().isNotEmpty) ...[
                          24.height,
                          _buildDescriptionSection(userData),
                        ],
                      ],
                    ),
                  ),
                  
                  // Reviews Section
                  _buildReviewsSection(data),
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
            loadingWidget: LoaderWidget(),
          ),
          Observer(builder: (_) => LoaderWidget().visible(appStore.isLoading)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserData userData) {
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          // Profile Image - Using low-level dart:ui to avoid triggering image picker
          _LowLevelImageWidget(
            imageUrl: userData.profileImage.validate(),
            height: 280,
            width: context.width(),
            placeholder: Container(
              height: 280,
              width: context.width(),
              color: context.cardColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: gradientRed.withValues(alpha: 0.1),
                    ),
                    child: Icon(Icons.person, size: 80, color: gradientRed),
                  ),
                  16.height,
                  Text(
                    userData.displayName.validate(),
                    style: boldTextStyle(size: 20),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Rating Badge
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: ratingBarColor, size: 16),
                  4.width,
                  Text(
                    userData.handymanRating.validate().toStringAsFixed(1),
                    style: boldTextStyle(size: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSection(UserData userData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Verified/Not Verified Icon
        if (userData.verifiedStickerIcon.validate().isNotEmpty)
          Image.network(
            userData.verifiedStickerIcon.validate(),
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/icons/verified_badge.jpg',
              width: 24,
              height: 24,
            ),
          )
        else
          Image.asset(
            'assets/icons/verified_badge.jpg',
            width: 24,
            height: 24,
          ),
        8.width,
        
        // Name
        Expanded(
          child: Text(
            userData.displayName.validate(),
            style: boldTextStyle(size: 22),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Verified Checkmark
        if ((userData.isVerifyProvider == 1) || (userData.isVerifyHandyman == 1))
          Image.asset(ic_verified, height: 20, color: Colors.green),
        
        8.width,
        
        // Membership Icon
        if (userData.membershipIcon.validate().isNotEmpty)
          Image.network(
            userData.membershipIcon.validate(),
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              'assets/icons/free-membership.jpg',
              width: 24,
              height: 24,
            ),
          )
        else
          Image.asset(
            'assets/icons/free-membership.jpg',
            width: 24,
            height: 24,
          ),
        
        // Designation
        if (userData.designation.validate().isNotEmpty) ...[
          12.width,
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: boxDecorationWithRoundedCorners(
              backgroundColor: gradientRed.withValues(alpha: 0.1),
              borderRadius: radius(12),
            ),
            child: Text(
              userData.designation.validate(),
              style: secondaryTextStyle(
                color: gradientRed,
                weight: FontWeight.bold,
                size: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatingSection(UserData userData) {
    return Row(
      children: [
        DisabledRatingBarWidget(
          rating: userData.handymanRating.validate(),
          size: 18,
        ),
        8.width,
        Text(
          '${userData.handymanRating.validate().toStringAsFixed(1)}',
          style: secondaryTextStyle(size: 14, weight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLocationSection(UserData userData) {
    final location = userData.cityName != null && country != null
        ? '${userData.cityName.validate()} - ${country?.name.validate()}'
        : userData.cityName ?? country?.name ?? '';
    
    if (location.isEmpty) return SizedBox.shrink();
    
    return Row(
      children: [
        Icon(Icons.location_on, size: 18, color: context.iconColor),
        8.width,
        Expanded(
          child: Text(
            location,
            style: secondaryTextStyle(size: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberSinceSection(UserData userData) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: context.iconColor),
        8.width,
        Text(
          '${language.lblMemberSince} ${formatDate(userData.createdAt.validate())}',
          style: secondaryTextStyle(size: 13),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection(UserData userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language.knownLanguages,
          style: boldTextStyle(size: 16),
        ),
        12.height,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: userData.knownLanguagesArray.map((language) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: appStore.isDarkMode
                    ? cardDarkColor
                    : gradientRed.withValues(alpha: 0.1),
                borderRadius: radius(8),
              ),
              child: Text(
                language,
                style: secondaryTextStyle(
                  weight: FontWeight.w600,
                  size: 13,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(UserData userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language.essentialSkills,
          style: boldTextStyle(size: 16),
        ),
        12.height,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: userData.skillsArray.map((skill) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: boxDecorationWithRoundedCorners(
                backgroundColor: appStore.isDarkMode
                    ? cardDarkColor
                    : gradientRed.withValues(alpha: 0.1),
                borderRadius: radius(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 16, color: primaryColor),
                  6.width,
                  Text(
                    skill,
                    style: secondaryTextStyle(
                      weight: FontWeight.w600,
                      size: 13,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(UserData userData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          language.lblAboutHandyman,
          style: boldTextStyle(size: 16),
        ),
        12.height,
        Text(
          userData.description.validate(),
          style: secondaryTextStyle(size: 14, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(ProviderInfoResponse data) {
    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ViewAllLabel(
            label: language.review,
            list: data.handymanRatingReviewList,
            onTap: () {
              RatingViewAllScreen(handymanId: data.userData!.id)
                  .launch(context);
            },
          ),
          16.height,
          data.handymanRatingReviewList.validate().isNotEmpty
              ? AnimatedListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  slideConfiguration: sliderConfigurationGlobal,
                  padding: EdgeInsets.zero,
                  itemCount: data.handymanRatingReviewList.validate().length,
                  itemBuilder: (context, index) => Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(16),
                    decoration: boxDecorationWithRoundedCorners(
                      borderRadius: radius(defaultRadius),
                      backgroundColor: context.cardColor,
                    ),
                    child: ReviewWidget(
                      data: data.handymanRatingReviewList.validate()[index],
                      isCustomer: true,
                    ),
                  ),
                )
              : Container(
                  padding: EdgeInsets.all(24),
                  decoration: boxDecorationWithRoundedCorners(
                    borderRadius: radius(defaultRadius),
                    backgroundColor: context.cardColor,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.reviews_outlined,
                            size: 48, color: context.iconColor),
                        12.height,
                        Text(
                          language.lblNoReviews,
                          style: secondaryTextStyle(size: 14),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// Low-level image widget using dart:ui to completely bypass Flutter's image widgets
class _LowLevelImageWidget extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double width;
  final Widget placeholder;

  const _LowLevelImageWidget({
    required this.imageUrl,
    required this.height,
    required this.width,
    required this.placeholder,
  });

  @override
  State<_LowLevelImageWidget> createState() => _LowLevelImageWidgetState();
}

class _LowLevelImageWidgetState extends State<_LowLevelImageWidget> {
  ui.Image? _uiImage;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageUrl.isNotEmpty) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        final codec = await ui.instantiateImageCodec(response.bodyBytes);
        final frame = await codec.getNextFrame();
        
        if (mounted) {
          setState(() {
            _uiImage = frame.image;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _uiImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty || _hasError) {
      return widget.placeholder;
    }

    if (_isLoading) {
      return Container(
        height: widget.height,
        width: widget.width,
        color: context.cardColor,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_uiImage != null) {
      return CustomPaint(
        size: Size(widget.width, widget.height),
        painter: _ImagePainter(_uiImage!),
      );
    }

    return widget.placeholder;
  }
}

// Custom painter to draw the ui.Image
class _ImagePainter extends CustomPainter {
  final ui.Image image;

  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final srcRect = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    canvas.drawImageRect(
      image,
      srcRect,
      dstRect,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
