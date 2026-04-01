module enet @if(env::WIN32);

  

const ENetSocket ENET_SOCKET_NULL = ~0;

struct ENetBuffer{
    usz dataLength;
    void * data;
}

const int ENET_BUFFER_MAXIMUM = 16;

module enet @if(!env::WIN32);



const int ENET_SOCKET_NULL = -1;

struct ENetBuffer {
    void * data;
    usz dataLength;
}

module enet;
import std::net::os;
typedef ENetSocket = NativeSocket;

const int ENET_BUFFER_MAXIMUM @if(!$defined(ENET_BUFFER_MAXIMUM)) = 1 + (2* (int)ENetProtocolMinMax.ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS);

typedef ENetVersion = uint;


const In6_addr ENET_V4_ANYADDR   = {{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00 }};
const In6_addr ENET_V4_NOADDR    = {{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff }};
const In6_addr ENET_V4_LOCALHOST = {{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0x7f, 0x00, 0x00, 0x01 }};
const In6_addr ENET_V6_ANYADDR   = {{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }};
const In6_addr ENET_V6_NOADDR    = {{ 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff }};
const In6_addr ENET_V6_LOCALHOST = {{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01 }};

// extern const In6_addr ENET_HOST_ANY @cname("in6addr_any");
extern fn In6_addr get_host_any() @cname("enet_get_host_any");

const In6_addr ENET_HOST_BROADCAST = {.val = 0xFFFFFFFFU};
const ushort ENET_PORT_ANY = 0;

alias ENET_Malloc_Fn = fn void*(usz size);
alias ENET_Free_Fn = fn void (void* memory);
alias ENET_No_Memory_Fn = fn void ();
alias ENET_Packet_Create_Fn = fn ENetPacket (void* data, usz dataLength, uint flags);
alias ENET_Packet_Destroy_Fn = fn void (ENetPacket* packet);

struct ENetCallbacks {
    ENET_Malloc_Fn  malloc;
    ENET_Free_Fn  free;
    ENET_No_Memory_Fn  no_memory;
	ENET_Packet_Create_Fn  packet_create;
    ENET_Packet_Destroy_Fn  packet_destroy;
}

extern fn void*			malloc(usz) @cname("enet_malloc");
extern fn void 			free(void *) @cname("enet_free");
extern fn ENetPacket* 	packet_create(void*,isz,uint) @cname("enet_packet_create");
extern fn ENetPacket* 	packet_resize(ENetPacket*, usz) @cname("enet_packet_resize");
extern fn ENetPacket* 	packet_copy(ENetPacket*) @cname("enet_packet_copy");
extern fn void 			packet_destroy(ENetPacket*) @cname("enet_packet_destroy");

// List
struct ENetListNode {
    ENetListNode *next;
    ENetListNode *previous;
}

typedef ENetListIterator = ENetListNode*;

struct ENetList {
    ENetListNode sentinel;
}

extern fn ENetListIterator list_insert(ENetListIterator, void *) @cname("enet_list_insert");
extern fn ENetListIterator list_move(ENetListIterator, void *, void *) @cname("enet_list_move");
extern fn void *list_remove(ENetListIterator) @cname("enet_list_remove");
extern fn void list_clear(ENetList *) @cname("enet_list_clear");
extern fn usz list_size(ENetList *) @cname("enet_list_size");

macro list_begin(ENetList list) => ((list).sentinel.next);
macro list_end(ENetList list) => (&(list).sentinel);
macro list_empty(ENetList list) => (enet_list_begin(list) == enet_list_end(list));
macro list_next(ENetListIterator iterator) => ((iterator).next);
macro list_previous(ENetListIterator iterator) => ((iterator).previous);
macro list_front(ENetList list) => ((void *)(list).sentinel.next);
macro list_back(ENetList list) => ((void *)(list).sentinel.previous);

// protocol
constdef ENetProtocolMinMax : int {
    ENET_PROTOCOL_MINIMUM_MTU             = 576,
    ENET_PROTOCOL_MAXIMUM_MTU             = 4096,
    ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS = 32,
    ENET_PROTOCOL_MINIMUM_WINDOW_SIZE     = 4096,
    ENET_PROTOCOL_MAXIMUM_WINDOW_SIZE     = 65536,
    ENET_PROTOCOL_MINIMUM_CHANNEL_COUNT   = 1,
    ENET_PROTOCOL_MAXIMUM_CHANNEL_COUNT   = 255,
    ENET_PROTOCOL_MAXIMUM_PEER_ID         = @peer_id(),
    ENET_PROTOCOL_MAXIMUM_FRAGMENT_COUNT  = 1024 * 1024
}

macro @peer_id() {
	$if $feature(ENET_USE_MORE_PEERS):
		return 0xFFFF;
	$else 
		return 0xFFF;
	$endif
}

constdef ENetProtocolCommand {
    ENET_PROTOCOL_COMMAND_NONE                     = 0,
    ENET_PROTOCOL_COMMAND_ACKNOWLEDGE              = 1,
    ENET_PROTOCOL_COMMAND_CONNECT                  = 2,
    ENET_PROTOCOL_COMMAND_VERIFY_CONNECT           = 3,
    ENET_PROTOCOL_COMMAND_DISCONNECT               = 4,
    ENET_PROTOCOL_COMMAND_PING                     = 5,
    ENET_PROTOCOL_COMMAND_SEND_RELIABLE            = 6,
    ENET_PROTOCOL_COMMAND_SEND_UNRELIABLE          = 7,
    ENET_PROTOCOL_COMMAND_SEND_FRAGMENT            = 8,
    ENET_PROTOCOL_COMMAND_SEND_UNSEQUENCED         = 9,
    ENET_PROTOCOL_COMMAND_BANDWIDTH_LIMIT          = 10,
    ENET_PROTOCOL_COMMAND_THROTTLE_CONFIGURE       = 11,
    ENET_PROTOCOL_COMMAND_SEND_UNRELIABLE_FRAGMENT = 12,
    ENET_PROTOCOL_COMMAND_COUNT                    = 13,
    ENET_PROTOCOL_COMMAND_MASK                     = 0x0F
}

constdef ENetProtocolFlag @if($feature(ENET_USE_MORE_PEERS)) {
    ENET_PROTOCOL_COMMAND_FLAG_ACKNOWLEDGE = (1 << 7),
    ENET_PROTOCOL_COMMAND_FLAG_UNSEQUENCED = (1 << 6),
    ENET_PROTOCOL_HEADER_FLAG_PEER_EXTRA   = (1 << 13),
    ENET_PROTOCOL_HEADER_FLAG_COMPRESSED   = (1 << 14),
    ENET_PROTOCOL_HEADER_FLAG_SENT_TIME    = (1 << 15),
    ENET_PROTOCOL_HEADER_FLAG_MASK         = ENetProtocolFlag.ENET_PROTOCOL_HEADER_FLAG_PEER_EXTRA | ENetProtocolFlag.ENET_PROTOCOL_HEADER_FLAG_COMPRESSED | ENET_PROTOCOL_HEADER_FLAG_SENT_TIME,
    ENET_PROTOCOL_HEADER_SESSION_MASK      = (3 << 11),
    ENET_PROTOCOL_HEADER_SESSION_SHIFT     = 11
} 

constdef ENetProtocolFlag @if(!$feature(ENET_USE_MORE_PEERS)) {
    ENET_PROTOCOL_COMMAND_FLAG_ACKNOWLEDGE = (1 << 7),
    ENET_PROTOCOL_COMMAND_FLAG_UNSEQUENCED = (1 << 6),
    ENET_PROTOCOL_HEADER_FLAG_COMPRESSED   = (1 << 14),
    ENET_PROTOCOL_HEADER_FLAG_SENT_TIME    = (1 << 15),
    ENET_PROTOCOL_HEADER_FLAG_MASK         = ENetProtocolFlag.ENET_PROTOCOL_HEADER_FLAG_COMPRESSED | ENetProtocolFlag.ENET_PROTOCOL_HEADER_FLAG_SENT_TIME,
    ENET_PROTOCOL_HEADER_SESSION_MASK      = (3 << 12),
    ENET_PROTOCOL_HEADER_SESSION_SHIFT     = 12
} 

attrdef @EnetPacked @if(  ($defined(__GNUC__) || $defined(_clang_))) = @packed;
attrdef @EnetPacked @if( !($defined(__GNUC__) || $defined(_clang_)));

struct ENetProtocolHeader @EnetPacked {
    ushort peerID;
    ushort sentTime;
}

struct ENetProtocolHeaderMinimal @EnetPacked {
    ushort peerID;
}

struct ENetProtocolCommandHeader @EnetPacked {
    char  command;
    char  channelID;
    ushort reliableSequenceNumber;
}

struct ENetProtocolAcknowledge @EnetPacked {
    ENetProtocolCommandHeader header;
    ushort               receivedReliableSequenceNumber;
    ushort               receivedSentTime;
}

struct ENetProtocolConnect @EnetPacked {
    ENetProtocolCommandHeader header;
    ushort               outgoingPeerID;
    char                incomingSessionID;
    char                outgoingSessionID;
    uint               mtu;
    uint               windowSize;
    uint               channelCount;
    uint               incomingBandwidth;
    uint               outgoingBandwidth;
    uint               packetThrottleInterval;
    uint               packetThrottleAcceleration;
    uint               packetThrottleDeceleration;
    uint               connectID;
    uint               data;
}

struct ENetProtocolVerifyConnect @EnetPacked {
    ENetProtocolCommandHeader header;
    ushort               outgoingPeerID;
    char                incomingSessionID;
    char                outgoingSessionID;
    uint               mtu;
    uint               windowSize;
    uint               channelCount;
    uint               incomingBandwidth;
    uint               outgoingBandwidth;
    uint               packetThrottleInterval;
    uint               packetThrottleAcceleration;
    uint               packetThrottleDeceleration;
    uint               connectID;
}

struct ENetProtocolBandwidthLimit @EnetPacked {
    ENetProtocolCommandHeader header;
    uint               incomingBandwidth;
    uint               outgoingBandwidth;
}

struct ENetProtocolThrottleConfigure @EnetPacked {
    ENetProtocolCommandHeader header;
    uint               packetThrottleInterval;
    uint               packetThrottleAcceleration;
    uint               packetThrottleDeceleration;
}

struct ENetProtocolDisconnect @EnetPacked {
    ENetProtocolCommandHeader header;
    uint               data;
}

struct ENetProtocolPing @EnetPacked {
    ENetProtocolCommandHeader header;
}

struct ENetProtocolSendReliable @EnetPacked {
    ENetProtocolCommandHeader header;
    ushort               dataLength;
}

struct ENetProtocolSendUnreliable @EnetPacked {
    ENetProtocolCommandHeader header;
    ushort               unreliableSequenceNumber;
    ushort               dataLength;
}

struct ENetProtocolSendUnsequenced @EnetPacked {
    ENetProtocolCommandHeader header;
    ushort               unsequencedGroup;
    ushort               dataLength;
}

struct ENetProtocolSendFragment @EnetPacked {
    ENetProtocolCommandHeader header;
    ushort               startSequenceNumber;
    ushort               dataLength;
    uint               fragmentCount;
    uint               fragmentNumber;
    uint               totalLength;
    uint               fragmentOffset;
}

union ENetProtocol @EnetPacked {
    ENetProtocolCommandHeader     header;
    ENetProtocolAcknowledge       acknowledge;
    ENetProtocolConnect           connect;
    ENetProtocolVerifyConnect     verifyConnect;
    ENetProtocolDisconnect        disconnect;
    ENetProtocolPing              ping;
    ENetProtocolSendReliable      sendReliable;
    ENetProtocolSendUnreliable    sendUnreliable;
    ENetProtocolSendUnsequenced   sendUnsequenced;
    ENetProtocolSendFragment      sendFragment;
    ENetProtocolBandwidthLimit    bandwidthLimit;
    ENetProtocolThrottleConfigure throttleConfigure;
} 

// General ENet structs/enums
constdef ENetSocketType {
    ENET_SOCKET_TYPE_STREAM   = 1,
    ENET_SOCKET_TYPE_DATAGRAM = 2
}

constdef ENetSocketWait {
    ENET_SOCKET_WAIT_NONE      = 0,
    ENET_SOCKET_WAIT_SEND      = (1 << 0),
    ENET_SOCKET_WAIT_RECEIVE   = (1 << 1),
    ENET_SOCKET_WAIT_INTERRUPT = (1 << 2)
}

constdef ENetSocketOption {
    ENET_SOCKOPT_NONBLOCK  = 1,
    ENET_SOCKOPT_BROADCAST = 2,
    ENET_SOCKOPT_RCVBUF    = 3,
    ENET_SOCKOPT_SNDBUF    = 4,
    ENET_SOCKOPT_REUSEADDR = 5,
    ENET_SOCKOPT_RCVTIMEO  = 6,
    ENET_SOCKOPT_SNDTIMEO  = 7,
    ENET_SOCKOPT_ERROR     = 8,
    ENET_SOCKOPT_NODELAY   = 9,
    ENET_SOCKOPT_IPV6_V6ONLY = 10,
    ENET_SOCKOPT_TTL       = 11,
}

constdef ENetSocketShutdown {
    ENET_SOCKET_SHUTDOWN_READ       = 0,
    ENET_SOCKET_SHUTDOWN_WRITE      = 1,
    ENET_SOCKET_SHUTDOWN_READ_WRITE = 2
}

/**
 * Portable internet address structure.
 *
 * The host must be specified in network byte-order, and the port must be in host
 * byte-order. The constant ENET_HOST_ANY may be used to specify the default
 * server host. The constant ENET_HOST_BROADCAST may be used to specify the
 * broadcast address (255.255.255.255).  This makes sense for enet_host_connect,
 * but not for enet_host_create.  Once a server responds to a broadcast, the
 * address is updated from ENET_HOST_BROADCAST to the server's actual IP address.
 */
struct ENetAddress {
    In6_addr host;
    ushort port;
    ushort sin6_scope_id;
}

macro in6_equal(addr_a, addr_b) {
    return addr_a.val == addr_b.val ;
}

/**
 * Packet flag bit constants.
 *
 * The host must be specified in network byte-order, and the port must be in
 * host byte-order. The constant ENET_HOST_ANY may be used to specify the
 * default server host.
 *
 * @sa ENetPacket
 */
constdef ENetPacketFlag {
    ENET_PACKET_FLAG_RELIABLE            = (1 << 0), /** packet must be received by the target peer and resend attempts should be made until the packet is delivered */
    ENET_PACKET_FLAG_UNSEQUENCED         = (1 << 1), /** packet will not be sequenced with other packets */
    ENET_PACKET_FLAG_NO_ALLOCATE         = (1 << 2), /** packet will not allocate data, and user must supply it instead */
    ENET_PACKET_FLAG_UNRELIABLE_FRAGMENT = (1 << 3), /** packet will be fragmented using unreliable (instead of reliable) sends if it exceeds the MTU */
    ENET_PACKET_FLAG_UNTHROTTLED         = (1 << 4), /** packet that was enqueued for sending unreliably should not be dropped due to throttling and sent if possible */
    ENET_PACKET_FLAG_SENT                = (1 << 8), /** whether the packet has been sent from all queues it has been entered into */
}

alias ENetPacketFreeCallback = fn void(void*);

/**
 * ENet packet structure.
 *
 * An ENet data packet that may be sent to or received from a peer. The shown
 * fields should only be read and never modified. The data field contains the
 * allocated data for the packet. The dataLength fields specifies the length
 * of the allocated data.  The flags field is either 0 (specifying no flags),
 * or a bitwise-or of any combination of the following flags:
 *
 *    ENET_PACKET_FLAG_RELIABLE - packet must be received by the target peer and resend attempts should be made until the packet is delivered
 *    ENET_PACKET_FLAG_UNSEQUENCED - packet will not be sequenced with other packets (not supported for reliable packets)
 *    ENET_PACKET_FLAG_NO_ALLOCATE - packet will not allocate data, and user must supply it instead
 *    ENET_PACKET_FLAG_UNRELIABLE_FRAGMENT - packet will be fragmented using unreliable (instead of reliable) sends if it exceeds the MTU
 *    ENET_PACKET_FLAG_SENT - whether the packet has been sent from all queues it has been entered into
 * @sa ENetPacketFlag
 */
struct ENetPacket {
    usz                 	referenceCount; /**< internal use only */
    uint            		flags;          /**< bitwise-or of ENetPacketFlag constants */
    char *           		data;           /**< allocated data for packet */
    usz                 	dataLength;     /**< length of data */
    ENetPacketFreeCallback 	freeCallback;   /**< function to be called when the packet is no longer in use */
    void *                 	userData;       /**< application private data, may be freely modified */
}

struct ENetAcknowledgement {
    ENetListNode acknowledgementList;
    uint  sentTime;
    ENetProtocol command;
}

struct ENetOutgoingCommand {
    ENetListNode outgoingCommandList;
    ushort  reliableSequenceNumber;
    ushort  unreliableSequenceNumber;
    uint  sentTime;
    uint  roundTripTimeout;
    uint  queueTime;
    uint  fragmentOffset;
    ushort  fragmentLength;
    ushort  sendAttempts;
    ENetProtocol command;
    ENetPacket * packet;
}

struct ENetIncomingCommand {
    ENetListNode incomingCommandList;
    ushort  reliableSequenceNumber;
    ushort  unreliableSequenceNumber;
    ENetProtocol command;
    uint  fragmentCount;
    uint  fragmentsRemaining;
    uint *fragments;
    ENetPacket * packet;
}

constdef ENetPeerState {
    ENET_PEER_STATE_DISCONNECTED             = 0,
    ENET_PEER_STATE_CONNECTING               = 1,
    ENET_PEER_STATE_ACKNOWLEDGING_CONNECT    = 2,
    ENET_PEER_STATE_CONNECTION_PENDING       = 3,
    ENET_PEER_STATE_CONNECTION_SUCCEEDED     = 4,
    ENET_PEER_STATE_CONNECTED                = 5,
    ENET_PEER_STATE_DISCONNECT_LATER         = 6,
    ENET_PEER_STATE_DISCONNECTING            = 7,
    ENET_PEER_STATE_ACKNOWLEDGING_DISCONNECT = 8,
    ENET_PEER_STATE_ZOMBIE                   = 9
}

constdef Enet_Host_Peer_Enum : inline int {
    ENET_HOST_RECEIVE_BUFFER_SIZE          = 256 * 1024,
    ENET_HOST_SEND_BUFFER_SIZE             = 256 * 1024,
    ENET_HOST_BANDWIDTH_THROTTLE_INTERVAL  = 1000,
    ENET_HOST_DEFAULT_MTU                  = 1392,
    ENET_HOST_DEFAULT_MAXIMUM_PACKET_SIZE  = 32 * 1024 * 1024,
    ENET_HOST_DEFAULT_MAXIMUM_WAITING_DATA = 32 * 1024 * 1024,

    ENET_PEER_DEFAULT_ROUND_TRIP_TIME      = 500,
    ENET_PEER_DEFAULT_PACKET_THROTTLE      = 32,
    ENET_PEER_PACKET_THROTTLE_SCALE        = 32,
    ENET_PEER_PACKET_THROTTLE_COUNTER      = 7,
    ENET_PEER_PACKET_THROTTLE_ACCELERATION = 2,
    ENET_PEER_PACKET_THROTTLE_DECELERATION = 2,
    ENET_PEER_PACKET_THROTTLE_INTERVAL     = 5000,
    ENET_PEER_PACKET_LOSS_SCALE            = (1 << 16),
    ENET_PEER_PACKET_LOSS_INTERVAL         = 10000,
    ENET_PEER_WINDOW_SIZE_SCALE            = 64 * 1024,
    ENET_PEER_TIMEOUT_LIMIT                = 32,
    ENET_PEER_TIMEOUT_MINIMUM              = 5000,
    ENET_PEER_TIMEOUT_MAXIMUM              = 30000,
    ENET_PEER_PING_INTERVAL                = 500,
    ENET_PEER_UNSEQUENCED_WINDOWS          = 64,
    ENET_PEER_UNSEQUENCED_WINDOW_SIZE      = 1024,
    ENET_PEER_FREE_UNSEQUENCED_WINDOWS     = 32,
    ENET_PEER_RELIABLE_WINDOWS             = 16,
    ENET_PEER_RELIABLE_WINDOW_SIZE         = 0x1000,
    ENET_PEER_FREE_RELIABLE_WINDOWS        = 8
}

struct ENetChannel {
    ushort outgoingReliableSequenceNumber;
    ushort outgoingUnreliableSequenceNumber;
    ushort usedReliableWindows;
    ushort[Enet_Host_Peer_Enum.ENET_PEER_RELIABLE_WINDOWS] reliableWindows;
    ushort incomingReliableSequenceNumber;
    ushort incomingUnreliableSequenceNumber;
    ENetList    incomingReliableCommands;
    ENetList    incomingUnreliableCommands;
}

constdef ENetPeerFlag
{
    ENET_PEER_FLAG_NEEDS_DISPATCH = (1 << 0),
    ENET_PEER_FLAG_CONTINUE_SENDING = (1 << 1)
}

/**
 * An ENet peer which data packets may be sent or received from.
 *
 * No fields should be modified unless otherwise specified.
 */
struct ENetPeer {
    ENetListNode      dispatchList;
    ENetHost *host;
    ushort       outgoingPeerID;
    ushort       incomingPeerID;
    uint       connectID;
    char        outgoingSessionID;
    char        incomingSessionID;
    ENetAddress       address; /**< Internet address of the peer */
    void *            data;    /**< Application private data, may be freely modified */
    ENetPeerState     state;
    ENetChannel *     channels;
    usz            channelCount;      /**< Number of channels allocated for communication with peer */
    uint       incomingBandwidth; /**< Downstream bandwidth of the client in bytes/second */
    uint       outgoingBandwidth; /**< Upstream bandwidth of the client in bytes/second */
    uint       incomingBandwidthThrottleEpoch;
    uint       outgoingBandwidthThrottleEpoch;
    uint       incomingDataTotal;
    ulong       totalDataReceived;
    uint       outgoingDataTotal;
    ulong       totalDataSent;
    uint       lastSendTime;
    uint       lastReceiveTime;
    uint       nextTimeout;
    uint       earliestTimeout;
    uint       packetLossEpoch;
    uint       packetsSent;
    ulong       totalPacketsSent; /**< total number of packets sent during a session */
    uint       packetsLost;
    uint       totalPacketsLost;     /**< total number of packets lost during a session */
    uint       packetLoss; /**< mean packet loss of reliable packets as a ratio with respect to the constant ENET_PEER_PACKET_LOSS_SCALE */
    uint       packetLossVariance;
    uint       packetThrottle;
    uint       packetThrottleLimit;
    uint       packetThrottleCounter;
    uint       packetThrottleEpoch;
    uint       packetThrottleAcceleration;
    uint       packetThrottleDeceleration;
    uint       packetThrottleInterval;
    uint       pingInterval;
    uint       timeoutLimit;
    uint       timeoutMinimum;
    uint       timeoutMaximum;
    uint       lastRoundTripTime;
    uint       lowestRoundTripTime;
    uint       lastRoundTripTimeVariance;
    uint       highestRoundTripTimeVariance;
    uint       roundTripTime; /**< mean round trip time (RTT), in milliseconds, between sending a reliable packet and receiving its acknowledgement */
    uint       roundTripTimeVariance;
    uint       mtu;
    uint       windowSize;
    uint       reliableDataInTransit;
    ushort       outgoingReliableSequenceNumber;
    ENetList          acknowledgements;
    ENetList          sentReliableCommands;
    ENetList          outgoingCommands;
    ENetList          outgoingSendReliableCommands;
    ENetList          dispatchedCommands;
    ushort       flags;
    ushort       reserved;
    ushort       incomingUnsequencedGroup;
    ushort       outgoingUnsequencedGroup;
    uint[Enet_Host_Peer_Enum.ENET_PEER_UNSEQUENCED_WINDOW_SIZE / 32]       unsequencedWindow;
    uint       eventData;
    usz            totalWaitingData;
}

/** An ENet packet compressor for compressing UDP packets before socket sends or receives. */
struct ENetCompressor {
    /** Context data for the compressor. Must be non-NULL. */
    void *context;
    ENetCompressorCompressFn compress;
    ENetCompressorDecompressFn decompress;
    ENetCompressorDestroyFn destroy;
}

/** Compresses from inBuffers[0:inBufferCount-1], containing inLimit bytes, to outData, outputting at most outLimit bytes. Should return 0 on failure. */
alias ENetCompressorCompressFn = fn usz (void *context, ENetBuffer * inBuffers, usz inBufferCount, usz inLimit, char * outData, usz outLimit);

/** Decompresses from inData, containing inLimit bytes, to outData, outputting at most outLimit bytes. Should return 0 on failure. */
alias ENetCompressorDecompressFn = fn usz (void *context, ZString inData, usz inLimit, char * outData, usz outLimit);

/** Destroys the context when compression is disabled or the host is destroyed. May be NULL. */
alias ENetCompressorDestroyFn = fn void (void *context);

/** Callback that computes the checksum of the data held in buffers[0:bufferCount-1] */
alias ENetChecksumCallback = fn uint (ENetBuffer *buffers, usz bufferCount);

/** Callback for intercepting received raw UDP packets. Should return 1 to intercept, 0 to ignore, or -1 to propagate an error. */
alias ENetInterceptCallback = fn int ( ENetHost *host, void *event);

    /** An ENet host for communicating with peers.
     *
     * No fields should be modified unless otherwise stated.
     *
     *  @sa enet_host_create()
     *  @sa enet_host_destroy()
     *  @sa enet_host_connect()
     *  @sa enet_host_service()
     *  @sa enet_host_flush()
     *  @sa enet_host_broadcast()
     *  @sa enet_host_compress()
     *  @sa enet_host_channel_limit()
     *  @sa enet_host_bandwidth_limit()
     *  @sa enet_host_bandwidth_throttle()
     */
struct ENetHost {
    ENetSocket            socket;
    ENetAddress           address;           /**< Internet address of the host */
    uint           incomingBandwidth; /**< downstream bandwidth of the host */
    uint           outgoingBandwidth; /**< upstream bandwidth of the host */
    uint           bandwidthThrottleEpoch;
    uint           mtu;
    uint           randomSeed;
    int                   recalculateBandwidthLimits;
    ENetPeer *            peers;        /**< array of peers allocated for this host */
    usz                peerCount;    /**< number of peers allocated for this host */
    usz                channelLimit; /**< maximum number of channels allowed for connected peers */
    uint           serviceTime;
    ENetList              dispatchQueue;
    uint           totalQueued;
    usz                packetSize;
    ushort           headerFlags;
    ENetProtocol[(int) ENetProtocolMinMax.ENET_PROTOCOL_MAXIMUM_PACKET_COMMANDS]          commands;
    usz                commandCount;
    ENetBuffer[ENET_BUFFER_MAXIMUM]            buffers;
    usz                bufferCount;
    ENetChecksumCallback  checksum; /**< callback the user can set to enable packet checksums for this host */
    ENetCompressor        compressor;
    char[2][(int)ENetProtocolMinMax.ENET_PROTOCOL_MAXIMUM_MTU]            packetData;
    ENetAddress           receivedAddress;
    char *          receivedData;
    usz                receivedDataLength;
    uint           totalSentData;        /**< total data sent, user should reset to 0 as needed to prevent overflow */
    uint           totalSentPackets;     /**< total UDP packets sent, user should reset to 0 as needed to prevent overflow */
    uint           totalReceivedData;    /**< total data received, user should reset to 0 as needed to prevent overflow */
    uint           totalReceivedPackets; /**< total UDP packets received, user should reset to 0 as needed to prevent overflow */
    ENetInterceptCallback intercept;            /**< callback the user can set to intercept received raw UDP packets */
    usz                connectedPeers;
    usz                bandwidthLimitedPeers;
    usz                duplicatePeers;     /**< optional number of allowed peers from duplicate IPs, defaults to ENET_PROTOCOL_MAXIMUM_PEER_ID */
    usz                maximumPacketSize;  /**< the maximum allowable packet size that may be sent or received on a peer */
    usz                maximumWaitingData; /**< the maximum aggregate amount of buffer space a peer may use waiting for packets to be delivered */
} 

/**
 * An ENet event type, as specified in @ref ENetEvent.
 */
enum ENetEventType : int {
    /** no event occurred within the specified time limit */
    ENET_EVENT_TYPE_NONE       ,//= 0,
    /** a connection request initiated by enet_host_connect has completed.
     * The peer field contains the peer which successfully connected.
     */
    ENET_EVENT_TYPE_CONNECT    ,//= 1,
    /** a peer has disconnected.  This event is generated on a successful
     * completion of a disconnect initiated by enet_peer_disconnect, if
     * a peer has timed out.  The peer field contains the peer
     * which disconnected. The data field contains user supplied data
     * describing the disconnection, or 0, if none is available.
     */
    ENET_EVENT_TYPE_DISCONNECT ,//= 2,
    /** a packet has been received from a peer.  The peer field specifies the
     * peer which sent the packet.  The channelID field specifies the channel
     * number upon which the packet was received.  The packet field contains
     * the packet that was received; this packet must be destroyed with
     * enet_packet_destroy after use.
     */
    ENET_EVENT_TYPE_RECEIVE    ,//= 3,
    /** a peer is disconnected because the host didn't receive the acknowledgment
     * packet within certain maximum time out. The reason could be because of bad
     * network connection or  host crashed.
     */
    ENET_EVENT_TYPE_DISCONNECT_TIMEOUT ,//= 4,
}

/**
 * An ENet event as returned by enet_host_service().
 *
 * @sa enet_host_service
 */
struct ENetEvent {
    ENetEventType type;      /**< type of the event */
    ENetPeer *    peer;      /**< peer that generated a connect, disconnect or receive event */
    char    channelID; /**< channel on the peer that generated the event, if appropriate */
    uint   data;      /**< data associated with the event, if appropriate */
    ENetPacket *  packet;    /**< packet associated with the event, if appropriate */
}

// public API


    /**
     * Initializes ENet globally.  Must be called prior to using any functions in ENet.
     * @returns 0 on success, < 0 on failure
     */
    extern fn int initialize() @cname("enet_initialize");

    /**
     * Initializes ENet globally and supplies user-overridden callbacks. Must be called prior to using any functions in ENet. Do not use enet_initialize() if you use this variant. Make sure the ENetCallbacks structure is zeroed out so that any additional callbacks added in future versions will be properly ignored.
     *
     * @param version the constant ENET_VERSION should be supplied so ENet knows which version of ENetCallbacks struct to use
     * @param inits user-overridden callbacks where any NULL callbacks will use ENet's defaults
     * @returns 0 on success, < 0 on failure
     */
    extern fn int initialize_with_callbacks(ENetVersion version, ENetCallbacks * inits) @cname("enet_initialize_with_callbacks");

    /**
     * Shuts down ENet globally.  Should be called when a program that has initialized ENet exits.
     */
    extern fn void deinitialize() @cname("enet_deinitialize");

    /**
     * Gives the linked version of the ENet library.
     * @returns the version number
     */
    extern fn ENetVersion linked_version() @cname("enet_linked_version");

    /** Returns the monotonic time in milliseconds. Its initial value is unspecified unless otherwise set. */
    extern fn uint time_get() @cname("enet_time_get");

    /** ENet socket functions */
    extern fn ENetSocket socket_create(ENetSocketType) @cname("enet_socket_create");
    extern fn int        socket_bind(ENetSocket, ENetAddress *) @cname("enet_socket_bind");
    extern fn int        socket_get_address(ENetSocket, ENetAddress *) @cname("enet_socket_get_address");
    extern fn int        socket_listen(ENetSocket, int) @cname("enet_socket_listen");
    extern fn ENetSocket socket_accept(ENetSocket, ENetAddress *) @cname("enet_socket_accept");
    extern fn int        socket_connect(ENetSocket, ENetAddress *) @cname("enet_socket_connect");
    extern fn int        socket_send(ENetSocket, ENetAddress *, ENetBuffer *, usz) @cname("enet_socket_send");
    extern fn int        socket_receive(ENetSocket, ENetAddress *, ENetBuffer *, usz) @cname("enet_socket_receive");
    extern fn int        socket_wait(ENetSocket, uint *, ulong) @cname("enet_socket_wait");
    extern fn int        socket_set_option(ENetSocket, ENetSocketOption, int) @cname("enet_socket_set_option");
    extern fn int        socket_get_option(ENetSocket, ENetSocketOption, int *) @cname("enet_socket_get_option");
    extern fn int        socket_shutdown(ENetSocket, ENetSocketShutdown) @cname("enet_socket_shutdown");
    extern fn void       socket_destroy(ENetSocket) @cname("enet_socket_destroy");
    extern fn int        socketset_select(ENetSocket, ENetSocketSet *, ENetSocketSet *, uint) @cname("enet_socketset_select");

    /** Attempts to parse the printable form of the IP address in the parameter hostName
        and sets the host field in the address parameter if successful.
        @param address destination to store the parsed IP address
        @param hostName IP address to parse
        @retval 0 on success
        @retval < 0 on failure
        @returns the address of the given hostName in address on success
    */
    extern fn int address_set_host_ip_old(ENetAddress * address, ZString hostName) @cname("enet_address_set_host_ip_old");

    /** Attempts to resolve the host named by the parameter hostName and sets
        the host field in the address parameter if successful.
        @param address destination to store resolved address
        @param hostName host name to lookup
        @retval 0 on success
        @retval < 0 on failure
        @returns the address of the given hostName in address on success
    */
    extern fn int address_set_host_old(ENetAddress * address, ZString hostName) @cname("enet_address_set_host_old");

    /** Gives the printable form of the IP address specified in the address parameter.
        @param address    address printed
        @param hostName   destination for name, must not be NULL
        @param nameLength maximum length of hostName.
        @returns the null-terminated name of the host in hostName on success
        @retval 0 on success
        @retval < 0 on failure
    */
    extern fn int address_get_host_ip_old(ENetAddress * address, char * hostName, usz nameLength) @cname("enet_address_get_host_ip_old");

    /** Attempts to do a reverse lookup of the host field in the address parameter.
        @param address    address used for reverse lookup
        @param hostName   destination for name, must not be NULL
        @param nameLength maximum length of hostName.
        @returns the null-terminated name of the host in hostName on success
        @retval 0 on success
        @retval < 0 on failure
    */
    extern fn int address_get_host_old(ENetAddress * address, char * hostName, usz nameLength) @cname("enet_address_get_host_old");

    extern fn int address_set_host_ip_new(ENetAddress * address, ZString hostName) @cname("enet_address_set_host_ip_new");
    extern fn int address_set_host_new(ENetAddress * address, ZString hostName) @cname("enet_address_set_host_new");
    extern fn int address_get_host_ip_new(ENetAddress * address, char * hostName, usz nameLength) @cname("enet_address_get_host_ip_new");
    extern fn int address_get_host_new(ENetAddress * address, char * hostName, usz nameLength) @cname("enet_address_get_host_new");

module enet @if($feature(ENET_FEATURE_ADDRESS_MAPPING));
macro address_set_host_ip(ENetAddress * address, ZString hostName) => address_set_host_ip_new(address, hostName);
macro address_set_host(ENetAddress * address, ZString hostName) =>    address_set_host_new(address, hostName);
macro address_get_host_ip(ENetAddress * address, char * hostName, usz nameLength) => address_get_host_ip_new(address, hostName, nameLength);
macro address_get_host(ENetAddress * address, char * hostName, usz nameLength) =>    address_get_host_new(address, hostName, nameLength);

module enet @if(!$feature(ENET_FEATURE_ADDRESS_MAPPING));
macro address_set_host_ip(ENetAddress * address, ZString hostName) =>                    address_set_host_ip_old(address, hostName);
macro address_set_host(ENetAddress * address, ZString hostName) =>                      address_set_host_old(address, hostName);
macro address_get_host_ip(ENetAddress * address, char * hostName, usz nameLength) =>     address_get_host_ip_old(address, hostName, nameLength);
macro address_get_host(ENetAddress * address, char * hostName, usz nameLength) =>       address_get_host_old(address, hostName, nameLength);


module enet;

extern fn uint host_get_peers_count(ENetHost *) @cname("enet_host_get_peers_count");
extern fn uint host_get_packets_sent(ENetHost *) @cname("enet_host_get_packets_sent");
extern fn uint host_get_packets_received(ENetHost *) @cname("enet_host_get_packets_received");
extern fn uint host_get_bytes_sent(ENetHost *) @cname("enet_host_get_bytes_sent");
extern fn uint host_get_bytes_received(ENetHost *) @cname("enet_host_get_bytes_received");
extern fn uint host_get_received_data(ENetHost *, char** data) @cname("enet_host_get_received_data");
extern fn uint host_get_mtu(ENetHost *) @cname("enet_host_get_mtu");

extern fn uint      peer_get_id(ENetPeer *) @cname("enet_peer_get_id");
extern fn uint      peer_get_ip(ENetPeer *, char * ip, usz ipLength) @cname("enet_peer_get_ip");
extern fn ushort    peer_get_port(ENetPeer *) @cname("enet_peer_get_port");
extern fn uint      peer_get_rtt(ENetPeer *) @cname("enet_peer_get_rtt");
extern fn ulong     peer_get_packets_sent(ENetPeer *) @cname("enet_peer_get_packets_sent");
extern fn uint      peer_get_packets_lost(ENetPeer *) @cname("enet_peer_get_packets_lost");
extern fn ulong     peer_get_bytes_sent(ENetPeer *) @cname("enet_peer_get_bytes_sent");
extern fn ulong     peer_get_bytes_received(ENetPeer *) @cname("enet_peer_get_bytes_received");

extern fn ENetPeerState peer_get_state(ENetPeer *) @cname("enet_peer_get_state");

extern fn void * peer_get_data(ENetPeer *) @cname("enet_peer_get_data");
extern fn void   peer_set_data(ENetPeer *,  void *) @cname("enet_peer_set_data");

extern fn void *      packet_get_data(ENetPacket *) @cname("enet_packet_get_data");
extern fn uint        packet_get_length(ENetPacket *) @cname("enet_packet_get_length");
extern fn void        packet_set_free_callback(ENetPacket *, void *) @cname("enet_packet_set_free_callback");

extern fn ENetPacket *  packet_create_offset( void *, usz, usz, uint) @cname("enet_packet_create_offset");
extern fn uint          crc32(ENetBuffer *, usz) @cname("enet_crc32");

extern fn ENetHost * host_create(ENetAddress *, usz, usz, uint, uint) @cname("enet_host_create");
extern fn void       host_destroy(ENetHost *) @cname("enet_host_destroy");
extern fn ENetPeer * host_connect(ENetHost *, ENetAddress *, usz, uint) @cname("enet_host_connect");
extern fn int        host_check_events(ENetHost *, ENetEvent *) @cname("enet_host_check_events");
extern fn int        host_service(ENetHost *, ENetEvent *, uint) @cname("enet_host_service");
extern fn int        host_send_raw(ENetHost *, ENetAddress *, char *, usz) @cname("enet_host_send_raw");
extern fn int        host_send_raw_ex(ENetHost *host, ENetAddress* address, char* data, usz skipBytes, usz bytesToSend) @cname("enet_host_send_raw_ex");
extern fn void       host_set_intercept(ENetHost *, ENetInterceptCallback) @cname("enet_host_set_intercept");
extern fn void       host_flush(ENetHost *) @cname("enet_host_flush");
extern fn void       host_broadcast(ENetHost *, char, ENetPacket *) @cname("enet_host_broadcast");
extern fn void       host_compress(ENetHost *, ENetCompressor *) @cname("enet_host_compress");
extern fn void       host_channel_limit(ENetHost *, usz) @cname("enet_host_channel_limit");
extern fn void       host_bandwidth_limit(ENetHost *, uint, uint) @cname("enet_host_bandwidth_limit");
extern fn void       host_bandwidth_throttle(ENetHost *) @cname("enet_host_bandwidth_throttle");
extern fn ulong      host_random_seed() @cname("enet_host_random_seed");
extern fn uint       host_random(ENetHost *) @cname("enet_host_random");

extern fn int                   peer_send(ENetPeer *, char, ENetPacket *) @cname("enet_peer_send");
extern fn ENetPacket *          peer_receive(ENetPeer *, char * channelID) @cname("enet_peer_receive");
extern fn void                  peer_ping(ENetPeer *) @cname("enet_peer_ping");
extern fn void                  peer_ping_interval(ENetPeer *, uint) @cname("enet_peer_ping_interval");
extern fn void                  peer_timeout(ENetPeer *, uint, uint, uint) @cname("enet_peer_timeout");
extern fn void                  peer_reset(ENetPeer *) @cname("enet_peer_reset");
extern fn void                  peer_disconnect(ENetPeer *, uint) @cname("enet_peer_disconnect");
extern fn void                  peer_disconnect_now(ENetPeer *, uint) @cname("enet_peer_disconnect_now");
extern fn void                  peer_disconnect_later(ENetPeer *, uint) @cname("enet_peer_disconnect_later");
extern fn void                  peer_throttle_configure(ENetPeer *, uint, uint, uint) @cname("enet_peer_throttle_configure");
extern fn int                   peer_throttle(ENetPeer *, uint) @cname("enet_peer_throttle");
extern fn void                  peer_reset_queues(ENetPeer *) @cname("enet_peer_reset_queues");
extern fn int                   peer_has_outgoing_commands(ENetPeer *) @cname("enet_peer_has_outgoing_commands");
extern fn void                  peer_setup_outgoing_command(ENetPeer *, ENetOutgoingCommand *) @cname("enet_peer_setup_outgoing_command");
extern fn ENetOutgoingCommand * peer_queue_outgoing_command(ENetPeer *,  ENetProtocol *, ENetPacket *, uint, ushort) @cname("enet_peer_queue_outgoing_command");
extern fn ENetIncomingCommand * peer_queue_incoming_command(ENetPeer *,  ENetProtocol *,  void *, usz, uint, uint) @cname("enet_peer_queue_incoming_command");
extern fn ENetAcknowledgement * peer_queue_acknowledgement(ENetPeer *,  ENetProtocol *, ushort) @cname("enet_peer_queue_acknowledgement");
extern fn void                  peer_dispatch_incoming_unreliable_commands(ENetPeer *, ENetChannel *, ENetIncomingCommand *) @cname("enet_peer_dispatch_incoming_unreliable_commands");
extern fn void                  peer_dispatch_incoming_reliable_commands(ENetPeer *, ENetChannel *, ENetIncomingCommand *) @cname("enet_peer_dispatch_incoming_reliable_commands");
extern fn void                  peer_on_connect(ENetPeer *) @cname("enet_peer_on_connect");
extern fn void                  peer_on_disconnect(ENetPeer *) @cname("enet_peer_on_disconnect");

extern fn usz protocol_command_size (char) @cname("enet_protocol_command_size");

typedef ENetSocketSet @structlike = void;

module enet::helper;
import std::io;


//partially yoinked idea from "inetaddr.c3" in std lib
struct In6_addr (Printable)  {
	union {
		char[16] s6_addr ;   /* IPv6 address */
		uint128 val;
	}
}

fn usz? In6_addr.to_format(&self, Formatter* formatter) @dynamic {
	for(int i =0; i < self.s6_addr.len; i++) {
		formatter.printf("%d", self.s6_addr[i])!;
	}

	return $typeof(self.val).sizeof;
}

// NOTE: SKIPPING ATOMICS FOR NOW

