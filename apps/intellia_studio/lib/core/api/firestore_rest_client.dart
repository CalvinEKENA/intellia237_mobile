import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/auth/domain/auth_session.dart';

class FirestoreDocument {
  const FirestoreDocument({
    required this.name,
    required this.fields,
    this.createTime,
    this.updateTime,
  });

  final String name;
  final Map<String, dynamic> fields;
  final DateTime? createTime;
  final DateTime? updateTime;

  String get id => name.split('/').last;

  dynamic operator [](String key) => fields[key];

  factory FirestoreDocument.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'] as Map<String, dynamic>? ?? {};
    final fields = rawFields.map(
      (k, v) => MapEntry(
        k,
        FirestoreValueCodec.decodeValue(v as Map<String, dynamic>),
      ),
    );
    return FirestoreDocument(
      name: json['name'] as String? ?? '',
      fields: fields,
      createTime: json['createTime'] != null
          ? DateTime.tryParse(json['createTime'] as String)
          : null,
      updateTime: json['updateTime'] != null
          ? DateTime.tryParse(json['updateTime'] as String)
          : null,
    );
  }
}

class FirestoreValueCodec {
  static dynamic decodeValue(Map<String, dynamic> json) {
    if (json.containsKey('stringValue')) return json['stringValue'];
    if (json.containsKey('integerValue'))
      return int.tryParse(json['integerValue'].toString()) ?? 0;
    if (json.containsKey('doubleValue'))
      return (json['doubleValue'] as num).toDouble();
    if (json.containsKey('booleanValue')) return json['booleanValue'] as bool;
    if (json.containsKey('timestampValue')) return json['timestampValue'];
    if (json.containsKey('nullValue')) return null;
    if (json.containsKey('arrayValue')) {
      final values =
          (json['arrayValue'] as Map<String, dynamic>)['values']
              as List<dynamic>? ??
          [];
      return values.map((e) => decodeValue(e as Map<String, dynamic>)).toList();
    }
    if (json.containsKey('mapValue')) {
      final fields =
          (json['mapValue'] as Map<String, dynamic>)['fields']
              as Map<String, dynamic>? ??
          {};
      return fields.map(
        (k, v) => MapEntry(k, decodeValue(v as Map<String, dynamic>)),
      );
    }
    return null;
  }

  static Map<String, dynamic> encodeValue(dynamic value) {
    if (value == null) return {'nullValue': null};
    if (value is bool) return {'booleanValue': value};
    if (value is int) return {'integerValue': value.toString()};
    if (value is double) return {'doubleValue': value};
    if (value is String) return {'stringValue': value};
    if (value is DateTime)
      return {'timestampValue': value.toUtc().toIso8601String()};
    if (value is List) {
      return {
        'arrayValue': {'values': value.map(encodeValue).toList()},
      };
    }
    if (value is Map<String, dynamic>) {
      return {
        'mapValue': {
          'fields': value.map((k, v) => MapEntry(k, encodeValue(v))),
        },
      };
    }
    return {'stringValue': value.toString()};
  }

  static Map<String, dynamic> encodeFields(Map<String, dynamic> data) {
    return data.map((k, v) => MapEntry(k, encodeValue(v)));
  }
}

class FirestoreRestClient {
  FirestoreRestClient({
    http.Client? httpClient,
    this.projectId = 'edunova-aabd1',
    required this.sessionProvider,
    this.tokenRefresher,
    this.onSessionExpired,
  }) : _http = httpClient ?? http.Client();

  final http.Client _http;
  final String projectId;
  final AuthSession? Function() sessionProvider;
  final Future<AuthSession?> Function()? tokenRefresher;
  final Future<void> Function()? onSessionExpired;

  Future<AuthSession?>? _inFlightRefresh;

  String get _databaseRoot =>
      'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  bool _isUnauthenticated(http.Response res) {
    if (res.statusCode == 401) return true;
    if (res.statusCode == 400 && res.body.contains('INVALID_ID_TOKEN'))
      return true;
    if (res.statusCode == 403 && res.body.contains('UNAUTHENTICATED'))
      return true;
    return false;
  }

  Future<AuthSession?> _performSingleRefresh() {
    if (_inFlightRefresh != null) return _inFlightRefresh!;
    if (tokenRefresher == null) return Future.value(null);

    _inFlightRefresh = tokenRefresher!().whenComplete(() {
      _inFlightRefresh = null;
    });
    return _inFlightRefresh!;
  }

  Future<http.Response> _sendAuthenticated(
    Future<http.Response> Function(String token) requestFn,
  ) async {
    final session = sessionProvider();
    if (session == null) throw Exception('Non authentifié.');

    var response = await requestFn(session.idToken);

    if (_isUnauthenticated(response)) {
      if (tokenRefresher == null) {
        if (onSessionExpired != null) await onSessionExpired!();
        return response;
      }

      final refreshed = await _performSingleRefresh();
      if (refreshed == null) {
        if (onSessionExpired != null) await onSessionExpired!();
        return response;
      }

      // Retry original request ONCE with newly acquired token
      response = await requestFn(refreshed.idToken);

      // If STILL unauthenticated, do NOT retry again (prevents infinite loops)
      if (_isUnauthenticated(response)) {
        if (onSessionExpired != null) await onSessionExpired!();
      }
    }

    return response;
  }

  // =========================================================================
  // BOUNDED READ OPERATIONS ONLY
  // (Zero direct client writes: all administrative mutations pass through authoritative callables)
  // =========================================================================

  Future<List<FirestoreDocument>> listDocuments(
    String collectionPath, {
    int pageSize = 100,
    String? pageToken,
    String? orderBy,
  }) async {
    var url = '$_databaseRoot/$collectionPath?pageSize=$pageSize';
    if (pageToken != null && pageToken.isNotEmpty) {
      url += '&pageToken=${Uri.encodeComponent(pageToken)}';
    }
    if (orderBy != null && orderBy.isNotEmpty) {
      url += '&orderBy=${Uri.encodeComponent(orderBy)}';
    }

    final response = await _sendAuthenticated(
      (token) => _http.get(Uri.parse(url), headers: _headers(token)),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 404) return [];
      throw Exception(
        'Erreur Firestore (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final docs = body['documents'] as List<dynamic>? ?? [];
    return docs
        .map((d) => FirestoreDocument.fromJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<FirestoreDocument?> getDocument(String documentPath) async {
    final response = await _sendAuthenticated(
      (token) => _http.get(
        Uri.parse('$_databaseRoot/$documentPath'),
        headers: _headers(token),
      ),
    );

    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw Exception(
        'Erreur Firestore (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return FirestoreDocument.fromJson(body);
  }

  Future<List<FirestoreDocument>> runQuery({
    required String fromCollection,
    Map<String, dynamic>? whereFilter,
    int? limit,
    String? orderByField,
    bool descending = false,
  }) async {
    final structuredQuery = <String, dynamic>{
      'from': [
        {'collectionId': fromCollection},
      ],
    };

    if (whereFilter != null) {
      structuredQuery['where'] = whereFilter;
    }

    if (limit != null) {
      structuredQuery['limit'] = limit;
    }

    if (orderByField != null) {
      structuredQuery['orderBy'] = [
        {
          'field': {'fieldPath': orderByField},
          'direction': descending ? 'DESCENDING' : 'ASCENDING',
        },
      ];
    }

    final response = await _sendAuthenticated(
      (token) => _http.post(
        Uri.parse('$_databaseRoot:runQuery'),
        headers: _headers(token),
        body: jsonEncode({'structuredQuery': structuredQuery}),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Erreur Firestore Query (${response.statusCode}): ${response.body}',
      );
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    final docs = <FirestoreDocument>[];
    for (final item in list) {
      if (item is Map<String, dynamic> && item.containsKey('document')) {
        docs.add(
          FirestoreDocument.fromJson(item['document'] as Map<String, dynamic>),
        );
      }
    }
    return docs;
  }

  /// Authoritative server-side aggregation query for counts (COUNT(*))
  /// Returns null if count cannot be aggregated safely by the backend.
  Future<int?> runAggregationCount(
    String collectionId, {
    Map<String, dynamic>? whereFilter,
  }) async {
    final structuredAggregationQuery = <String, dynamic>{
      'structuredQuery': {
        'from': [
          {'collectionId': collectionId},
        ],
        if (whereFilter != null) 'where': whereFilter,
      },
      'aggregations': [
        {'alias': 'total', 'count': {}},
      ],
    };

    try {
      final response = await _sendAuthenticated(
        (token) => _http.post(
          Uri.parse('$_databaseRoot:runAggregationQuery'),
          headers: _headers(token),
          body: jsonEncode({
            'structuredAggregationQuery': structuredAggregationQuery,
          }),
        ),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isNotEmpty && list.first is Map<String, dynamic>) {
        final result =
            (list.first as Map<String, dynamic>)['result']
                as Map<String, dynamic>?;
        final aggregateFields =
            result?['aggregateFields'] as Map<String, dynamic>?;
        final totalMap = aggregateFields?['total'] as Map<String, dynamic>?;
        final countStr = totalMap?['integerValue']?.toString();
        if (countStr != null) {
          return int.tryParse(countStr);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
