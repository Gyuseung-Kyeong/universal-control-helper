import Foundation

func runIntegratedChecks() {
    var permissionQueries = 0
    let swap = TargetModifierSwap(hasPermission: { permissionQueries += 1; return false })
    for role: ComputerRole in [.source, .target] {
        for enabled in [false, true] {
            for requested in [false, true] {
                let before = permissionQueries
                swap.configure(requested: requested, role: role, helperEnabled: enabled)
                let shouldTry = role == .target && enabled && requested
                require(permissionQueries - before == (shouldTry ? 1 : 0), "permission check must be Target-only")
                require(!swap.isRunning, "no permission must mean no tap")
                if shouldTry { require(swap.state == .permissionRequired, "permission feedback") }
                if role == .source { require(swap.state == .source, "Source must remain unchanged") }
                if role == .target && !enabled { require(swap.state == .helperDisabled, "global off wins") }
            }
        }
    }
    swap.stop()
    require(swap.state == .off && !swap.isRunning, "stop must clear state")

    let suite = "com.gyuseungkyeong.ModifierChecks." + UUID().uuidString
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let prefs = Preferences(defaults: defaults)
    require(!prefs.modifierSwapEnabled, "new install must default to swap off")
    prefs.modifierSwapEnabled = true
    require(Preferences(defaults: defaults).modifierSwapEnabled, "explicit preference persists")
    prefs.modifierSwapEnabled = false
    require(!Preferences(defaults: defaults).modifierSwapEnabled, "emergency off can persist")

    let model = SettingsViewModel()
    var changed: Bool?
    var refreshed = false
    model.modifierSwapDidChange = { changed = $0 }
    model.modifierPermissionRefreshRequested = { refreshed = true }
    model.setModifierSwapEnabled(true)
    require(changed == true && model.modifierSwapEnabled, "toggle reaches controller")
    model.refreshModifierPermission()
    require(refreshed, "refresh reaches controller")
    var snapshot = SettingsSnapshot(role: .target, pairingCode: "123456", connectionStatus: "대기 중",
                                    inputMonitoringReady: true, helperEnabled: true,
                                    currentVersion: "1.5.4", canCheckForUpdates: false,
                                    launchAtLoginState: .disabled,
                                    modifierSwapEnabled: false, modifierSwapStatus: "긴급 중지됨")
    model.editPairingCode("654")
    model.update(snapshot: snapshot)
    require(!model.modifierSwapEnabled && model.modifierSwapStatus == "긴급 중지됨", "actual state replaces pending UI")
    require(model.pairingCode == "654", "swap refresh must preserve unsaved pairing code")
    snapshot.modifierSwapEnabled = true
    snapshot.modifierSwapStatus = "교환 중"
    model.update(snapshot: snapshot)
    require(model.modifierSwapEnabled && model.modifierSwapStatus == "교환 중", "active state rendered")
    print("PASS: Target-only gates (8 combinations), permission denial, default off, persistence, UI callbacks and pairing edit preservation")
}

private func require(_ condition: Bool, _ message: String) {
    guard condition else { fatalError(message) }
}
