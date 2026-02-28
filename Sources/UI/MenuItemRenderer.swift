import Cocoa

@MainActor
struct MenuItemRenderer {
    struct Style {
        let nameFont: NSFont
        let valueFont: NSFont
        let nameColor: NSColor
        let valueColor: NSColor
        let outColor: NSColor
        let inColor: NSColor
        let lowPercentColor: NSColor

        @MainActor static let `default` = Style(
            nameFont: .systemFont(ofSize: 12, weight: .semibold),
            valueFont: .systemFont(ofSize: 11, weight: .regular),
            nameColor: .white,
            valueColor: .white,
            outColor: .systemRed,
            inColor: .systemGreen,
            lowPercentColor: .systemRed
        )
    }

    let style: Style

    init(style: Style = .default) {
        self.style = style
    }

    func attributedTitle(
        for device: SolixAppState.Device,
        status: NSAttributedString? = nil
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()

        result.append(
            NSAttributedString(
                string: device.name,
                attributes: [
                    .font: style.nameFont,
                    .foregroundColor: style.nameColor,
                ]
            )
        )

        result.append(
            NSAttributedString(
                string: "  ",
                attributes: [
                    .font: style.valueFont,
                    .foregroundColor: style.valueColor,
                ]
            )
        )


        result.append(attributedOutText(for: device))

        result.append(
            NSAttributedString(
                string: " / ",
                attributes: [
                    .font: style.valueFont,
                    .foregroundColor: style.valueColor,
                ]
            )
        )

        result.append(attributedInText(for: device))

        result.append(
            NSAttributedString(
                string: " / ",
                attributes: [
                    .font: style.valueFont,
                    .foregroundColor: style.valueColor,
                ]
            )
        )

        result.append(attributedPercentText(for: device))

        if let status {
            result.append(
                NSAttributedString(
                    string: " ",
                    attributes: [
                        .font: style.valueFont,
                        .foregroundColor: style.valueColor,
                    ]
                )
            )
            result.append(status)
        }

        return result
    }

    private func attributedOutText(for device: SolixAppState.Device) -> NSAttributedString {
        let value = device.outputWatts.map(String.init) ?? "--"
        return NSAttributedString(
            string: "OUT: \(value) W",
            attributes: [
                .font: style.valueFont,
                .foregroundColor: style.outColor,
            ]
        )
    }

    private func attributedInText(for device: SolixAppState.Device) -> NSAttributedString {
        let value = device.inputWatts.map(String.init) ?? "--"
        return NSAttributedString(
            string: "IN: \(value) W",
            attributes: [
                .font: style.valueFont,
                .foregroundColor: style.inColor,
            ]
        )
    }

    private func attributedPercentText(for device: SolixAppState.Device) -> NSAttributedString {
        let percentValue = device.batteryPercent
        let percentText = percentValue.map { String($0) } ?? "--"
        let color: NSColor = {
            guard let percentValue else { return style.valueColor }
            return percentValue < 10 ? style.lowPercentColor : style.valueColor
        }()
        let result = NSMutableAttributedString(
            string: percentText,
            attributes: [
                .font: style.valueFont,
                .foregroundColor: color,
            ]
        )
        result.append(
            NSAttributedString(
                string: " per",
                attributes: [
                    .font: style.valueFont,
                    .foregroundColor: color,
                ]
            )
        )
        return result
    }
}
