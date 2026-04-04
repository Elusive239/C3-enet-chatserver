module app;
import enet;
import sdl3;

fn void run_gui_client() {
	SdlWindow* window;
	SdlRenderer* renderer;

	const ZString TITLE = "Gui Client Example";
	const SdlColor BG = {0,0,0,0};
	const SCREEN_WIDTH  = 1920/2;
	const SCREEN_HEIGHT = 1080/2;

	sdl3::init( {
		.video = true
	} );
	defer sdl3::quit();
	sdl3::setLogOutputFunction(
		(SdlLogOutputFunction) &sdl_log_wrapper, 
		null
	); 

	window 	= sdl3::createWindow(
		TITLE,
		SCREEN_WIDTH, 
		SCREEN_HEIGHT,
		{
			.resizable = true,
		}
		// windowFlags
	);
	renderer = sdl3::createRenderer(window, "My Renderer");
	//RENDERER_ACCELERATED
	bool cont = true;
	while(cont) {
		cont = gui_client_handle_events();
		gui_client_render(renderer, BG);
	}
}

fn bool gui_client_handle_events() {
	SdlEvent e;
	bool cont = true;
	while(sdl3::pollEvent(&e)){
        // User requests quit
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

fn void gui_client_render(SdlRenderer* renderer, SdlColor bg) {
		// Set background color
	{
		// Initialize renderer color
    	sdl3::setRenderDrawColor(renderer, bg.r, bg.g, bg.b, bg.a);
    	// Clear screen
    	sdl3::renderClear(renderer);
	}

	// Render Custom Stuff Here
	{

	}
	
	// Update Screen
	sdl3::renderPresent(renderer);
	
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