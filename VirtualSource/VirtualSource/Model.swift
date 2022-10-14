//
//  Model.swift
//  VirtualSource
//
//  Created by Shinichiro Oba on 2022/10/14.
//

import Foundation
import CoreMIDI

@MainActor
class Model: ObservableObject {
    
    private var clientRef = MIDIClientRef()
    
    private var sourceRef = MIDIEndpointRef()
    private var midi10SourceRef = MIDIEndpointRef()
    
    private let timebase: mach_timebase_info = {
        var timebase = mach_timebase_info()
        mach_timebase_info(&timebase)
        return timebase
    }()
    
    init() {
        MIDIClientCreate("VirtualSource - Cient" as CFString, nil, nil, &clientRef)
        
        MIDISourceCreate(clientRef, "VirtualSource - Deprecated API" as CFString, &sourceRef)
        MIDISourceCreateWithProtocol(clientRef, "VirtualSource - UMP MIDI 1.0" as CFString, ._1_0, &midi10SourceRef)
    }
    
    deinit {
        MIDIEndpointDispose(sourceRef)
        MIDIEndpointDispose(midi10SourceRef)
    }
    
    func sendNoteOn(channel: UInt8, note: UInt8, velocity: UInt8, delay: Double? = nil) {
        var packet = MIDIPacket()
        
        packet.length = 3
        packet.data.0 = 0x90 + (channel & 0x0f)
        packet.data.1 = note & 0x7f
        packet.data.2 = velocity & 0x7f
        
        if let delay {
            // Convert millisecond to MIDITimeStamp
            let delayTime = MIDITimeStamp(delay * 1_000_000 * Double(timebase.denom) / Double(timebase.numer))
            packet.timeStamp = mach_absolute_time() + delayTime
        }
        
        var packetList = MIDIPacketList(numPackets: 1, packet: packet)
        
        MIDIReceived(sourceRef, &packetList)
    }
    
    func sendMIDI1UPNoteOn(channel: UInt8, note: UInt8, velocity: UInt8, delay: Double? = nil) {
        var packet = MIDIEventPacket()
        
        packet.wordCount = 1
        packet.words.0 = MIDI1UPNoteOn(0, channel, note, velocity)
        
        print(String(format: "%08x", packet.words.0))
        
        if let delay {
            // Convert millisecond to MIDITimeStamp
            let delayTime = MIDITimeStamp(delay * 1_000_000 * Double(timebase.denom) / Double(timebase.numer))
            packet.timeStamp = mach_absolute_time() + delayTime
        }
        
        var eventList = MIDIEventList(protocol: ._1_0, numPackets: 1, packet: packet)
        
        MIDIReceivedEventList(midi10SourceRef, &eventList)
    }
}
