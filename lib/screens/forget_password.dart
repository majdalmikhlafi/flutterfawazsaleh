import 'package:flutter/material.dart';
import 'package:flutter_ecomarce/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgetPassword extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ForgetPasswordState();
  }
}

class _ForgetPasswordState extends State<ForgetPassword>
    with SingleTickerProviderStateMixin {
  final Map<String, dynamic> _formData = {'email': null};
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoader = false;

  @override
  Widget build(BuildContext context) {
    Size _deviceSize = MediaQuery.of(context).size;
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double targetWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green.shade300,
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop();
              }
            ),
            title: Text(
              'fawaz',
              style: TextStyle(fontFamily: 'HolyFat', fontSize: 50),
            ),
            bottom: PreferredSize(
              preferredSize: Size(_deviceSize.width, 50),
              child: Column(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.all(10),
                    child: Text("FORGET PASSWORD",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20
                      ),
                    )
                  )
                ],
              )
            )
          ),
          body: SingleChildScrollView(
            child: Container(
              width: targetWidth,
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 20.0,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                          labelText: 'E-Mail', filled: true, fillColor: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      validator: (String value) {
                        if (value.isEmpty ||
                            !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
                                .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                      },
                      onSaved: (String value) {
                        _formData['email'] = value;
                      },
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    _isLoader
                        ? CircularProgressIndicator(
                            backgroundColor: Colors.green.shade300)
                        : RaisedButton(
                            textColor: Colors.white,
                            color: Colors.green.shade300,
                            child: Text('SEND MAIL'),
                            onPressed: () => _submitFogetPassword(),
                          ),
                    SizedBox(
                      height: 20.0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitFogetPassword() async {
    setState(() {
      _isLoader = true;
    });
    if (!_formKey.currentState.validate()) {
      setState(() {
        _isLoader = false;
      });
      return;
    }
    _formKey.currentState.save();
    final Map<String, dynamic> authData = {
      "spree_user": {
        'email': _formData['email'],
      }
    };

    final http.Response response = await http.post(
      Settings.SERVER_URL + 'auth/passwords',
      body: json.encode(authData),
      headers: {'Content-Type': 'application/json'},
    );

    final Map<String, dynamic> responseData = json.decode(response.body);
    String message = 'Something went wrong.';
    bool hasError = true;

    if (responseData.containsKey('id')) {
      message = 'Password reset successfully. Please check register mail.';
      hasError = false;
    } else if (responseData.containsKey('error')) {
      message = "Email does not exist.";
    }

    final Map<String, dynamic> successInformation = {
      'success': !hasError,
      'message': message
    };
    if (successInformation['success']) {
      Navigator.of(context).pop();
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return _alertDialog('Success!', successInformation['message']);
          });
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return _alertDialog(
                'An Error Occurred!', successInformation['message']);
          });
    }
    setState(() {
      _isLoader = false;
    });
  }

  Widget _alertDialog(String boxTitle, String message) {
    return AlertDialog(
      title: Text(boxTitle),
      content: Text(message),
      actions: <Widget>[
        FlatButton(
          child: Text('Okay',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.green.shade300)),
          onPressed: () {
            //Navigator.of(context).pop();
          },
        )
      ],
    );
  }
}
