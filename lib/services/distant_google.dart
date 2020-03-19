import 'dart:async';
import 'dart:core';

import 'package:dio/dio.dart';
import 'package:geocoder/model.dart';
import 'package:geocoder/services/base.dart';

/// Geocoding and reverse geocoding through requests to Google APIs.
class GoogleGeocoding implements Geocoding {

  static const _host = 'https://maps.google.com/maps/api/geocode/json';

  final String apiKey;
  final String language;

  final Dio _dio;

  GoogleGeocoding(this.apiKey, { this.language }) :
    _dio = Dio(),
    assert(apiKey != null, "apiKey must not be null");

  Future<List<Address>> findAddressesFromCoordinates(Coordinates coordinates) async  {
    final url = '$_host?key=$apiKey${language != null ? '&language='+language : ''}&latlng=${coordinates.latitude},${coordinates.longitude}';
    return _send(url);
  }

  Future<List<Address>> findAddressesFromQuery(String address) async {
    var encoded = Uri.encodeComponent(address);
    final url = '$_host?key=$apiKey&address=$encoded';
    return _send(url);
  }

  Future<List<Address>> _send(String url) async {
    final uri = Uri.parse(url);
    final response = await _dio.getUri(uri);
    var data = response.data;

    var results = data["results"];

    if(results == null)
      return null;

    return results.map(_convertAddress)
                  .map<Address>((map) => Address.fromMap(map))
                  .toList();
  }

  Map _convertCoordinates(dynamic geometry) {
    if(geometry == null)
      return null;

    var location = geometry["location"];
    if(location == null)
      return null;

    return {
      "latitude" : location["lat"],
      "longitude" : location["lng"],
    };
  }

  Map _convertAddress(dynamic data) {

    Map result = Map();

    result["coordinates"] = _convertCoordinates(data["geometry"]);
    result["addressLine"] = data["formatted_address"];

    var addressComponents = data["address_components"];

    addressComponents.forEach((item) {

      List types = item["types"];

      if(types.contains("route")) {

        result["thoroughfare"] = item["long_name"];
      }
      else if(types.contains("street_number")) {

        result["subThoroughfare"] = item["long_name"];
      }
      else if(types.contains("country")) {
        result["countryName"] = item["long_name"];
        result["countryCode"] = item["short_name"];
      }
      else if(types.contains("locality")) {
        result["locality"] = item["long_name"];
      }
      else if(types.contains("postal_code")) {
        result["postalCode"] = item["long_name"];
      }
      else if(types.contains("postal_code")) {
        result["postalCode"] = item["long_name"];
      }
      else if(types.contains("administrative_area_level_1")) {
        result["adminArea"] = item["long_name"];
      }
      else if(types.contains("administrative_area_level_2")) {
        result["subAdminArea"] = item["long_name"];
      }
      else if(types.contains("sublocality") || types.contains("sublocality_level_1")) {
        result["subLocality"] = item["long_name"];
      }
      else if(types.contains("premise")) {
        result["featureName"] = item["long_name"];
      }

      result["featureName"] = result["featureName"] ?? result["addressLine"];

    });

    return result;
  }
}
