import 'index.dart';
import 'package:three_dart/three_dart.dart' as three;

class DirectGeometry {
  late int id;
  late String uuid;
  late String name;
  late String type;

  List<three.Vector3> vertices = [];
  List<three.Vector3> normals = [];
  List<three.Color> colors = [];
  List<three.Vector2> uvs = [];
  List<three.Vector2> uvs2 = [];
  List<Map<String, int>> groups = [];
  Map<String, dynamic> morphTargets = <String, dynamic>{};
  List<three.Vector4> skinWeights = [];
  List<three.Vector4> skinIndices = [];
  three.Box3? boundingBox;
  three.Sphere? boundingSphere;

  bool verticesNeedUpdate = false;
  bool normalsNeedUpdate = false;
  bool colorsNeedUpdate = false;
  bool uvsNeedUpdate = false;
  bool groupsNeedUpdate = false;
  bool lineDistancesNeedUpdate = false;

  DirectGeometry();

  computeGroups(geometry) {
    List<Map<String, int>> groups = [];

    Map<String, int>? group;
    var i;
    var materialIndex;

    var faces = geometry.faces;

    for (i = 0; i < faces.length; i++) {
      var face = faces[i];

      // materials

      if (face.materialIndex != materialIndex) {
        materialIndex = face.materialIndex;

        if (group != null) {
          group["count"] = (i * 3) - group["start"];
          groups.add(group);
        }

        group = {"start": i * 3, "materialIndex": materialIndex};
      }
    }

    if (group != null) {
      group["count"] = (i * 3) - group["start"];
      groups.add(group);
    }

    this.groups = groups;
  }

  fromGeometry(Geometry geometry) {
    var faces = geometry.faces;
    var vertices = geometry.vertices;
    var faceVertexUvs = geometry.faceVertexUvs;

    var hasFaceVertexUv = faceVertexUvs.isNotEmpty && faceVertexUvs[0] != null;
    var hasFaceVertexUv2 = faceVertexUvs.length >= 2 && faceVertexUvs[1] != null;

    // morphs

    var morphTargets = geometry.morphTargets;
    var morphTargetsLength = morphTargets.length;

    var morphTargetsPosition;

    if (morphTargetsLength > 0) {
      morphTargetsPosition = [];

      for (var i = 0; i < morphTargetsLength; i++) {
        morphTargetsPosition.add({"name": morphTargets[i].name, "data": []});
      }

      this.morphTargets["position"] = morphTargetsPosition;
    }

    var morphNormals = geometry.morphNormals;
    var morphNormalsLength = morphNormals.length;

    var morphTargetsNormal;

    if (morphNormalsLength > 0) {
      morphTargetsNormal = [];

      for (var i = 0; i < morphNormalsLength; i++) {
        morphTargetsNormal[i] = {"name": morphNormals[i].name, "data": []};
      }

      this.morphTargets["normal"] = morphTargetsNormal;
    }

    // skins

    var skinIndices = geometry.skinIndices;
    var skinWeights = geometry.skinWeights;

    var hasSkinIndices = skinIndices.length == vertices.length;
    var hasSkinWeights = skinWeights.length == vertices.length;

    //

    if (vertices.isNotEmpty && faces.isEmpty) {
      print('THREE.DirectGeometry: Faceless geometries are not supported.');
    }

    for (var i = 0; i < faces.length; i++) {
      var face = faces[i];

      this.vertices.addAll([vertices[face.a], vertices[face.b], vertices[face.c]]);

      var vertexNormals = face.vertexNormals;

      if (vertexNormals.length == 3) {
        normals.addAll([vertexNormals[0], vertexNormals[1], vertexNormals[2]]);
      } else {
        var normal = face.normal;

        normals.addAll([normal, normal, normal]);
      }

      var vertexColors = face.vertexColors;

      if (vertexColors.length == 3) {
        colors.addAll([vertexColors[0], vertexColors[1], vertexColors[2]]);
      } else {
        var color = face.color;

        colors.addAll([color, color, color]);
      }

      if (hasFaceVertexUv == true) {
        var vertexUvs = faceVertexUvs[0]?[i];

        if (vertexUvs != null) {
          uvs.addAll([vertexUvs[0], vertexUvs[1], vertexUvs[2]]);
        } else {
          print('THREE.DirectGeometry.fromGeometry(): null vertexUv $i');

          uvs.addAll([three.Vector2(null, null), three.Vector2(null, null), three.Vector2(null, null)]);
        }
      }

      if (hasFaceVertexUv2 == true) {
        var vertexUvs = faceVertexUvs[1]?[i];

        if (vertexUvs != null) {
          uvs2.addAll([vertexUvs[0], vertexUvs[1], vertexUvs[2]]);
        } else {
          print('THREE.DirectGeometry.fromGeometry(): null vertexUv2 $i');

          uvs2.addAll([three.Vector2(null, null), three.Vector2(null, null), three.Vector2(null, null)]);
        }
      }

      // morphs

      for (var j = 0; j < morphTargetsLength; j++) {
        var morphTarget = morphTargets[j].vertices;

        morphTargetsPosition[j]["data"].addAll([morphTarget[face.a], morphTarget[face.b], morphTarget[face.c]]);
      }

      for (var j = 0; j < morphNormalsLength; j++) {
        var morphNormal = morphNormals[j].vertexNormals[i];

        morphTargetsNormal[j]["data"].addAll([morphNormal.a, morphNormal.b, morphNormal.c]);
      }

      // skins

      if (hasSkinIndices) {
        this.skinIndices.addAll([skinIndices[face.a], skinIndices[face.b], skinIndices[face.c]]);
      }

      if (hasSkinWeights) {
        this.skinWeights.addAll([skinWeights[face.a], skinWeights[face.b], skinWeights[face.c]]);
      }
    }

    computeGroups(geometry);

    verticesNeedUpdate = geometry.verticesNeedUpdate;
    normalsNeedUpdate = geometry.normalsNeedUpdate;
    colorsNeedUpdate = geometry.colorsNeedUpdate;
    uvsNeedUpdate = geometry.uvsNeedUpdate;
    groupsNeedUpdate = geometry.groupsNeedUpdate;

    if (geometry.boundingSphere != null) {
      boundingSphere = geometry.boundingSphere!.clone();
    }

    if (geometry.boundingBox != null) {
      boundingBox = geometry.boundingBox!.clone();
    }

    return this;
  }
}
