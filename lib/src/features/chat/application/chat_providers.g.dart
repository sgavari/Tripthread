// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live-updating chat history for a trip, newest last (ready for a
/// bottom-anchored chat list).

@ProviderFor(tripMessages)
final tripMessagesProvider = TripMessagesFamily._();

/// Live-updating chat history for a trip, newest last (ready for a
/// bottom-anchored chat list).

final class TripMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          Stream<List<ChatMessage>>
        >
    with
        $FutureModifier<List<ChatMessage>>,
        $StreamProvider<List<ChatMessage>> {
  /// Live-updating chat history for a trip, newest last (ready for a
  /// bottom-anchored chat list).
  TripMessagesProvider._({
    required TripMessagesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripMessagesHash();

  @override
  String toString() {
    return r'tripMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ChatMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatMessage>> create(Ref ref) {
    final argument = this.argument as String;
    return tripMessages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TripMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripMessagesHash() => r'dbdb42b07c0aaeb58e6f66ac4ba6ba54a88d5f5f';

/// Live-updating chat history for a trip, newest last (ready for a
/// bottom-anchored chat list).

final class TripMessagesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ChatMessage>>, String> {
  TripMessagesFamily._()
    : super(
        retry: null,
        name: r'tripMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live-updating chat history for a trip, newest last (ready for a
  /// bottom-anchored chat list).

  TripMessagesProvider call(String tripId) =>
      TripMessagesProvider._(argument: tripId, from: this);

  @override
  String toString() => r'tripMessagesProvider';
}

/// Just the most recent message in a trip, for a chat-list preview row.
/// Null while the trip has no messages yet.

@ProviderFor(tripLatestMessage)
final tripLatestMessageProvider = TripLatestMessageFamily._();

/// Just the most recent message in a trip, for a chat-list preview row.
/// Null while the trip has no messages yet.

final class TripLatestMessageProvider
    extends
        $FunctionalProvider<
          AsyncValue<ChatMessage?>,
          ChatMessage?,
          Stream<ChatMessage?>
        >
    with $FutureModifier<ChatMessage?>, $StreamProvider<ChatMessage?> {
  /// Just the most recent message in a trip, for a chat-list preview row.
  /// Null while the trip has no messages yet.
  TripLatestMessageProvider._({
    required TripLatestMessageFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripLatestMessageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripLatestMessageHash();

  @override
  String toString() {
    return r'tripLatestMessageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<ChatMessage?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ChatMessage?> create(Ref ref) {
    final argument = this.argument as String;
    return tripLatestMessage(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TripLatestMessageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripLatestMessageHash() => r'6aec0cd3b466a6f1844541147102590fa4368171';

/// Just the most recent message in a trip, for a chat-list preview row.
/// Null while the trip has no messages yet.

final class TripLatestMessageFamily extends $Family
    with $FunctionalFamilyOverride<Stream<ChatMessage?>, String> {
  TripLatestMessageFamily._()
    : super(
        retry: null,
        name: r'tripLatestMessageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Just the most recent message in a trip, for a chat-list preview row.
  /// Null while the trip has no messages yet.

  TripLatestMessageProvider call(String tripId) =>
      TripLatestMessageProvider._(argument: tripId, from: this);

  @override
  String toString() => r'tripLatestMessageProvider';
}

@ProviderFor(ChatController)
final chatControllerProvider = ChatControllerProvider._();

final class ChatControllerProvider
    extends $AsyncNotifierProvider<ChatController, void> {
  ChatControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatControllerHash();

  @$internal
  @override
  ChatController create() => ChatController();
}

String _$chatControllerHash() => r'41881895b28e11e6066b42a1bd0c26dc863b76da';

abstract class _$ChatController extends $AsyncNotifier<void> {
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
