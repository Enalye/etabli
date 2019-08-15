/**
    Client

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.net.client;

import std.stdio;
import std.socket;
import core.time: dur;

import atelier.core;
import atelier.net.tcpclient;
import atelier.net.server;
import atelier.net.netevent;

shared ClientInfo[] localClientsInfo;
shared bool hasLocalClientsInfoChanged;

private {
	__gshared RingBuffer!OutStream clientSendBuffer;
	__gshared RingBuffer!InStream clientReceiveBuffer;
	Client client;
}

void startClient(TcpSocket socket) {
	if(client !is null && client.isWorking)
		throw new Exception("Client already running");
	client = new Client(socket);
	client.start();
}

void closeClient() {
	if(client is null)
		throw new Exception("Could not close the client");
	client.isWorking = false;
}

bool isClientWorking() {
	return (client !is null && client.isWorking);
}

void clientSend(OutStream stream) {
	clientSendBuffer.write(stream);
}

InStream clientReceive() {
	return clientReceiveBuffer.read();
}

bool clientHasPendingMessage() {
	return !clientReceiveBuffer.isEmpty;
}

class Client: TcpClient {
	shared bool isWorking = true;
	bool hasJustConnected = true;

	this(TcpSocket socket) {
		super(socket);
		clientSendBuffer = new RingBuffer!OutStream;
		clientReceiveBuffer = new RingBuffer!InStream;
	}

	override void run() {
		try {
			SocketSet readSet = new SocketSet(1u);
			SocketSet writeSet = new SocketSet(1u);
			SocketSet errorSet = new SocketSet(1u);

			while(isWorking) {
				readSet.reset();
				writeSet.reset();
				errorSet.reset();
				
				readSet.add(_socket);
				writeSet.add(_socket);
				errorSet.add(_socket);

				Socket.select(readSet, writeSet, errorSet, dur!"seconds"(1));

				if(errorSet.isSet(_socket))
					isWorking = false;
				else if(readSet.isSet(_socket) && !clientReceiveBuffer.isFull) {
					auto inStream = new InStream;
					if(receive(inStream)) {
						if(hasJustConnected) {
							hasJustConnected = false;
							if(inStream.read!NetEvent() == NetEvent.Disconnected)
								isWorking = false;
						}
						else
							clientReceiveBuffer.write(inStream);
					}
					else
						isWorking = false;
				}
				else if(writeSet.isSet(_socket) && !clientSendBuffer.isEmpty) {
					auto outStream = clientSendBuffer.read();
					if(!send(outStream))
						isWorking = false;
				}
			}
			close();
		}
		catch(Exception e) {
			writeln(e.msg);
			close();
		}
	}
}