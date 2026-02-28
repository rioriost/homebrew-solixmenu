import Combine
import Foundation

@MainActor
final class SolixAppState: ObservableObject {
    struct Device: Identifiable, Equatable {
        let id: String
        var name: String
        var batteryPercent: Int?
        var outputWatts: Int?
        var inputWatts: Int?

        init(
            id: String,
            name: String,
            batteryPercent: Int? = nil,
            outputWatts: Int? = nil,
            inputWatts: Int? = nil
        ) {
            self.id = id
            self.name = name
            self.batteryPercent = batteryPercent
            self.outputWatts = outputWatts
            self.inputWatts = inputWatts
        }

        var percentText: String {
            guard let batteryPercent else { return "--" }
            return "\(batteryPercent)"
        }

        var outputText: String {
            let value = outputWatts.map(String.init) ?? "--"
            return "OUT: \(value) W"
        }

        var inputText: String {
            let value = inputWatts.map(String.init) ?? "--"
            return "IN: \(value) W"
        }

        var statusLine: String {
            "\(outputText) / \(inputText) / \(percentText) %"
        }
    }

    @Published private(set) var devices: [String: Device] = [:]
    @Published var isAuthenticated: Bool = false
    @Published var lastErrorMessage: String?

    var sortedDevices: [Device] {
        devices.values.sorted { lhs, rhs in
            if lhs.name == rhs.name { return lhs.id < rhs.id }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func updateDevice(
        id: String,
        name: String? = nil,
        batteryPercent: Int? = nil,
        outputWatts: Int? = nil,
        inputWatts: Int? = nil
    ) {
        var device = devices[id] ?? Device(id: id, name: name ?? id)
        if let name { device.name = name }
        if let batteryPercent { device.batteryPercent = batteryPercent }
        if let outputWatts { device.outputWatts = outputWatts }
        if let inputWatts { device.inputWatts = inputWatts }
        devices[id] = device
    }

    func removeDevice(id: String) {
        devices.removeValue(forKey: id)
    }

    func clearDevices() {
        devices.removeAll()
    }
}
