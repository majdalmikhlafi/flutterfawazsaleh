import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_ecomarce/models/category.dart';
import 'package:flutter_ecomarce/models/option_type.dart';
import 'package:flutter_ecomarce/models/option_value.dart';
import 'package:flutter_ecomarce/models/product.dart';
import 'package:flutter_ecomarce/screens/search.dart';
import 'package:flutter_ecomarce/utils/color_list.dart';
import 'package:flutter_ecomarce/utils/constants.dart';
import 'package:flutter_ecomarce/utils/drawer_homescreen.dart';
import 'package:flutter_ecomarce/widgets/product_container_for_pagination.dart';
import 'package:flutter_ecomarce/widgets/shopping_cart_button.dart';

class CategoryListing extends StatefulWidget {
  final String categoryName;
  final int categoryId;
  final int parentId;

  CategoryListing(this.categoryName, this.categoryId, this.parentId);
  @override
  State<StatefulWidget> createState() {
    return _CategoryListingState();
  }
}

class _CategoryListingState extends State<CategoryListing> {
  Size _deviceSize;
  bool _isLoading = true;
  int level = 0;
  static const int PAGE_SIZE = 20;
  List<Category> categoryList = [];
  List<Category> subCategoryList = [];
  List<Product> productsByCategory = [];
  List<Widget> header = [];
  final int perPage = TWENTY;
  int currentPage = ONE;
  int subCatId = ZERO;
  int currentIndex = -1;
  Map<int, List<Widget>> subCatListForFilter = Map();
  final scrollController = ScrollController();
  bool hasMore = false, isFilterDataLoading = false;
  bool isChecked = false;
  List<Category> filterSubCategoryList = [];
  final GlobalKey<ScaffoldState> _scaffoldKey =
      new GlobalKey<ScaffoldState>(); // ADD THIS LINE
  Map<dynamic, dynamic> responseBody;
  List<Category> _listViewData = [];
  List<DropdownMenuItem<String>> _dropDownMenuItems;
  String _currentItem;
  List filterItems = [
    "Newest",
    "Avg.Customer Review",
    "Most Reviews",
    "A TO Z",
    "Z TO A"
  ];
  List<DropdownMenuItem<String>> getDropDownMenuItems() {
    List<DropdownMenuItem<String>> items = new List();
    for (String city in filterItems) {
      items.add(new DropdownMenuItem(
          value: city,
          child: Text(
            city,
            style: TextStyle(color: Colors.black),
          )));
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _dropDownMenuItems = getDropDownMenuItems();
    _currentItem = _dropDownMenuItems[0].value;
    scrollController.addListener(() {
      if (scrollController.position.maxScrollExtent ==
          scrollController.offset) {
        getProductsByCategory(0);
      }
    });
    header.add(
        textField(widget.categoryName, FontWeight.normal, 0, Colors.white));
    getCategory();
  }

  void getSubCatList(int categoryId, String catName) async {
    setState(() {
      isFilterDataLoading = true;
    });
    if (currentIndex >= 0) {
      _listViewData = [];
      await http
          .get(Settings.SERVER_URL +
              'api/v1/taxonomies/${widget.parentId}/taxons/$categoryId')
          .then((response) {
        responseBody = json.decode(response.body);
        print(responseBody);
        responseBody['taxons'].forEach((category) {
          _listViewData.add(Category(
              id: category['id'],
              name: category['name'],
              parentId: widget.parentId,
              isChecked: false));
        });
      });
    }
    print(_listViewData);
    List<Widget> subCatList = [];
    for (Category cat in _listViewData) {
      print('Data');
      subCatList.add(InkWell(
        onTap: () {
          setState(() {
            cat.isChecked = cat.isChecked ? false : true;
            subCatId = cat.id;
            Navigator.pop(context);
            adjustHeaders(catName, cat.name);
            loadProductsByCategory();
          });
        },
        child: ListTile(
          title: Text(cat.name),
          /*trailing: cat.isChecked
              ? Icon(
                  Icons.radio_button_checked,
                  color: Colors.green,
                )
              : Icon(Icons.radio_button_unchecked),*/
        ),
      ));
      setState(() {
        subCatListForFilter[currentIndex] = subCatList;
        isFilterDataLoading = false;
        // filterDrawer(subCatListForFilter);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _deviceSize = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () => _canLeave(),
      child: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text('Shop'),
            elevation: 0.0,
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  MaterialPageRoute route =
                      MaterialPageRoute(builder: (context) => ProductSearch());
                  Navigator.of(context).push(route);
                },
              ),
              shoppingCartIconButton()
            ],
          ),
          drawer: HomeDrawer(),
          endDrawer: filterDrawer(),
          body: Stack(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 50.0),
                child: !_isLoading ? body(level) : Container(),
              ),
              Container(
                color: Colors.green,
                height: 50.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      margin: EdgeInsets.only(
                        left: 70,
                      ),
                      height: 30.0,
                      alignment: Alignment.centerLeft,
                      child: headerRow(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 50.0),
                child: _isLoading ? LinearProgressIndicator() : Container(),
              ),
              level == 2
                  ? Container(
                      padding: EdgeInsets.only(right: 20.0, top: 15.0),
                      alignment: Alignment.topRight,
                      child: FloatingActionButton(
                        onPressed: () {
                          _scaffoldKey.currentState.openEndDrawer();
                        },
                        child: Icon(
                          Icons.filter_list,
                          color: Colors.white,
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    )
                  : Container(),
            ],
          )),
    );
  }

  Widget filterDrawer() {
    return Drawer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Material(
            elevation: 3.0,
            child: Container(
                alignment: Alignment.centerLeft,
                color: Colors.orange,
                height: 180.0,
                child: ListTile(
                  title: Row(
                    children: <Widget>[
                      Text(
                        'Sort By:  ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18.0),
                      ),
                      DropdownButton(
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold),
                        value: _currentItem,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        items: _dropDownMenuItems,
                        onChanged: changedDropDownItem,
                      )
                    ],
                  ),
                )),
          ),
          Expanded(
            child: Theme(
                data: ThemeData(primarySwatch: Colors.green),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(8.0),
                  separatorBuilder: (context, index) => Divider(
                    color: Colors.grey,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return ExpansionTile(
                        onExpansionChanged: (value) {
                          if (value) {
                            // widget.getSubCat(index);
                            currentIndex = index;
                            getSubCatList(categoryList[index].id,
                                categoryList[index].name);
                          }
                        },
                        title: Text(categoryList[index].name),
                        children: subCatListForFilter[index] != null
                            ? subCatListForFilter[index]
                            : isFilterDataLoading
                                ? progressBar()
                                : subCatListForFilter[index]);
                  },
                  itemCount: categoryList.length,
                )),
          ),
        ],
      ),
    );
  }

  List<Widget> progressBar() {
    List<Widget> progressBar = [];
    progressBar.add(
      CircularProgressIndicator(),
    );
    return progressBar;
  }

  Widget body(int level) {
    switch (level) {
      case 0:
        return GridView.builder(
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
          itemBuilder: (BuildContext context, int index) {
            return getCategoryBox(index, level);
          },
          itemCount: categoryList.length,
        );
        break;
      case 1:
        return GridView.builder(
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
          itemBuilder: (BuildContext context, int index) {
            return getCategoryBox(index, level);
          },
          itemCount: subCategoryList.length,
        );
        break;
      case 2:
        return Theme(
          data: ThemeData(primarySwatch: Colors.green),
          child: ListView.builder(
              controller: scrollController,
              itemCount: productsByCategory.length + 1,
              itemBuilder: (context, index) {
                if (index < productsByCategory.length) {
                  return productContainer(
                      context, productsByCategory[index], index);
                }
                if (hasMore && productsByCategory.length == 0) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 50.0),
                    child: Center(
                      child: Text(
                        'No Product Found',
                        style: TextStyle(fontSize: 20.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!hasMore) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 25.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else {
                  return Container();
                }
              }),
        );
        break;
      default:
        return Container();
    }
  }

  Widget headerRow() {
    return Row(
      children: header,
    );
  }

  Widget textField(
      String text, FontWeight fontWeight, int categoryLevel, Color textColor) {
    int sublevel;

    return GestureDetector(
        onTap: () {
          sublevel = level - categoryLevel;
          setState(() {
            for (int i = 0; i < sublevel; i++) {
              header.removeLast();
            }
            level = level - sublevel;
          });
        },
        child: Text(
          text,
          style:
              TextStyle(color: textColor, fontSize: 18, fontWeight: fontWeight),
        ));
  }

  Widget getCategoryBox(int index, int level) {
    return GestureDetector(
        onTap: () {
          if (level == 0) {
            getSubCategory(categoryList[index].id);
            setState(() {
              header.add(textField(' > ' + categoryList[index].name,
                  FontWeight.normal, 1, Colors.white));
            });
          } else {
            subCatId = subCategoryList[index].id;
            loadProductsByCategory();
            setState(() {
              header.add(textField(' > ' + subCategoryList[index].name,
                  FontWeight.normal, 2, Colors.white));
            });
          }
        },
        child: Container(
          alignment: Alignment.center,
          margin: EdgeInsets.all(10.0),
          padding: EdgeInsets.all(10),
          width: _deviceSize.width * 0.4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorList[index],
          ),
          child: Text(
            level == 0 ? categoryList[index].name : subCategoryList[index].name,
            style: TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ));
  }

  void adjustHeaders(String catName, String subCatName) {
    setState(() {
      header.removeLast();
      header.removeLast();
      header
          .add(textField(' > ' + catName, FontWeight.normal, 1, Colors.white));
      header.add(
          textField(' > ' + subCatName, FontWeight.normal, 2, Colors.white));
    });
  }

  getCategory() {
    categoryList = [];
    http
        .get(Settings.SERVER_URL +
            'api/v1/taxonomies/${widget.parentId}/taxons/${widget.categoryId}')
        .then((response) {
      responseBody = json.decode(response.body);
      responseBody['taxons'].forEach((category) {
        categoryList.add(Category(
            id: category['id'],
            name: category['name'],
            parentId: widget.parentId));
      });
      //print(Settings.SERVER_URL + 'api/v1/taxonomies/${widget.parentId}/taxons/${widget.categoryId}');
      setState(() {
        _isLoading = false;
        level = 0;
      });
    });
  }

  getSubCategory(int categoryId) {
    setState(() {
      _isLoading = true;
      subCategoryList = [];
    });
    http
        .get(Settings.SERVER_URL +
            'api/v1/taxonomies/${widget.parentId}/taxons/$categoryId')
        .then((response) {
      responseBody = json.decode(response.body);
      print(responseBody);
      responseBody['taxons'].forEach((category) {
        subCategoryList.add(Category(
            id: category['id'],
            name: category['name'],
            parentId: widget.parentId));
      });
      setState(() {
        level = 1;
        _isLoading = false;
      });
    });
  }

  void getProductsByCategory(int id, [String sortBy]) async {
    List<Product> variants = [];
    List<OptionValue> optionValues = [];
    List<OptionType> optionTypes = [];

    setState(() {
      hasMore = false;
    });
    var response;
    print(sortBy);
    if (sortBy != null) {
      response = (await http.get(Settings.SERVER_URL +
              'api/v1/taxons/products?id=$subCatId&page=$currentPage&per_page=$perPage&q[s]=$sortBy&data_set=small'))
          .body;
    } else {
      response = (await http.get(Settings.SERVER_URL +
              'api/v1/taxons/products?id=$subCatId&page=$currentPage&per_page=$perPage&data_set=small'))
          .body;
    }

    currentPage++;
    responseBody = json.decode(response);
    print(responseBody);
    responseBody['products'].forEach((product) {
      int review_product_id = product["id"];
      variants = [];
      if (product['has_variants']) {
        product['variants'].forEach((variant) {
          optionValues = [];
          optionTypes = [];
          variant['option_values'].forEach((option) {
            optionValues.add(OptionValue(
              id: option['id'],
              name: option['name'],
              optionTypeId: option['option_type_id'],
              optionTypeName: option['option_type_name'],
              optionTypePresentation: option['option_type_presentation'],
            ));
          });

          variants.add(Product(
              id: variant['id'],
              name: variant['name'],
              description: variant['description'],
              optionValues: optionValues,
              displayPrice: variant['display_price'],
              image: variant['images'][0]['product_url'],
              isOrderable: variant['is_orderable'],
              avgRating: double.parse(product['avg_rating']),
              reviewsCount: product['reviews_count'].toString(),
              reviewProductId: review_product_id));
        });
        product['option_types'].forEach((optionType) {
          optionTypes.add(OptionType(
              id: optionType['id'],
              name: optionType['name'],
              position: optionType['position'],
              presentation: optionType['presentation']));
        });

        productsByCategory.add(Product(
            taxonId: product['taxon_ids'].first,
            id: product['id'],
            name: product['name'],
            displayPrice: product['display_price'],
            avgRating: double.parse(product['avg_rating']),
            reviewsCount: product['reviews_count'].toString(),
            image: product['master']['images'][0]['product_url'],
            variants: variants,
            reviewProductId: review_product_id,
            hasVariants: product['has_variants'],
            optionTypes: optionTypes));
      } else {
        productsByCategory.add(Product(
          taxonId: product['taxon_ids'].first,
          id: product['id'],
          name: product['name'],
          displayPrice: product['display_price'],
          avgRating: double.parse(product['avg_rating']),
          reviewsCount: product['reviews_count'].toString(),
          image: product['master']['images'][0]['product_url'],
          hasVariants: product['has_variants'],
          isOrderable: product['master']['is_orderable'],
          reviewProductId: review_product_id,
          description: product['description'],
        ));
      }
    });
    setState(() {
      hasMore = true;
    });
  }

  void loadProductsByCategory([String sortBy]) {
    setState(() {
      currentPage = ZERO;
      productsByCategory = [];

      sortBy != null
          ? getProductsByCategory(0, sortBy)
          : getProductsByCategory(0);
      level = 2;
      _isLoading = false;
    });
  }

  Future<bool> _canLeave() {
    if (level == 0) {
      return Future<bool>.value(true);
    } else {
      setState(() {
        level = level - 1;
        header.removeLast();
      });
      return Future<bool>.value(false);
    }
  }

  void changedDropDownItem(String selectedCity) {
    String sortingWith = '';
    setState(() {
      _currentItem = selectedCity;
      switch (_currentItem) {
        case 'Newest':
          sortingWith = 'updated_at+asc';
          break;
        case 'Avg.Customer Review':
          sortingWith = 'avg_rating+desc ';
          break;
        case 'Most Reviews':
          sortingWith = 'reviews_count+desc';
          break;
        case 'A TO Z':
          sortingWith = 'name+asc';
          break;
        case 'Z TO A':
          sortingWith = 'name+desc';
          break;
      }

      loadProductsByCategory(sortingWith);
    });
  }
}
