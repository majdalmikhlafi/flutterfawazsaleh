import 'dart:convert';


import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ecomarce/utils/constants.dart';
import 'package:flutter_ecomarce/utils/headers.dart';

import 'package:http/http.dart' as http;

import 'dart:io';

getParams() async {
  print("GETTTING PARAMS");
  Map<String, dynamic> urlResponse;
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String surl = '${Settings.SERVER_URL}payment/handle_payubiz';
  String furl = '${Settings.SERVER_URL}payment/canceled_payubiz';

  Map<String, String> headers = await getHeaders();

  Map<String, dynamic> params = {
    'params': {
      'surl': surl,
      'furl': furl,
      'order_number': prefs.getString('orderNumber'),
      'ismobileview': true
    }
  };
  http.Response response = await http.post(
      Settings.SERVER_URL + 'payment/post_request_payubiz',
      body: json.encode(params),
      headers: headers);

  urlResponse = json.decode(response.body);
  return urlResponse['url'];
}
