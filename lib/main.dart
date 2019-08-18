import 'package:flutter/material.dart';
import 'package:flutter_ecomarce/scoped-models/main.dart';
import 'package:flutter_ecomarce/screens/home.dart';
import 'package:scoped_model/scoped_model.dart';

import 'package:flutter_ecomarce/screens/home.dart';
import 'package:flutter_ecomarce/scoped-models/main.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  final MainModel _model = MainModel();
  // This widget is the root of your application.

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  final MainModel _model = MainModel();

  @override
  void initState() {
    _model.loggedInUser();
    _model.fetchCurrentOrder();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModel<MainModel>(
      model: _model,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.green,
          accentColor: Colors.white,
        ),
        home: HomeScreen(),
      ),
    );
  }
}
