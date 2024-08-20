module main

import backend
import helper
import gg
import gx

fn main() {
	mut app := &backend.App{}

	app.gg = gg.new_context(
		width: 800
		height: 800
		create_window: true
		window_title: 'V Shader Shit'
		user_data: app
		bg_color: gx.white
		frame_fn: backend.app_frame
		init_fn: backend.app_init
		event_fn: backend.app_eventman
	)

	app.width = 800
	app.height = 800

	app.gg.run()
}
