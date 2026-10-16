import ApplicationServices
import Foundation
import UniversalControlCore

/// Changes events locally on Target; never sends key events over the relay.
/// It also affects Target's own keyboards. Input origin is not distinguishable here.
final class TargetModifierSwap {
    enum State: String {
        case off = "꺼짐"
        case source = "Source에서는 키를 바꾸지 않습니다."
        case helperDisabled = "전체 기능이 꺼져 있습니다."
        case permissionRequired = "접근성을 허용한 뒤 권한 다시 확인을 누르세요."
        case held = "Option과 Command에서 손을 뗀 뒤 권한 다시 확인을 누르세요."
        case failed = "키 교환을 시작하지 못했습니다. 권한과 앱 재실행 여부를 확인하세요."
        case active = "Option ↔ Command 교환 중"
        case emergency = "긴급 중지됨. 모든 modifier 키에서 손을 떼세요."
        case systemDisabled = "macOS가 키 교환을 중단했습니다. 스위치를 다시 켜면 재시도합니다."
    }

    private(set) var state: State = .off
    var stopped: (() -> Void)?
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private let hasPermission: () -> Bool
    var isRunning: Bool { tap != nil }

    init(hasPermission: @escaping () -> Bool = { AXIsProcessTrusted() }) {
        self.hasPermission = hasPermission
    }

    // Called on the main run loop, including permission refresh and role changes.
    func configure(requested: Bool, role: ComputerRole, helperEnabled: Bool) {
        stop()
        guard role == .target else { state = .source; return }
        guard helperEnabled else { state = .helperDisabled; return }
        guard requested else { return }
        guard hasPermission() else { state = .permissionRequired; return }
        guard CGEventSource.flagsState(.combinedSessionState)
            .intersection([.maskAlternate, .maskCommand]).isEmpty else {
            state = .held
            return
        }
        let events: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged, .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp,
            .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .mouseMoved, .scrollWheel,
        ]
        let mask = events.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                return Unmanaged<TargetModifierSwap>.fromOpaque(context)
                    .takeUnretainedValue().receive(type, event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { state = .failed; return }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            state = .failed
            return
        }
        self.tap = tap
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        state = .active
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            CFRunLoopSourceInvalidate(source)
        }
        tap = nil
        source = nil
        state = .off
    }

    private func receive(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            stop()
            state = .systemDisabled
            DispatchQueue.main.async { [weak self] in self?.stopped?() }
            return Unmanaged.passUnretained(event)
        }
        if type == .keyDown, event.getIntegerValueField(.keyboardEventKeycode) == 53,
           event.flags.contains([.maskControl, .maskShift]) {
            stop()
            state = .emergency
            DispatchQueue.main.async { [weak self] in self?.stopped?() }
            return nil
        }
        OptionCommandSwap.apply(to: event, type: type)
        return Unmanaged.passUnretained(event)
    }

    deinit { stop() }
}
