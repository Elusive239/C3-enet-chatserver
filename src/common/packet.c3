module app::common;
import std::io;
import enet;
import std::collections;

// Packet Data Types

enum PacketType : inline char {
	ERROR,			// No packet type = big problems!
	REGISTER,		// First packet sent by client, sends Username to server.
	
	HANDSHAKE,  	// Give the server assigned ID back to the client + currently connected users info. 
					// Also updates currently connected clients
	
	BROADCAST,		// Send a message to the server! or get a message from another client *throught* the server
	USER_JOIN,  	// Update other clients username/id map on REGISTER
	USER_MESSAGE,   // Send SenderId + Sender Message from a broadcast
	USER_COMMAND,	//
}

struct RegisterPacket {
	String username;
}

struct HandshakePacket {
	int recieved_id;
	ClientData*[] connected_clients;
}

struct BroadcastPacket {
	String message;
}

struct UserJoinPacket {
	int id;
	String username;
}

struct UserMessagePacket {
	int id;
	String message;
}

struct UserCommandPacket {
	String command;
	String args; //interpreted by server for now? maybe client should handle that...
}

// Packet Definition
/*
	1. Packet Type
	2. Packet Length
	3. Packet Data
*/
struct Packet {
	PacketType ptype;
	union {
		RegisterPacket register;
		HandshakePacket handshake;
		BroadcastPacket broadcast;
		UserJoinPacket userjoin;
		UserMessagePacket usermsg;
		UserCommandPacket usercommand;
	}
}

faultdef INVALID_PACKET_TYPE;

fn void? send_broadcast(ENetPeer* peer, String message) {
	send_packet(peer, {
		.ptype = PacketType.BROADCAST,
		.register.username = message,
	})!;
}

fn void? send_username(ENetPeer* peer, String username) {
	send_packet(peer, {
		.ptype = PacketType.REGISTER,
		.register.username = username,
	})!;
}

fn void? send_packet(ENetPeer* peer,  Packet packet) => @pool(){
	String buffer = write_packet(packet)!;
	ENetPacket* epacket = enet::packet_create( buffer.ptr, buffer.len, (uint) ENetPacketFlag.ENET_PACKET_FLAG_RELIABLE);
	enet::peer_send(peer, 0, epacket);
}

fn void? send_packet_all(ENetHost* server, Packet packet) => @pool(){
	String buffer = write_packet(packet)!;
	ENetPacket* epacket = enet::packet_create( buffer.ptr, buffer.len, (uint) ENetPacketFlag.ENET_PACKET_FLAG_RELIABLE);
	enet::host_broadcast(server, 0, epacket);
}

// Free Packet

fn void destroy_packet(Packet packet) {
	switch(packet.ptype) {
		case ERROR: 
			break;
		case HANDSHAKE: 	destroy_packet_data{HandshakePacket}(packet.handshake);
		case REGISTER:  	destroy_packet_data{RegisterPacket}(packet.register);
		case BROADCAST: 	destroy_packet_data{BroadcastPacket}(packet.broadcast);
		case USER_JOIN: 	destroy_packet_data{UserJoinPacket}(packet.userjoin);
		case USER_MESSAGE: 	destroy_packet_data{UserMessagePacket}(packet.usermsg);
		case USER_COMMAND: 	destroy_packet_data{UserCommandPacket}(packet.usercommand);
		default: unreachable("Unimplemented PacketType '%s'", packet.ptype.nameof);
	}
}

fn void destroy_packet_data(Type value) <Type> @if($defined(Type.membersof )) {
	$foreach $member : Type.membersof : 
		$switch :
			$case $typefrom($member.type) == String :
				value.$eval($member.nameof).free(mem);
			$case $typefrom($member.type) == ClientData*[]: 
				foreach (ClientData* client : value.$eval($member.nameof)) {
					client.free();
				}
				mem::free( value.$eval($member.nameof).ptr);
			$case $typefrom($member.type).kindof.@is_int() :
				{
					//we dont actually have to do anything here... Aint that neat!
				}
			$default: 
				{
					io::eprintfn("%s for %s is unimplemented!", $$FUNC, $typefrom($member.type).nameof );
				}
		$endswitch
	$endforeach
}

// Read Packet

fn Packet? parse_packet(char* data) {
	ByteReader reader = io::wrap_bytes(data[:(PacketType.sizeof + usz.sizeof)]);

	PacketType ptype = PacketType.from_ordinal( reader.read_byte()!! );
	if(ptype == PacketType.ERROR) return {};
	usz packet_size = read_number{usz}(&reader)!!; // should include (PacketType.sizeof + usz.sizeof) in size calculation
	// ilog("Read Type: %s, Bytes: %s", ptype.nameof, data[:20]);
	// ilog("READ PACKET SIZE %s, at %d", packet_size, reader.index);
	reader.init(
		data[:packet_size]
	);
	reader.index = PacketType.sizeof + usz.sizeof ;
	// reader = io::wrap_bytes((data+usz.sizeof)[:packet_size]);
	return read_packet_data(&reader, ptype);
}

macro Packet? read_packet_data(InStream reader, PacketType ptype) {
	switch (ptype) {
		case REGISTER:		return { .ptype = ptype, .register 		= (RegisterPacket ) 		read_packet_data_private{RegisterPacket} (reader) };
		case HANDSHAKE:		return { .ptype = ptype, .handshake		= (HandshakePacket) 		read_packet_data_private{HandshakePacket}(reader) };
		case BROADCAST:		return { .ptype = ptype, .broadcast		= (BroadcastPacket) 		read_packet_data_private{BroadcastPacket}(reader) };
		case USER_JOIN:		return { .ptype = ptype, .userjoin 		= (UserJoinPacket)  		read_packet_data_private{UserJoinPacket}(reader) };
		case USER_MESSAGE:	return { .ptype = ptype, .usermsg  		= (UserMessagePacket) 		read_packet_data_private{UserMessagePacket}(reader) };
		case USER_COMMAND:	return { .ptype = ptype, .usercommand  	= (UserCommandPacket) 		read_packet_data_private{UserCommandPacket}(reader) };
		
		default: unreachable("Unimplmeneted Packet Type " +++ $$FUNC +++ " %s", ptype.nameof);
	}
}

fn Type? read_packet_data_private(InStream reader) <Type> @if($defined(Type.membersof ))  {
	Type data = {};
	$foreach $member : Type.membersof : 
		$switch :
			$case $typefrom($member.type).kindof.@is_int():
				data.$eval($member.nameof) = read_number{$typefrom($member.type)}(reader)!;
			$case $typefrom($member.type) == String:
				{
					usz len = read_number{usz}(reader)!;
					data.$eval($member.nameof) = (String) mem::new_array(char, len);
					if(len) reader.read(data.$eval($member.nameof))!!;
				}
			$case $typefrom($member.type) == ClientData*[]: 
				{
					usz len = read_number{usz}(reader)!;
					if(len > 0) data.$eval($member.nameof) = mem::new_array(ClientData*, len);
					for(int i =0 ; i < len; i++) {
						ClientData* client = mem::new(ClientData);
						data.$eval($member.nameof)[i] = client;

						client.id = read_number{int}(reader)!;

						usz username_len = read_number{usz}(reader)!;
						client.username = (String) mem::new_array(char, username_len);
						reader.read(client.username)!;
					}
				}
			$default:
				$echo("UNSUPPORTED PARSE TYPE! Type: " +++ $typefrom($member.type).nameof);
		$endswitch
	$endforeach
	return data;
}

fn Type? read_number(InStream buffer) <Type> @if(!$defined(Type.membersof )) {
	Type value;
	const SHIFT = Type.sizeof-1;
	// io::read_any(buffer, &value)!;
	for(int i =0; i < Type.sizeof; i++) {
		value += ((Type)buffer.read_byte()!) << ((SHIFT - i)*8);
	}
	return value;
}

// Write Packet

fn String? write_packet(Packet packet) {
	if(packet.ptype == ERROR) return INVALID_PACKET_TYPE~;
	usz packet_len = data_packet_size(packet) + usz.sizeof + PacketType.sizeof  ;
	char[] buffer =allocator::new_array(tmem, char,
		packet_len + 1
	);
	OutStream writer = ((ByteWriter){}).init_with_buffer(buffer);
	writer.write_byte( packet.ptype.ordinal )!;
	write_number{usz}(writer, packet_len)!;
	write_packet_data(writer, packet)!;
	return (String) buffer[:packet_len];
}

macro usz data_packet_size(packet) {
	switch (packet.ptype) {
		case REGISTER:		return data_packet_size_private{RegisterPacket}(packet.register );
		case HANDSHAKE:		return data_packet_size_private{HandshakePacket}(packet.handshake);
		case BROADCAST:		return data_packet_size_private{BroadcastPacket}(packet.broadcast);
		case USER_JOIN:		return data_packet_size_private{UserJoinPacket}(packet.userjoin);
		case USER_MESSAGE:	return data_packet_size_private{UserMessagePacket}(packet.usermsg);
		case USER_COMMAND:	return data_packet_size_private{UserCommandPacket}(packet.usercommand);
		case ERROR	  : 	return 1;
		default: unreachable("Unimplmeneted Packet Type " +++ $$FUNC +++ " %s", packet.ptype.nameof);
	}
}

fn usz data_packet_size_private(Type value) <Type> @if($defined(Type.membersof )) {
	usz len;
	$foreach $member : Type.membersof : 
		$switch :
			$case $typefrom($member.type).kindof.@is_int(): len += $typefrom($member.type).sizeof;
			$case $typefrom($member.type) == String:		len += usz.sizeof + value.$eval($member.nameof).len;
			$case $typefrom($member.type) == ClientData*[]: 
				len += usz.sizeof;
				foreach (client : value.$eval($member.nameof)) {
					len += int.sizeof + usz.sizeof + client.username.len;
				}

			$default: unreachable("Unimplmeneted Type for packet parsing " +++ $$FUNC +++ " " +++ Type.nameof);
		$endswitch
	$endforeach
	return len;
}

macro write_packet_data(OutStream writer, packet) {
	switch(packet.ptype) {
		case REGISTER:		return write_packet_data_private{RegisterPacket}(writer, &packet.register )!;
		case HANDSHAKE:		return write_packet_data_private{HandshakePacket} (writer, &packet.handshake)!;
		case BROADCAST:		return write_packet_data_private{BroadcastPacket}(writer, &packet.broadcast)!;
		case USER_JOIN:		return write_packet_data_private{UserJoinPacket}(writer, &packet.userjoin)!;
		case USER_MESSAGE:	return write_packet_data_private{UserMessagePacket}(writer, &packet.usermsg)!;
		case USER_COMMAND:	return write_packet_data_private{UserCommandPacket}(writer, &packet.usercommand)!;

		case ERROR: return INVALID_PACKET_TYPE~;
		default: unreachable("Unimplmeneted Packet Type " +++ $$FUNC +++ " %s" , packet.ptype.nameof);
	}
}

fn void? write_packet_data_private(OutStream writer, Type* value) <Type> @if($defined(Type.membersof )) {
	$foreach $member : Type.membersof : 
		$switch :
			$case $typefrom($member.type).kindof.@is_int():
				write_number{$typefrom($member.type)}(
					writer, 
					value.$eval($member.nameof)
				)!;
			$case $typefrom($member.type) == String:
				write_number{usz}(
					writer, 
					value.$eval($member.nameof).len
				)!;
				writer.write(value.$eval($member.nameof))!;
			$case $typefrom($member.type) == ClientData*[]: 
				write_number{usz}(
					writer, 
					value.$eval($member.nameof).len
				)!;
				foreach(client : value.$eval($member.nameof)) {
					write_number{int}(
						writer, 
						client.id
					)!;
					write_number{usz}(
						writer, 
						client.username.len
					)!;
					writer.write(client.username)!;
				}
			$default:
				$echo("UNSUPPORTED PARSE TYPE! Type: " +++ $typefrom($member.type).nameof);
		$endswitch
	$endforeach
}

fn void? write_number(OutStream buffer, Type value) <Type> @if(!$defined(Type.membersof )) {
	const SHIFT = Type.sizeof-1;
	// io::read_any(buffer, &value)!;
	for(int i =0; i < Type.sizeof; i++) {
		buffer.write_byte(
			(char)(value >> ((SHIFT - i)*8))
		)!;
		// value += buffer.read_byte()! << ((SHIFT - i)*8);
	}
}