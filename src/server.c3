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

fn void server_event_loop(ENetHost * server) {
    ENetEvent event;
	bool running = true;
	int chat_id =0 ;

	ClientMap clients;
	clients.init(mem);
	defer { 
		foreach(ClientData* data : clients.value_iter()) {
			if(data.username.len > 0) data.username.free(mem);
			mem::free(data);
		}
		clients.free();
	}

	while(running) while(enet::host_service(server, &event, 0) > 0) {
        switch (event.type) {
            case ENET_EVENT_TYPE_CONNECT: @pool() {
                io::printf("A new client connected from %s:%s.\n",  event.peer.address.host, event.peer.address.port);
				
				event.peer.data = mem::new(ClientData,  {.id = chat_id});
				//Create a packet
				Packet newpacket = {
					.ptype = PacketType.HANDSHAKE,
					//Assign user ID to Packet
					.handshake.recieved_id = chat_id,
					//Add ClientData of other users (id/username) to Packet
					.handshake.connected_clients = clients.values(tmem),
				};

				//TODO: Length of packet is INCORRECT when "clients" has a user...
				common::send_packet(event.peer, newpacket)!!;
				clients[chat_id] = event.peer.data;
				chat_id++;
			};
			case ENET_EVENT_TYPE_RECEIVE:
				defer enet::packet_destroy (event.packet);
				Packet? received = common::parse_packet( 
					event.packet.data
				);
				if(catch err = received) {
					io::printf("Recieved broken packet! ERROR: %s", err);
					break;
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

						common::send_packet_all(server, updatepacket)!!;
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
						common::send_packet_all(server,  sendpacket)!!;
						// for each user
					default: io::printfn("Recieved an unhandled packet of type %s!", received.ptype.nameof);
				}

			case ENET_EVENT_TYPE_DISCONNECT:
				io::printf("%s disconnected.\n", event.peer);
                /* Reset the peer's client information. */
				ClientData* client = event.peer.data;
				clients.remove(client.id);
				client.free();
                event.peer.data = null;
				// running = false;
			case ENET_EVENT_TYPE_DISCONNECT_TIMEOUT:
			    io::printf("%s disconnected due to timeout.\n", event.peer);
                /* Reset the peer's client information. */
                event.peer.data = null;
				// running = false;
			case ENET_EVENT_TYPE_NONE:
				io::printfn("No Event!");
                break;
		}
	}

}