module app;
import std;

OutStream logstream @private;

fn void set_logstream(OutStream stream) {
	logstream = stream;
}

macro void @log_to_file(String fname; @body) {
	File? file = file::open(fname, "wb");
	if(catch file) os::exit(1);
	defer (void) file.close();
	defer set_logstream(io::stdout());
	DualStream stream;
	set_logstream(stream.init(io::stdout(), &file));
	@body();
}

enum LogType : (String msg_start){
	NONE  	 {""},
	INFO	 {"INFO  - "},
	WARNING	 {"WARN  - "},
	ERROR	 {"ERROR - "},
}

macro log(String fmt, args...)  => log_msg(LogType.NONE, fmt, ...args)!!;

macro ilog(String fmt, args...)  => log_msg(LogType.INFO, fmt, ...args)!!;

macro wlog(String fmt, args...)  => log_msg(LogType.WARNING, fmt, ...args)!!;

macro elog(String fmt, args...) => log_msg(LogType.ERROR, fmt, ...args)!!;

fn usz? log_msg(LogType type, String fmt, args...) @private {
	DString buffer;
	buffer.init(mem);
	defer if(&logstream.flush) (void) logstream.flush();
	defer buffer.free();
	
	if(type.msg_start.len) {
		DateTime rn = datetime::now();
		@pool() {
			buffer.appendf("%s ", rn.format(tmem,DateTimeFormat.DATETIME));
		};

		buffer.appendf(type.msg_start);
	}
	
	buffer.appendfn(fmt, ...args);
	return io::fprint(logstream,buffer)!;
}

struct DualStream (OutStream) {
	OutStream first;
	OutStream second;
}

fn DualStream* DualStream.init(&self, OutStream a, OutStream b) {
	*self ={
		a, b
	};
	return self;
}

fn usz? DualStream.write(&self, char[] data) @dynamic {
	return min(
		self.first.write(data)!, 
		self.second.write(data)!
	);
}

fn void? DualStream.write_byte(&self, char data) @dynamic {
	self.first.write_byte(data)!; 
	self.second.write_byte(data)!;
}

fn void? DualStream.flush(&self) @dynamic {
	if(&self.first.flush ) self.first.flush()!;
	if(&self.second.flush ) self.second.flush()!;
}