module app::ui;
import sdl3;
import sdl3_ttf;
import sdl3_image;
import std;

const float TITLEBAR_HEIGHT = 25;
const float TITLEBAR_WIDGET_PADDING = 5f;
const float PADDING = 2.5f;

struct UIWindow (UIObject) {
	inline UIBase base;
	float drag_x;
	float drag_y;

	SdlTexture* title_tex;

	bool has_titlebar; 
	bool resizeable; // can the window be resized..
	bool is_resized; // has the window been resized
	bool is_minimized;
	bool is_dragged;
	bool is_minimize_hovered; 	// titlebar button minimize
	bool is_close_hovered;		// titlebar button close
	// list of children
	List{UIAny} children;
}

fn UIWindow* new_window(String windowname, float x, float y, float w, float h, bool has_titlebar = true, bool resizeable = true) {
	UIManager* manager = ui::manager();

	UIWindow* window = mem::new(UIWindow, (UIWindow){
		.base = { . rect = {x, y, w, h }}, 
		.has_titlebar = has_titlebar, 
		.resizeable = resizeable,
		.title_tex = render_static_text(windowname, {255, 255, 255, 255}),
	});
	manager.windows.push(window);
	return window;
}

fn void UIWindow.render(&this, SdlRenderer* renderer) @dynamic {
	if(this.is_hidden) return;

	if(this.is_minimized && this.has_titlebar) {
		render_titlebar(this, renderer);
		return;
	}

	UIManager* manager = ui::manager();

	SdlSurface* s = sdl3::createSurface((int)this.w, (int)this.h, RGBA8888);
	SdlTexture* window_tex = sdl3::createTextureFromSurface(renderer, s);
	sdl3::setRenderTarget(renderer, window_tex);
	defer sdl3::destroySurface(s);

	// Outline
	sdl3::setRenderDrawColor(renderer, ...manager.theme.window_background_0);

	SdlFRect padded = {
		this.x - (PADDING/2), this.y - (PADDING/2) , this.w + PADDING, this.h + PADDING 
 	};
	sdl3::renderFillRect(renderer, &padded);

	// Window part
	sdl3::setRenderDrawColor(renderer, ...manager.theme.window_background_1);
	sdl3::renderFillRect(renderer, &this.rect);

	// Title Bar
	if(this.has_titlebar) {
		render_titlebar(this, renderer);
	}

	foreach(child : this.children) {
		if(&((UIObject) child).render) ((UIObject)child).render(renderer);
		sdl3::setRenderTarget(renderer, window_tex);
	}

	sdl3::renderTexture(renderer, window_tex, null, &this.rect);
	sdl3::destroyTexture(window_tex);
}

fn void render_titlebar(UIWindow* this, SdlRenderer* renderer) {
	UIManager* manager = ui::manager();
	float tex_w, tex_h;
	SdlFRect titlebar = {
		this.x , this.y, this.w , TITLEBAR_HEIGHT 
	};

	if(this.is_active) {
		sdl3::setRenderDrawColor(renderer, ...manager.theme.window_titlebar_focused);
	} else {
		sdl3::setRenderDrawColor(renderer, ...manager.theme.window_titlebar_unfocused);
	}
	sdl3::renderFillRect(renderer, &titlebar);
	// Render Text
	if(this.title_tex) {
		sdl3::setRenderDrawColor(renderer, ...manager.theme.text_color_0);
		sdl3::getTextureSize( this.title_tex,&tex_w, &tex_h);
		SdlFRect r = {this.x + (TITLEBAR_HEIGHT/4), this.y + (TITLEBAR_HEIGHT/4), tex_w, tex_h};
		sdl3::renderTexture(renderer, this.title_tex, null, &r);
	}

	// Close Icon
	{
		sdl3::getTextureSize( manager.window_cross_tex,&tex_w, &tex_h);
		SdlFRect close_button = {
			this.x + this.w - tex_w, this.y,
			tex_w, tex_h
		};
		if(this.is_close_hovered && manager.active_window == this) {
			sdl3::setRenderDrawColor(renderer, ...manager.theme.highlight_0);
			sdl3::renderFillRect(renderer, &close_button);
		}

		sdl3::renderTexture(renderer, manager.window_cross_tex, null, &close_button);
	}
	// Hide Icon
	{
		float last = tex_w;
		sdl3::getTextureSize( manager.window_hide_tex,&tex_w, &tex_h);
		SdlFRect close_button = {
			this.x + this.w - (tex_w+last + TITLEBAR_WIDGET_PADDING ), this.y,
			tex_w, tex_h
		};	
		if(this.is_minimize_hovered && manager.active_window == this) {
			sdl3::setRenderDrawColor(renderer, ...manager.theme.highlight_0);
			sdl3::renderFillRect(renderer, &close_button);

		}
		sdl3::renderTexture(renderer, manager.window_hide_tex, null, &close_button);
	}
}

fn void UIWindow.process(&this) @dynamic {
	if(this.is_hidden) {
		return;
	}
	UIManager* manager = ui::manager();
	UIMouseButton state = ui::mouseButton(LEFT);


	// Title Bar
	if(this.has_titlebar && this == manager.active_window ) {
		if(state == MOUSEBUTTON_RELEASED || state == MOUSEBUTTON_NONE)
		{
			this.is_dragged = false;
		}
		SdlFPoint mxy = {manager.mx, manager.my};

		SdlFRect titlebar = {
			this.x, this.y, this.w, TITLEBAR_HEIGHT
		};

		if  (sdl3::pointInRectFloat(&mxy, &titlebar) ) {
			if(state == MOUSEBUTTON_PRESSED && !this.is_dragged) {
				this.is_dragged = true;
				this.drag_x = manager.mx - this.x;
				this.drag_y = manager.my - this.y;
				// setActiveWindow(this);
			}

		}

		if(state == MOUSEBUTTON_HELD && this.is_dragged) {
			sdl3::setCursor(manager.cursor_arrow);
			float old_x = this.x;
			float old_y = this.y;

			int window_w, window_h;
			sdl3::getWindowSize(manager.sdlwindow, &window_w, &window_h);
			this.x = math::min( math::max( (float) manager.mx - this.drag_x, 0f), (float) window_w - this.rect.w);
			this.y = math::min( math::max( (float) manager.my - this.drag_y, 0f), (float) window_h - this.rect.h);
			for (int i = 0; i < this.children.size; ++i)
			{
				UIBase* child = this.children[i].ptr; 
				child.x += this.x - old_x;
				child.y += this.y - old_y;
			}
		}
		
		float tex_w, tex_h;

		sdl3::getTextureSize( manager.window_cross_tex,&tex_w, &tex_h);
		SdlFRect close_button = {
			this.x + this.w - tex_w, this.y,
			tex_w, tex_h
		};

		float last = tex_w;
		sdl3::getTextureSize( manager.window_hide_tex,&tex_w, &tex_h);
		this.is_close_hovered = sdl3::pointInRectFloat(&mxy, &close_button);
		close_button.x += -(last + TITLEBAR_WIDGET_PADDING);
		this.is_minimize_hovered = sdl3::pointInRectFloat(&mxy, &close_button);
		
		if(this.is_minimize_hovered && state == MOUSEBUTTON_PRESSED) {
			this.is_minimized = !this.is_minimized; 
		}
		
		if(this.is_close_hovered && state == MOUSEBUTTON_PRESSED) {
			this.is_hidden = !this.is_hidden; 
		}
	}

	if(this.is_minimized) {
		return;
	}

	// if  (!this.is_active && sdl3::pointInRectFloat(&&{ (int)manager.mx, (int)manager.my}, &this.rect) && (state == MOUSEBUTTON_PRESSED)) {
	// 	setActiveWindow(this);
	// } 
	

	foreach(child : this.children) {
		if(&((UIObject) child).process) ((UIObject)child).process();
	}
}
