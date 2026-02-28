import Cocoa

@MainActor
final class ChargeDischargeAnimator {
    enum Mode {
        case idle
        case charging
        case discharging
    }

    @MainActor
    struct Style {
        let segmentCount: Int
        let segmentCharacter: String
        let inactiveColor: NSColor
        let chargingColor: NSColor
        let dischargingColor: NSColor
        let textColor: NSColor
        let font: NSFont
        let spacing: String

        @MainActor static let `default` = Style(
            segmentCount: 5,
            segmentCharacter: "▮",
            inactiveColor: .tertiaryLabelColor,
            chargingColor: .systemGreen,
            dischargingColor: .systemBlue,
            textColor: .secondaryLabelColor,
            font: .monospacedDigitSystemFont(ofSize: 11, weight: .regular),
            spacing: " "
        )
    }

    private let style: Style
    private let interval: TimeInterval
    private var timer: Timer?
    private var stepIndex: Int = 0

    private var mode: Mode = .idle
    private var percentText: String = "--%"
    private var flowText: String = "—"

    var onFrame: ((NSAttributedString) -> Void)?

    init(style: Style = .default, interval: TimeInterval = 0.5) {
        self.style = style
        self.interval = interval
    }

    func update(percent: Int?, isCharging: Bool?) {
        if let percent {
            percentText = "\(percent)%"
        } else {
            percentText = "--%"
        }

        if let isCharging {
            mode = isCharging ? .charging : .discharging
            flowText = isCharging ? "IN" : "OUT"
            startIfNeeded()
        } else {
            mode = .idle
            flowText = "—"
            stop()
        }

        emitFrame()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        stepIndex = 0
    }

    private func startIfNeeded() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.step()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    private func step() {
        stepIndex = (stepIndex + 1) % style.segmentCount
        emitFrame()
    }

    private func emitFrame() {
        onFrame?(renderFrame())
    }

    private func renderFrame() -> NSAttributedString {
        let result = NSMutableAttributedString()
        let segmentCount = style.segmentCount
        let activeIndex = activeSegmentIndex(count: segmentCount)

        for idx in 0..<segmentCount {
            let color = segmentColor(index: idx, activeIndex: activeIndex)
            let segment = NSAttributedString(
                string: style.segmentCharacter,
                attributes: [
                    .font: style.font,
                    .foregroundColor: color,
                ]
            )
            result.append(segment)
        }

        result.append(
            NSAttributedString(
                string: style.spacing,
                attributes: [
                    .font: style.font,
                    .foregroundColor: style.textColor,
                ]
            )
        )

        result.append(
            NSAttributedString(
                string: percentText,
                attributes: [
                    .font: style.font,
                    .foregroundColor: style.textColor,
                ]
            )
        )

        result.append(
            NSAttributedString(
                string: style.spacing,
                attributes: [
                    .font: style.font,
                    .foregroundColor: style.textColor,
                ]
            )
        )

        result.append(
            NSAttributedString(
                string: flowText,
                attributes: [
                    .font: style.font,
                    .foregroundColor: style.textColor,
                ]
            )
        )

        return result
    }

    private func activeSegmentIndex(count: Int) -> Int? {
        switch mode {
        case .idle:
            return nil
        case .charging:
            return stepIndex % count
        case .discharging:
            return (count - 1 - (stepIndex % count))
        }
    }

    private func segmentColor(index: Int, activeIndex: Int?) -> NSColor {
        guard let activeIndex else {
            return style.inactiveColor
        }

        switch mode {
        case .charging:
            return index == activeIndex ? style.chargingColor : style.inactiveColor
        case .discharging:
            return index == activeIndex ? style.dischargingColor : style.inactiveColor
        case .idle:
            return style.inactiveColor
        }
    }
}
