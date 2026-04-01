module app::common;
import std::collections;

struct ClientData {
	int id;
	String username;
}

fn void ClientData.init(&self, int id, String username) {
	self.id = id;
	self.username = username;
}

fn void ClientData.free(&self) {
	if(self.username.len > 0) self.username.free(mem);
	mem::free(self);
}

alias ClientMap = HashMap{int, ClientData*};
