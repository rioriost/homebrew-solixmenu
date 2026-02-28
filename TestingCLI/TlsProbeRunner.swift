import CFNetwork
import Foundation
import Security

struct TlsProbeRunner {
    enum Mode: String {
        case apiCa = "api-ca"
        case systemCa = "system-ca"
    }

    static func run() async {
        let env = ProcessInfo.processInfo.environment
        let email = env["SOLIX_EMAIL"] ?? ""
        let password = env["SOLIX_PASSWORD"] ?? ""
        let country = env["SOLIX_COUNTRY"] ?? "EU"
        let mode = Mode(rawValue: env["SOLIX_TLS_MODE"] ?? "api-ca") ?? .apiCa
        let timeoutSeconds = TimeInterval(env["SOLIX_TLS_TIMEOUT"].flatMap { Double($0) } ?? 10)

        guard !email.isEmpty, !password.isEmpty else {
            print("Missing credentials. Set SOLIX_EMAIL and SOLIX_PASSWORD.")
            exit(1)
        }

        do {
            let config = ApiSessionConfiguration(logger: { print($0) })
            let api = try ApiSession(
                email: email, password: password, countryId: country, configuration: config)
            _ = try await api.authenticate()
            let mqttInfo = try await api.getMqttInfo()

            guard let host = mqttInfo["endpoint_addr"] as? String, !host.isEmpty else {
                print("Missing endpoint_addr in mqtt_info.")
                exit(2)
            }

            let caPem = mqttInfo["aws_root_ca1_pem"] as? String ?? ""
            let certPem = mqttInfo["certificate_pem"] as? String ?? ""
            let keyPem = mqttInfo["private_key"] as? String ?? ""
            let pkcs12Base64 = mqttInfo["pkcs12"] as? String ?? ""
            let pkcs12Passphrase = env["SOLIX_TLS_PKCS12_PASSPHRASE"] ?? ""

            print("TLS probe mode: \(mode.rawValue)")
            print("endpoint_addr: \(host)")
            print("CA PEM length: \(caPem.count)")
            print("Cert PEM length: \(certPem.count)")
            print("Key PEM length: \(keyPem.count)")

            guard !certPem.isEmpty, !keyPem.isEmpty else {
                print("Missing certificate_pem or private_key in mqtt_info.")
                exit(3)
            }

            var identity = importIdentityFromPEM(certPem: certPem, keyPem: keyPem)
            if identity == nil, !pkcs12Base64.isEmpty {
                if !pkcs12Passphrase.isEmpty {
                    print("TLS probe: using PKCS#12 passphrase (length \(pkcs12Passphrase.count)).")
                }
                identity = importIdentityFromPkcs12(
                    base64: pkcs12Base64,
                    passphrase: pkcs12Passphrase
                )
            }
            guard let identity else {
                print("Failed to build client identity from PEM/PKCS#12.")
                exit(4)
            }

            let certChain = pemCertificates(certPem)
            let caCert = mode == .apiCa ? pemCertificates(caPem).first : nil

            var sslSettings: [String: Any] = [
                kCFStreamSSLPeerName as String: host,
                kCFStreamSSLIsServer as String: kCFBooleanFalse as Any,
                kCFStreamSSLValidatesCertificateChain as String: kCFBooleanTrue as Any,
            ]

            var certs: [Any] = [identity]
            if !certChain.isEmpty {
                certs.append(contentsOf: certChain)
            }
            if let caCert {
                certs.append(caCert)
            }
            sslSettings[kCFStreamSSLCertificates as String] = certs

            let result = await tlsHandshake(
                host: host,
                port: 8883,
                sslSettings: sslSettings,
                timeout: timeoutSeconds
            )

            if result.success {
                print("TLS handshake success")
                print("Stream status: \(result.status)")
                if let peerSummaries = result.peerSummaries {
                    print("Server cert subjects:")
                    for summary in peerSummaries {
                        print("  - \(summary)")
                    }
                }
            } else {
                print("TLS handshake failed")
                if let error = result.error {
                    print("Error: \(error)")
                }
            }
        } catch {
            print("TLS probe failed: \(error)")
            exit(10)
        }
    }

    private static func tlsHandshake(
        host: String,
        port: Int,
        sslSettings: [String: Any],
        timeout: TimeInterval
    ) async -> (success: Bool, status: Stream.Status, error: String?, peerSummaries: [String]?) {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocketToHost(
            nil, host as CFString, UInt32(port), &readStream, &writeStream)

        guard
            let read = readStream?.takeRetainedValue(),
            let write = writeStream?.takeRetainedValue()
        else {
            return (false, .error, "Failed to create CFStreams.", nil)
        }

        let input = read as InputStream
        let output = write as OutputStream

        let settings = sslSettings as CFDictionary
        CFReadStreamSetProperty(read, CFStreamPropertyKey(kCFStreamPropertySSLSettings), settings)
        CFWriteStreamSetProperty(write, CFStreamPropertyKey(kCFStreamPropertySSLSettings), settings)

        input.open()
        output.open()

        let deadline = Date().addingTimeInterval(timeout)
        var success = false
        var lastError: String? = nil

        while Date() < deadline {
            try? await Task.sleep(nanoseconds: 100_000_000)

            let inStatus = input.streamStatus
            let outStatus = output.streamStatus

            if inStatus == .open || outStatus == .open {
                success = true
                break
            }
            if inStatus == .error || outStatus == .error {
                lastError =
                    input.streamError?.localizedDescription
                    ?? output.streamError?.localizedDescription
                break
            }
            if inStatus == .closed || outStatus == .closed {
                lastError = "Stream closed before open."
                break
            }
        }

        let peerSummaries: [String]? = nil
        input.close()
        output.close()

        let status = input.streamStatus
        return (success, status, lastError, peerSummaries)
    }

    private static func fetchPeerCertSummaries(readStream: CFReadStream) -> [String]? {
        _ = readStream
        return nil
    }

    private static func importIdentityFromPEM(certPem: String, keyPem: String) -> SecIdentity? {
        let combined = certPem + "\n" + keyPem
        if let data = combined.data(using: .utf8) {
            var items: CFArray?
            let status = SecItemImport(
                data as CFData,
                nil,
                nil,
                nil,
                SecItemImportExportFlags(),
                nil,
                nil,
                &items
            )
            if status == errSecSuccess, let array = items as? [Any] {
                for item in array {
                    let cfItem = item as CFTypeRef
                    if CFGetTypeID(cfItem) == SecIdentityGetTypeID() {
                        return (item as! SecIdentity)
                    }
                }
            }
        }

        guard let keyData = pemData(keyPem) else { return nil }
        let certChain = pemCertificates(certPem)
        guard
            let certificate =
                certChain.first
                ?? pemData(certPem).flatMap({ SecCertificateCreateWithData(nil, $0 as CFData) })
        else { return nil }
        guard let privateKey = secKeyFromPrivateKeyData(keyData) else { return nil }

        if let tag = "solix.tlsprobe.\(UUID().uuidString)".data(using: .utf8) {
            _ = addKeychainItem(value: privateKey, itemClass: kSecClassKey, tag: tag)
            _ = addKeychainItem(value: certificate, itemClass: kSecClassCertificate, tag: tag)
        }

        var identity: SecIdentity?
        let status = SecIdentityCreateWithCertificate(nil, certificate, &identity)
        if status == errSecSuccess, let identity {
            return identity
        }
        return nil
    }

    private static func pemData(_ pem: String) -> Data? {
        let lines =
            pem
            .components(separatedBy: .newlines)
            .filter {
                !$0.hasPrefix("-----")
                    && !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        let base64 = lines.joined()
        return Data(base64Encoded: base64)
    }

    private static func secKeyFromPrivateKeyData(_ data: Data) -> SecKey? {
        let candidates: [(CFString, Int)] = [
            (kSecAttrKeyTypeRSA, 2048),
            (kSecAttrKeyTypeRSA, 4096),
            (kSecAttrKeyTypeECSECPrimeRandom, 256),
            (kSecAttrKeyTypeECSECPrimeRandom, 384),
        ]

        for (type, size) in candidates {
            let attributes: [String: Any] = [
                kSecAttrKeyType as String: type,
                kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
                kSecAttrKeySizeInBits as String: size,
            ]
            if let key = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, nil) {
                return key
            }
        }
        return nil
    }

    private static func addKeychainItem(
        value: CFTypeRef,
        itemClass: CFString,
        tag: Data
    ) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: itemClass,
            kSecAttrApplicationTag as String: tag,
            kSecValueRef as String: value,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private static func importIdentityFromPkcs12(
        base64: String,
        passphrase: String = ""
    ) -> SecIdentity? {
        let trimmed = base64.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("TLS probe: PKCS#12 payload empty.")
            return nil
        }
        guard let data = Data(base64Encoded: trimmed, options: [.ignoreUnknownCharacters]) else {
            print("TLS probe: PKCS#12 base64 decode failed.")
            return nil
        }
        guard !data.isEmpty else {
            print("TLS probe: PKCS#12 decoded data empty.")
            return nil
        }

        let options = [kSecImportExportPassphrase as String: passphrase] as CFDictionary
        var items: CFArray?
        let status = SecPKCS12Import(data as CFData, options, &items)
        if status != errSecSuccess {
            let message = SecCopyErrorMessageString(status, nil) as String? ?? "unknown"
            print("TLS probe: PKCS#12 import failed (status \(status)) \(message)")
            return nil
        }
        guard let array = items as? [[String: Any]] else {
            print("TLS probe: PKCS#12 import returned no items.")
            return nil
        }

        for item in array {
            if let identity = item[kSecImportItemIdentity as String] {
                return (identity as! SecIdentity)
            }
        }
        print("TLS probe: PKCS#12 import returned no identity.")
        return nil
    }

    private static func pemCertificates(_ pem: String) -> [SecCertificate] {
        let begin = "-----BEGIN CERTIFICATE-----"
        let end = "-----END CERTIFICATE-----"
        var certs: [SecCertificate] = []
        var remainder = pem

        while let beginRange = remainder.range(of: begin) {
            remainder = String(remainder[beginRange.upperBound...])
            guard let endRange = remainder.range(of: end) else { break }

            let body = String(remainder[..<endRange.lowerBound])
            let base64 =
                body
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined()

            if let data = Data(base64Encoded: base64),
                let cert = SecCertificateCreateWithData(nil, data as CFData)
            {
                certs.append(cert)
            }
            remainder = String(remainder[endRange.upperBound...])
        }
        return certs
    }
}
