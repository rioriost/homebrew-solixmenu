import Cocoa

@main
@MainActor
final class SolixMenuApp: NSObject, NSApplicationDelegate {
    private let coordinator = SolixAppCoordinator()
    private var statusBarController: StatusBarController?
    private var accountSettingsWindow: AccountSettingsWindowController?
    private let terminationReason = "SolixMenu status item"

    static func main() {
        let app = NSApplication.shared
        let delegate = SolixMenuApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination(terminationReason)
        NSLog("SolixMenu: configuring status bar controller.")
        statusBarController = StatusBarController(appState: coordinator.appState)
        NSLog("SolixMenu: status bar controller configured: \(statusBarController != nil).")
        statusBarController?.onAccountSettings = { [weak self] in
            self?.showAccountSettings()
        }
        statusBarController?.onAbout = { [weak self] in
            self?.showAbout()
        }
        statusBarController?.onQuit = {
            NSApp.terminate(nil)
        }
        Task { await coordinator.start() }
    }


    private func showAccountSettings() {
        let credentials = CredentialStore.shared.load()
        let window = AccountSettingsWindowController(
            credentials: credentials,
            onVerify: { [weak self] credentials in
                guard let self else {
                    return .failure(ApiSessionError.authenticationFailed)
                }
                let result = await self.coordinator.applySettings(credentials)
                if case .success = result {
                    self.accountSettingsWindow = nil
                }
                return result
            },
            onCancel: { [weak self] in
                self?.accountSettingsWindow = nil
            }
        )
        accountSettingsWindow = window
        window.present()
    }

    private func showAbout() {
        AboutWindowController.shared.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        ProcessInfo.processInfo.enableAutomaticTermination(terminationReason)
        coordinator.stop()
    }
}
