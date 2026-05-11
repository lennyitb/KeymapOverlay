import Foundation
import IOKit
import IOKit.hid
import os.log

private let log = Logger(subsystem: "lenny.KeymapOverlay", category: "HID")

@Observable
final class HIDKeyboardMonitor {
    var keyboardState = KeyboardHIDState()
    var isDeviceConnected = false
    var onStateChange: ((KeyboardHIDState) -> Void)?

    private var manager: IOHIDManager?
    private let reportBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 64)

    func start() {
        let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))

        let matchingDict: [String: Any] = [
            kIOHIDDeviceUsagePageKey as String: 0xFF42
        ]
        IOHIDManagerSetDeviceMatching(mgr, matchingDict as CFDictionary)

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        IOHIDManagerRegisterDeviceMatchingCallback(mgr, hidDeviceConnected, selfPtr)
        IOHIDManagerRegisterDeviceRemovalCallback(mgr, hidDeviceRemoved, selfPtr)

        IOHIDManagerScheduleWithRunLoop(mgr, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let result = IOHIDManagerOpen(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            log.error("IOHIDManagerOpen failed: \(result)")
            return
        }

        self.manager = mgr
        log.info("HID monitor started")
    }

    func stop() {
        guard let mgr = manager else { return }
        IOHIDManagerClose(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerUnscheduleFromRunLoop(mgr, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        manager = nil
        isDeviceConnected = false
        keyboardState = KeyboardHIDState()
    }

    fileprivate func handleDeviceConnected(_ device: IOHIDDevice) {
        isDeviceConnected = true
        log.info("HID device connected")

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(
            device,
            reportBuffer,
            64,
            hidInputReport,
            selfPtr
        )
    }

    fileprivate func handleDeviceRemoved(_ device: IOHIDDevice) {
        log.info("HID device removed")
        isDeviceConnected = false
        keyboardState = KeyboardHIDState()
        onStateChange?(keyboardState)
    }

    fileprivate func handleInputReport(reportID: UInt32, report: UnsafeMutablePointer<UInt8>, length: Int) {
        let bytes = (0..<min(length, 8)).map { String(format: "%02x", report[$0]) }.joined(separator: " ")
        log.info("HID report: id=\(reportID) len=\(length) bytes=[\(bytes)]")

        guard reportID == 0x20 else { return }

        // IOKit includes the report ID as byte 0 of the buffer
        let offset: Int
        if length >= 5 {
            offset = 1
        } else if length >= 4 {
            offset = 0
        } else {
            return
        }

        let layerState = UInt16(report[offset]) | (UInt16(report[offset + 1]) << 8)
        let modifiers = report[offset + 2]
        let modFlags = report[offset + 3]

        let newState = KeyboardHIDState(
            layerState: layerState,
            modifiers: modifiers,
            modFlags: modFlags
        )
        guard newState != keyboardState else { return }
        keyboardState = newState
        log.info("State: layers=0x\(String(layerState, radix: 16)) mods=0x\(String(modifiers, radix: 16)) nonBase=\(newState.isNonBaseLayerActive)")
        onStateChange?(newState)
    }

    deinit {
        stop()
        reportBuffer.deallocate()
    }
}

private func hidDeviceConnected(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    device: IOHIDDevice
) {
    guard let context else { return }
    let monitor = Unmanaged<HIDKeyboardMonitor>.fromOpaque(context).takeUnretainedValue()
    MainActor.assumeIsolated {
        monitor.handleDeviceConnected(device)
    }
}

private func hidDeviceRemoved(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    device: IOHIDDevice
) {
    guard let context else { return }
    let monitor = Unmanaged<HIDKeyboardMonitor>.fromOpaque(context).takeUnretainedValue()
    MainActor.assumeIsolated {
        monitor.handleDeviceRemoved(device)
    }
}

private func hidInputReport(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    type: IOHIDReportType,
    reportID: UInt32,
    report: UnsafeMutablePointer<UInt8>,
    reportLength: CFIndex
) {
    guard let context else { return }
    let monitor = Unmanaged<HIDKeyboardMonitor>.fromOpaque(context).takeUnretainedValue()
    MainActor.assumeIsolated {
        monitor.handleInputReport(reportID: reportID, report: report, length: reportLength)
    }
}
