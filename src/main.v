module main

import backend
import helper

fn main() {
	mut app := &backend.App{
		width: 800
		height: 800
		pass_action: backend.get_default_passaction()
	}
	app.run()
}
