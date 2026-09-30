import CoreGraphics
import Foundation

private let reconfigurationCallback: CGDisplayReconfigurationCallBack = { _, flags, userInfo in
    guard let userInfo, !flags.contains(.beginConfigurationFlag) else { return }
    let relevant: CGDisplayChangeSummaryFlags = [.addFlag, .removeFlag, .enabledFlag, .disabledFlag]
    guard !flags.intersection(relevant).isEmpty else { return }
    Unmanaged<DisplayWatcher>.fromOpaque(userInfo).takeUnretainedValue().scheduleChange()
}

/// Notifies (debounced) when displays are connected, disconnected, enabled or disabled.
final class DisplayWatcher {
    private let onChange: () -> Void
    private var pending: DispatchWorkItem?

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        CGDisplayRegisterReconfigurationCallback(reconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
    }

    // macOS sends a burst of callbacks and restores its own layout first; act once things settle.
    fileprivate func scheduleChange() {
        pending?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.onChange() }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: work)
    }

    deinit {
        CGDisplayRemoveReconfigurationCallback(reconfigurationCallback, Unmanaged.passUnretained(self).toOpaque())
    }
}
