#=======================================================
# Arturo
# Programming Language + Bytecode VM compiler
# (c) 2019-2022 Yanis Zafirópulos
#
# @file: library/Sockets.nim
#=======================================================

## The main Sockets module 
## (part of the standard library)

#=======================================
# Pragmas
#=======================================

{.used.}

#=======================================
# Libraries
#=======================================

when not defined(WEB):
    import std/net as netsock except Socket
    import nativesockets

import vm/values/custom/[vsocket]

import vm/lib

when not defined(WEB):
    import vm/errors

#=======================================
# Methods
#=======================================

proc defineSymbols*() =
    
    when not defined(WEB):

        builtin "accept",
            alias       = unaliased, 
            rule        = PrefixPrecedence,
            description = "accept incoming connection and return corresponding socket",
            args        = {
                "server"    : {Socket}
            },
            attrs       = NoAttrs,
            returns     = {Socket},
            example     = """
            """:
                #=======================================================
                when defined(SAFE): RuntimeError_OperationNotPermitted("accept")

                var client: netsock.Socket
                echo "pre-accept"
                x.sock.socket.accept(client)
                echo "post-accept"

                let address = ""
                let port = Port(0)
                #let (address,port) = getPeerAddr(client)

                let socket = initSocket(client, proto=x.sock.protocol, address=address, port=port)
                echo "after initSocket"
                push newSocket(socket)

        builtin "connect",
            alias       = unaliased, 
            rule        = PrefixPrecedence,
            description = "create new socket connection to given server port",
            args        = {
                "port"  : {Integer}
            },
            attrs       = {
                "to"        : ({String},"set socket address"),
                "udp"       : ({Logical},"use UDP instead of TCP")
            },
            returns     = {Socket},
            example     = """
            """:
                #=======================================================
                when defined(SAFE): RuntimeError_OperationNotPermitted("connect")

                let isUDP = hadAttr("udp")

                let protocol = 
                    if isUDP: IPPROTO_UDP
                    else: IPPROTO_TCP

                var toAddress: string  
                if checkAttr("to"):
                    toAddress = aTo.s
                else:
                    toAddress = "0.0.0.0"

                var port = Port(x.i)

                var sock: netsock.Socket = netsock.newSocket(protocol=protocol)
                if not isUDP:
                    sock.connect(toAddress, port)

                let socket = initSocket(sock, proto=protocol, address=toAddress, port=port)

                push newSocket(socket)

        builtin "listen",
            alias       = unaliased, 
            rule        = PrefixPrecedence,
            description = "start listening on given port and return new socket",
            args        = {
                "port"  : {Integer}
            },
            attrs       = {
                "blocking"  : ({String},"set blocking mode (default: false)"),
                "udp"       : ({Logical},"use UDP instead of TCP")
            },
            returns     = {Socket},
            example     = """
            """:
                #=======================================================
                when defined(SAFE): RuntimeError_OperationNotPermitted("listen")

                let blocking = hadAttr("blocking")
                let protocol = 
                    if hadAttr("udp"): IPPROTO_UDP
                    else: IPPROTO_TCP

                var sock: netsock.Socket = netsock.newSocket(protocol=protocol)
                sock.setSockOpt(OptReuseAddr, true)
                
                sock.getFd().setBlocking(blocking)
                sock.bindAddr(Port(x.i))
                sock.listen()

                let (address,port) = getLocalAddr(sock)

                let socket = initSocket(sock, proto=protocol, address=address, port=port)

                push newSocket(socket)

        builtin "receive",
            alias       = unaliased, 
            rule        = PrefixPrecedence,
            description = "receive line of data from selected socket",
            args        = {
                "origin"    : {Socket}  
            },
            attrs       = {
                "size"      : ({Integer},"set maximum size of received data"),
                "timeout"   : ({Integer},"set timeout (in milliseconds)")
            },
            returns     = {String},
            example     = """
            """:
                #=======================================================
                when defined(SAFE): RuntimeError_OperationNotPermitted("receive")

                var size = MaxLineLength
                if checkAttr("size"):
                    size = aSize.i

                var timeout = -1
                if checkAttr("timeout"):
                    timeout = aTimeout.i

                push newString(x.sock.socket.recvLine(timeout=timeout, maxLength=size))

        builtin "send",
            alias       = unaliased, 
            rule        = PrefixPrecedence,
            description = "send given message to selected socket",
            args        = {
                "destination"   : {Socket},
                "message"       : {String}    
            },
            attrs       = NoAttrs,
            returns     = {Nothing},
            example     = """
            """:
                #=======================================================
                when defined(SAFE): RuntimeError_OperationNotPermitted("send")

                x.sock.socket.send(y.s)

        builtin "send?",
            alias       = unaliased, 
            rule        = PrefixPrecedence,
            description = "send given message to selected socket and return true if successful",
            args        = {
                "destination"   : {Socket},
                "message"       : {String}    
            },
            attrs       = NoAttrs,
            returns     = {Logical},
            example     = """
            """:
                #=======================================================
                when defined(SAFE): RuntimeError_OperationNotPermitted("send?")

                push newLogical(x.sock.socket.trySend(y.s))

        builtin "unplug",
            alias       = unaliased, 
            rule        = PrefixPrecedence,
            description = "close given socket",
            args        = {
                "socket"    : {Socket} 
            },
            attrs       = NoAttrs,
            returns     = {Nothing},
            example     = """
            """:
                #=======================================================
                when defined(SAFE): RuntimeError_OperationNotPermitted("unplug")

                x.sock.socket.close()
    else:
        discard

#=======================================
# Add Library
#=======================================

Libraries.add(defineSymbols)
