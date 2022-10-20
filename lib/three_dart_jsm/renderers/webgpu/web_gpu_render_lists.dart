import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart';

painterSortStable(a, b) {
  if (a.groupOrder != b.groupOrder) {
    return a.groupOrder - b.groupOrder;
  } else if (a.renderOrder != b.renderOrder) {
    return a.renderOrder - b.renderOrder;
  } else if (a.material.id != b.material.id) {
    return a.material.id - b.material.id;
  } else if (a.z != b.z) {
    return a.z - b.z;
  } else {
    return a.id - b.id;
  }
}

reversePainterSortStable(a, b) {
  if (a.groupOrder != b.groupOrder) {
    return a.groupOrder - b.groupOrder;
  } else if (a.renderOrder != b.renderOrder) {
    return a.renderOrder - b.renderOrder;
  } else if (a.z != b.z) {
    return b.z - a.z;
  } else {
    return a.id - b.id;
  }
}

class WebGPURenderList {
  late List renderItems;
  late int renderItemsIndex;
  late List opaque;
  late List transparent;

  WebGPURenderList() {
    renderItems = [];
    renderItemsIndex = 0;

    opaque = [];
    transparent = [];
  }

  init() {
    renderItemsIndex = 0;

    opaque.length = 0;
    transparent.length = 0;
  }

  getNextRenderItem(object, geometry, material, groupOrder, z, group) {
    var renderItem;

    if (renderItemsIndex < renderItems.length) {
      renderItem = renderItems[renderItemsIndex];
    }

    if (renderItem == undefined) {
      renderItem = RenderItem(
          id: object.id,
          object: object,
          geometry: geometry,
          material: material,
          groupOrder: groupOrder,
          renderOrder: object.renderOrder,
          z: z,
          group: group);

      // this.renderItems[ this.renderItemsIndex ] = renderItem;
      renderItems.add(renderItem);
    } else {
      renderItem.id = object.id;
      renderItem.object = object;
      renderItem.geometry = geometry;
      renderItem.material = material;
      renderItem.groupOrder = groupOrder;
      renderItem.renderOrder = object.renderOrder;
      renderItem.z = z;
      renderItem.group = group;
    }

    renderItemsIndex++;

    return renderItem;
  }

  push(object, geometry, material, groupOrder, z, group) {
    var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

    (material.transparent == true ? transparent : opaque).add(renderItem);
  }

  unshift(object, geometry, material, groupOrder, z, group) {
    var renderItem = getNextRenderItem(object, geometry, material, groupOrder, z, group);

    (material.transparent == true ? transparent : opaque).insert(0, renderItem);
  }

  sort(customOpaqueSort, customTransparentSort) {
    if (opaque.length > 1) opaque.sort(customOpaqueSort ?? painterSortStable);
    if (transparent.length > 1) transparent.sort(customTransparentSort ?? reversePainterSortStable);
  }

  finish() {
    // Clear references from inactive renderItems in the list

    for (var i = renderItemsIndex, il = renderItems.length; i < il; i++) {
      var renderItem = renderItems[i];

      if (renderItem.id == null) break;

      renderItem.id = null;
      renderItem.object = null;
      renderItem.geometry = null;
      renderItem.material = null;
      renderItem.program = null;
      renderItem.group = null;
    }
  }
}

class WebGPURenderLists {
  late WeakMap lists;

  WebGPURenderLists() {
    lists = WeakMap();
  }

  get(scene, camera) {
    var lists = this.lists;

    var cameras = lists.get(scene);
    var list;

    if (cameras == undefined) {
      list = WebGPURenderList();
      lists.set(scene, WeakMap());
      lists.get(scene).set(camera, list);
    } else {
      list = cameras.get(camera);
      if (list == undefined) {
        list = WebGPURenderList();
        cameras.set(camera, list);
      }
    }

    return list;
  }

  dispose() {
    lists = WeakMap();
  }
}

class RenderItem {
  dynamic id;
  dynamic object;
  dynamic geometry;
  dynamic material;
  dynamic groupOrder;
  dynamic renderOrder;
  dynamic z;
  dynamic group;

  RenderItem(
      {this.id, this.object, this.geometry, this.material, this.groupOrder, this.renderOrder, this.z, this.group});
}
