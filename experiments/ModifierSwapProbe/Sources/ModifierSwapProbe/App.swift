import AppKit
import ApplicationServices
#if SWIFT_PACKAGE
import ModifierSwapCore
#endif

// This experiment has no network, persistence, updater or event-content logging.
// Every tap and callback runs on the main run loop.
final class Probe: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var timer: Timer?
    private var deadline: TimeInterval = 0
    private var swapping = false
    private var keyDownCount = 0
    private var modifierCount = 0
    private var changedCount = 0
    private let state = NSTextField(wrappingLabelWithString: "대기 중. 입력 감지와 교환 모두 꺼져 있습니다.")
    private let counts = NSTextField(labelWithString: "키 누름 0 / modifier 변화 0 / 변환 이벤트 0")
    private let permissions = NSTextField(wrappingLabelWithString: "")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        let menu = NSMenu()
        let appItem = NSMenuItem()
        menu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = menu

        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 460),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "Option / Command 교환 테스트"
        window.isReleasedWhenClosed = false
        let title = NSTextField(labelWithString: "대상 Mac에서만 실행하세요")
        title.font = .boldSystemFont(ofSize: 21)
        let explanation = NSTextField(wrappingLabelWithString:
            "Universal Control 입력을 이 Mac에서 바꿀 수 있는지 확인하는 실험입니다.\n" +
            "현재는 입력 출처를 구별하지 않으므로 이 Mac의 자체 키보드에도 적용될 수 있습니다.\n" +
            "일반 입력 내용은 저장하거나 전송하지 않습니다. 숫자는 이벤트 개수입니다.")
        let instructions = NSTextField(wrappingLabelWithString:
            "1. 감지 테스트를 켜고 Source에서 커서를 이 Mac으로 옮겨 입력합니다.\n" +
            "2. 숫자가 증가하면 교환 테스트를 켜고 TextEdit 등에서 단축키를 확인합니다.\n" +
            "3. 시작과 종료 전에는 Option과 Command에서 손을 떼세요.\n" +
            "60초 뒤 자동 종료됩니다. 즉시 중지: Control + Shift + Escape.")
        let buttons = NSStackView(views: [
            button("입력 감지 테스트 (60초)", #selector(observe)),
            button("Option ↔ Command 교환 (60초)", #selector(swap)),
        ])
        buttons.orientation = .horizontal
        buttons.spacing = 12
        let stopButtons = NSStackView(views: [
            button("즉시 중지", #selector(stopPressed)),
            button("앱 종료", #selector(quit)),
        ])
        stopButtons.orientation = .horizontal
        stopButtons.spacing = 12
        state.font = .boldSystemFont(ofSize: 14)
        counts.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        permissions.font = .systemFont(ofSize: 12)
        let stack = NSStackView(views: [title, explanation, instructions, buttons, stopButtons, state, counts, permissions])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 17
        stack.translatesAutoresizingMaskIntoConstraints = false
        window.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: window.contentView!.topAnchor, constant: 24),
        ])
        refreshPermissions()
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func button(_ title: String, _ action: Selector) -> NSButton {
        NSButton(title: title, target: self, action: action)
    }

    @objc private func observe() { start(swap: false) }
    @objc private func swap() { start(swap: true) }
    @objc private func stopPressed() { stop("중지됨. 모든 modifier 키에서 손을 떼세요.") }
    @objc private func quit() { NSApp.terminate(nil) }

    private func refreshPermissions() {
        permissions.stringValue = "입력 감지 권한: \(CGPreflightListenEventAccess() ? "허용" : "미허용") / 접근성: \(AXIsProcessTrusted() ? "허용" : "미허용")"
    }

    private func start(swap: Bool) {
        stop("준비 중")
        if swap && !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            state.stringValue = "시스템 설정에서 이 테스트 앱의 접근성을 허용한 뒤 다시 눌러주세요."
            refreshPermissions()
            return
        }
        if !swap && !CGPreflightListenEventAccess() && !AXIsProcessTrusted() {
            _ = CGRequestListenEventAccess()
            state.stringValue = "입력 모니터링을 허용한 뒤 앱을 다시 열고 감지 테스트를 눌러주세요."
            refreshPermissions()
            return
        }
        let held = CGEventSource.flagsState(.combinedSessionState)
        if !held.intersection([.maskAlternate, .maskCommand]).isEmpty {
            state.stringValue = "Option과 Command에서 손을 뗀 뒤 다시 눌러주세요."
            return
        }
        let types: [CGEventType] = [
            .keyDown, .keyUp, .flagsChanged, .leftMouseDown, .leftMouseUp,
            .rightMouseDown, .rightMouseUp, .otherMouseDown, .otherMouseUp,
            .leftMouseDragged, .rightMouseDragged, .otherMouseDragged, .mouseMoved, .scrollWheel,
        ]
        let mask = types.reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
        swapping = swap
        guard let newTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: swap ? .defaultTap : .listenOnly, eventsOfInterest: mask,
            callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                let probe = Unmanaged<Probe>.fromOpaque(context).takeUnretainedValue()
                return probe.receive(type, event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            state.stringValue = "이벤트 처리기를 만들지 못했습니다. 권한과 앱 재실행 여부를 확인하세요."
            refreshPermissions()
            return
        }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, newTap, 0) else {
            CFMachPortInvalidate(newTap)
            state.stringValue = "이벤트 처리기 초기화 실패. 테스트를 시작하지 않았습니다."
            return
        }
        tap = newTap
        runLoopSource = source
        keyDownCount = 0
        modifierCount = 0
        changedCount = 0
        deadline = ProcessInfo.processInfo.systemUptime + 60
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: newTap, enable: true)
        timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(timer!, forMode: .common)
        refreshPermissions()
        tick()
    }

    private func receive(_ type: CGEventType, _ event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            stop("macOS가 이벤트 처리를 중단했습니다. 자동 재시도하지 않습니다.")
            return Unmanaged.passUnretained(event)
        }
        // Check the deadline in the input path as well as the UI timer.
        if ProcessInfo.processInfo.systemUptime >= deadline {
            stop("60초 테스트가 끝났습니다. 모든 modifier 키에서 손을 떼세요.")
            return Unmanaged.passUnretained(event)
        }
        if type == .keyDown {
            keyDownCount += 1
            if event.getIntegerValueField(.keyboardEventKeycode) == 53,
               event.flags.contains([.maskControl, .maskShift]) {
                let wasSwapping = swapping
                stop("긴급 중지됨. 모든 modifier 키에서 손을 떼세요.")
                return wasSwapping ? nil : Unmanaged.passUnretained(event)
            }
        }
        if type == .flagsChanged { modifierCount += 1 }
        if swapping && OptionCommandSwap.apply(to: event, type: type) { changedCount += 1 }
        return Unmanaged.passUnretained(event)
    }

    private func tick() {
        let remaining = max(0, Int(ceil(deadline - ProcessInfo.processInfo.systemUptime)))
        updateCounts()
        if remaining == 0 {
            stop("60초 테스트가 끝났습니다. 모든 modifier 키에서 손을 떼세요.")
        } else {
            state.stringValue = "\(swapping ? "교환 켜짐" : "감지만 켜짐, 입력 변경 없음") / \(remaining)초 남음"
        }
    }

    private func updateCounts() {
        counts.stringValue = "키 누름 \(keyDownCount) / modifier 변화 \(modifierCount) / 변환 이벤트 \(changedCount)"
    }

    private func stop(_ reason: String) {
        timer?.invalidate()
        timer = nil
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CFRunLoopSourceInvalidate(runLoopSource)
        }
        tap = nil
        runLoopSource = nil
        swapping = false
        updateCounts()
        state.stringValue = reason
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationWillTerminate(_ notification: Notification) { stop("종료") }
}

@main
enum Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = Probe()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
