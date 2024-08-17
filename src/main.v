// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license file distributed with this software package
module main

// Example shader triangle adapted to V from https://github.com/floooh/sokol-samples/blob/1f2ad36/sapp/triangle-sapp.c
import sokol.sapp
import sokol.gfx
import gg
import stbi

// Use `v shader` or `sokol-shdc` to generate the necessary `.h` file
// Using `v shader -v .` in this directory will show some additional
// info - and what you should include to make things work.
#include "@VMODROOT/simple_shader.h" # # It should be generated with `v shader .`

// simple_shader_desc is a C function declaration defined by
// the `@program` entry in the `simple_shader.glsl` shader file.
// When the shader is compiled this function name is generated
// by the shader compiler for easier inclusion of universal shader code
// in C (and V) code.
fn C.simple_shader_desc(gfx.Backend) &gfx.ShaderDesc

// Vertex_t makes it possible to model vertex buffer data
// for use with the shader system
struct Vertex_t {
	// Position
	x f32
	y f32
	z f32
	// Color
	r f32
	g f32
	b f32
	a f32
	// uv
	u f32
	v f32
}

//
//
//

fn create_texture(imgpath string) (gfx.Image, gfx.Sampler) {
	data := stbi.load(imgpath, stbi.LoadParams{4}) or {
		println('Failed to load image')
		panic(err)
	}

	println(data)

	mut img_desc := gfx.ImageDesc{
		width: data.width
		height: data.height
		pixel_format: .rgba8
		num_mipmaps: 0
		// wrap_u: .clamp_to_edge
		// wrap_v: .clamp_to_edge
		// min_filter: .linear
		// max_filter: .linear
		// usage: .dynamic
		label: &u8(0)
		d3d11_texture: 0
	}

	// println(tymeof(data.data[0]))

	// comment if .dynamic is enabled
	img_desc.data.subimage[0][0] = gfx.Range{
		ptr: data.data
		size: usize(data.width * data.height * 4)
	}

	println(img_desc)

	sg_img := gfx.make_image(&img_desc)

	// println(sg_img)

	mut smp_desc := gfx.SamplerDesc{
		min_filter: .linear
		mag_filter: .linear
		wrap_u: .clamp_to_border
		wrap_v: .clamp_to_border
	}

	sg_smp := gfx.make_sampler(&smp_desc)
	return sg_img, sg_smp
}

fn destroy_texture(sg_img gfx.Image) {
	gfx.destroy_image(sg_img)
}

//
//
//

fn main() {
	mut app := &App{
		width: 800
		height: 400
		pass_action: gfx.create_clear_pass_action(0.0, 0.0, 0.0, 1.0) // This will create a black color as a default pass (window background color)
	}
	app.run()
}

struct App {
	pass_action gfx.PassAction
mut:
	width           int
	height          int
	texture         gfx.Image
	sampler         gfx.Sampler
	shader_pipeline gfx.Pipeline
	bind            gfx.Bindings
}

fn (mut a App) run() {
	title := 'V Simple Shader Example'
	desc := sapp.Desc{
		width: a.width
		height: a.height
		user_data: a
		init_userdata_cb: init
		frame_userdata_cb: frame
		window_title: title.str
		html5_canvas_name: title.str
		cleanup_userdata_cb: cleanup
		sample_count: 4 // Enables MSAA (Multisample anti-aliasing) x4 on rendered output, this can be omitted.
	}

	sapp.run(&desc)
}

fn init(user_data voidptr) {
	mut app := unsafe { &App(user_data) }
	mut desc := sapp.create_desc()

	gfx.setup(&desc)

	app.texture, app.sampler = create_texture('testimg.png')

	vertices := [
		Vertex_t{-0.5, 0.5, 0.5, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0},
		Vertex_t{0.5, -0.5, 0.5, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0},
		Vertex_t{-0.5, -0.5, 0.5, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0},
		Vertex_t{0.5, 0.5, 0.5, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0},
	]

	indices := [
		u16(0),
		3,
		1,
		0,
		1,
		2,
	]

	mut vertex_buffer_desc := gfx.BufferDesc{
		label: c'triangle-vertices'
	}
	unsafe { vmemset(&vertex_buffer_desc, 0, int(sizeof(vertex_buffer_desc))) }

	vertex_buffer_desc.size = usize(vertices.len * int(sizeof(Vertex_t)))
	vertex_buffer_desc.data = gfx.Range{
		ptr: vertices.data
		size: vertex_buffer_desc.size
	}

	app.bind.vertex_buffers[0] = gfx.make_buffer(&vertex_buffer_desc)

	mut index_buffer_desc := gfx.BufferDesc{
		label: c'triangle-indices'
	}
	unsafe { vmemset(&index_buffer_desc, 0, int(sizeof(index_buffer_desc))) }

	index_buffer_desc.size = usize(indices.len * int(sizeof(u16)))
	index_buffer_desc.@type = .indexbuffer
	index_buffer_desc.data = gfx.Range{
		ptr: indices.data
		size: index_buffer_desc.size
	}

	app.bind.index_buffer = gfx.make_buffer(&index_buffer_desc)
	app.bind.fs.images[C.SLOT_tex] = app.texture
	app.bind.fs.samplers[C.SLOT_smp] = app.sampler

	shader := gfx.make_shader(C.simple_shader_desc(gfx.query_backend()))

	mut pipeline_desc := gfx.PipelineDesc{}
	unsafe { vmemset(&pipeline_desc, 0, int(sizeof(pipeline_desc))) }

	pipeline_desc.shader = shader
	pipeline_desc.layout.attrs[C.ATTR_vs_position].format = .float3
	pipeline_desc.layout.attrs[C.ATTR_vs_color0].format = .float4
	pipeline_desc.layout.attrs[C.ATTR_vs_texcoord].format = .float2
	pipeline_desc.index_type = .uint16
	pipeline_desc.label = c'triangle-pipeline'

	app.shader_pipeline = gfx.make_pipeline(&pipeline_desc)
}

fn cleanup(user_data voidptr) {
	gfx.shutdown()
}

fn frame(user_data voidptr) {
	mut app := unsafe { &App(user_data) }

	pass := sapp.create_default_pass(app.pass_action)
	gfx.begin_pass(&pass)

	gfx.apply_pipeline(app.shader_pipeline)
	gfx.apply_bindings(&app.bind)

	gfx.draw(0, 6, 1)

	gfx.end_pass()
	gfx.commit()
}
