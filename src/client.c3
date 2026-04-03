module app;
import std::io, std::atomic, std::thread;
import enet;

fn int run_client(String uname) {
	String username = uname.copy(mem); 
	defer username.free(mem);
	
	ENetHost*? client = client_create();
	if(catch client) return 1;

	ENetPeer*? server = client_connect(client);
	if(catch server) return 1;
	defer client_kill(client, server);
	

	// START HERE
	common::send_username(server, username)!!;

	Atomic{bool} running;

	ChatClient cli = {};
	cli.init(client, username, &running);

	Thread thread;
	thread.create( (ThreadFn) &client_event_loop,  &cli)!!;

	client_user_input(server, username, &running);

	running.store(false);
	(void) thread.join();
	
	// END HERE
	return 0;
}


fn ENetHost*? client_create() {
	if (enet::initialize () != 0) {
        elog("An error occurred while initializing ENet.");
        return FAILED_TO_INIT_ENET~;
    }

	ENetHost* client = enet::host_create(null, 1, 1, 0, 0);

	if( !client) {
		elog("An error occurred while trying to create an ENet client host!");
		return FAILED_TO_START_CLIENT~;
	}

	return client;
}

fn ENetPeer*? client_connect(ENetHost* client) {
	ENetAddress address;
	ZString hostname = "127.0.0.1";
	ushort port = 7777;
	enet::address_set_host(&address, hostname);
	address.port = port;
	
	ENetPeer* peer = enet::host_connect(client, &address, 1, 0);

	if(!peer) {
		elog("No available peers for initiating an ENet connection!");
		return FAILED_TO_CONNECT_TO_SERVER~;
	}

	ENetEvent event;
	if(  enet::host_service(client, &event, 5000) > 0 && event.type == ENET_EVENT_TYPE_CONNECT) {
		log("Connected to %s:%s successfully!", hostname, address.port);
	}else {
		enet::peer_reset(peer);
		elog("Connection to %s:%s failed!", hostname, address.port);
		return FAILED_TO_CONNECT_TO_SERVER~;
	}
	return peer;
}

fn void client_kill(ENetHost* client, ENetPeer* server) {
	enet::peer_disconnect(server, 0);
	enet::host_flush(client);
	enet::peer_reset(server);
	enet::deinitialize();
}

fn void client_user_input(ENetPeer* server , String username, Atomic{bool}* running) {
	log("Client %s has connected! Say hi!", username);

	while( running.load()) {
		String msg = io::treadline()!!;
		if(msg.len  == 0) {continue;}
		else if(msg == "/quit" || msg == "/exit"){ 
			running.store(false); 
			break;
		} else if (msg.len > 0 && msg[0] == '/') {
			int index = (int)msg.index_of(" ") ?? -1;
			String args = index < 0 ? "" : msg[index+1..];
			String cmd = msg[1..max(index, msg.len-1)];
			@pool() {
				Packet command = {
					.ptype = USER_COMMAND,
					.usercommand = {
						.command = cmd .copy(tmem), 
						.args    = args.trim().copy(tmem)
					}
				};
				common::send_packet(server, command)!!;
			};
		} else {
			common::send_broadcast(server, msg)!!;
			log("%s: %s", username, msg);
		}
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

fn int client_event_loop(ChatClient* client) => @pool_init(mem, 1024*4) {	
	defer client.free();

	ENetEvent event;
	while( client.running()) {
		while(enet::host_service(client.client, &event, 0) ) {
			switch(event.type) {
				case ENET_EVENT_TYPE_RECEIVE:			 client_on_recieve(client, &event);

				case ENET_EVENT_TYPE_DISCONNECT:	
				case ENET_EVENT_TYPE_DISCONNECT_TIMEOUT: client_on_disconnect(client, &event);
				default: ilog("EVENT TYPE: %s", event.type.nameof); break;
			}
		}
	}
	return 0;
}

fn void client_on_recieve(ChatClient* client, ENetEvent* event) {
	defer enet::packet_destroy(event.packet);
	Packet? packet = common::parse_packet(event.packet.data);
	if(catch err = packet) {
		elog("Recieved bad packet from server! ERROR %s", err);
		return;
	}
	// Packet packet;
	defer common::destroy_packet(packet);
	// log("Recieved Packet of Type %s!", packet.ptype.nameof);
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
				log("'%s' joined the server! Say hi!", newclient.username);
			case PacketType.USER_MESSAGE:
				int id = packet.usermsg.id;
				if(client.id == id) break;
				String message = packet.usermsg.message;
				log("%s: %s", client.otherclients[id].username, message)!!;
		default: elog("Unhandled packet type %s recieved...", packet.ptype.nameof);
	}
}

fn void client_on_disconnect(ChatClient* client, ENetEvent* event) {
	if (event.type == ENET_EVENT_TYPE_DISCONNECT_TIMEOUT) {
		elog("Lost connection to server. Reason: TIMEOUT");
	} else {
		ilog("Diconnected from server.");
	}
	client.end();
}