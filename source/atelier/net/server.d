/**
    Server

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.net.server;

import std.stdio;
import std.socket;
import std.conv;
import std.algorithm: remove;
import core.time: dur;

import atelier.core;
import atelier.common;

import atelier.net.tcpserver;
import atelier.net.netevent;

//Number of clients allowed (the server is not counted, so there is 'nbOfClientsAllowed + 1' players in total).
static immutable uint nbOfClientsAllowed = 7u;

shared ClientInfo[nbOfClientsAllowed] clientsInfo;
shared bool clientsInfoChanged, isServerAllowingConnections;

private {
	__gshared RingBuffer!(OutStream)[nbOfClientsAllowed] serverSendBuffers;
	__gshared RingBuffer!InStream serverReceiveBuffer;
	Server server;
}

void startServer(ushort port) {
	if(server !is null && server.isWorking)
		throw new Exception("Server already running");
	isServerAllowingConnections = true;
	server = new Server(port);
	server.start();
}

void closeServer() {
	if(server is null)
		throw new Exception("Could not close the server");
	server.isWorking = false;
}

struct ClientInfo {
	//Used internally, do not modify.
	bool isSlotUsed;

	//Display name
	string name;
}

void serverBroadcast(OutStream stream) {
	foreach(int i, serverSendBuffer; serverSendBuffers) {
		if(clientsInfo[i].isSlotUsed)
			serverSendBuffer.write(stream);
	}
}

void serverSend(int id, OutStream stream) {
	if(id >= nbOfClientsAllowed)
		return;
	if(clientsInfo[id].isSlotUsed)
		serverSendBuffers[id].write(stream);
}

InStream serverReceive() {
	return serverReceiveBuffer.read();
}

bool serverHasPendingMessage() {
	return !serverReceiveBuffer.isEmpty;
}

class Server: TcpServer {
	shared bool isWorking = true;

	this(ushort port) {
		super();
		serverReceiveBuffer = new RingBuffer!InStream;
		foreach(i; 0..nbOfClientsAllowed)
			serverSendBuffers[i] = new RingBuffer!OutStream;
		open(port);
	}

	override void run() {
		try {
			SocketSet readSet = new SocketSet(nbOfClientsAllowed + 1u);
			SocketSet writeSet = new SocketSet(nbOfClientsAllowed);
			SocketSet errorSet = new SocketSet(nbOfClientsAllowed + 1u);
			Socket[] clientsSockets;
			int[] clientsId;
			int disconnectingClient = -1;

			while(isWorking) {
				//Socketset selection.
				readSet.reset();
				writeSet.reset();
				errorSet.reset();
				
				readSet.add(_socket);
				errorSet.add(_socket);
				foreach(socket; clientsSockets) {
					readSet.add(socket);
					writeSet.add(socket);
					errorSet.add(socket);
				}

				Socket.select(readSet, writeSet, errorSet, dur!"seconds"(1));

				if(!isWorking)
					break;
				
				//Read/write operations.
				foreach(size_t i, Socket socket; clientsSockets) {
					int id = clientsId[i];
					if(errorSet.isSet(socket))
						disconnectingClient = cast(int)i;
					else if(readSet.isSet(socket) && !serverReceiveBuffer.isFull) {
						auto inStream = new InStream;
						if(receive(socket, inStream))
							serverReceiveBuffer.write(inStream);
						else
							disconnectingClient = cast(int)i;
					}
					else if(writeSet.isSet(socket) && !serverSendBuffers[id].isEmpty) {
						auto outStream = serverSendBuffers[id].read();
						if(!send(socket, outStream))
							disconnectingClient = cast(int)i;
					}
				}

				//Client Disconnection.
				//Only one disconnection is handled at a time.
				if(disconnectingClient != -1) {
					int id = clientsId[disconnectingClient];
					clientsSockets[disconnectingClient].shutdown(SocketShutdown.BOTH);
					clientsSockets[disconnectingClient].close();
					clientsSockets = clientsSockets.remove(disconnectingClient);
					clientsInfo[id].isSlotUsed = false;
					serverSendBuffers[id].reset();
					clientsId = clientsId.remove(disconnectingClient);
					clientsInfoChanged = true;
					disconnectingClient = -1;
				}

				//Client Connection.
				//Check errorSet to avoid ghost connections.
				if(readSet.isSet(_socket) && errorSet.isSet(_socket) == 0) {
					auto check = new OutStream;
					if(clientsSockets.length < nbOfClientsAllowed && isServerAllowingConnections) {
						Socket newSocket = _socket.accept();
						newSocket.blocking = true;
						clientsSockets ~= newSocket;
						
						foreach(id; 0 .. nbOfClientsAllowed) {
							if(!clientsInfo[id].isSlotUsed) {
								clientsInfo[id].isSlotUsed = true;
								clientsInfo[id].name = "Guest " ~ to!string(id);
								clientsId ~= id;
								break;
							}
						}
						check.write(NetEvent.Connected);
						send(newSocket, check);
						clientsInfoChanged = true;
					}
					else {
						auto newSocket = _socket.accept();
						newSocket.blocking = true;
						check.write(NetEvent.Disconnected);
						send(newSocket, check);
						newSocket.shutdown(SocketShutdown.BOTH);
						newSocket.close();
					}
				}
			}

			foreach(id; 0 .. nbOfClientsAllowed)
				clientsInfo[id].isSlotUsed = false;

			foreach(socket; clientsSockets) {
				socket.shutdown(SocketShutdown.BOTH);
				socket.close();
			}
			close();
		}
		catch(Exception e) {
			writeln(e.msg);
			close();
		}
	}
}