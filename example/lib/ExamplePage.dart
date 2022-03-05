
import 'package:example/misc_controls_orbit.dart';

import 'package:flutter/material.dart';

import 'misc_controls_arcball.dart';
import 'misc_controls_map.dart';
import 'misc_controls_trackball.dart';


class ExamplePage extends StatefulWidget {
  String? id;
  ExamplePage({Key? key, this.id}) : super(key: key);

  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<ExamplePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget page;

    String fileName = widget.id!;

    if (fileName == "misc_controls_orbit") {
      page = misc_controls_orbit(fileName: fileName);
    } else if (fileName == "misc_controls_trackball") {
      page = misc_controls_trackball(fileName: fileName);
    } else if (fileName == "misc_controls_arcball") {
      page = misc_controls_arcball(fileName: fileName);
    } else if (fileName == "misc_controls_map") {
      page = misc_controls_map(fileName: fileName);
      
    } else {
      throw ("ExamplePage fileName ${fileName} is not support yet ");
    }

    return page;
  }
}
