import SwiftUI

struct NotchIslandView: View {
    @EnvironmentObject var vm: NotchViewModel

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                // Main Pitch-Black Dynamic Island Container anchored to top edge (y = 0)
                RoundedRectangle(cornerRadius: vm.isExpanded ? 38 : 22, style: .continuous)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: vm.isExpanded ? 38 : 22, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(vm.isExpanded ? 0.22 : 0.14),
                                        Color.cyan.opacity(vm.isExpanded ? 0.35 : 0.18),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                    .shadow(color: Color.black.opacity(0.75), radius: vm.isExpanded ? 24 : 8, x: 0, y: 10)

                if vm.isExpanded {
                    expandedContent
                        .padding(.top, 38) // Clears the physical iPhone 11 30pt notch cutout
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                        .transition(.opacity.combined(with: .scale(scale: 0.92, anchor: .top)))
                } else {
                    compactWingsContent
                        .padding(.horizontal, 12)
                        .frame(height: vm.notchHeight)
                }
            }
            .frame(
                width: vm.isExpanded ? 382 : (vm.notchWidth + 92),
                height: vm.isExpanded ? 236 : vm.notchHeight
            )
            .contentShape(Rectangle())
            .onTapGesture {
                vm.toggleExpand()
            }
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onEnded { value in
                        if value.translation.height > 16 && !vm.isExpanded {
                            vm.toggleExpand()
                        } else if value.translation.height < -16 && vm.isExpanded {
                            vm.toggleExpand()
                        }
                    }
            )
        }
    }

    // MARK: - Compact Wings Left & Right of the Physical iPhone 11 Notch
    private var compactWingsContent: some View {
        HStack(spacing: 0) {
            // Left Wing ( sits just left of the 209pt physical notch or acts as left ear )
            HStack(spacing: 5) {
                Image(systemName: vm.isPlaying ? "waveform" : "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.cyan)
                    .scaleEffect(vm.isPlaying ? 1.15 : 1.0)
                Text(vm.isTimerRunning ? vm.formattedTimer : "LIVE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .frame(width: 44, alignment: .leading)

            // Space occupied by physical iPhone 11 notch camera/speaker housing
            Spacer(minLength: vm.notchWidth - 10)

            // Right Wing
            HStack(spacing: 4) {
                Circle()
                    .fill(vm.isCharging ? Color.green : Color.cyan)
                    .frame(width: 6, height: 6)
                Text("\(vm.batteryLevel)%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 44, alignment: .trailing)
        }
    }

    // MARK: - Expanded Dynamic Island Content (Below the 30pt Notch Cutout)
    private var expandedContent: some View {
        VStack(spacing: 14) {
            // Tab Bar Selector
            HStack(spacing: 8) {
                ForEach(IslandTab.allCases) { tab in
                    Button {
                        vm.selectTab(tab)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(vm.selectedTab == tab ? Color.white.opacity(0.18) : Color.white.opacity(0.05))
                        )
                        .foregroundColor(vm.selectedTab == tab ? .cyan : .gray)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Active Tab View
            Group {
                switch vm.selectedTab {
                case .media:
                    mediaTabView
                case .timer:
                    timerTabView
                case .system:
                    systemTabView
                case .shelf:
                    shelfTabView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - 1. Media Tab
    private var mediaTabView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.indigo, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(vm.trackTitle)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(vm.trackArtist)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }

                Spacer()

                // Animated Equalizer Bars
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { idx in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.cyan)
                            .frame(width: 3, height: vm.isPlaying ? CGFloat([14, 24, 18, 22][idx]) : 6)
                            .animation(
                                .easeInOut(duration: 0.35).repeatForever(autoreverses: true).delay(Double(idx) * 0.08),
                                value: vm.isPlaying
                            )
                    }
                }
            }

            // Progress & Transport Controls
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.14))
                            .frame(height: 5)
                        Capsule()
                            .fill(Color.cyan)
                            .frame(width: geo.size.width * vm.trackProgress, height: 5)
                    }
                }
                .frame(height: 5)

                HStack(spacing: 36) {
                    Button(action: vm.previousTrack) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Button(action: vm.togglePlayPause) {
                        Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.cyan)
                    }
                    Button(action: vm.nextTrack) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    // MARK: - 2. Timer Tab
    private var timerTabView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("NOTCH COUNTDOWN")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
                Text(vm.formattedTimer)
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    ForEach([60, 300, 900], id: \.self) { preset in
                        Button("\(preset / 60)m") {
                            vm.resetTimer(seconds: preset)
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                        .foregroundColor(.white)
                    }
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: vm.toggleTimer) {
                    Circle()
                        .fill(vm.isTimerRunning ? Color.orange : Color.green)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: vm.isTimerRunning ? "pause.fill" : "play.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black)
                        )
                }
                Button {
                    vm.resetTimer(seconds: vm.timerTotalSeconds)
                } label: {
                    Circle()
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
        }
    }

    // MARK: - 3. System HUD Tab
    private var systemTabView: some View {
        HStack(spacing: 12) {
            statCard(title: "BATTERY", value: "\(vm.batteryLevel)%", subtitle: vm.isCharging ? "Charging" : "Discharging", icon: "battery.100.bolt", color: .green)
            statCard(title: "STORAGE", value: vm.freeDiskGB, subtitle: "Available", icon: "internaldrive.fill", color: .cyan)
            statCard(title: "DEVICE", value: "iPhone 11", subtitle: "Notch Active", icon: "iphone.gen2", color: .purple)
        }
    }

    private func statCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.gray)
            }
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07)))
    }

    // MARK: - 4. Quick Shelf / Clipboard Tab
    private var shelfTabView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(vm.clipboardText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                Spacer()
                Button(action: vm.pasteFromClipboard) {
                    Label("Paste", systemImage: "doc.on.clipboard.fill")
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.cyan))
                        .foregroundColor(.black)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.quickNotes, id: \.self) { note in
                        Text(note)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.white.opacity(0.09)))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}
