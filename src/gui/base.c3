module app::ui;
import sdl3;

struct UIBase {
	union {
		struct {
			float x;
			float y;
			float w;
			float h;
		}
		SdlFRect rect;
	}
	bitstruct : char {
		// if the item is hidden
		bool is_hidden;
		bool is_enabled;
		bool is_active;
	}
	UIAny parent; //pointer + typeinfo
}

alias UIAny = any;

interface UIObject {
	fn void render(SdlRenderer* renderer) ;
	fn void process() @optional;
}