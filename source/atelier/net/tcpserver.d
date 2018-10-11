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

module atelier.net.tcpserver;

import core.thread;
import std.socket;
import std.bitmanip;
import std.conv;

import atelier.core;

abstract class TcpServer: Thread {
	protected {
		TcpSocket _socket;
		Address _address;
	}

	@property {
		string address() const { return _address.toAddrString(); }
		string port() const { return _address.toPortString(); }
	}

	this() {
		super(&run);
		_socket = new TcpSocket;
		_socket.blocking = true;
	}

	~this() {
		close();
	}

	void open(ushort listenPort) {
		if(_socket is null)
			return;
		_address = new InternetAddress(listenPort);
		_socket.bind(_address);
		_socket.listen(10);
		if(!_socket.isAlive())
			throw new Exception("Could not start the server.");
	}

	void close() {
		if(_socket is null)
			return;
		_socket.shutdown(SocketShutdown.BOTH);
		_socket.close();
		_socket = null;
	}

	Socket accept() {
		if(_socket is null)
			throw new Exception("Server socket not initialized");
		return _socket.accept();
	}

	bool send(Socket clientSocket, string message) {
		char[] buffer = message.dup;
		bool isValid = (message.length == clientSocket.send(buffer));
		return isValid;
	}

	bool receive(Socket clientSocket, ref string message, uint size) {
		char[] buffer = new char[size];
		bool isValid = (size == clientSocket.receive(buffer));
		message = to!string(buffer);
		return isValid;
	}

	bool send(Socket clientSocket, OutStream stream) {
		ubyte[ushort.sizeof] sizeBuffer = nativeToBigEndian!ushort(cast(ushort)stream.length);
		bool isValid = (ushort.sizeof == clientSocket.send(sizeBuffer));
		if(!isValid)
			return isValid;
		isValid = (stream.length == clientSocket.send(stream.data));
		return isValid;
	}

	bool receive(Socket clientSocket, ref InStream stream) {
		ubyte[ushort.sizeof] sizeBuffer;
		bool isValid = (ushort.sizeof == clientSocket.receive(sizeBuffer));
		if(!isValid)
			return isValid;
		ushort size = bigEndianToNative!ushort(sizeBuffer);
		stream.length = size;
		isValid = (size == clientSocket.receive(stream.data));
		return isValid;
	}

	abstract protected void run();
}