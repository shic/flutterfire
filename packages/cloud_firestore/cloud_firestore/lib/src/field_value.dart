// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

part of cloud_firestore;

/// Sentinel values that can be used when writing document fields with set() or
/// update().
///
/// This class serves as a static factory for [FieldValuePlatform] instances, but also
/// as a facade for the [FieldValue] type, so plugin users don't need to worry about
/// the actual internal implementation of their [FieldValue]s after they're created.
class FieldValue extends FieldValuePlatform {
  static final FieldValueFactoryPlatform _factory =
      FieldValueFactoryPlatform.instance;

  FieldValue._(this._delegate) : super(_delegate);

  /// Returns a [FieldValue] that tells the server to union the given elements
  /// with any array value that already exists on the server.
  ///
  /// Each specified element that doesn't already exist in the array will be
  /// added to the end. If the field being modified is not already an array it
  /// will be overwritten with an array containing exactly the specified
  /// elements.
  static FieldValue arrayUnion(List<dynamic> elements) =>
      FieldValue._(_factory.arrayUnion(_CodecUtility.valueEncode(elements)));

  /// Returns a [FieldValue] that tells the server to remove the given
  /// elements from any array value that already exists on the server.
  ///
  /// All instances of each element specified will be removed from the array.
  /// If the field being modified is not already an array it will be overwritten
  /// with an empty array.
  static FieldValue arrayRemove(List<dynamic> elements) =>
      FieldValue._(_factory.arrayRemove(_CodecUtility.valueEncode(elements)));

  /// Returns a sentinel for use with update() to mark a field for deletion.
  static FieldValue delete() => FieldValue._(_factory.delete());

  /// Returns a sentinel for use with set() or update() to include a
  /// server-generated timestamp in the written data.
  static FieldValue serverTimestamp() =>
      FieldValue._(_factory.serverTimestamp());

  /// Returns a special value for use with set() or update() that tells the
  /// server to increment the field’s current value by the given value.
  static FieldValue increment(num value) =>
      FieldValue._(_factory.increment(value));

  dynamic _delegate;

  @override
  String toString() => '$runtimeType($_delegate)';

  @override
  bool operator ==(Object o) {
    return o is FieldValue && o._delegate == _delegate;
  }

  @override
  int get hashCode => _delegate.hashCode;
}
