module app;
import enet;
import sdl3;
import sdl3_ttf;
import app::ui;
import std;

struct GuiClient {
	SdlWindow* window;
	SdlRenderer* renderer;
	SdlTTFFont* font;
}

fn GuiClient* GuiClient.init(&self) {
	const ZString TITLE = "Gui Client Example";
	const SCREEN_WIDTH  = 1920;
	const SCREEN_HEIGHT = 1080;

	sdl3::init( {
		.video = true
	} );
	sdl3_ttf::init();

	sdl3::setLogOutputFunction( (SdlLogOutputFunction) &sdl_log_wrapper,  null); 

	// https://www.fontspace.com/swansea-font-f5873
	const ZString FONT_PATH = "resources/fonts/swansea-font/Swansea-q3pd.ttf";

	const FONT_SIZE = 12;

	self.font = sdl3_ttf::openFont(FONT_PATH, FONT_SIZE);
	if (!self.font) {
    	elog("Couldn't load font: %s", sdl3::getError());
    	return FAILED_TO_LOAD_FONT~!!;
	}
	self.window   = sdl3::createWindow( TITLE, SCREEN_WIDTH,  SCREEN_HEIGHT, { 	.resizable = true, } ); // windowFlags
	self.renderer = sdl3::createRenderer(self.window, null);
	return self;
}

macro void GuiClient.destroy(self) {
	sdl3::quit();
	sdl3_ttf::quit();
}

fn void run_gui_client() {
	const SdlColor BG = {0,0,0,255};
	// GuiClient* client = ((GuiClient){}).init();
	// defer client.destroy();
	//RENDERER_ACCELERATED
	bool cont = true;

	sdl3::init( {
		.video = true
	} );
	sdl3_ttf::init();
	defer {
		sdl3::quit();
		sdl3_ttf::quit();
	};
	sdl3::setLogOutputFunction( (SdlLogOutputFunction) &sdl_log_wrapper,  null); 

	UIManager* manager = ui::manager();

	UIWindow* a = ui::new_window("Albert",50, 50, 500, 500);
	// UIWindow* b = ui::new_window("Chris",50, 50, 300, 300);
	// UIWindow* c = ui::new_window("Jill",90, 200, 140, 500);
	// UILabel* label = ui::new_label(a, "Hello!", 20, 10);

	UIButton* button = ui::new_button(a, "Hello!", 80, 80, 60, 30);

	while(cont) {
		
		cont = gui_client_handle_events();
		ui::process();

		if(button.clicked()) {
			io::printfn("Clicked me!");
		}
		
		// Initialize renderer color
    	sdl3::setRenderDrawColor(manager.renderer, ...BG);
    	// Clear screen
    	sdl3::renderClear(manager.renderer);

		ui::render();
		// gui_client_render(client,  BG);
		sdl3::renderPresent(manager.renderer);
	}
}

fn bool gui_client_handle_events() {
	float mouse_x;
	float mouse_y;

	SdlMouseButtonFlags flags =  sdl3::getRelativeMouseState(
		&mouse_x, &mouse_y
	);

	SdlEvent e;
	bool cont = true;
	while(sdl3::pollEvent(&e)){
        // User requests quit
		ui::handleEvent(&e);
        if(e.type == QUIT){
			log("Quitting...");
            cont = false;
			break;
        } else if(e.type == KEY_DOWN) {
			SdlEvent game_quit = {
				.quit = {
					QUIT,
					0, // reserved 
					0  // timestamp
				},
			};
            switch (e.key.key ) {
            	case KEY_ESCAPE: sdl3::pushEvent(&game_quit);
				default: break;
			}
		}
	}
	return cont;
}

fn void gui_client_render( GuiClient* client, SdlColor bg) {
		// Set background color
	{
		// Initialize renderer color
    	sdl3::setRenderDrawColor(client.renderer, bg.r, bg.g, bg.b, bg.a);
    	// Clear screen
    	sdl3::renderClear(client.renderer);
	}

	// Render Custom Stuff Here
	{
		const String TEXT = "put your text here";
		SdlFRect last = render_message( client, TEXT, 0, 0);

		const SdlRect TEXT_INPUT_AREA = {1920/2, 1080/2, 200,200};
		static int cursor = 0;
		if(!sdl3::setTextInputArea(client.window, &TEXT_INPUT_AREA, cursor) ) {

		}
	}
	
	// Update Screen
	sdl3::renderPresent(client.renderer);
	
}

fn SdlFRect render_message(GuiClient* client, String text, int posx, int posy) {
	const WIDTH = 800;
	const MAX_HEIGHT = 500;
	// https://stackoverflow.com/questions/22886500/how-to-render-text-in-sdl2
	sdl3_ttf::setFontSize(client.font, 36);
	
	// sdl3_ttf::setFontCharSpacing(client.font,1);
	SdlTTFTextEngine* engine = sdl3_ttf::createRendererTextEngine(client.renderer);
	defer sdl3_ttf::destroyRendererTextEngine(engine);
	SdlTTFText* outtext = sdl3_ttf::createText( engine, client.font, text.ptr,text.len);
	defer sdl3_ttf::destroyText(outtext);
	int w, h;
	float padding = 5;
	int fontskip = 33 + 32; 
	sdl3_ttf::setFontLineSkip(client.font, fontskip);
	// log("Font skip: %s", fontskip);
	sdl3_ttf::setTextWrapWidth(outtext, (int) (WIDTH));
	sdl3_ttf::getTextSize(outtext, & w, & h);
	SdlFRect backpanel = {
		posx, posy,
		WIDTH + padding,
		min(h, MAX_HEIGHT) + padding
	};
    sdl3::setRenderDrawColor(client.renderer, 0, 80, 80, 255);
	sdl3::renderFillRect(client.renderer, &backpanel);
	sdl3_ttf::drawRendererText(outtext, backpanel.x + (padding/2), backpanel.y + (padding/2));
	return backpanel;
}

fn void sdl_log_wrapper(void* userdata, SdlLogCategory category, SdlLogPriority priority, ZString message) {
	switch (priority) {
		case INFO: 	ilog("%s", message);
		case WARN: 	wlog("%s", message);
		case ERROR: 	
		case CRITICAL: elog("%s", message);
		case DEBUG:	
		case VERBOSE: 	
		default:					log("%s", message);
	}
}