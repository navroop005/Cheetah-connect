import 'dart:convert';
import 'dart:io';

import 'package:cheetah_connect/control/connection.dart';
import 'package:cheetah_connect/control/details.dart';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:http/http.dart' as http;

int httpPort = 8004;

class PairServer {
  static HttpServer? _server;

  static Future<Response> _pair(Request request) async {
    if (_server != null) {
      try {
        String body = await request.readAsString();
        Map<String, String> map = Map<String, String>.from(jsonDecode(body));
        debugPrint('Connection request: $map');
        bool accepted = await Connection.handlePair(
          DeviceDetail(
            map['name']!,
            map['IPv4']!,
            map['IPv6'],
            map['os']!,
          ),
          map['passKey']!,
        );
        if (accepted) {
          return Response.ok('Connected');
        } else {
          return Response.forbidden('Connection rejected');
        }
      } catch (e) {
        debugPrint('Error: $e');
        return Response.badRequest();
      }
    } else {
      return Response.forbidden('Not accepting connections');
    }
  }

  static Future<Response> _handler(Request request) async {
    if (request.url.path == 'pair') {
      return _pair(request);
    } else {}
    return Response.badRequest();
  }

  static void start() async {
    if (!(_server != null)) {
      final ip = InternetAddress.anyIPv4;

      const port = 8004;
      _server = await serve(_handler, ip, port);

      debugPrint('Server listening on port ${_server?.port}');
    } else {
      debugPrint('Server already running');
    }
  }

  static void stop() async {
    if (_server != null) {
      await _server?.close();
      _server = null;
      debugPrint('Server stopped');
    }
  }
}

class PairRequest {
  static Future<bool> pair(
      String ipOther, DeviceDetail detail, String passKey) async {
    Uri uri = Uri.http('$ipOther:$httpPort', 'pair');
    String body = jsonEncode({
      'name': detail.name,
      'os': detail.os,
      'IPv4': detail.ipv4,
      'passKey': passKey,
    });
    var response = await http.post(uri, body: body);
    return response.statusCode == 200;
  }
}
