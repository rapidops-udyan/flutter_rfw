import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;

class API {
  final Dio _dio = Dio();
  final String _defaultImagePath = 'assets/default.png';

  Future<Uint8List> fetchImage(String url) async {
    final String requestUrl = 'https://logo.clearbit.com/$url';

    try {
      Response response = await _dio.get(
        requestUrl,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );
      return response.data;
    } catch (e) {
      return await _loadDefaultImage();
    }
  }

  Future<Uint8List> _loadDefaultImage() async {
    final ByteData data = await rootBundle.load(_defaultImagePath);
    return data.buffer.asUint8List();
  }
}
