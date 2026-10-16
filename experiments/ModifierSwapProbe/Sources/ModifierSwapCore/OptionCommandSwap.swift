import CoreGraphics

public enum OptionCommandSwap {
    public static func flags(_ original: CGEventFlags) -> CGEventFlags {
        // Device-dependent masks from IOKit/hidsystem/IOLLEvent.h.
        let pairs: [(UInt64, UInt64)] = [
            (CGEventFlags.maskAlternate.rawValue, CGEventFlags.maskCommand.rawValue),
            (0x20, 0x08), // NX_DEVICELALTKEYMASK, NX_DEVICELCMDKEYMASK
            (0x40, 0x10), // NX_DEVICERALTKEYMASK, NX_DEVICERCMDKEYMASK
        ]
        var result = original.rawValue
        for (option, command) in pairs {
            result &= ~(option | command)
            if original.rawValue & option != 0 { result |= command }
            if original.rawValue & command != 0 { result |= option }
        }
        return CGEventFlags(rawValue: result)
    }

    public static func modifierKeyCode(_ original: Int64) -> Int64 {
        switch original {
        case 58: return 55 // Left Option -> Left Command
        case 55: return 58
        case 61: return 54 // Right Option -> Right Command
        case 54: return 61
        default: return original
        }
    }

    @discardableResult
    public static func apply(to event: CGEvent, type: CGEventType) -> Bool {
        let oldFlags = event.flags
        event.flags = flags(oldFlags)
        var changed = event.flags != oldFlags
        if type == .flagsChanged {
            let oldCode = event.getIntegerValueField(.keyboardEventKeycode)
            let newCode = modifierKeyCode(oldCode)
            event.setIntegerValueField(.keyboardEventKeycode, value: newCode)
            changed = changed || oldCode != newCode
        }
        return changed
    }
}
