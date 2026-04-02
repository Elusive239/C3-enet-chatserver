module app;
import enet;

fn void main(String[] args) {
	if($feature(SERVER)) {
		run_server();
	} else {
		String uname = args[1];
		run_client(uname);
	}
}