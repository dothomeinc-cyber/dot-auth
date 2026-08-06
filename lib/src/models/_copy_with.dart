/// Marker meaning "this argument was not supplied".
///
/// The usual `value ?? this.value` pattern in `copyWith` makes it impossible to
/// set a nullable field back to `null` — passing `null` is indistinguishable
/// from omitting the argument, so the old value survives. Every model in this
/// package takes `Object?` for nullable fields, defaults them to [kUnset], and
/// resolves them with [pick].
///
/// A dedicated type rather than `const Object()`, because Dart canonicalises
/// const instances: a caller passing their own `const Object()` would otherwise
/// be `identical` to the sentinel and get silently ignored.
class Unset {
  /// Creates the sentinel. Use [kUnset] rather than constructing your own.
  const Unset();
}

/// The single sentinel instance.
const Unset kUnset = Unset();

/// Returns [current] when [value] was omitted, otherwise [value] cast to `T?`.
T? pick<T>(Object? value, T? current) =>
    value is Unset ? current : value as T?;
