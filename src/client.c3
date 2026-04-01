module app;
import std::io, std::atomic, std::thread;
import enet;

fn int run_client(String uname) {
	String username = uname.copy(mem); 
	defer username.free(mem);
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

	Atomic{bool} running;

	ChatClient cli = {};
	cli.init(client, username, &running);

	Thread thread;
	thread.create( (ThreadFn) &client_event_loop,  &cli)!!;

	client_user_input(peer, username, &running);

	running.store(false);
	(void) thread.join();
	enet::peer_disconnect(peer, 0);
	enet::host_flush(client);
	enet::peer_reset(peer);
	// END HERE
	return 0;
}

fn void client_user_input(ENetPeer* server , String username, Atomic{bool}* running) {
	io::printfn("Client %s has connected! Say hi!", username);

	while( running.load()) {
		String msg = io::treadline()!!;
		if(msg.len  == 0) continue;
		if(msg == "/quit" || msg == "/exit"){ 
			running.store(false); 
			break;
		}
		common::send_broadcast(server, msg)!!;
		io::printfn("%s: %s", username, msg);
	}
}

struct ChatClient {
	inline ENetHost* client;
	Atomic{bool}* cont;
	int id;
	String username;
	ClientMap otherclients;
}

fn void ChatClient.init(&self, ENetHost* enetclient, String username, Atomic{bool}* cont) {
	self.client = enetclient;
	// make a copy so we dont run into weird concurrency issues
	self.username = username.copy(mem);
	self.cont = cont;
	self.cont.store(true);
	self.otherclients.init(mem);
}

macro bool ChatClient.running(&self) => self.cont.load();

macro void ChatClient.end(&self) => self.cont.store(false);

fn void ChatClient.free(&self) {
	foreach(ClientData* data : self.otherclients.value_iter()) {
		if(data.username.len > 0) data.username.free(mem);
		mem::free(data);
	}
	self.otherclients.free();
	self.username.free(mem);
}

fn int client_event_loop(ChatClient* client) {	
	defer client.free();

	ENetEvent event;
	while( client.running()) {
		while(enet::host_service(client.client, &event, 0) ) {
			switch(event.type) {
				case ENET_EVENT_TYPE_RECEIVE:			 client_on_recieve(client, &event);

				case ENET_EVENT_TYPE_DISCONNECT:	
				case ENET_EVENT_TYPE_DISCONNECT_TIMEOUT: client_on_disconnect(client, &event);
				default: io::printfn("EVENT TYPE: %s", event.type.nameof); break;
			}
		}
	}
	return 0;
}

fn void client_on_recieve(ChatClient* client, ENetEvent* event) {
	defer enet::packet_destroy(event.packet);
	Packet? packet = common::parse_packet(event.packet.data);
	if(catch err = packet) {
		io::printfn("Recieved bad packet from server! ERROR %s", err);
		return;
	}
	// Packet packet;
	defer common::destroy_packet(packet);
	// io::printfn("Recieved Packet of Type %s!", packet.ptype.nameof);
	switch(packet.ptype) {
		case PacketType.HANDSHAKE: 
			client.id = packet.handshake.recieved_id;
			foreach(newclient : packet.handshake.connected_clients) {
				if(newclient.id == client.id) break;
				ClientData* copy = mem::new(ClientData);
				client.otherclients[newclient.id] = copy;
				copy.id = newclient.id;
				copy.username = newclient.username.copy(mem);
			}
			case PacketType.USER_JOIN:
				if(client.id == packet.userjoin.id) break;
				ClientData* newclient = mem::new(ClientData);
				newclient.id = packet.userjoin.id;
				newclient.username = packet.userjoin.username.copy(mem);
				client.otherclients[newclient.id] =newclient;
				io::printfn("'%s' joined the server! Say hi!", newclient.username);
			case PacketType.USER_MESSAGE:
				int id = packet.usermsg.id;
				if(client.id == id) break;
				String message = packet.usermsg.message;
				io::printfn("%s: %s", client.otherclients[id].username, message)!!;
		default: io::printfn("Unhandled packet type %s recieved...", packet.ptype.nameof);
	}
}

fn void client_on_disconnect(ChatClient* client, ENetEvent* event) {
	if (event.type == ENET_EVENT_TYPE_DISCONNECT_TIMEOUT) {
		io::printfn("Lost connection to server. Reason: TIMEOUT");
	} else {
		io::printfn("Diconnected from server.");
	}
	client.end();
}