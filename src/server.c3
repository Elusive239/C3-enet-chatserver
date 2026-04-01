module app;
import std::io;
import enet;

fn int run_server() {
	if (enet::initialize () != 0) {
        io::printf("An error occurred while initializing ENet.\n");
        return 1;
    }

    ENetAddress address = {};

    address.host = enet::get_host_any(); /* Bind the server to the default localhost.     */
    address.port = 7777; /* Bind the server to port 7777. */

	const int MAX_CLIENTS = 32;

    /* create a server */
    ENetHost * server = enet::host_create(&address, MAX_CLIENTS, 2, 0, 0);

    if (server == null) {
        io::printf("An error occurred while trying to create an ENet server host.\n");
        return 1;
    } else {
		io::printfn("Host Created: Socket  %s", server.socket);
		io::printfn("            : Address %s", server.address);
	}

	defer {
		enet::host_flush(server);
		enet::host_destroy(server);
		enet::deinitialize();
	};
    io::printf("Started a server...\n");
	server_event_loop(server);
	return 0;
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

	while(server.running()) while(enet::host_service(server, &event, 100) > 0) {
        switch (event.type) {
            case ENET_EVENT_TYPE_CONNECT:	server_on_connect(&server, &event);
			case ENET_EVENT_TYPE_RECEIVE:	server_on_recieve(&server, &event);
			case ENET_EVENT_TYPE_DISCONNECT:
			case ENET_EVENT_TYPE_DISCONNECT_TIMEOUT: server_on_disconnect(&server, &event);

			case ENET_EVENT_TYPE_NONE: io::printfn("No Event!"); break;
		}
	}

}

fn void server_on_connect(ChatServer* server, ENetEvent* event)  => @pool() {
	int newid = server.new_id();
    io::printf("A new client connected from %s:%s.\n",  event.peer.address.host, event.peer.address.port);
	event.peer.data = mem::new(ClientData,  {.id = newid});
	//Create a packet
	Packet newpacket = {
		.ptype = PacketType.HANDSHAKE,
		//Assign user ID to Packet
		.handshake.recieved_id = newid,
		//Add ClientData of other users (id/username) to Packet
		.handshake.connected_clients = server.clients.values(tmem),
	};
	common::send_packet(event.peer, newpacket)!!;
	server.clients[newid] = event.peer.data;
}

fn void server_on_recieve(ChatServer* server, ENetEvent* event) {
	defer enet::packet_destroy (event.packet);
	Packet? received = common::parse_packet( 
		event.packet.data
	);
	if(catch err = received) {
		io::printf("Recieved broken packet! ERROR: %s", err);
		return;
	}
	defer common::destroy_packet(received);

	switch(received.ptype ) {
		case PacketType.REGISTER:
			io::printfn("Recieved handshake '%s' from user %s!", 
				received.register.username,
				((ClientData*)event.peer.data).id
			);
			((ClientData*)event.peer.data).username = received.register.username.copy(mem); 
			Packet updatepacket = {
				.ptype = PacketType.USER_JOIN,
				.userjoin.id = 		 ((ClientData*)event.peer.data).id ,
				.userjoin.username = ((ClientData*)event.peer.data).username,
			};
			common::send_packet_all(server.server, updatepacket)!!;
		case PacketType.BROADCAST:
			io::printfn("Recieved msg '%s' from user %s!", 
				received.broadcast.message,
				((ClientData*)event.peer.data).username
			);
			int ignore_client = ((ClientData*)event.peer.data).id;
			
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
		default: io::printfn("Recieved an unhandled packet of type %s!", received.ptype.nameof);
	}
}

fn void server_on_disconnect(ChatServer* server, ENetEvent* event) {
	if(event.type == ENET_EVENT_TYPE_DISCONNECT_TIMEOUT) {
		io::printf("%s disconnected due to timeout.\n", event.peer);
	}else {
		io::printf("%s disconnected.\n", event.peer);
	}
	/* Reset the peer's client information. */
	ClientData* client = event.peer.data;
	server.clients.remove(client.id);
	client.free();
    event.peer.data = null;
}