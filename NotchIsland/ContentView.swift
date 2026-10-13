import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: NotchViewModel
    @EnvironmentObject var pipManager: PiPIslandManager

    var body: some View {
        ZStack(alignment: .top) {
            // Subtle OLED dark ambient background so the top notch seamlessly blends into the island
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.05, green: 0.07, blue: 0.12),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Hidden 1x1 host layer for Picture-in-Picture Home Screen Floating Island
            PiPLayerHostView(layer: pipManager.displayLayer)
                .frame(width: 1, height: 1)
                .opacity(0.01)

            // Dashboard Body Below the Interactive Notch
            ScrollView {
                VStack(spacing: 22) {
                    Spacer().frame(height: vm.isExpanded ? 245 : 58)

                    // Clock & Date Standby Header
                    VStack(spacing: 4) {
                        Text(Date(), style: .time)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text(Date().formatted(date: .complete, time: .omitted).uppercased())
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 10)

                    // Home Screen Floating Island (PiP) Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "pip.enter")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.cyan)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Float Island Over Home Screen (PiP)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Uses iOS Picture-in-Picture to keep a live mini Dynamic Island pill floating when you swipe home or switch apps.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }

                        Button {
                            pipManager.togglePiP()
                        } label: {
                            HStack {
                                Image(systemName: pipManager.isPiPActive ? "pip.exit" : "pip.enter")
                                Text(pipManager.isPiPActive ? "Stop Floating PiP Island" : "Launch Floating Home Screen Island")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(pipManager.isPiPActive ? Color.orange : Color.cyan)
                            )
                            .foregroundColor(.black)
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )

                    // Quick Action Triggers for Testing the Notch Island
                    VStack(alignment: .leading, spacing: 14) {
                        Text("NOTCH ISLAND QUICK ACTIONS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.gray)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            quickActionTile(title: vm.isExpanded ? "Collapse Notch" : "Expand Notch", subtitle: "Spring physics", icon: "rectangle.expand.vertical", color: .cyan) {
                                vm.toggleExpand()
                            }
                            quickActionTile(title: "Music Controls", subtitle: vm.trackTitle, icon: "waveform", color: .indigo) {
                                vm.selectTab(.media)
                            }
                            quickActionTile(title: vm.isTimerRunning ? "Pause Timer" : "Start 5m Timer", subtitle: vm.formattedTimer, icon: "timer", color: .orange) {
                                vm.selectTab(.timer)
                                if !vm.isTimerRunning { vm.toggleTimer() }
                            }
                            quickActionTile(title: "Paste Clipboard", subtitle: "Pin to Notch Shelf", icon: "doc.on.clipboard", color: .green) {
                                vm.selectTab(.shelf)
                                vm.pasteFromClipboard()
                            }
                        }
                    }

                    // Notch Calibration Slider for iPhone 11 / 12 / 13 / XR
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Notch Cutout Width Calibration")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(vm.notchWidth)) pt")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        Slider(value: $vm.notchWidth, in: 160...240, step: 1)
                            .tint(.cyan)
                        Text("Default 214 pt wraps cleanly around the iPhone 11 / XR notch. Adjust if you use a screen protector border.")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.05)))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 40)
            }

            // Interactive Notch Island pinned to the physical top edge (y = 0)
            NotchIslandView()
                .ignoresSafeArea(edges: .top)
        }
        .ignoresSafeArea(edges: .top)
    }

    private func quickActionTile(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
        }
        .buttonStyle(.plain)
    }
}
