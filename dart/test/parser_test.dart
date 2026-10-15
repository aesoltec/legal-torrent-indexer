import 'package:test/test.dart';
import 'package:legal_torrent_indexer/legal_torrent_indexer.dart';

void main() {
  group('parseQuery', () {
    test('public domain movie allowed', () {
      final r = parseQuery(
        'vieux film Night of the Living Dead de George Romero',
      );
      expect(r.isAdult, isFalse);
      expect(r.isLegalRequest, isTrue);
      expect(r.category, Category.movies);
      expect(r.searchPayload.broadQuery, isNotNull);
      expect(r.keywords, isNotEmpty);
      expect(r.clientPlatformHint, 'local_flutter_payload');
      expect(r.confidence, isIn([Confidence.high, Confidence.medium]));
      expect(r.jurisdiction, 'unknown');
    });

    test('recent TV show refused', () {
      final r = parseQuery('Dernier épisode de House of the Dragon');
      expect(r.isAdult, isFalse);
      expect(r.isLegalRequest, isFalse);
      expect(r.searchPayload.broadQuery, isNull);
      expect(r.keywords, isEmpty);
      expect(r.clientPlatformHint, 'local_flutter_payload');
      expect(r.confidence, Confidence.high);
      expect(r.jurisdiction, 'unknown');
    });

    test('Ubuntu ISO allowed', () {
      final r = parseQuery('ISO Ubuntu 24.04');
      expect(r.isAdult, isFalse);
      expect(r.isLegalRequest, isTrue);
      expect(r.category, Category.software);
      expect(r.searchPayload.linuxSoftwareQuery, isNotNull);
      expect(r.clientPlatformHint, 'local_flutter_payload');
      expect(r.confidence, Confidence.high);
    });

    test('adult content refused', () {
      final r = parseQuery('films x');
      expect(r.isAdult, isTrue);
      expect(r.isLegalRequest, isFalse);
      expect(r.searchPayload.broadQuery, isNull);
      expect(r.keywords, isEmpty);
      expect(r.clientPlatformHint, 'local_flutter_payload');
      expect(r.confidence, Confidence.high);
    });

    test('Windows ISO refused', () {
      final r = parseQuery('Windows 11 ISO');
      expect(r.isLegalRequest, isFalse);
      expect(r.searchPayload.broadQuery, isNull);
      expect(r.clientPlatformHint, 'local_flutter_payload');
    });

    test('empty query refused', () {
      final r = parseQuery('   ');
      expect(r.isLegalRequest, isFalse);
      expect(r.keywords, isEmpty);
      expect(r.clientPlatformHint, 'local_flutter_payload');
      expect(r.jurisdiction, 'unknown');
    });

    test('JSON keys match required format', () {
      final r = parseQuery('Ubuntu 24.04');
      final json = r.toJson();
      expect(json.keys, containsAll([
        'original_query',
        'category',
        'is_adult',
        'is_legal_request',
        'search_payload',
        'keywords',
        'target_extension',
        'client_platform_hint',
        'reason',
        'confidence',
        'jurisdiction',
      ]));
      expect(json['client_platform_hint'], 'local_flutter_payload');
      expect(json['confidence'], isIn(['high', 'medium', 'low']));
      expect(json['jurisdiction'], 'unknown');
      expect(json['target_extension'], 'torrent');
    });
  });
}
