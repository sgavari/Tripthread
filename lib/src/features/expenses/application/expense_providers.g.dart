// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live-updating expense history for a trip, newest first.

@ProviderFor(tripExpenses)
final tripExpensesProvider = TripExpensesFamily._();

/// Live-updating expense history for a trip, newest first.

final class TripExpensesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Expense>>,
          List<Expense>,
          Stream<List<Expense>>
        >
    with $FutureModifier<List<Expense>>, $StreamProvider<List<Expense>> {
  /// Live-updating expense history for a trip, newest first.
  TripExpensesProvider._({
    required TripExpensesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripExpensesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripExpensesHash();

  @override
  String toString() {
    return r'tripExpensesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Expense>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Expense>> create(Ref ref) {
    final argument = this.argument as String;
    return tripExpenses(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TripExpensesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripExpensesHash() => r'f7af8baea8ff73e658693fa47d287c19dcacb05f';

/// Live-updating expense history for a trip, newest first.

final class TripExpensesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Expense>>, String> {
  TripExpensesFamily._()
    : super(
        retry: null,
        name: r'tripExpensesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Live-updating expense history for a trip, newest first.

  TripExpensesProvider call(String tripId) =>
      TripExpensesProvider._(argument: tripId, from: this);

  @override
  String toString() => r'tripExpensesProvider';
}

@ProviderFor(ExpenseController)
final expenseControllerProvider = ExpenseControllerProvider._();

final class ExpenseControllerProvider
    extends $AsyncNotifierProvider<ExpenseController, void> {
  ExpenseControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseControllerHash();

  @$internal
  @override
  ExpenseController create() => ExpenseController();
}

String _$expenseControllerHash() => r'2c2c871b4fba05f6d7a6acf54f3e8beefd085313';

abstract class _$ExpenseController extends $AsyncNotifier<void> {
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
