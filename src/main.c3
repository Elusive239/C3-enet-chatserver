module app;
import enet;
import std;

fn void main(String[] args) {
	const String LOG_FOLDER = "logs";
	String logname = LOG_FOLDER+++"/%s_%s.log"; //time_username OR time_server
	String filename;
	defer filename.free(mem);
	DateTime rn = datetime::now();
	if($feature(SERVER)) {
		filename = string::format(
			mem, logname, rn.format(mem, DateTimeFormat.DATETIME),"server" 
		);
	} else if(args.len > 1) {
		filename = string::format(
			mem, logname, rn.format(mem, DateTimeFormat.DATETIME),  args[1]
		);
	}

	@log_to_file(filename ) {
		if($feature(SERVER)) {
			run_server();
		} else {
			String uname = args[1];
			run_gui_client();
			// run_client(uname);
		}
	};
}