library three_webgpu;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter_gl/native-array/index.dart';
// import 'package:flutter_webgpu/flutter_webgpu.dart';
import 'package:three_dart/extra/console.dart';
import 'package:three_dart/three_dart.dart';

import '../nodes/index.dart';

part './extension_helper.dart';
part './constants.dart';
part './web_gpu_renderer.dart';
part './web_gpu_info.dart';
part './web_gpu_properties.dart';

part './web_gpu_attributes.dart';
part './web_gpu_geometries.dart';
part './web_gpu_textures.dart';
part './web_gpu_objects.dart';
part './web_gpu_compute_pipelines.dart';

part './web_gpu_programmable_stage.dart';
part './web_gpu_render_pipeline.dart';
part './web_gpu_render_pipelines.dart';
part './web_gpu_binding.dart';
part './web_gpu_bindings.dart';
part './web_gpu_background.dart';
part './web_gpu_render_lists.dart';

part './nodes/web_gpu_nodes.dart';
part './nodes/web_gpu_node_builder.dart';

part './web_gpu_texture_utils.dart';
part './web_gpu_sampler.dart';
part './nodes/web_gpu_node_sampler.dart';
part './web_gpu_sampled_texture.dart';
part './web_gpu_storage_buffer.dart';
part './nodes/web_gpu_node_sampled_texture.dart';
part './web_gpu_uniform_buffer.dart';
part './web_gpu_uniforms_group.dart';
part './web_gpu_buffer_utils.dart';
part './nodes/web_gpu_node_uniforms_group.dart';
part './nodes/web_gpu_node_uniform.dart';
part './web_gpu_texture_renderer.dart';
part './web_gpu_uniform.dart';
