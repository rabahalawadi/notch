import SwiftUI
import MediaPlayer
import Combine
import UIKit

enum IslandTab: String, CaseIterable, Identifiable {
    case media = "Music"
    case timer = "Timer"
    case system = "System"
    case shelf = "Shelf"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .media: return "waveform"
        case .timer: return "timer"
        case .system: return "bolt.shield.fill"
        case .shelf: return "tray.full.fill"
        }
    }
}

final class NotchViewModel: ObservableObject {
    // MARK: - Island Geometry & State
    // iPhone 11 physical notch measures ~209pt wide x 30pt tall on the 414x896pt screen
    @Published var isExpanded: Bool = false
    @Published var selectedTab: IslandTab = .media
    @Published var notchWidth: CGFloat = 214
    @Published var notchHeight: CGFloat = 34

    // MARK: - Now Playing State
    @Published var trackTitle: String = "Midnight City"
    @Published var trackArtist: String = "M83 — Hurry Up, We're Dreaming"
    @Published var isPlaying: Bool = false
    @Published var trackProgress: Double = 0.38

    // MARK: - Timer State
    @Published var timerRemainingSeconds: Int = 300
    @Published var timerTotalSeconds: Int = 300
    @Published var isTimerRunning: Bool = false

    // MARK: - System HUD State
    @Published var batteryLevel: Int = 85
    @Published var isCharging: Bool = false
    @Published var freeDiskGB: String = "42.8 GB"

    // MARK: - Quick Shelf / Clipboard
    @Published var clipboardText: String = "Tap 'Paste from Clipboard' to pin copied text or links right inside your notch."
    @Published var quickNotes: [String] = [
        "Swipe down on the notch to expand",
        "Long-press the notch to switch tabs",
        "Enable PiP Island to float over Home Screen"
    ]
    @Published var newNoteInput: String = ""

    private var timerCancellable: AnyCancellable?
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer

    init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        refreshSystemStats()
        setupMediaNotifications()
        startHeartbeatTimer()
    }

    func toggleExpand() {
        let generator = UIImpactFeedbackGenerator(style: isExpanded ? .light : .medium)
        generator.impactOccurred()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.74, blendDuration: 0.1)) {
            isExpanded.toggle()
        }
        refreshSystemStats()
    }

    func selectTab(_ tab: IslandTab) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            selectedTab = tab
            if !isExpanded {
                isExpanded = true
            }
        }
    }

    // MARK: - Media Controls
    func setupMediaNotifications() {
        musicPlayer.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer,
            queue: .main
        ) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
        NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer,
            queue: .main
        ) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
        updateNowPlayingInfo()
    }

    func updateNowPlayingInfo() {
        if let item = musicPlayer.nowPlayingItem {
            trackTitle = item.title ?? "Unknown Track"
            trackArtist = item.artist ?? "Apple Music / System Audio"
            let duration = item.playbackDuration
            if duration > 0 {
                trackProgress = min(max(musicPlayer.currentPlaybackTime / duration, 0), 1)
            }
        }
        isPlaying = (musicPlayer.playbackState == .playing)
    }

    func togglePlayPause() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        if musicPlayer.nowPlayingItem != nil {
            if isPlaying {
                musicPlayer.pause()
            } else {
                musicPlayer.play()
            }
            updateNowPlayingInfo()
        } else {
            isPlaying.toggle()
        }
    }

    func nextTrack() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if musicPlayer.nowPlayingItem != nil {
            musicPlayer.skipToNextItem()
            updateNowPlayingInfo()
        } else {
            let demos = [
                ("Starboy", "The Weeknd"),
                ("Veridis Quo", "Daft Punk"),
                ("Nightcall", "Kavinsky"),
                ("Midnight City", "M83")
            ]
            if let pick = demos.randomElement() {
                trackTitle = pick.0
                trackArtist = pick.1
                trackProgress = 0.12
            }
        }
    }

    func previousTrack() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if musicPlayer.nowPlayingItem != nil {
            musicPlayer.skipToPreviousItem()
            updateNowPlayingInfo()
        } else {
            trackProgress = 0.0
        }
    }

    // MARK: - Timer Controls
    func toggleTimer() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isTimerRunning.toggle()
    }

    func resetTimer(seconds: Int = 300) {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        isTimerRunning = false
        timerTotalSeconds = seconds
        timerRemainingSeconds = seconds
    }

    var formattedTimer: String {
        let mins = timerRemainingSeconds / 60
        let secs = timerRemainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    // MARK: - System & Clipboard
    func refreshSystemStats() {
        let rawBattery = UIDevice.current.batteryLevel
        if rawBattery >= 0 {
            batteryLevel = Int(rawBattery * 100)
        }
        let state = UIDevice.current.batteryState
        isCharging = (state == .charging || state == .full)

        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSize = attrs[.systemFreeSize] as? Int64 {
            let gb = Double(freeSize) / 1_073_741_824.0
            freeDiskGB = String(format: "%.1f GB", gb)
        }
    }

    func pasteFromClipboard() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let str = UIPasteboard.general.string, !str.isEmpty {
            clipboardText = str
            if !quickNotes.contains(str) {
                quickNotes.insert(str, at: 0)
            }
        } else {
            clipboardText = "Clipboard is currently empty."
        }
    }

    func addNote() {
        let trimmed = newNoteInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        quickNotes.insert(trimmed, at: 0)
        newNoteInput = ""
    }

    private func startHeartbeatTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.isTimerRunning {
                    if self.timerRemainingSeconds > 0 {
                        self.timerRemainingSeconds -= 1
                    } else {
                        self.isTimerRunning = false
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                }
                if self.isPlaying && self.musicPlayer.nowPlayingItem == nil {
                    self.trackProgress = min(1.0, self.trackProgress + 0.005)
                }
            }
    }
}
