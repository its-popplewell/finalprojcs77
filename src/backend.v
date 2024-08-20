module backend

import sokol.sapp
import sokol.gfx
import stbi
import math
import os

#include "@VMODROOT/simple_shader.h" # # It should be generated with `v shader .`

fn C.simple_shader_desc(gfx.Backend) &gfx.ShaderDesc

pub struct Vertex_Data {
	// position
	x f32
	y f32
	z f32
	// color
	r f32
	g f32
	b f32
	a f32
	// texture
	u f32
	v f32
	// id (0 if grid, 1 if sprite
	typeid i16
	id     i16
}

pub fn from_pixel_to_ogl(x int, y int, h int, w int) (f32, f32) {
	normx := f32(x) / f32(w)
	normy := 1 - (f32(y) / f32(h))
	return (normx * 2) - 1, normy * 2 - 1
}

pub fn generate_grid(height int, width int, unitsize int) ([]Vertex_Data, []u16) {
	assert math.mod(height, unitsize) == 0 && math.mod(width, unitsize) == 0

	num_squares_vert := height / unitsize
	num_squares_horz := width / unitsize

	mut outp_vert := []Vertex_Data{}
	mut outp_indx := []u16{}

	mut colr := f32(1.0)
	mut colg := f32(1.0)
	mut colb := f32(1.0)
	for x in 0 .. num_squares_horz {
		for y in 0 .. num_squares_vert {
			// println(x + y)
			if math.mod(x + y, 2) == 0 {
				colr = 0.290
				colg = 0.255
				colb = 0.255
			} else {
				colr = 0.980
				colg = 0.921
				colb = 0.921
			}

			// Corner X in picture space
			cx := x * unitsize
			cy := y * unitsize
			corners_x := [cx, cx + unitsize]
			corners_y := [cy, cy + unitsize]
			// other corners in picture space
			// convert all to ogl space

			mut corners_ogl_x := []f32{}
			mut corners_ogl_y := []f32{}
			for i in 0 .. 2 {
				for j in 0 .. 2 {
					normx := f32(corners_x[j]) / f32(width)
					normy := 1 - (f32(corners_y[i]) / f32(height))
					//println('Norms: ${normx} ${normy} XY: ${x} ${y} CXY: ${cx} ${cy}')
					corners_ogl_x << (normx * 2) - 1
					corners_ogl_y << (normy * 2) - 1
				}
			}

			// normx := f32(x * unitsize) / f32(width)
			// normy := f32((height - y) * unitsize) / f32(height)
			// xp := (normx * 2) - 1
			// yp := (normy * 2) - 1

			// minus 1 so that xyz coords have origin in top left corner
			// xp := (f32(x) * unitsize - (f32(width)/2.0)) / (f32(width) * 0.5)
			// yp := (f32(y) * unitsize - (f32(height)/2.0)) / (f32(height) * 0.5)
			// unitsize_w := unitsize / (f32(width) * 0.5)
			// unitsize_h := unitsize / (f32(height) * 0.5)
			boop_bop := [
				Vertex_Data{corners_ogl_x[0], corners_ogl_y[0], 0.5, colr, colg, colb, 1.0, 0.0, 0.0, i16(0), i16(0)},
				Vertex_Data{corners_ogl_x[1], corners_ogl_y[1], 0.5, colr, colg, colb, 1.0, 0.0, 0.0, i16(0), i16(0)},
				Vertex_Data{corners_ogl_x[2], corners_ogl_y[2], 0.5, colr, colg, colb, 1.0, 0.0, 0.0, i16(0), i16(0)},
				Vertex_Data{corners_ogl_x[3], corners_ogl_y[3], 0.5, colr, colg, colb, 1.0, 0.0, 0.0, i16(0), i16(0)},
			]

			boop_bop_i := [
				// tri 1
				u16(0 + outp_vert.len),
				u16(1 + outp_vert.len),
				u16(3 + outp_vert.len),
				// tri 2
				u16(0 + outp_vert.len),
				u16(3 + outp_vert.len),
				u16(2 + outp_vert.len),
			]

			outp_vert << boop_bop
			outp_indx << boop_bop_i
		}
	}

	//println(outp_vert)
	return outp_vert, outp_indx
}

fn new_vertex_data(x f32, y f32, z f32, r f32, g f32, b f32, u f32, v f32, tid i16, id i16) Vertex_Data {
	assert 0 <= u && u <= 1
	assert 0 <= v && v <= 1

	return Vertex_Data{x, y, z, r, g, b, 1.0, u, v, tid, id}
}

fn create_texture(imgpath string) (gfx.Image, gfx.Sampler) {
	assert os.exists(imgpath)

	data := stbi.load(imgpath, stbi.LoadParams{}) or {
		println('FAILED TO LOAD TEXTURE IMAGE')
		panic(err)
	}

	mut img_desc := gfx.ImageDesc{
		width: data.width
		height: data.height
		pixel_format: .rgba8
		num_mipmaps: 0
		label: &u8(0)
		d3d11_texture: 0
		// usage: .dynamic
	}
	// comment if .dynamic is enabled
	img_desc.data.subimage[0][0] = gfx.Range{
		ptr: data.data
		size: usize(data.width * data.height * 4)
	}
	sg_img := gfx.make_image(&img_desc)

	mut smp_desc := gfx.SamplerDesc{
		min_filter: .linear
		mag_filter: .linear
		wrap_u: .clamp_to_border
		wrap_v: .clamp_to_border
	}
	sg_smp := gfx.make_sampler(&smp_desc)

	return sg_img, sg_smp
}

pub struct App {
	pass_action gfx.PassAction
mut:
	num_indices     int
	width           int
	height          int
	texture         gfx.Image
	sampler         gfx.Sampler
	shader_pipeline gfx.Pipeline
	bind            gfx.Bindings
}

pub fn (mut a App) run() {
	title := 'V Simple Shader?'
	desc := sapp.Desc{
		width: a.width
		height: a.height
		user_data: a
		init_userdata_cb: init
		frame_userdata_cb: frame
		window_title: title.str
		html5_canvas_name: title.str
		cleanup_userdata_cb: cleanup
		sample_count: 4
	}

	sapp.run(&desc)
}

pub fn get_default_passaction() gfx.PassAction {
	return gfx.create_clear_pass_action(0.0, 0.0, 0.0, 1.0)
}

fn init(user_data voidptr) {
	mut app := unsafe { &App(user_data) }
	mut desc := sapp.create_desc()

	gfx.setup(&desc)

	app.texture, app.sampler = create_texture('testimg.png')

	// vertices := [
	//	Vertex_Data{-0.5, 0.5, 0.5, 1.0, 1.0, 0.0, 1.0, 0.0, 1.0},
	//	Vertex_Data{0.5, -0.5, 0.5, 1.0, 1.0, 0.0, 1.0, 1.0, 0.0},
	//	Vertex_Data{-0.5, -0.5, 0.5, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0},
	//	Vertex_Data{0.5, 0.5, 0.5, 1.0, 1.0, 0.0, 1.0, 1.0, 1.0},
	//]

	// indices := [
	//	u16(0),
	//	3,
	//	1,
	//	0,
	//	1,
	//	2,
	//]

	mut vertices, mut indices := generate_grid(app.height, app.width, 40)

	dx := [0, 40]
	dy := [0, 72]
	mut player := []Vertex_Data{}
	for i in 0 .. 2 {
		for j in 0 .. 2 {
			player_pos_x, player_pos_y := from_pixel_to_ogl(10 + dx[j], 20 + dy[i], app.height,
				app.width)
			player << Vertex_Data{player_pos_x, player_pos_y, 0.25, f32(100)/f32(255), f32(149)/f32(255), f32(237)/f32(255), 1.0, 0.0, 0.0, i16(1), i16(0)}
		}
	}

	vert_len := vertices.len
	vertices << player
	indices << [
		u16(0 + vert_len),
		u16(1 + vert_len),
		u16(3 + vert_len),
		u16(0 + vert_len),
		u16(3 + vert_len),
		u16(2 + vert_len),

		//u16(0), //+ u16(indices.len),
		//u16(1), //+ u16(indices.len),
		//u16(3), //+ u16(indices.len),
		//u16(0), //+ u16(indices.len),
		//u16(3), //+ u16(indices.len),
		//u16(2), //+ u16(indices.len),
	]

	//println(vertices)

	app.num_indices = indices.len

	mut vertex_buffer_desc := gfx.BufferDesc{
		label: c'vertices'
	}
	unsafe { vmemset(&vertex_buffer_desc, 0, int(sizeof(vertex_buffer_desc))) }

	vertex_buffer_desc.size = usize(vertices.len * int(sizeof(Vertex_Data)))
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
	// app.bind.fs.images[C.SLOT_tex] = app.texture
	// app.bind.fs.samplers[C.SLOT_smp] = app.sampler

	shader := gfx.make_shader(C.simple_shader_desc(gfx.query_backend()))

	mut pipeline_desc := gfx.PipelineDesc{}
	unsafe { vmemset(&pipeline_desc, 0, int(sizeof(pipeline_desc))) }

	pipeline_desc.shader = shader
	pipeline_desc.layout.attrs[C.ATTR_vs_position].format = .float3
	pipeline_desc.layout.attrs[C.ATTR_vs_color0].format = .float4
	pipeline_desc.layout.attrs[C.ATTR_vs_texcoord].format = .float2
	pipeline_desc.layout.attrs[C.ATTR_vs_id].format = .short2
	// pipeline_desc.layout.attrs[C.ATTR_vs_typeid].format = .ubyte4
	// pipeline_desc.layout.attrs[C.ATTR_vs_id].format = .ubyte4
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

	gfx.draw(0, app.num_indices, 1)

	gfx.end_pass()
	gfx.commit()
}
