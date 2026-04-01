#define ENET_IMPLEMENTATION
#include <enet.h>
#include <sys/socket.h>
#include <netinet/in.h>

struct in6_addr enet_get_host_any() {
    return ENET_HOST_ANY;
}