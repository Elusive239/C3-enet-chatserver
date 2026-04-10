module app::ui;
import sdl3;
import sdl3_ttf;
import sdl3_image;
import std;

struct UIManager {
	Theme theme;
	SdlWindow* sdlwindow;
	SdlRenderer* renderer;
	List{UIWindow*} windows;
	UIWindow* active_window;
	SdlTTFFont* font;

	SdlTexture* window_cross_tex;
	SdlTexture* window_hide_tex;

	float mx, my;
	bool[5] mouse_current_state;
	bool[5] mouse_last_state;

	SdlCursor *cursor_arrow;
	SdlCursor *cursor_ibeam;
	SdlCursor *cursor_size_we;
	SdlCursor *cursor_size_ns;
	SdlCursor *cursor_size_nwse;
	SdlCursor *cursor_size_nesw;
}

fn void UIManager.init(&self) {
	const ZString TITLE = "Gui Client Example";
	const SCREEN_WIDTH  = 1920;
	const SCREEN_HEIGHT = 1080;

	self.theme = default_theme();
	self.windows.init(mem);
	self.sdlwindow   = sdl3::createWindow( TITLE, SCREEN_WIDTH,  SCREEN_HEIGHT, { 	.resizable = true, } ); // windowFlags
	self.renderer = sdl3::createRenderer(self.sdlwindow, null);

	self.cursor_arrow = sdl3::createSystemCursor(SdlSystemCursor.DEFAULT);
	self.cursor_ibeam = sdl3::createSystemCursor(SdlSystemCursor.TEXT);
	self.cursor_size_we = sdl3::createSystemCursor(SdlSystemCursor.EW_RESIZE);
	self.cursor_size_ns = sdl3::createSystemCursor(SdlSystemCursor.NS_RESIZE);
	self.cursor_size_nwse = sdl3::createSystemCursor(SdlSystemCursor.NWSE_RESIZE);
	self.cursor_size_nesw = sdl3::createSystemCursor(SdlSystemCursor.NESW_RESIZE);
	sdl3::setCursor(self.cursor_arrow);

	self.font = sdl3_ttf::openFont("resources/fonts/swansea-font/Swansea-q3pd.ttf", 13f);
	self.window_cross_tex = load_image("resources/images/ui/titlebar0.png");
	self.window_hide_tex = load_image("resources/images/ui/titlebar1.png");
	io::printfn("Ready!");
}

fn UIManager* manager() {
	static UIManager manager;
	if(!manager.windows.is_initialized()) manager.init();
	return &manager;
}

fn void render() {
	UIManager* manager = ui::manager();
	foreach ( window : manager.windows) {
		window.render(manager.renderer);
	}
}

fn void process() {
	UIManager* manager = ui::manager();
	sdl3::getMouseState(&manager.mx, &manager.my);

	//TODO: Handle active window
	static UIResizeDirection res_dir = RESIZE_NONE;
	if(manager.active_window )
	{
		UIWindow* aw = manager.active_window;
		if(!aw.is_resized && aw.resizeable)
		{
			res_dir = setWindowResizeCursor(aw, manager.mx, manager.my);

			if(mouseButton(LEFT) == MOUSEBUTTON_HELD)
			{
				aw.is_resized = true;
			}
		}

		if(aw.is_resized && !aw.is_dragged)
		{
			resizeWindow(aw, res_dir, manager.mx, manager.my);
			// sdl3::destroyTexture(aw.tex_rect);
			// aw.tex_rect = sdl3::createTexture(manager.renderer, RGBA8888, TARGET, aw.w, aw.h);
		}
		if(mouseButton(LEFT) == MOUSEBUTTON_RELEASED && aw.is_resized)
		{
			aw.is_resized = false;
			sdl3::setCursor(manager.cursor_arrow);
		}
	}



	if(mouseButton(LEFT) == MOUSEBUTTON_PRESSED && sdl3::getCursor() == manager.cursor_arrow)
	{
		UIWindow *wnd;
		SdlFRect r;
		bool hovers_window = false;
		SdlFPoint mxy = {manager.mx, manager.my};
		int index=0;

		for (int i = 0; i < manager.windows.len(); ++i)
		{
			wnd = manager.windows[i];

			if(!wnd.is_hidden)
			{
				r = {wnd.x, wnd.y, wnd.w, wnd.h + TITLEBAR_HEIGHT};

				if(sdl3::pointInRectFloat(&mxy, &r))
				{
					index = i;
					hovers_window = true;
				}
			}
		}

		if(manager.windows[index] != manager.active_window && hovers_window)
		{
			setActiveWindow((UIWindow*)manager.windows[index]);
		}
		else if(!hovers_window)
		{
			setActiveWindow(null);
		}
	}

	// Handle window process
	foreach ( window : manager.windows) {
		window.process();
	}
	
	// record mouse state
	for(int i = 0; i < manager.mouse_current_state.len; i++){
		manager.mouse_last_state[i] = manager.mouse_current_state[i];
	}
}

fn void handleEvent(SdlEvent* event) {
	UIManager* manager = ui::manager();
	switch (event.type) {
		case MOUSE_BUTTON_DOWN:
			int mbutton = event.button.button;
			manager.mouse_current_state[mbutton] = true;
		case MOUSE_BUTTON_UP:
			int mbutton = event.button.button;
			manager.mouse_current_state[mbutton] = false;
	}
}

fn UIMouseButton mouseButton(SdlMouseButtonFlags mbuttons)
{
	UIManager* manager = ui::manager();
	int mbutton = (int) mbuttons;
	if(manager.mouse_current_state[mbutton] && !manager.mouse_last_state[mbutton])
	{
		return MOUSEBUTTON_PRESSED;
	}
	else if(manager.mouse_current_state[mbutton] && manager.mouse_last_state[mbutton])
	{
		return MOUSEBUTTON_HELD;
	}
	else if(!manager.mouse_current_state[mbutton] && manager.mouse_last_state[mbutton])
	{
		return MOUSEBUTTON_RELEASED;
	}

	return MOUSEBUTTON_NONE;
}

fn void setActiveWindow(UIWindow* window) {
	UIManager* manager = ui::manager();
	if(manager.active_window ) {
		manager.active_window.is_active = false;
	}
	manager.active_window = window;
	if(window == null ) return;
	manager.active_window.is_active = true;
	// make sure the active window is the one being rendererd first...
	(void) manager.windows.remove_item(window);
	manager.windows.push(window);
}

fn void resizeWindow(UIWindow *aw, UIResizeDirection res_dir, float mx, float my){
	UIManager* manager = ui::manager();
	if(res_dir == RESIZE_RIGHT)
	{
		aw.w = mx - aw.x;
	}
	else if(res_dir == RESIZE_LEFT)
	{
		float old_x = aw.x;
		aw.w += aw.x - mx;
		if(aw.w > WINDOW_MIN_SIZE)
		{
			aw.x = mx;
		}

		for (int i = 0; i < aw.children.len(); ++i)
		{
			UIBase* child = aw.children[i].ptr;
			child.x += aw.x - old_x;
		}
	}
	else if(res_dir == RESIZE_BOTTOM)
	{
		aw.h = my - aw.y;
	}
	else if(res_dir == RESIZE_TOP)
	{
		float old_y = aw.y;
		aw.h += aw.y - my;
		if(aw.h > WINDOW_MIN_SIZE)
		{
			aw.y = my;
		}

		for (int i = 0; i < aw.children.len(); ++i)
		{
			UIBase* child = aw.children[i].ptr;
			child.y += aw.y - old_y;
		}
	}
	else if(res_dir == RESIZE_LEFT_TOP)
	{
		float old_x = aw.x;
		float old_y = aw.y;
		aw.w += aw.x - mx;
		if(aw.w > WINDOW_MIN_SIZE)
		{
			aw.x = mx;
		}
		aw.h += aw.y - my;
		if(aw.h > WINDOW_MIN_SIZE)
		{
			aw.y = my;
		}

		for (int i = 0; i < aw.children.len(); ++i)
		{
			UIBase* child = aw.children[i].ptr;
			child.x += aw.x - old_x;
			child.y += aw.y - old_y;
		}
	}
	else if(res_dir == RESIZE_RIGHT_TOP)
	{
		float old_y = aw.y;
		aw.h += aw.y - my;
		if(aw.h > WINDOW_MIN_SIZE)
		{
			aw.y = my;
		}
		aw.w = mx - aw.x;

		for (int i = 0; i < aw.children.len(); ++i)
		{
			UIBase* child = aw.children[i].ptr;
			child.y += aw.y - old_y;
		}
	}
	else if(res_dir == RESIZE_LEFT_BOTTOM)
	{
		float old_x = aw.x;
		aw.w += aw.x - mx;
		if(aw.w > WINDOW_MIN_SIZE)
		{
			aw.x = mx;
		}
		aw.h = my - aw.y;

		for (int i = 0; i < aw.children.len(); ++i)
		{
			UIBase* child = aw.children[i].ptr;
			child.x += aw.x - old_x;
		}
	}
	else if(res_dir == RESIZE_RIGHT_BOTTOM)
	{
		aw.w = mx - aw.x;
		aw.h = my - aw.y;
	}

	aw.w = math::clamp(aw.w, 120, 10000);
	aw.h = math::clamp(aw.h, 120, 10000);
}


fn UIResizeDirection setWindowResizeCursor(UIWindow *wnd, float mousex, float mousey) {
	UIManager* manager = ui::manager();
	float x = wnd.x;
	float y = wnd.y;
	float w = wnd.w;
	float h = wnd.h;

	SdlFRect left, top, right, bottom, lt, rt, lb, rb;
	left = {x-8, y, 8, h};
	top = {x, y-8, w, 8};
	right = {x+w, y, 8, h};
	bottom = {x, y+h, w, 8};

	lt = {x-8, y-8, 8, 8};
	rt = {x+w, y-8, 8, 8};
	lb = {x-8, y+h, 8, 8};
	rb = {x+w, y+h, 8, 8};

	SdlFPoint mp = {mousex, mousey};

	if(sdl3::pointInRectFloat(&mp, &left))
	{
		sdl3::setCursor(manager.cursor_size_we);
		return RESIZE_LEFT;
	}
	else if(sdl3::pointInRectFloat(&mp, &top))
	{
		sdl3::setCursor(manager.cursor_size_ns);
		return RESIZE_TOP;
	}
	else if(sdl3::pointInRectFloat(&mp, &right))
	{
		sdl3::setCursor(manager.cursor_size_we);
		return RESIZE_RIGHT;
	}
	else if(sdl3::pointInRectFloat(&mp, &bottom))
	{
		sdl3::setCursor(manager.cursor_size_ns);
		return RESIZE_BOTTOM;
	}
	else if(sdl3::pointInRectFloat(&mp, &lt))
	{
		sdl3::setCursor(manager.cursor_size_nwse);
		return RESIZE_LEFT_TOP;
	}
	else if(sdl3::pointInRectFloat(&mp, &rt))
	{
		sdl3::setCursor(manager.cursor_size_nesw);
		return RESIZE_RIGHT_TOP;
	}
	else if(sdl3::pointInRectFloat(&mp, &lb))
	{
		sdl3::setCursor(manager.cursor_size_nesw);
		return RESIZE_LEFT_BOTTOM;
	}
	else if(sdl3::pointInRectFloat(&mp, &rb))
	{
		sdl3::setCursor(manager.cursor_size_nwse);
		return RESIZE_RIGHT_BOTTOM;
	}

	sdl3::setCursor(manager.cursor_arrow);

	return RESIZE_NONE;
}

fn SdlTexture* render_static_text(String text, SdlColor color) { //for creating labels that don't change
	UIManager* manager = ui::manager();
	SdlSurface *s = sdl3_ttf::renderText_Blended(manager.font, text.ptr, text.len, color);
	defer sdl3::destroySurface(s);
	return sdl3::createTextureFromSurface(manager.renderer, s);
}

fn SdlTexture* load_image(ZString path) {
	UIManager* manager = ui::manager();
	SdlSurface *s = sdl3_image::load( (char*)path); 
	defer sdl3::destroySurface(s);
	return sdl3::createTextureFromSurface(manager.renderer, s);
}