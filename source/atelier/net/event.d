/**
    Event

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.net.event;

import atelier.core;

alias NetEventType = ubyte;
enum NetEvent: NetEventType {
	Connected = 0,
	Disconnected,
	Custom
}