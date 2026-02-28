import Foundation

@main
struct TestTicket19CLI {
    static func main() async {
        let env = ProcessInfo.processInfo.environment

        let email = env["SOLIX_EMAIL"] ?? ""
        let password = env["SOLIX_PASSWORD"] ?? ""
        let country = env["SOLIX_COUNTRY"] ?? "US"
        let deviceSn = env["SOLIX_DEVICE_SN"]
        let tlsProbe = (env["SOLIX_TLS_PROBE"] ?? "") == "1"

        guard !email.isEmpty, !password.isEmpty else {
            print("Missing credentials. Set SOLIX_EMAIL and SOLIX_PASSWORD.")
            exit(1)
        }

        if tlsProbe {
            await TlsProbeRunner.run()
            return
        }

        await TestIntegrationRunner.run(
            .init(
                email: email,
                password: password,
                countryId: country,
                deviceSn: deviceSn
            )
        )
    }
}
