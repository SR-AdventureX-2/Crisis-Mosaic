import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'crisis_mosaic_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CrisisMosaicApp());
}
