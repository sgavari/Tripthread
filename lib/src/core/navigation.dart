import 'package:flutter/material.dart';

/// App-wide keys so code outside the widget tree (e.g. a push notification
/// tap handler firing from a background isolate callback) can still
/// navigate or show feedback.
final rootNavigatorKey = GlobalKey<NavigatorState>();
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
