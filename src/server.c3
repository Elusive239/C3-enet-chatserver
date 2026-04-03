module app;
import std::io;
import enet;

fn int run_server() {
	ENetAddress address = {};

    address.host = enet::get_host_any(); /* Bind the server to the default localhost.     */
    address.port = 7777; /* Bind the server to port 7777. */

	const int MAX_CLIENTS = 32;

	ENetHost*? server = server_create(address, MAX_CLIENTS);
	if(catch err = server) return err~!!;
	defer server_kill(server);
    ilog("Started a server...");
	server_event_loop(server);
	return 0;
}


fn ENetHost*? server_create(ENetAddress address, int max_clients) {
	if (enet::initialize () != 0) {
        elog("An error occurred while initializing ENet.");
        return FAILED_TO_INIT_ENET~;
    }

    /* create a server */
    ENetHost * server = enet::host_create(&address, max_clients, 2, 0, 0);

    if (server == null) {
        elog("An error occurred while trying to create an ENet server host.");
        return FAILED_TO_START_SERVER~;
    } else {
		ilog("Host Created: Socket  %s | Address %s", server.socket, server.address);
	}
	return server;
}

fn void server_kill(ENetHost* server) {
	enet::host_flush(server);
	enet::host_destroy(server);
	enet::deinitialize();
}

struct ChatServer{
	inline ENetHost* server;
	ClientMap clients;
	int chat_id;
	bool cont;
}

fn void ChatServer.init(&self, ENetHost* server) {
	self.clients.init(mem);
	self.chat_id =0 ;
	self.server = server;
	self.cont = true;
}

fn int ChatServer.new_id(&self) {
	return self.chat_id++;
}

macro bool ChatServer.running(self) => self.cont;
macro void ChatServer.end(self) => self.cont = false;

fn void ChatServer.free(&self) {
	foreach(ClientData* data : self.clients.value_iter()) {
		if(data.username.len > 0) data.username.free(mem);
		mem::free(data);
	}
	self.clients.free();
}

fn void server_event_loop(ENetHost * enetserver) {
    ChatServer server;
	server.init(enetserver);
	ENetEvent event;
	defer server.free();

	while(server.running()) {
		while(enet::host_service(server, &event, 100) > 0) @pool() {
			switch (event.type) {
				case ENET_EVENT_TYPE_CONNECT:	server_on_connect(&server, &event);
				case ENET_EVENT_TYPE_RECEIVE:	server_on_recieve(&server, &event);
				case ENET_EVENT_TYPE_DISCONNECT:
				case ENET_EVENT_TYPE_DISCONNECT_TIMEOUT: server_on_disconnect(&server, &event);

				case ENET_EVENT_TYPE_NONE: 	ilog("No Event!"); break;
				default:					wlog("Unimplemented Event Type %s!", event.type); break;
			}
		};
	}
}

fn void server_on_connect(ChatServer* server, ENetEvent* event) {
	int newid = server.new_id();
	ClientData* data = mem::new(ClientData);
	data.id = newid;
    // ilog("A new client connected from %s:%s.",  event.peer.address.host, event.peer.address.port);
	enet::peer_set_data(event.peer, data);
	//Create a packet
	Packet newpacket = {
		.ptype = PacketType.HANDSHAKE,
		//Assign user ID to Packet
		.handshake.recieved_id = newid,
		//Add ClientData of other users (id/username) to Packet
		.handshake.connected_clients = server.clients.values(tmem),
	};
	common::send_packet(event.peer, newpacket)!!;
	server.clients[newid] = data;
}

fn void server_on_recieve(ChatServer* server, ENetEvent* event) {
	defer enet::packet_destroy (event.packet);
	Packet? received = common::parse_packet( 
		event.packet.data
	);
	if(catch err = received) {
		elog("Recieved broken packet! %s", err);
		return;
	}
	defer common::destroy_packet(received);

	ClientData* client = enet::peer_get_data(event.peer);
	switch(received.ptype ) {
		case PacketType.REGISTER: 
			ilog("Recieved handshake '%s' from user %s!", 
				received.register.username,
				client.id
			);
			client.username = received.register.username.copy(mem); 
			Packet updatepacket = {
				.ptype = PacketType.USER_JOIN,
				.userjoin.id = 		 client.id ,
				.userjoin.username = client.username,
			};
			common::send_packet_all(server.server, updatepacket)!!;
		case PacketType.BROADCAST:
			ilog("Recieved msg '%s' from user %s!", 
				received.broadcast.message,
				client.username
			);
			int ignore_client = client.id;
			
			// Get sender id, add to packet
			// Add message contents to packet
			Packet sendpacket = {
				.ptype = PacketType.USER_MESSAGE,
				.usermsg.id = ignore_client,
				// BAD IDEA?
				.usermsg.message = received.broadcast.message,
			};
			common::send_packet_all(server.server,  sendpacket)!!;
			// for each user
		case PacketType.USER_COMMAND: 
			switch(received.usercommand.command) {
				case "help": ilog("Need to list cmds");
				case "squit":
					ilog("Server shutting down...");
					server.end();
				default: 
					elog("invalid command recieved! %s -- %s", received.usercommand.command ,received.usercommand.args);

			}
		default: wlog("Recieved an unhandled packet of type %s!", received.ptype.nameof);
	}
}

fn void server_on_disconnect(ChatServer* server, ENetEvent* event) {
	ClientData* client = enet::peer_get_data(event.peer);
	defer client.free();
	if(event.type == ENET_EVENT_TYPE_DISCONNECT_TIMEOUT) {
		ilog("%s disconnected due to timeout.", client.username);
	}else {
		ilog("%s disconnected.", client.username);
	}
	/* Reset the peer's client information. */
	server.clients.remove(client.id);
    enet::peer_set_data(event.peer, null);
}