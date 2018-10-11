/**
    TCP client

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.net.tcpclient;

import std.regex;
import std.socket;
import std.string;
import std.conv;
import std.bitmanip;
import core.thread;

import atelier.core.stream;

TcpSocket connectToServer(string address, ushort port) {
	TcpSocket socket = new TcpSocket;
	Address[] addresses = getAddress(address, port);
	socket.blocking = true;
	if(addresses.length == 0)
		return null;
	foreach(Address addr; addresses) {
		if(matchFirst(addr.toAddrString(), `\b[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}`)) {
			socket.connect(addr);
			if(socket.isAlive) {
				return socket;
			}
		}
	}
	return null;
}

abstract class TcpClient: Thread {
	protected {
		Address[] _addresses; //Todo: Fetch this from socket
		TcpSocket _socket;
	}

	@property {
		string address() const { return _addresses.length ? _addresses[0].toAddrString() : ""; }
		string port() const { return _addresses.length ? _addresses[0].toPortString() : ""; }
	}

	this(TcpSocket socket) {
		super(&run);
		_socket = socket;
	}

	~this() {
		close();
	}

	void close() {
		if(_socket is null)
			return;
		_socket.shutdown(SocketShutdown.BOTH);
		_socket.close();
		_socket = null;
	}

	bool send(string message) {
		char[] buffer = message.dup;
		bool isValid = (message.length == _socket.send(buffer)); 
		return isValid;
	}

	bool receive(ref string message, uint size) {
		char[] buffer = new char[size];
		bool isValid = (size == _socket.receive(buffer));
		message = to!string(buffer);
		return isValid;
	}

	bool send(OutStream stream) {
		ubyte[ushort.sizeof] sizeBuffer = nativeToBigEndian!ushort(cast(ushort)stream.length);
		bool isValid = (ushort.sizeof == _socket.send(sizeBuffer));
		if(!isValid)
			return isValid;
		isValid = (stream.length == _socket.send(stream.data));
		return isValid;
	}

	bool receive(ref InStream stream) {
		ubyte[ushort.sizeof] sizeBuffer;
		bool isValid = (ushort.sizeof == _socket.receive(sizeBuffer));
		if(!isValid)
			return isValid;
		ushort size = bigEndianToNative!ushort(sizeBuffer);
		stream.length = size;
		isValid = (size == _socket.receive(stream.data));
		return isValid;
	}

	abstract protected void run();
}