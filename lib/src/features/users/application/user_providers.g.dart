// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches a single user's public profile by uid. Cached per-uid by
/// Riverpod, so resolving the same member across many trips/screens is one
/// read, not one per usage.

@ProviderFor(userProfile)
final userProfileProvider = UserProfileFamily._();

/// Fetches a single user's public profile by uid. Cached per-uid by
/// Riverpod, so resolving the same member across many trips/screens is one
/// read, not one per usage.

final class UserProfileProvider
    extends
        $FunctionalProvider<AsyncValue<AppUser?>, AppUser?, FutureOr<AppUser?>>
    with $FutureModifier<AppUser?>, $FutureProvider<AppUser?> {
  /// Fetches a single user's public profile by uid. Cached per-uid by
  /// Riverpod, so resolving the same member across many trips/screens is one
  /// read, not one per usage.
  UserProfileProvider._({
    required UserProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @override
  String toString() {
    return r'userProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AppUser?> create(Ref ref) {
    final argument = this.argument as String;
    return userProfile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userProfileHash() => r'3277af827564f5b30f60c866e28e65aee9d63450';

/// Fetches a single user's public profile by uid. Cached per-uid by
/// Riverpod, so resolving the same member across many trips/screens is one
/// read, not one per usage.

final class UserProfileFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<AppUser?>, String> {
  UserProfileFamily._()
    : super(
        retry: null,
        name: r'userProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches a single user's public profile by uid. Cached per-uid by
  /// Riverpod, so resolving the same member across many trips/screens is one
  /// read, not one per usage.

  UserProfileProvider call(String uid) =>
      UserProfileProvider._(argument: uid, from: this);

  @override
  String toString() => r'userProfileProvider';
}
