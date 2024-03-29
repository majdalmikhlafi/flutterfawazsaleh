import 'package:flutter/material.dart';
import 'package:flutter_ecomarce/models/category.dart';
import 'package:flutter_ecomarce/screens/brandslisting.dart';
import 'package:flutter_ecomarce/screens/categorylisting.dart';
import 'package:flutter_ecomarce/utils/color_list.dart';

Widget categoryBox(int index, BuildContext context, Size _deviceSize,
    List<Category> categories) {
  if (index > 4) {
    return GestureDetector(
        onTap: () {
          MaterialPageRoute route =
              MaterialPageRoute(builder: (context) => BrandList());
          Navigator.push(context, route);
        },
        child: Container(
            margin: EdgeInsets.all(10.0),
            width: _deviceSize.width * 0.4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: colorList[index],
            ),
            child: Stack(children: [
              Container(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Shop By Brand',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          Text('A-Z',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600)),
                        ]),
                  )),
            ])));
  }
  return GestureDetector(
      onTap: () {
        MaterialPageRoute route = MaterialPageRoute(
            builder: (context) => CategoryListing(categories[index].name,
                categories[index].id, categories[index].parentId));
        Navigator.push(context, route);
      },
      child: Container(
          margin: EdgeInsets.all(10.0),
          width: _deviceSize.width * 0.4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: colorList[index],
          ),
          child: Stack(children: [
            Container(
                alignment: Alignment.bottomRight,
                child: ClipRRect(
                  child: Image.network(categories[index].image),
                  borderRadius: BorderRadius.circular(12),
                )),
            Container(
              padding: EdgeInsets.only(left: 10, top: 10),
              child: Text(
                categories[index].name,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ])));
}
