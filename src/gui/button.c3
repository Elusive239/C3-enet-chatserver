module app::ui;
import sdl3;
import sdl3_ttf;
import sdl3_image;


struct UIButton (UIObject) {
	inline UIBase base;
	UIButtonState state;
	float label_w;
	float label_h;
	SdlTexture* label_tex;
	bool clicked_this_frame;
}

fn UIButton* new_button(UIWindow* parent, String label, float x, float y, float w, float h ) {
	UIManager* manager = ui::manager();
	UIButton* button = mem::new(UIButton);
	button.rect = {x + parent.x, y + parent.y + TITLEBAR_HEIGHT, w, h};
	button.label_tex = render_static_text(label, manager.theme.text_color_0);
	sdl3::getTextureSize(button.label_tex, &button.label_w, &button.label_h);
	parent.children.push(button);
	return button;
}

fn void UIButton.render(&this, SdlRenderer* renderer) @dynamic {
	UIManager* manager = ui::manager();

	SdlFRect border = {
		this.x - (PADDING/2), this.y - (PADDING/2), this.w + PADDING, this.h + PADDING
	};

	sdl3::setRenderDrawColor(renderer, ...manager.theme.window_background_0);
	sdl3::renderFillRect(renderer, &border);

	switch (this.state) {
		case BUTTON_STATE_NORMAL: 
			sdl3::setRenderDrawColor(renderer, ...manager.theme.window_background_1);
		case BUTTON_STATE_HOVER: 
			sdl3::setRenderDrawColor(renderer, ...manager.theme.highlight_0);
		case BUTTON_STATE_CLICK: 
			sdl3::setRenderDrawColor(renderer, ...manager.theme.window_titlebar_focused);
	}
	sdl3::renderFillRect(renderer, &this.rect);

	SdlFRect text = {
		this.x + ((this.w - this.label_w)/2), 
		this.y + ((this.h - this.label_h)/2),
		this.label_w,
		this.label_h,
	};
	sdl3::renderTexture(renderer, this.label_tex, null, &text);
}

fn void UIButton.process(&this) @dynamic {
	UIManager* manager = ui::manager();
	UIMouseButton mb_state = mouseButton(LEFT);

	SdlFPoint mxy = {manager.mx, manager.my};
	bool contains = sdl3::pointInRectFloat(&mxy, &this.rect);
	this.clicked_this_frame = false;
	if( contains && mb_state == MOUSEBUTTON_NONE) {
		this.state = BUTTON_STATE_HOVER;
	} else if (contains && mb_state == MOUSEBUTTON_PRESSED) {
		this.state = BUTTON_STATE_CLICK;
		this.clicked_this_frame = true;
	} else if (contains && mb_state == MOUSEBUTTON_HELD) {
		this.state = BUTTON_STATE_CLICK;
	} else {
		this.state = BUTTON_STATE_NORMAL;
	}
}

fn bool UIButton.clicked(&this) {
	return this.clicked_this_frame;
}