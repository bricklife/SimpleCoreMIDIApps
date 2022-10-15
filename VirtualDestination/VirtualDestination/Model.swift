//
//  Model.swift
//  VirtualDestination
//
//  Created by Shinichiro Oba on 2022/10/15.
//

import Foundation
import CoreMIDI

struct LogItem: Identifiable {
    let id = UUID()
    let date: Date
    let timeStamp: MIDITimeStamp
    let text: String
}

@MainActor
class Model: ObservableObject {
    @Published var logItems: [LogItem] = []
    
    private var clientRef = MIDIClientRef()
    
    private var destinationRef = MIDIEndpointRef()
    private var umpDestinationRef = MIDIEndpointRef()
    
    init() {
        MIDIClientCreate("VirtualDestination - Cient" as CFString, nil, nil, &clientRef)
        
        MIDIDestinationCreateWithBlock(clientRef, "VirtualDestination - Deprecated API" as CFString, &destinationRef) { [weak self] pktList, srcConnRefCon in
            for packet in pktList.unsafeSequence() {
                let text = packet.bytes().map({ String(format: "%02x", $0) }).joined(separator: " ")
                Task { @MainActor in
                    self?.logItems.append(.init(date: Date(), timeStamp: packet.pointee.timeStamp, text: text))
                }
            }
        }
        
        MIDIDestinationCreateWithProtocol(clientRef, "VirtualDestination - UMP MIDI 1.0" as CFString, ._1_0, &umpDestinationRef) { [weak self]  evtlist, srcConnRefCon in
            for packet in evtlist.unsafeSequence() {
                let text = packet.words().map({ String(format: "%08x", $0) }).joined(separator: " ")
                Task { @MainActor in
                    self?.logItems.append(.init(date: Date(), timeStamp: packet.pointee.timeStamp, text: text))
                }
            }
        }
    }
    
    deinit {
        MIDIEndpointDispose(destinationRef)
        MIDIEndpointDispose(umpDestinationRef)
    }
}
