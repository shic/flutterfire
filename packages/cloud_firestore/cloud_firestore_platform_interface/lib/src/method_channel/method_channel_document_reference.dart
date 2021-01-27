// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';
import 'package:flutter/services.dart';

import 'method_channel_firestore.dart';
import 'utils/source.dart';
import 'utils/exception.dart';

/// An implementation of [DocumentReferencePlatform] that uses [MethodChannel] to
/// communicate with Firebase plugins.
class MethodChannelDocumentReference extends DocumentReferencePlatform {
  late Pointer _pointer;

  /// Creates a [DocumentReferencePlatform] that is implemented using [MethodChannel].
  MethodChannelDocumentReference(
      FirebaseFirestorePlatform firestore, String path)
      : super(firestore, path) {
    _pointer = Pointer(path);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    try {
      await MethodChannelFirebaseFirestore.channel.invokeMethod<void>(
        'DocumentReference#set',
        <String, dynamic>{
          'firestore': firestore,
          'reference': this,
          'data': data,
          'options': <String, dynamic>{
            'merge': options?.merge,
            'mergeFields': options?.mergeFields,
          },
        },
      );
    } catch (e) {
      throw convertPlatformException(e);
    }
  }

  @override
  Future<void> update(Map<String, dynamic> data) async {
    try {
      await MethodChannelFirebaseFirestore.channel.invokeMethod<void>(
        'DocumentReference#update',
        <String, dynamic>{
          'firestore': firestore,
          'reference': this,
          'data': data,
        },
      );
    } catch (e) {
      throw convertPlatformException(e);
    }
  }

  @override
  Future<DocumentSnapshotPlatform> get(
      [GetOptions? options = const GetOptions()]) async {
    try {
      final Map<String, dynamic>? data = await MethodChannelFirebaseFirestore
          .channel
          .invokeMapMethod<String, dynamic>(
        'DocumentReference#get',
        <String, dynamic>{
          'firestore': firestore,
          'reference': this,
          'source': getSourceString(options!.source),
        },
      );

      return DocumentSnapshotPlatform(firestore, _pointer.path, data!);
    } catch (e) {
      throw convertPlatformException(e);
    }
  }

  @override
  Future<void> delete() async {
    try {
      await MethodChannelFirebaseFirestore.channel.invokeMethod<void>(
        'DocumentReference#delete',
        <String, dynamic>{'firestore': firestore, 'reference': this},
      );
    } catch (e) {
      throw convertPlatformException(e);
    }
  }

  @override
  Stream<DocumentSnapshotPlatform> snapshots({
    bool includeMetadataChanges = false,
  }) {
    // It's fine to let the StreamController be garbage collected once all the
    // subscribers have cancelled; this analyzer warning is safe to ignore.
    late StreamController<DocumentSnapshotPlatform>
        controller; // ignore: close_sinks

    StreamSubscription<dynamic>? snapshotStream;
    controller = StreamController<DocumentSnapshotPlatform>.broadcast(
      onListen: () async {
        final observerId = await MethodChannelFirebaseFirestore.channel
            .invokeMethod<String>('DocumentReference#snapshots');
        snapshotStream =
            MethodChannelFirebaseFirestore.documentSnapshotChannel(observerId)
                .receiveBroadcastStream(
          <String, dynamic>{
            'reference': this,
            'includeMetadataChanges': includeMetadataChanges,
          },
        ).listen((snapshot) {
          controller.add(
            DocumentSnapshotPlatform(
              firestore,
              snapshot['path'],
              <String, dynamic>{
                'data': snapshot['data'],
                'metadata': snapshot['metadata'],
              },
            ),
          );
        }, onError: (error, stack) {
          controller.addError(convertPlatformException(error), stack);
        });
      },
      onCancel: () {
        snapshotStream?.cancel();
      },
    );

    return controller.stream;
  }
}
