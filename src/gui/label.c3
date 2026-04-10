module app::ui;
import sdl3;
import sdl3_image;
import sdl3_ttf;

struct UILabel (UIObject) {
	inline UIBase base;
	SdlTexture* label_tex;
}

fn UILabel* new_label(UIWindow* parent, String text, float x, float y) {
	UIManager* manager = ui::manager();
	UILabel* label = mem::new(UILabel, { .base = {.rect ={x + parent.x, y + parent.y + TITLEBAR_HEIGHT, 0, 0}} });
	label.label_tex = render_static_text(text, manager.theme.text_color_2);
	sdl3::getTextureSize(label.label_tex, &label.w, &label.h);
	parent.children.push(label);
	return label;
}

fn void UILabel.render(&this, SdlRenderer* renderer) @dynamic {
	if(this.is_hidden) return;
	UIManager* manager = ui::manager();
	
	sdl3::setRenderDrawColor(renderer, ...manager.theme.window_background_2);
	float padd = PADDING*2;
	SdlFRect padded = {
		this.x - (padd/2),
		this.y - (padd/2),
		this.w + padd,
		this.h + padd,
	};
	sdl3::renderFillRect(renderer, &padded);
	sdl3::renderTexture(renderer, this.label_tex, null, &this.rect);
}
