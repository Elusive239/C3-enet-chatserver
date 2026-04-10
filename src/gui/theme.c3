module app::ui;
import sdl3;

alias Color = SdlColor;

struct Theme {
	Color window_background_0;
	Color window_background_1;
	Color window_background_2;
	Color window_titlebar_focused;
	Color window_titlebar_unfocused;
	Color highlight_0;
	Color highlight_1;
	Color highlight_2;
	Color text_color_0;
	Color text_color_1;
	Color text_color_2;
}

macro Theme default_theme() {
	return {
		.window_background_0 		= {80,80,80,255},
		.window_background_1 		= {35,35,35,255},
		.window_background_2 		= {60,60,60,255},
		.window_titlebar_focused 	= {10,10,10,255},
		.window_titlebar_unfocused 	= {30,30,30,255},
		.highlight_0				= {0, 100, 100, 255},
		.highlight_1				= {0, 100, 0, 255},
		.highlight_2  				= {200, 0, 0, 255},
		.text_color_0 				= {255, 255, 255, 255},
		.text_color_1 				= {255, 0, 0, 255},
		.text_color_2 				= {0, 255, 0, 255},
	};
}