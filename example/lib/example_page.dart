import 'package:example/misc_controls_pointerlock.dart';
import 'package:example/webgl_loader_fbx.dart';

import './misc_controls_orbit.dart';
// import './webgpu_rtt.dart';

import 'package:flutter/material.dart';

import 'games_fps.dart';
import 'misc_controls_arcball.dart';
import 'misc_controls_map.dart';
import 'misc_controls_trackball.dart';

class ExamplePage extends StatefulWidget {
  final String? id;
  const ExamplePage({Key? key, this.id}) : super(key: key);

  @override
  State<ExamplePage> createState() => _MyAppState();
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

    if (fileName == "games_fps") {
      page = TestGame(fileName: fileName);
    } else if (fileName == "misc_controls_orbit") {
      page = MiscControlsOrbit(fileName: fileName);
    } else if (fileName == "misc_controls_trackball") {
      page = MiscControlsTrackball(fileName: fileName);
    } else if (fileName == "misc_controls_arcball") {
      page = MiscControlsArcball(fileName: fileName);
    } else if (fileName == "misc_controls_map") {
      page = MiscControlsMap(fileName: fileName);
      // } else if (fileName == "webgpu_rtt") {
      //   page = webgpu_rtt(fileName: fileName);
    } else if (fileName == "misc_controls_pointerlock") {
      page = MiscControlsPointerlock(fileName: fileName);
    } else if (fileName == "webgl_loader_fbx") {
      page = WebglLoaderFbx(fileName: fileName);
    } else {
      throw ("ExamplePage fileName $fileName is not support yet ");
    }

    return page;
  }
}
