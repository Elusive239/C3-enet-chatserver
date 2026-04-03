module app;
import std::math;
import std::collections;
import std::io;

const char[] RAND_TABLE = {
	..."ABCD1E90FGHI2JKL8MN3OP7QRSTU4VW6XY5Z",
};

fn char[8] gen_code() {
	char[8] code;
	for(int i =0; i < code.len; i++) {
		code[i] = RAND_TABLE[rand(code.len)];
	}
	return code;
}

struct User {
	String username;
	String password;
	// other data
}

alias UserDB = HashMap{String, User};

fn void servercode_experiment(UserDB db) {
	// check if a server file exists
	String server_code;
	const String SERVER_DATA = "chatter.serv";
	// first line is verification code
	// then Users
	// when creating above file, first user created should be the admin user..

	UserDB users;
	users.init(mem);

	if(file::exists(SERVER_DATA) ) {
		File file = file::open(SERVER_DATA, "rb")!!;
		defer (void) file.close();
		char[9] data; //first 9 bytes should be server code + newline char
		usz? read = file.read(&data);
		if(catch read) {
			io::eprintfn("Corrupted .serv file...");
			return;
		} else if (9 != read) {
			io::eprintfn("Corrupted .serv file...");
			return;
		}

		do {
			//csv format
			String? userinfo = io::readline(tmem, &file);
			if(catch userinfo) break;
			defer userinfo.free(tmem);
			Splitter split = userinfo.tokenize_all(",");
			String username = split.next()!!.copy(mem);
			String password = split.next()!!.copy(mem);

			users[username] = {
				username, password
			};

			// ByteReader br = io::wrap_bytes(userinfo);

			//THIS IS DUMB USE THE SPLITTER IN STRING INSTEAD!
			// CsvReader reader;
			// reader.init(&br);
		} while(true);


		server_code = ((String) data[:8]).copy(mem);
	} else {
		File file = file::open(SERVER_DATA, "wb")!!;
		defer (void) file.close();

		server_code = ((String)gen_code()[:8]).copy(mem);
		io::printf("Admin Username: ");
		String username = io::readline(mem)!!;
		io::printf("Admin Password: ");
		String password = io::readline(mem)!!;
		users[username] = {
			username, password
		};
		
		{
			(void) file.write(server_code);
			(void) file.write_byte('\n');
			(void) file.write(username);
			(void) file.write_byte(',');
			(void) file.write(password);
			(void) file.write_byte('\n');
		};
	}

	foreach( idx, user : users.value_iter()) {
		io::printfn("User %d: '%s', '%s'", idx, user.username, user.password);
	}
	// if it exists, read 8 digit code and existing users into memory
	// otherwise:
		// create a server file (chatter.serv?)
		// generate an 8 digit code, consisting of random characters (1-9, A-Z), write to file
		// prompt for admin username / password, write to file
		// close file to save
	srand(0);
	char[8] code = gen_code();
	io::printfn("GENERATED CODE: %s", (String) code[:code.len]);
}
