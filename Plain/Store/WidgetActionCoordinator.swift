import AppKit
import Foundation
import SwiftData
import WidgetKit
import PlainCore

/// ウィジェット拡張が直接 DB を更新できない環境（adhoc 署名ビルドなど）で
/// ウィジェットが書き残したペンディング操作を本体側で DB に反映する。
/// 反映タイミング: start() 直後・アプリのアクティブ化時・メールボックスの
/// ディレクトリ変更検知時。
@MainActor
final class WidgetActionCoordinator {
    private let container: ModelContainer
    private let store: WidgetActionStore
    private var observers: [NSObjectProtocol] = []
    private var directorySource: DispatchSourceFileSystemObject?

    init(container: ModelContainer, store: WidgetActionStore = WidgetActionStore()) {
        self.container = container
        self.store = store
    }

    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        directorySource?.cancel()
    }

    func start() {
        applyPendingActions()
        startWatchingDirectory()
        observers.append(NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in self.applyPendingActions() }
        })
    }

    func applyPendingActions() {
        let consumed = store.applyPendingActions(context: container.mainContext)
        guard consumed > 0 else { return }
        do {
            try SharedWidgetSnapshotStore.write(from: container)
        } catch {
            print("[WidgetActionCoordinator] snapshot update failed: \(error)")
        }
        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .plainDataDidChange, object: nil)
    }

    private func startWatchingDirectory() {
        let directory = store.directoryURL
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fd = open(directory.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd, eventMask: .write, queue: .main
        )
        source.setEventHandler { [weak self] in
            guard let self else { return }
            Task { @MainActor in self.applyPendingActions() }
        }
        source.setCancelHandler { close(fd) }
        source.resume()
        directorySource = source
    }
}
