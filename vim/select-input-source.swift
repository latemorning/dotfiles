import Carbon
import Foundation

let defaultInputSourceID = "com.apple.keylayout.ABC"

func fail(_ message: String, code: Int32 = 1) -> Never {
    fputs("select-input-source: \(message)\n", stderr)
    exit(code)
}

func propertyString(_ source: TISInputSource, _ key: CFString) -> String? {
    guard let rawValue = TISGetInputSourceProperty(source, key) else {
        return nil
    }

    return Unmanaged<CFString>
        .fromOpaque(rawValue)
        .takeUnretainedValue() as String
}

func inputSources(matching inputSourceID: String) -> [TISInputSource] {
    let filter = [kTISPropertyInputSourceID as String: inputSourceID] as CFDictionary

    guard let sourceList = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
        return []
    }

    return sourceList
}

func currentInputSourceID() -> String {
    let currentSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
    return propertyString(currentSource, kTISPropertyInputSourceID) ?? ""
}

let arguments = Array(CommandLine.arguments.dropFirst())

if arguments.first == "--current" {
    print(currentInputSourceID())
    exit(0)
}

let inputSourceID = arguments.first ?? defaultInputSourceID

guard let inputSource = inputSources(matching: inputSourceID).first else {
    fail("input source not found: \(inputSourceID)", code: 2)
}

let status = TISSelectInputSource(inputSource)

if status != noErr {
    fail("failed to select input source \(inputSourceID): \(status)", code: 3)
}
