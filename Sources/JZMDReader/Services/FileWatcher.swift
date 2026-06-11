import Darwin
import Foundation

/// Watches a file path for changes. Survives atomic saves (write-to-temp +
/// rename) by re-opening the path when the watched inode is renamed or
/// deleted, and coalesces event bursts into a single callback.
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var pendingNotify: DispatchWorkItem?
    private var stopped = false

    init?(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        guard attach() else { return nil }
    }

    deinit {
        stop()
    }

    func stop() {
        stopped = true
        pendingNotify?.cancel()
        pendingNotify = nil
        source?.cancel()
        source = nil
    }

    private func attach() -> Bool {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return false }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .attrib, .rename, .delete, .link],
            queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self, let source = self.source else { return }
            let events = source.data
            self.scheduleNotify()
            if events.contains(.rename) || events.contains(.delete) {
                self.reattach()
            }
        }
        source.setCancelHandler {
            close(descriptor)
        }
        source.resume()
        self.source = source
        return true
    }

    private func reattach() {
        source?.cancel()
        source = nil
        retryAttach(delay: 0.25, remainingAttempts: 4)
    }

    private func retryAttach(delay: TimeInterval, remainingAttempts: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self, !self.stopped, self.source == nil else { return }
            if !self.attach(), remainingAttempts > 1 {
                self.retryAttach(delay: delay * 2, remainingAttempts: remainingAttempts - 1)
            }
        }
    }

    private func scheduleNotify() {
        pendingNotify?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.onChange()
        }
        pendingNotify = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: work)
    }
}
