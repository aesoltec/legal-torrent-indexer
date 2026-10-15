/// Exemple CLI local (Dart pur, zéro serveur, zéro Python).
///
/// Usage:
///   dart run example/main.dart "ISO Ubuntu 24.04"
///   dart run example/main.dart "films x"

import 'dart:convert';
import 'package:legal_torrent_indexer/legal_torrent_indexer.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run example/main.dart "<requête>"');
    return;
  }
  final query = args.join(' ');
  final result = parseQuery(query);
  print(const JsonEncoder.withIndent(null).convert(result.toJson()));
}
