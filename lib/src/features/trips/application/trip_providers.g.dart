// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A member's nickname for this specific trip, if they set one — distinct
/// from their account-wide display name, e.g. "Coach" on this trip only.

@ProviderFor(tripMemberNickname)
final tripMemberNicknameProvider = TripMemberNicknameFamily._();

/// A member's nickname for this specific trip, if they set one — distinct
/// from their account-wide display name, e.g. "Coach" on this trip only.

final class TripMemberNicknameProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// A member's nickname for this specific trip, if they set one — distinct
  /// from their account-wide display name, e.g. "Coach" on this trip only.
  TripMemberNicknameProvider._({
    required TripMemberNicknameFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'tripMemberNicknameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripMemberNicknameHash();

  @override
  String toString() {
    return r'tripMemberNicknameProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as (String, String);
    return tripMemberNickname(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is TripMemberNicknameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripMemberNicknameHash() =>
    r'b8c4d51ec124707f53f24c691c494c7b58cbd11b';

/// A member's nickname for this specific trip, if they set one — distinct
/// from their account-wide display name, e.g. "Coach" on this trip only.

final class TripMemberNicknameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, (String, String)> {
  TripMemberNicknameFamily._()
    : super(
        retry: null,
        name: r'tripMemberNicknameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A member's nickname for this specific trip, if they set one — distinct
  /// from their account-wide display name, e.g. "Coach" on this trip only.

  TripMemberNicknameProvider call(String tripId, String uid) =>
      TripMemberNicknameProvider._(argument: (tripId, uid), from: this);

  @override
  String toString() => r'tripMemberNicknameProvider';
}

/// Live-updating list of trips the current user belongs to, newest first.
///
/// Emits an empty list while signed out.

@ProviderFor(myTrips)
final myTripsProvider = MyTripsProvider._();

/// Live-updating list of trips the current user belongs to, newest first.
///
/// Emits an empty list while signed out.

final class MyTripsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Trip>>,
          List<Trip>,
          Stream<List<Trip>>
        >
    with $FutureModifier<List<Trip>>, $StreamProvider<List<Trip>> {
  /// Live-updating list of trips the current user belongs to, newest first.
  ///
  /// Emits an empty list while signed out.
  MyTripsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myTripsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myTripsHash();

  @$internal
  @override
  $StreamProviderElement<List<Trip>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Trip>> create(Ref ref) {
    return myTrips(ref);
  }
}

String _$myTripsHash() => r'3f1d857ceb20b34e39ef38eb5e64ffd515ef994b';

@ProviderFor(TripController)
final tripControllerProvider = TripControllerProvider._();

final class TripControllerProvider
    extends $AsyncNotifierProvider<TripController, void> {
  TripControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripControllerHash();

  @$internal
  @override
  TripController create() => TripController();
}

String _$tripControllerHash() => r'eacc669469f97a36d1e8272bae09c50473ca5727';

abstract class _$TripController extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
