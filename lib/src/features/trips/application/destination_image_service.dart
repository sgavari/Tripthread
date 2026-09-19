import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'destination_image_service.g.dart';

@riverpod
DestinationImageService destinationImageService(Ref ref) =>
    const DestinationImageService();

/// Looks up a representative photo for a place name.
///
/// Uses Wikipedia's public REST API, which is free and keyless — most
/// well-known cities/regions/landmarks have a page with a lead image.
/// Best-effort only: returns null (never throws) if nothing is found or the
/// request fails, so a missing photo never blocks trip creation.
class DestinationImageService {
  const DestinationImageService();

  Future<String?> lookupImageUrl(String destination) async {
    final query = destination.trim();
    if (query.isEmpty) return null;

    try {
      final uri = Uri.https(
        'en.wikipedia.org',
        '/api/rest_v1/page/summary/${Uri.encodeComponent(query)}',
      );
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final thumbnail = body['thumbnail'] as Map<String, dynamic>?;
      final originalImage = body['originalimage'] as Map<String, dynamic>?;
      return (originalImage ?? thumbnail)?['source'] as String?;
    } catch (_) {
      return null;
    }
  }
}
