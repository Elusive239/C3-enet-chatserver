module app;
import std::io, std::atomic, std::thread;
import enet;

fn int run_test_client() {
	String username = "username1";

	if (enet::initialize () != 0) {
        io::eprintf("An error occurred while initializing ENet.\n");
        return -1;
    }
    defer enet::deinitialize();

	ENetHost* client = enet::host_create(null, 1, 1, 0, 0);

	if( !client) {
		io::eprintfn("An error occurred while trying to create an ENet client host!");
		return -1;
	}

	ENetAddress address;
	ENetEvent event;
	ENetPeer* peer;

	ZString hostname = "127.0.0.1";
	ushort port = 7777;
	enet::address_set_host(&address, hostname);
	address.port = port;
	
	peer = enet::host_connect(client, &address, 1, 0);

	if(!peer) {
		io::eprintfn("No available peers for initiating an ENet connection!");
		return -1;
	}

	if(  enet::host_service(client, &event, 5000) > 0 && event.type == ENET_EVENT_TYPE_CONNECT) {
		io::printfn("Connected to %s:%s successfully!", hostname, port);
	}else {
		enet::peer_reset(peer);
		io::printfn("Connection to %s:%s failed!", hostname, port);
		return 0;
	}

	// START HERE
	common::send_username(peer, username)!!;

	common::send_broadcast(peer, "This is a message to our server!")!!;
	enet::host_flush(client);
	enet::peer_disconnect(peer, 0);

	enet::host_flush(client);
	enet::peer_reset(peer);
	return 0;
}