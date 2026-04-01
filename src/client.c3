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

	ChatClient tuple = {client, {true}};

	Thread thread;
	thread.create( (ThreadFn) &client_event_loop,  &tuple)!!;

	client_user_input(peer, username, &tuple.running);

	tuple.running.store(false);
	(void) thread.join();
	enet::peer_disconnect(peer, 0);
	enet::host_flush(client);
	enet::peer_reset(peer);
	// END HERE
	return 0;
}

struct ChatClient {
	ENetHost* client;
	Atomic{bool} running;
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

fn int client_event_loop(ChatClient* tuple) {
	ENetHost* client = tuple.client;

	int user_id;

	ClientMap otherclients;
	otherclients.init(mem);
	defer { 
		foreach(ClientData* data : otherclients.value_iter()) {
			if(data.username.len > 0) data.username.free(mem);
			mem::free(data);
		}
		otherclients.free();
	}

	tuple.running.store(true);
	ENetEvent event;
	while( tuple.running.load() == true) {
		while(enet::host_service(client, &event, 0) ) {
			defer enet::packet_destroy(event.packet);
			switch(event.type) {
				case ENET_EVENT_TYPE_RECEIVE: 
					Packet? packet = common::parse_packet(event.packet.data);
					if(catch err = packet) {
						io::printfn("Recieved bad packet from server! ERROR %s", err);
						break;
					}
					// Packet packet;
					defer common::destroy_packet(packet);
					// io::printfn("Recieved Packet of Type %s!", packet.ptype.nameof);
					switch(packet.ptype) {
						case PacketType.HANDSHAKE: 
							user_id = packet.handshake.recieved_id;
							foreach(newclient : packet.handshake.connected_clients) {
								if(newclient.id == user_id) continue;
								ClientData* copy = mem::new(ClientData);
								otherclients[newclient.id] = copy;
								copy.id = newclient.id;
								copy.username = newclient.username.copy(mem);
							}
							case PacketType.USER_JOIN:
								if(user_id == packet.userjoin.id) continue;
								ClientData* newclient = mem::new(ClientData);
								newclient.id = packet.userjoin.id;
								newclient.username = packet.userjoin.username.copy(mem);
								otherclients[newclient.id] =newclient;
								io::printfn("'%s' joined the server! Say hi!", newclient.username);
							case PacketType.USER_MESSAGE:
								int id = packet.usermsg.id;
								if(user_id == id) continue;
								String message = packet.usermsg.message;
								io::printfn("%s: %s", otherclients[id].username, message)!!;
						default: io::printfn("Unhandled packet type %s recieved...", packet.ptype.nameof);
					}

				case ENET_EVENT_TYPE_DISCONNECT:
					tuple.running.store(false);
					io::printfn("Lost connection to server. Reason: SERVER SHUTDOWN or MANUAL CLOSE");
				case ENET_EVENT_TYPE_DISCONNECT_TIMEOUT:
					tuple.running.store(false);
					io::printfn("Lost connection to server. Reason: TIMEOUT");
				default: io::printfn("EVENT TYPE: %s", event.type.nameof); break;
			}
		}
	}


	return 0;
}