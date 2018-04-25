/**
Grimoire
Copyright (c) 2017 Enalye

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising
from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute
it freely, subject to the following restrictions:

	1. The origin of this software must not be misrepresented;
	   you must not claim that you wrote the original software.
	   If you use this software in a product, an acknowledgment
	   in the product documentation would be appreciated but
	   is not required.

	2. Altered source versions must be plainly marked as such,
	   and must not be misrepresented as being the original software.

	3. This notice may not be removed or altered from any source distribution.
*/

module net.tcpclient;

import std.regex;
import std.socket;
import std.string;
import std.conv;
import std.bitmanip;
import core.thread;

import core.stream;

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