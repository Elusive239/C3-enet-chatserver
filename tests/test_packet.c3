module app::tests;
import app;
import std::io;

macro char[<usz.sizeof>] usz_to_bytes(usz $value) {
	return num_to_bytes{usz}($value);
}

macro char[<int.sizeof>] int_to_bytes(int $value) {
	return num_to_bytes{int}($value);
}

fn char[<Type.sizeof>] num_to_bytes(Type value) <Type> {
	char[<Type.sizeof>] buffer;
	const SHIFT = Type.sizeof-1;
	// io::read_any(buffer, &value)!;
	for(Type i =0; i < Type.sizeof; i++) {
		buffer[i] = ( (char)(value >> ((SHIFT - i)*Type.sizeof)) );
	}

	return buffer;
}

macro usz full_packet_size (Packet packet) {
	// packet data length + size of var to store total length (this number) + packet type length
	return common::data_packet_size(packet) + usz.sizeof + PacketType.sizeof;
}

fn void assert_packet(Packet expect, Packet result) {
	assert(result.ptype == expect.ptype, "Expected %s, Got %s", expect.ptype.nameof, result.ptype.nameof);
	usz expected_size = full_packet_size(expect);
	usz result_size = full_packet_size(result);
	assert(result_size == expected_size, "Expected %s, Got %s", expected_size, result_size);
	switch(result.ptype) {
		case 	ERROR:  break;
		case REGISTER:  
			assert(result.register.username == expect.register.username, "Expected %s, Got %s", expect.register.username, result.register.username);
		case HANDSHAKE: 
			assert(result.handshake.recieved_id == expect.handshake.recieved_id, "Expected %s, Got %s", expect.handshake.recieved_id, result.handshake.recieved_id);
			assert(result.handshake.connected_clients.len == expect.handshake.connected_clients.len, "Expected %s, Got %s",expect.handshake.connected_clients.len, result.handshake.connected_clients.len);
			
			bool matching = true;
			for(int i = 0 ; i < expect.handshake.connected_clients.len; i++) {
				bool match = false;
				ClientData* e = 	expect.handshake.connected_clients[i];
				for(int y = 0; y < expect.handshake.connected_clients.len; y++) {
					ClientData* r = result.handshake.connected_clients[y];
					if(r.id == e.id && r.username == e.username) {
						match = true; 
						break;
					}
				}
				if(!match) {
					io::eprintfn("Expected [%s] {%s,%s}, Found no match!", i, e.id, e.username);
					matching = false;
				}
			}
			assert(matching);
		case BROADCAST: 
			assert(result.broadcast.message == expect.broadcast.message, "Expected %s, Got %s", expect.broadcast.message, result.broadcast.message);
		case USER_JOIN: 
			assert (result.userjoin.id == expect.userjoin.id ,"Expected %s, Got %s", expect.userjoin.id, result.userjoin.id);
			assert (result.userjoin.username == expect.userjoin.username, "Expected %s, Got %s",expect.userjoin.username, result.userjoin.username );
		case USER_MESSAGE: 
			assert (result.usermsg.id == expect.usermsg.id ,"Expected %s, Got %s", expect.usermsg.id, result.usermsg.id);
			assert (result.usermsg.message == expect.usermsg.message, "Expected %s, Got %s",expect.usermsg.message, result.usermsg.message );
		case USER_COMMAND:
			assert (result.usercommand.command == expect.usercommand.command , "Expected %s, Got %s", expect.usercommand.command, result.usercommand.command);
			assert (result.usercommand.args == expect.usercommand.args , "Expected %s, Got %s", expect.usercommand.args, result.usercommand.args);
		default: unreachable("Unimplemented PacketType %s", result.ptype);
	} 
}

fn void packet_parse() @test {
	{
		//We shouldn't get these, so we should probably discard the packet when we do!
		//PacketType
		//char.sizeof 
		//1
		Packet expect = {
			.ptype = PacketType.ERROR
		};
		char[*] testdata = {PacketType.ERROR.ordinal};
		Packet? result = common::parse_packet(&testdata);
		if(catch err =result) err~!!;
		defer common::destroy_packet(result);
		assert_packet( expect,  result);
	}
	{
		//PacketType + len of packet in bytes + len of username length in bytes + len of username in bytes 
		//char.sizeof + usz.sizeof + usz.sizeof + register.len Bytes
		//1 + 8 + 8 + 3 = 20
		Packet expect = {
			.ptype = PacketType.REGISTER ,
			.register.username = "elu"
		};
		char[*] testdata = {PacketType.REGISTER.ordinal, ...usz_to_bytes(20), ...usz_to_bytes(3), ..."elu" };
		Packet? result = common::parse_packet(&testdata);
		if(catch err =result) err~!!;
		defer common::destroy_packet(result);
		assert_packet( expect,  result);
	}
	{
		//PacketType + len of packet in bytes + recieved id in bytes
		//char.sizeof + usz.sizeof + int.sizeof
		//1 + 8 + 4 = 13
		Packet expect = {
			.ptype = PacketType.HANDSHAKE ,
			.handshake.recieved_id = -1
		};
		char[*] testdata = {PacketType.HANDSHAKE.ordinal, ...usz_to_bytes(21), ...int_to_bytes(-1), ...usz_to_bytes(0) };
		Packet? result = common::parse_packet(&testdata);
		if(catch err =result) err~!!;
		defer common::destroy_packet(result);
		assert_packet( expect,  result);
	}
	{
		//PacketType + len of packet in bytes + recieved id in bytes
		//char.sizeof + usz.sizeof + int.sizeof
		//1 + 8 + 4 = 13
		const int DUMMY_ID = -1;
		const String USERNAME_1 = "Jeremy";
		const String USERNAME_2 = "Babishes";
		const String USERNAME_3 = "Oscar";
		Packet expect = {
			.ptype = PacketType.HANDSHAKE ,
			.handshake.recieved_id = DUMMY_ID ,
			.handshake.connected_clients = {
				&&{DUMMY_ID , USERNAME_1}, &&{DUMMY_ID , USERNAME_2}, &&{DUMMY_ID , USERNAME_3}
			}
		};
		char[<int.sizeof>] dummy_splatable = int_to_bytes(DUMMY_ID );
		const usz LEN = 1 + (usz.sizeof * 5) + (int.sizeof * 4) + USERNAME_1.len + USERNAME_2.len + USERNAME_3.len ;
		char[*] testdata = {
			PacketType.HANDSHAKE.ordinal, 
			...usz_to_bytes(LEN), 
			...dummy_splatable, ...usz_to_bytes(3),  
				...dummy_splatable, ...usz_to_bytes(USERNAME_1.len), ...USERNAME_1, 
				...dummy_splatable, ...usz_to_bytes(USERNAME_2.len), ...USERNAME_2,
				...dummy_splatable, ...usz_to_bytes(USERNAME_3.len), ...USERNAME_3,
		};
		Packet? result = common::parse_packet(&testdata);
		if(catch err =result) err~!!;
		defer common::destroy_packet(result);
		assert_packet( expect,  result);
	}
	{
		//PacketType + len of packet in bytes + len of username length in bytes + len of username in bytes 
		//char.sizeof + usz.sizeof + usz.sizeof + register.len Bytes
		//1 + 8 + 8 + 3 = 20
		const String MESSAGE = "Hello friends!";
		Packet expect = {
			.ptype = PacketType.BROADCAST ,
			.broadcast.message = MESSAGE
		};
		char[*] testdata = {PacketType.BROADCAST.ordinal, ...usz_to_bytes(1 + (usz.sizeof*2) + MESSAGE.len), ...usz_to_bytes(MESSAGE.len), ...MESSAGE };
		Packet? result = common::parse_packet(&testdata);
		if(catch err =result) err~!!;
		defer common::destroy_packet(result);
		assert_packet( expect,  result);
	}

	{
		//PacketType + len of packet in bytes + recieved id in bytes
		//char.sizeof + usz.sizeof + int.sizeof
		//1 + 8 + 4 = 13
		Packet expect = {
			.ptype = PacketType.USER_JOIN ,
			.userjoin.id = -1,
			.userjoin.username = "elu"
		};
		char[*] testdata = {PacketType.USER_JOIN.ordinal, ...usz_to_bytes(32), ...int_to_bytes(-1),  ...usz_to_bytes(3), ..."elu", ...usz_to_bytes(0) };
		Packet? result = common::parse_packet(&testdata);
		if(catch err =result) err~!!;
		defer common::destroy_packet(result);
		assert_packet( expect,  result);
	}
	{
		//PacketType + len of packet in bytes + recieved id in bytes
		//char.sizeof + usz.sizeof + int.sizeof
		//1 + 8 + 4 = 13
		const String MESSAGE = "Hello World!";
		Packet expect = {
			.ptype = PacketType.USER_MESSAGE ,
			.usermsg.id = -1,
			.usermsg.message = MESSAGE
		};

		char[*] testdata = {PacketType.USER_MESSAGE.ordinal, ...usz_to_bytes(41), ...int_to_bytes(-1), ...usz_to_bytes(MESSAGE.len),...MESSAGE, ...usz_to_bytes(0) };
		Packet? result = common::parse_packet(&testdata);
		if(catch err =result) err~!!;
		defer common::destroy_packet(result);
		assert_packet( expect,  result);
	}
	{
		const String CMD = "help";
		const String ARGS = "";

		Packet expect = {
			.ptype = PacketType.USER_COMMAND ,
			.usercommand.command = CMD,
			.usercommand.args = ARGS
		};
		const usz LEN = 1 + (usz.sizeof * 3) + CMD.len + ARGS.len;
		char[*] testdata = { 
			PacketType.USER_COMMAND.ordinal, ...usz_to_bytes(LEN), ...usz_to_bytes(CMD.len), ...CMD, ...usz_to_bytes(ARGS.len)//, //...ARGS 
		};
		Packet? result = common::parse_packet(&testdata);
		if(catch err =result) err~!!;
		defer common::destroy_packet(result);
		assert_packet( expect,  result);
	}
	{
		const String CMD = "help";
		const String ARGS = "oh ok here we are some args";

		Packet expect = {
			.ptype = PacketType.USER_COMMAND ,
			.usercommand.command = CMD,
			.usercommand.args = ARGS
		};
		const usz LEN = 1 + (usz.sizeof * 3) + CMD.len + ARGS.len;
		char[*] testdata = { 
			PacketType.USER_COMMAND.ordinal, ...usz_to_bytes(LEN), ...usz_to_bytes(CMD.len), ...CMD, ...usz_to_bytes(ARGS.len), ...ARGS 
		};
		Packet? result = common::parse_packet(&testdata);
		if(catch err =result) err~!!;
		defer common::destroy_packet(result);
		assert_packet( expect,  result);
	}
}

fn void packet_write() @test {
	{ // shouldn't be possible but hey why not
		Packet testdata = {
			.ptype = PacketType.ERROR
		};
		String? result = common::write_packet(testdata);
		assert(@catch(result) == common::INVALID_PACKET_TYPE, "Expected %s Got %s", common::INVALID_PACKET_TYPE ,@catch(result));
	}
	{
		const PacketType PTYPE = PacketType.REGISTER;
		const String USERNAME = "elu";
		Packet testdata = {
			.ptype = PTYPE ,
			.register.username = USERNAME
		};
		char[*] expect = { PTYPE.ordinal, ...usz_to_bytes(20), ...usz_to_bytes(USERNAME.len), ...USERNAME };

		String? r = common::write_packet(testdata);
		if(catch err = r) return err~!!;

		assert(r.len == expect.len, "Expected %s Got %s", expect.len, r.len); 
		assert(r == ((String)expect[:r.len]), "Expected %s Got %s", expect, r[:r.len]);
	}
	{
		const PacketType PTYPE = PacketType.HANDSHAKE;
		const int ID = -1;
		Packet testdata = {
			.ptype = PTYPE ,
			.handshake.recieved_id = ID
		};
		char[*] expect = { PTYPE.ordinal, ...usz_to_bytes(21), ...int_to_bytes(ID), ...usz_to_bytes(0) };

		String? r = common::write_packet(testdata);
		if(catch err = r) return err~!!;

		assert(r.len == expect.len, "Expected %s Got %s", expect.len, r.len); 
		assert(r == ((String)expect[:r.len]), "Expected %s Got %s", expect, r[:r.len]);
	}
	{
		const PacketType PTYPE = PacketType.BROADCAST;
		const String MESSAGE = "Hello friends!";
		Packet testdata = {
			.ptype = PTYPE ,
			.broadcast.message = MESSAGE
		};
		char[*] expect = { PTYPE.ordinal, ...usz_to_bytes(1 + (usz.sizeof * 2) + MESSAGE.len ), ...usz_to_bytes(MESSAGE.len), ...MESSAGE };

		String? r = common::write_packet(testdata);
		if(catch err = r) return err~!!;

		assert(r.len == expect.len, "Expected %s Got %s", expect.len, r.len); 
		assert(r == ((String)expect[:r.len]), "Expected %s Got %s", expect, r[:r.len]);
		
	}
	{
		const String CMD = "help";
		const String ARGS = "";

		Packet testdata = {
			.ptype = PacketType.USER_COMMAND ,
			.usercommand.command = CMD,
			.usercommand.args = ARGS
		};
		const usz LEN = 1 + (usz.sizeof * 3) + CMD.len + ARGS.len;

		char[*] expect = { 
			PacketType.USER_COMMAND.ordinal, ...usz_to_bytes(LEN), ...usz_to_bytes(CMD.len), ...CMD, ...usz_to_bytes(ARGS.len)//, //...ARGS 
		};

		String? r = common::write_packet(testdata);
		if(catch err = r) return err~!!;

		assert(r.len == expect.len, "Expected %s Got %s", expect.len, r.len); 
		assert(r == ((String)expect[:r.len]), "Expected %s Got %s", expect, r[:r.len]);
		
	}
	{
		const String CMD = "help";
		const String ARGS = "oh ok here we are some args";

		Packet testdata = {
			.ptype = PacketType.USER_COMMAND ,
			.usercommand.command = CMD,
			.usercommand.args = ARGS
		};
		const usz LEN = 1 + (usz.sizeof * 3) + CMD.len + ARGS.len;

		char[*] expect = { 
			PacketType.USER_COMMAND.ordinal, ...usz_to_bytes(LEN), ...usz_to_bytes(CMD.len), ...CMD, ...usz_to_bytes(ARGS.len), ...ARGS 
		};
		
		String? r = common::write_packet(testdata);
		if(catch err = r) return err~!!;

		assert(r.len == expect.len, "Expected %s Got %s", expect.len, r.len); 
		assert(r == ((String)expect[:r.len]), "Expected %s Got %s", expect, r[:r.len]);
		
	}
}