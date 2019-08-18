import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_ecomarce/models/option_type.dart';
import 'package:flutter_ecomarce/models/option_value.dart';
import 'package:flutter_ecomarce/models/product.dart';
import 'package:flutter_ecomarce/models/review.dart';
import 'package:flutter_ecomarce/scoped-models/main.dart';
import 'package:flutter_ecomarce/screens/auth.dart';
import 'package:flutter_ecomarce/screens/review_detail.dart';
import 'package:flutter_ecomarce/screens/search.dart';
import 'package:flutter_ecomarce/utils/constants.dart';
import 'package:flutter_ecomarce/utils/headers.dart';
import 'package:flutter_ecomarce/widgets/rating_bar.dart';
import 'package:flutter_ecomarce/widgets/shopping_cart_button.dart';
import 'package:flutter_ecomarce/widgets/similar_products_card.dart';
import 'package:flutter_ecomarce/widgets/snackbar.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  ProductDetailScreen(this.product);
  @override
  State<StatefulWidget> createState() {
    return _ProductDetailScreenState();
  }
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  TabController _tabController;
  Size _deviceSize;
  int quantity = 1;
  double _rating;
  Product selectedProduct;
  bool _hasVariants = false;
  List<Review> reviews = [];
  int total_reviews = 0;
  double recommended_percent = 0;
  double avg_rating = 0;
  String htmlDescription;
  List<Product> similarProducts = List();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    if (widget.product.hasVariants != null) {
      if (widget.product.hasVariants) {
        _hasVariants = widget.product.hasVariants;
        selectedProduct = widget.product.variants.first;
        htmlDescription = widget.product.variants.first.description != null
            ? widget.product.variants.first.description
            : '';
      } else {
        selectedProduct = widget.product;
        htmlDescription = widget.product.description != null
            ? widget.product.description
            : '';
      }
    } else {
      selectedProduct = widget.product;
      htmlDescription =
          widget.product.description != null ? widget.product.description : '';
    }
    get_reviews();
    getSimilarProducts();
    super.initState();
  }

  get_reviews() {
    Map<dynamic, dynamic> responseBody;
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'token-type': 'Bearer',
      'ng-api': 'true',
    };
    reviews = [];
    String url = Settings.SERVER_URL +
        "products/${selectedProduct.reviewProductId}/reviews";
    http.get(url, headers: headers).then((response) {
      responseBody = json.decode(response.body);
      double total = 0;
      double total_given_rating = 0;
      responseBody['rating_summery'].forEach((rating) {
        if (rating['percentage'] != null) {
          total += rating["percentage"];
        }
        total_given_rating += rating['rating'] * rating['count'];
      });
      total_reviews = responseBody['total_ratings'];
      if (total_reviews > 0) {
        avg_rating = (total_given_rating / total_reviews);
      }
      recommended_percent = total;
      responseBody['reviews'].forEach((review) {
        reviews.add(Review(
            id: review['id'],
            name: review['name'],
            title: review['title'],
            review: review['review'],
            rating: review['rating'].toDouble(),
            approved: review['approved'],
            created_at: review['created_at'],
            updated_at: review['updated_at']));
      });
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    _deviceSize = MediaQuery.of(context).size;
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Item Details'),
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
          bottom: TabBar(
            controller: _tabController,
            tabs: <Widget>[
              Tab(
                text: 'HIGHLIGHTS',
              ),
              Tab(
                text: 'REVIEWS',
              )
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[highlightsTab(), reviewsTab()],
        ),
        floatingActionButton: addToCartFAB());
  }

  Widget reviewsTab() {
    if (reviews.length == 0) {
      return Container(
          alignment: Alignment.center,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 10,
              ),
              writeReview(),
              Container(
                height: 400,
                alignment: Alignment.center,
                child: Text("No Reviews found"),
              )
            ],
          ));
    }
    return ListView.builder(
      itemCount: reviews.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return rating_summary(avg_rating, recommended_percent, total_reviews);
        }
        return review(reviews[index - 1]);
      },
    );
  }

  Widget rating_summary(rating, recommended_percent, total_reviews) {
    return Card(
      elevation: 2.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: Colors.orange),
                          child: Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 17.0,
                                fontWeight: FontWeight.w300),
                          ),
                        ),
                        ratingBar(rating, 14)
                      ],
                    )),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text("${total_reviews} Customer Reviews",
                          style: TextStyle(
                              fontSize: 12.0, fontWeight: FontWeight.w400)),
                      Text(
                          "Recommended by ${recommended_percent}% of reviewers",
                          style: TextStyle(
                              fontSize: 15.0, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              ],
            ),
            SizedBox(
              height: 15,
            ),
            writeReview(),
          ],
        ),
      ),
    );
  }

  Widget writeReview() {
    return ScopedModelDescendant<MainModel>(
        builder: (BuildContext context, Widget child, MainModel model) {
      return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 40.0,
              width: 335,
              child: GestureDetector(
                onTap: () {
                  if (model.isAuthenticated) {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            ReviewDetailScreen(selectedProduct)));
                  } else {
                    // Scaffold.of(context).showSnackBar(LoginErroSnackbar);
                    _scaffoldKey.currentState.showSnackBar(SnackBar(
                      content: Text(
                        'Please Login Review',
                      ),
                      action: SnackBarAction(
                        label: 'LOGIN',
                        onPressed: () {
                          MaterialPageRoute route = MaterialPageRoute(
                              builder: (context) => Authentication(0));
                          Navigator.push(context, route);
                        },
                      ),
                    ));
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green,
                      style: BorderStyle.solid,
                      width: 1.0,
                    ),
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Center(
                        child: Text(
                          "WRITE A REVIEW",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ]);
    });
  }

  Widget review(Review review) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: Colors.orange),
                  child: Text(
                    review.rating.toString(),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w300),
                  ),
                ),
                ratingBar(review.rating, 12)
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.only(bottom: 12.0),
              decoration: BoxDecoration(
                  border: Border(
                      bottom:
                          BorderSide(color: Color(0xFFDCDCDC), width: 0.7))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Text(review.title,
                        style: TextStyle(
                            fontSize: 15.0, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Text(getReviewByText(review),
                        style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey)),
                  ),
                  Text(review.review,
                      style: TextStyle(
                          fontSize: 15.0, fontWeight: FontWeight.w300))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  String getReviewByText(Review review) {
    RegExp exp = new RegExp(r"([^@]+)");
    var now = DateTime.parse(review.created_at);
    var formatter = new DateFormat('MMM d y');

    return "By ${exp.firstMatch(review.name).group(0)} - ${formatter.format(now)}";
  }

  Widget variantRow() {
    if (widget.product.hasVariants != null) {
      if (widget.product.hasVariants) {
        List<Widget> optionValueNames = [];
        List<Widget> optionTypeNames = [];
        widget.product.optionTypes.forEach((optionType) {
          optionTypeNames.add(Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.all(10),
              child: Text(optionType.name)));
        });
        widget.product.variants.forEach((variant) {
          variant.optionValues.forEach((optionValue) {
            optionValueNames.add(GestureDetector(
                onTap: () {
                  setState(() {
                    widget.product.variants.forEach((variant) {
                      if (variant.optionValues[0] == optionValue) {
                        setState(() {
                          selectedProduct = variant;
                        });
                      }
                    });
                  });
                },
                child: Container(
                    decoration: BoxDecoration(
                        border: Border.all(
                      color: selectedProduct.optionValues[0].name ==
                              optionValue.name
                          ? Colors.green
                          : Colors.black,
                    )),
                    alignment: Alignment.centerLeft,
                    margin: EdgeInsets.all(10),
                    padding: EdgeInsets.all(10),
                    child: Text(
                      optionValue.name,
                      style: TextStyle(
                          color: selectedProduct.optionValues[0].name ==
                                  optionValue.name
                              ? Colors.green
                              : Colors.black),
                    ))));
          });
        });
        return Container(
          height: 60.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: optionValueNames,
          ),
        );
        /*return ListView.builder(
          shrinkWrap: true,
          itemCount: 1,
          itemBuilder: (context, index) {
            return Container(
              height: 60.0,
              child: Column(children: [
                optionTypeNames[index],
                SingleChildScrollView(
                    child: ListView(

                  shrinkWrap: true,
                  children: <Widget>[
                    Row(children: optionValueNames),
                  ],
                ))
              ]),
            );
          },
        );*/
      } else {
        return Container();
      }
    } else {
      return Container();
    }
  }

  Widget highlightsTab() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          Container(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    height: 300,
                    child: FadeInImage(
                      image: NetworkImage(selectedProduct.image),
                      placeholder: AssetImage(
                          'images/placeholders/no-product-image.png'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Container(
            width: _deviceSize.width,
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Text(
                    'by ${selectedProduct.name.split(' ')[0]}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.normal,
                        color: Colors.green),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    padding: EdgeInsets.all(10),
                    alignment: Alignment.topRight,
                    icon: Icon(Icons.favorite),
                    color: Colors.orange,
                    onPressed: () async {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      String authToken = prefs.getString('spreeApiKey');

                      if (authToken == null) {
                        _scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text(
                            'Please Login to add to Favorites',
                          ),
                          action: SnackBarAction(
                            label: 'LOGIN',
                            onPressed: () {
                              MaterialPageRoute route = MaterialPageRoute(
                                  builder: (context) => Authentication(0));
                              Navigator.push(context, route);
                            },
                          ),
                        ));
                      } else {
                        _scaffoldKey.currentState.showSnackBar(SnackBar(
                          content: Text(
                            'Adding to Favorites, please wait.',
                          ),
                          duration: Duration(seconds: 1),
                        ));
                        Map<String, String> headers = await getHeaders();
                        http
                            .post(Settings.SERVER_URL + 'favorite_products',
                                body: json.encode({
                                  'id':
                                      widget.product.reviewProductId.toString()
                                }),
                                headers: headers)
                            .then((response) {
                          Map<dynamic, dynamic> responseBody =
                              json.decode(response.body);

                          _scaffoldKey.currentState.showSnackBar(SnackBar(
                            content: Text(responseBody['message']),
                            duration: Duration(seconds: 1),
                          ));
                        });
                      }
                    },
                  ),
                ),
                ratingBar(selectedProduct.avgRating, 20),
                Container(
                    margin: EdgeInsets.only(right: 10),
                    child: Text(selectedProduct.reviewsCount)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(10),
            child: Text(
              selectedProduct.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          variantRow(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
                child: Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.all(10),
              child: Text(
                'Quantity: ',
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            )),
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () {
                if (quantity > 1) {
                  setState(() {
                    quantity = quantity - 1;
                  });
                }
              },
            ),
            Text(quantity.toString()),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                setState(() {
                  quantity = quantity + 1;
                });
              },
            ),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.all(10),
                child: Text(
                  'Price :',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.all(10),
                child: Text(
                  selectedProduct.displayPrice,
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.red,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          addToCartFlatButton(),
          Container(
              padding: EdgeInsets.only(left: 8.0, top: 8.0),
              alignment: Alignment.centerLeft,
              child: Text("Description",
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15.0))),
          HtmlWidget(htmlDescription),
          Container(
              width: _deviceSize.width,
              color: Colors.white,
              child: ListTile(
                /* dense: true,
                leading: Icon(
                  Icons.shop,
                  color: Colors.green,
                ),*/
                title: Text('Similar Products',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black)),
              )),
          _isLoading
              ? Container(
                  height: _deviceSize.height * 0.47,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.blue,
                  ),
                )
              : Container(
                  height: _deviceSize.height * 0.5,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: similarProducts.length,
                    itemBuilder: (context, index) {
                      return similarProductCard(
                          index, similarProducts, _deviceSize, context);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget addToCartFlatButton() {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0),
          child: Container(
            width: double.infinity,
            height: 45.0,
            child: FlatButton(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color:
                      selectedProduct.isOrderable ? Colors.green : Colors.grey,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                selectedProduct.isOrderable ? 'ADD TO CART' : 'OUT OF STOCK',
                style: TextStyle(
                    color: selectedProduct.isOrderable
                        ? Colors.green
                        : Colors.grey),
              ),
              onPressed: () {
                Scaffold.of(context).showSnackBar(processSnackbar);
                if (selectedProduct.isOrderable) {
                  model.addProduct(
                      variantId: selectedProduct.id, quantity: quantity);
                }
                if (!model.isLoading) {
                  Scaffold.of(context).showSnackBar(completeSnackbar);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget addToCartFAB() {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        return _tabController.index == 0
            ? FloatingActionButton(
                child: Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                ),
                onPressed: () {
                  Scaffold.of(context).showSnackBar(processSnackbar);
                  selectedProduct.isOrderable
                      ? model.addProduct(
                          variantId: selectedProduct.id, quantity: quantity)
                      : null;
                  if (!model.isLoading) {
                    Scaffold.of(context).showSnackBar(completeSnackbar);
                  }
                },
                backgroundColor:
                    selectedProduct.isOrderable ? Colors.orange : Colors.grey,
              )
            : FloatingActionButton(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
                onPressed: () {
                  if (model.isAuthenticated) {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) =>
                            ReviewDetailScreen(selectedProduct)));
                  } else {
                    Scaffold.of(context).showSnackBar(LoginErroSnackbar);
                  }
                },
                backgroundColor: Colors.orange);
      },
    );
  }

//  return ScopedModelDescendant<MainModel>(
//       builder: (BuildContext context, Widget child, MainModel model) {
//         return FloatingActionButton(
//           child: Icon(
//             Icons.shopping_cart,
//             color: Colors.white,
//           ),
//           onPressed: () {
//             Scaffold.of(context).showSnackBar(processSnackbar);
//             selectedProduct.isOrderable
//                 ? model.addProduct(
//                 variantId: selectedProduct.id, quantity: quantity)
//                 : null;
//             if (!model.isLoading) {
//               Scaffold.of(context).showSnackBar(completeSnackbar);
//             }
//           },
//           backgroundColor:
//           selectedProduct.isOrderable ? Colors.orange : Colors.grey,
//         );
//       },
//     );
//   }

  getSimilarProducts() {
    Map<String, dynamic> responseBody = Map();
    List<Product> variants = [];
    List<OptionValue> optionValues = [];
    List<OptionType> optionTypes = [];
    http
        .get(Settings.SERVER_URL +
            'api/v1/taxons/products?id=${widget.product.taxonId}&per_page=15&data_set=small')
        .then((response) {
      responseBody = json.decode(response.body);
      responseBody['products'].forEach((product) {
        int review_product_id = product["id"];
        variants = [];
        if (product['has_variants']) {
          product['variants'].forEach((variant) {
            optionValues = [];
            optionTypes = [];
            variant['option_values'].forEach((option) {
              setState(() {
                optionValues.add(OptionValue(
                  id: option['id'],
                  name: option['name'],
                  optionTypeId: option['option_type_id'],
                  optionTypeName: option['option_type_name'],
                  optionTypePresentation: option['option_type_presentation'],
                ));
              });
            });
            setState(() {
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
          });
          product['option_types'].forEach((optionType) {
            setState(() {
              optionTypes.add(OptionType(
                  id: optionType['id'],
                  name: optionType['name'],
                  position: optionType['position'],
                  presentation: optionType['presentation']));
            });
          });
          setState(() {
            similarProducts.add(Product(
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
          });
        } else {
          setState(() {
            similarProducts.add(Product(
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
          });
        }
      });
      setState(() {
        _isLoading = false;
      });
    });
  }
}
