An example text chat client/server written in [C3](https://c3-lang.org/)!  

I've been writing this to figure out client / server shenanigans for an app I want to write.  

Originally based off of this tutorial: https://github.com/usergames-net/basic-enet-tutorial-series

To run as client: `c3c run client -- %%username%%`  
To run as server: `c3c run server`  

Server currently hardcoded to use port 7777  

## Known Issues
 - When a client disconnects, the server crashes. Seems to be a bug in enet?  

## TODO:  
 - Raylib or SDL3 based client to replace the Terminal based one currently in use.  
 - User "account" creation (username, password, permissions).   
 	Nothing super complicated. At most for this project just storing it in a .csv file somewhere...  
 - Simple admin commands & user commands
    Example(s):  
	`/roll 1d6`           -> rolls a d6, prints the result, no privileges required  
	`/mute %%username%%`  ->  prevent a user from sending messages, alert user they're muted when sending a msg, moderator privilege required  

## Dependencies:  
- [C3 Standard library](https://github.com/c3lang/c3c/tree/master/lib/std)  
- [enet](https://github.com/zpl-c/enet) [(See Bindings)](/lib/enet.c3l)  
