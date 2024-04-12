import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:managed_configurations/managed_configurations.dart';
import 'package:managed_configurations/managed_configurations_platform_interface.dart';

const String getManagedConfiguration = "getManagedConfigurations";
const String reportKeyedAppState = "reportKeyedAppState";

/// An implementation of [ManagedConfigurationsPlatform] that uses method channels.
class MethodChannelManagedConfigurations extends ManagedConfigurationsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('managed_configurations');

  static const MethodChannel _managedConfigurationMethodChannel =
      const MethodChannel('managed_configurations_method');
  static const EventChannel _managedConfigurationEventChannel =
      const EventChannel('managed_configurations_event');

  static StreamController<Map<String, dynamic>?>
      _mangedConfigurationsController =
      StreamController<Map<String, dynamic>?>.broadcast();

  static Stream<Map<String, dynamic>?> _managedConfigurationsStream =
      _mangedConfigurationsController.stream.asBroadcastStream();

  /// Returns a broadcast stream which calls on managed app configuration changes
  /// Json will be returned
  /// Call [dispose] when stream is not more necessary
  static Stream<Map<String, dynamic>?> get mangedConfigurationsStream {
    if (_actionApplicationRestrictionsChangedSubscription == null) {
      _actionApplicationRestrictionsChangedSubscription =
          _managedConfigurationEventChannel
              .receiveBroadcastStream()
              .listen((newManagedConfigurations) {
        if (newManagedConfigurations != null) {
          _mangedConfigurationsController
              .add(json.decode(newManagedConfigurations));
        }
      });
    }
    return _managedConfigurationsStream;
  }

  static StreamSubscription<dynamic>?
      _actionApplicationRestrictionsChangedSubscription;

  /// Returns managed app configurations as Json
  static Future<Map<String, dynamic>?> get getManagedConfigurations async {
    final String? rawJson = await _managedConfigurationMethodChannel
        .invokeMethod(getManagedConfiguration);
    if (rawJson != null) {
      return json.decode(rawJson);
    } else {
      return null;
    }
  }

  /// This method is only supported on Android Platform
  static Future<void> reportKeyedAppStates(
    String key,
    Severity severity,
    String? message,
    String? data,
  ) async {
    if (Platform.isAndroid) {
      await _managedConfigurationMethodChannel.invokeMethod(
        reportKeyedAppState,
        {
          'key': key,
          'severity': severity.toInteger(),
          'message': message,
          'data': data,
        },
      );
    }
  }

  static dispose() {
    _actionApplicationRestrictionsChangedSubscription?.cancel();
  }
}
