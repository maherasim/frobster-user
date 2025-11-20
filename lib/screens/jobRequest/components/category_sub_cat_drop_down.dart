import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/category_model.dart';
import 'package:booking_system_flutter/network/rest_apis.dart';
import 'package:booking_system_flutter/utils/common.dart';
import 'package:booking_system_flutter/utils/constant.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

class CategorySubCatDropDown extends StatefulWidget {
  final int? categoryId;
  final int? subCategoryId;
  final Function(int? val) onCategorySelect;
  final Function(int? val) onSubCategorySelect;
  final bool? isCategoryValidate;
  final bool? isSubCategoryValidate;
  final Color? fillColor;

  CategorySubCatDropDown({this.categoryId, this.subCategoryId, required this.onSubCategorySelect, required this.onCategorySelect, this.isSubCategoryValidate, this.isCategoryValidate, this.fillColor});

  @override
  State<CategorySubCatDropDown> createState() => _CategorySubCatDropDownState();
}

class _CategorySubCatDropDownState extends State<CategorySubCatDropDown> {
  List<CategoryData> categoryList = [];
  List<CategoryData> subCategoryList = [];

  CategoryData? selectedCategory;
  CategoryData? selectedSubCategory;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    getCategory();
  }

  Future<void> getSubCategory({required int categoryId}) async {
    await getSubCategoryList(catId: categoryId.toInt()).then((value) {
      subCategoryList = value.categoryList.validate();

      if (widget.subCategoryId != null) {
        selectedSubCategory = value.categoryList!.firstWhere((element) => element.id == widget.subCategoryId);
        widget.onSubCategorySelect.call(selectedSubCategory?.id.validate());
      }

      setState(() {});
    }).catchError((e) {
      log(e.toString());
    });
  }

  Future<void> getCategory() async {
    appStore.setLoading(true);

    await getCategoryList( CATEGORY_LIST_ALL).then((value) {
      categoryList = value.categoryList!;

      ///
      if (widget.categoryId != null) {
        ///
        selectedCategory = value.categoryList!.firstWhere((element) => element.id == widget.categoryId);
        widget.onCategorySelect.call(selectedCategory?.id.validate());

        ///
        if (widget.subCategoryId != null) {
          getSubCategory(categoryId: selectedCategory!.id.validate());
        }
      }
      setState(() {});
    }).catchError((e) {
      toast(e.toString(), print: true);
    });

    appStore.setLoading(false);
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  String getStringValue() {
    if (selectedCategory == null) {
      return language.selectCategory;
    } else {
      return language.lblSubCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          DropdownButtonFormField<CategoryData>(
            initialValue: selectedCategory,
            decoration: inputDecoration(
              context,
              labelText: language.lblCategory,
            ),
            dropdownColor: context.cardColor,
            isExpanded: true,
            items: categoryList.map((data) {
              return DropdownMenuItem<CategoryData>(
                value: data,
                child: Text(data.name.validate(), style: primaryTextStyle()),
              );
            }).toList(),
            validator: widget.isCategoryValidate.validate(value: true)
                ? (value) {
                    if (value == null) return errorThisFieldRequired;

                    return null;
                  }
                : null,
            onChanged: (CategoryData? value) async {
              selectedCategory = value!;
              widget.onCategorySelect.call(selectedCategory!.id.validate());

              if (selectedSubCategory != null) {
                selectedSubCategory = null;
                subCategoryList.clear();
                widget.onSubCategorySelect.call(null);
              }
              getSubCategory(categoryId: value.id.validate());
              setState(() {});
            },
          ),
          16.height,
          DropdownButtonFormField<CategoryData>(
            decoration: inputDecoration(
              context,
              labelText: getStringValue(),
            ),
            dropdownColor: context.cardColor,
            initialValue: selectedSubCategory,
            validator: widget.isSubCategoryValidate.validate(value: true)
                ? (value) {
                    if (value == null) return errorThisFieldRequired;

                    return null;
                  }
                : null,
            items: subCategoryList.map((data) {
              return DropdownMenuItem<CategoryData>(
                value: data,
                child: Text(data.name.validate(), style: primaryTextStyle()),
              );
            }).toList(),
            onChanged: (CategoryData? value) async {
              selectedSubCategory = value!;
              widget.onSubCategorySelect.call(selectedSubCategory!.id.validate());
              setState(() {});
            },
          ),
        ],
      ),
    );
  }
}
