import CoreGraphics
import ModifierSwapCore

struct OptionCommandSwapChecks {
    func testLeftAndRightFlagsPreserveOtherModifiers() {
        let shiftControl = CGEventFlags([.maskShift, .maskControl, .maskAlphaShift, .maskSecondaryFn]).rawValue
        let cases: [(UInt64, UInt64)] = [
            (0x80020, 0x100008), (0x80040, 0x100010),
            (0x100008, 0x80020), (0x100010, 0x80040),
            (0x180028, 0x180028), (0x180030, 0x180048),
        ]
        for (input, expected) in cases {
            expectEqual(OptionCommandSwap.flags(CGEventFlags(rawValue: input | shiftControl)).rawValue,
                           expected | shiftControl)
        }
    }

    func testEveryModifierBitCombinationRoundTrips() {
        let bits: [UInt64] = [0x80000, 0x100000, 0x20, 0x08, 0x40, 0x10]
        for selection in 0..<64 {
            let raw = bits.enumerated().reduce(UInt64(0x20000)) {
                $0 | ((selection & (1 << $1.offset)) != 0 ? $1.element : 0)
            }
            let original = CGEventFlags(rawValue: raw)
            expectEqual(OptionCommandSwap.flags(OptionCommandSwap.flags(original)), original)
        }
    }

    func testPressAndReleaseCodesStayPaired() {
        for (original, expected): (Int64, Int64) in [(58, 55), (55, 58), (61, 54), (54, 61)] {
            for flags: CGEventFlags in [.maskAlternate, .maskCommand, []] {
                let event = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(original), keyDown: true)!
                event.type = .flagsChanged
                event.flags = flags
                expectTrue(OptionCommandSwap.apply(to: event, type: .flagsChanged))
                expectEqual(event.getIntegerValueField(.keyboardEventKeycode), expected)
                expectEqual(event.flags, OptionCommandSwap.flags(flags))
            }
        }
    }

    func testLetterKeyDownAndUpKeepKeyCodeWhileChangingFlags() {
        for type: CGEventType in [.keyDown, .keyUp] {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: 8, keyDown: type == .keyDown)!
            event.flags = [.maskAlternate, .maskShift]
            expectTrue(OptionCommandSwap.apply(to: event, type: type))
            expectEqual(event.getIntegerValueField(.keyboardEventKeycode), 8)
            expectEqual(event.flags, [.maskCommand, .maskShift])
        }
    }

    func testUnmodifiedInputAndEmergencyChordArePreserved() {
        for flags: CGEventFlags in [[], [.maskControl, .maskShift]] {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: true)!
            event.flags = flags
            expectFalse(OptionCommandSwap.apply(to: event, type: .keyDown))
            expectEqual(event.flags, flags)
            expectEqual(event.getIntegerValueField(.keyboardEventKeycode), 53)
        }
    }

    func testMouseModifierFlagsAreAlsoSwapped() {
        let event = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                            mouseCursorPosition: CGPoint(x: 10, y: 20), mouseButton: .left)!
        event.flags = .maskAlternate
        expectTrue(OptionCommandSwap.apply(to: event, type: .leftMouseDown))
        expectEqual(event.flags, .maskCommand)
        expectEqual(event.location, CGPoint(x: 10, y: 20))
    }
}

private func expectEqual<T: Equatable>(_ actual: T, _ expected: T, line: UInt = #line) {
    guard actual == expected else { fatalError("Line \(line): \(actual) != \(expected)") }
}
private func expectTrue(_ value: Bool, line: UInt = #line) {
    guard value else { fatalError("Line \(line): expected true") }
}
private func expectFalse(_ value: Bool, line: UInt = #line) {
    guard !value else { fatalError("Line \(line): expected false") }
}

@main
struct RunChecks {
    static func main() {
        let checks = OptionCommandSwapChecks()
        checks.testLeftAndRightFlagsPreserveOtherModifiers()
        checks.testEveryModifierBitCombinationRoundTrips()
        checks.testPressAndReleaseCodesStayPaired()
        checks.testLetterKeyDownAndUpKeepKeyCodeWhileChangingFlags()
        checks.testUnmodifiedInputAndEmergencyChordArePreserved()
        checks.testMouseModifierFlagsAreAlsoSwapped()
        print("PASS: 6 modifier swap checks, including 64 flag combinations")
    }
}
