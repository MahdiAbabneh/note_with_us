import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveIndicator extends StatelessWidget {

  const AdaptiveIndicator({super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return const CircularProgressIndicator();
    }
    return const CupertinoActivityIndicator();
  }
}
