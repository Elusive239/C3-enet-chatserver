module app;
import enet;

fn void main(String[] args) {
	if($feature(SERVER)) {
		run_server();
	} else {
		if(!$feature(TEST)) {
			String uname = args[1];
			run_client(uname);
		} else {
			run_test_client();
		}
	}
}