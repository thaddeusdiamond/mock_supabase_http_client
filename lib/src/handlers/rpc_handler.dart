import 'dart:convert';

import 'package:http/http.dart';

/// Handles RPC (Remote Procedure Call) operations for the mock Supabase client
class RpcHandler {
  final Map<
      String,
      dynamic Function(Map<String, dynamic>? params,
          Map<String, List<Map<String, dynamic>>> tables)> _rpcFunctions;
  final Map<String, List<Map<String, dynamic>>> _database;

  RpcHandler(this._rpcFunctions, this._database);

  /// Handles an RPC call
  ///
  /// [functionName] The name of the RPC function to call
  /// [request] The original HTTP request
  /// [body] The parsed request body containing parameters
  StreamedResponse handleRpc(
    String functionName,
    BaseRequest request,
    dynamic body,
  ) {
    if (!_rpcFunctions.containsKey(functionName)) {
      return _createResponse(
        {'error': 'RPC function not found'},
        statusCode: 404,
        request: request,
      );
    }

    final function = _rpcFunctions[functionName]!;

    try {
      final result = function(body, _database);
      return _createResponse(result, request: request);
    } catch (e) {
      return _createResponse(
        {'error': 'RPC function execution failed: $e'},
        statusCode: 500,
        request: request,
      );
    }
  }

  /// Creates a StreamedResponse with the given data and headers
  StreamedResponse _createResponse(
    dynamic data, {
    int statusCode = 200,
    required BaseRequest request,
    Map<String, String>? headers,
  }) {
    final responseHeaders = {
      'content-type': 'application/json; charset=utf-8',
      ...?headers,
    };

    return StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(data))),
      statusCode,
      headers: responseHeaders,
      request: request,
    );
  }

  /// Registers a new RPC function
  ///
  /// [name] The name of the function to register
  /// [function] The function implementation
  void registerFunction(
    String name,
    dynamic Function(Map<String, dynamic>? params,
            Map<String, List<Map<String, dynamic>>> tables)
        function,
  ) {
    _rpcFunctions[name] = function;
  }

  /// Clears all registered RPC functions
  void reset() {
    _rpcFunctions.clear();
  }
}
