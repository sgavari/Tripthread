// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destination_image_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(destinationImageService)
final destinationImageServiceProvider = DestinationImageServiceProvider._();

final class DestinationImageServiceProvider
    extends
        $FunctionalProvider<
          DestinationImageService,
          DestinationImageService,
          DestinationImageService
        >
    with $Provider<DestinationImageService> {
  DestinationImageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'destinationImageServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$destinationImageServiceHash();

  @$internal
  @override
  $ProviderElement<DestinationImageService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DestinationImageService create(Ref ref) {
    return destinationImageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DestinationImageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DestinationImageService>(value),
    );
  }
}

String _$destinationImageServiceHash() =>
    r'234d20be92a1e3d8c9c29344bae6510f8f75dde8';
