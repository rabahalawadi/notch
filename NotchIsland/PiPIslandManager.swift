import SwiftUI
import UIKit
import AVKit
import AVFoundation
import CoreMedia
import CoreVideo
import Combine

final class PiPIslandManager: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    @Published var isPiPActive: Bool = false
    @Published var isPiPSupported: Bool = false

    let displayLayer = AVSampleBufferDisplayLayer()
    private var pipController: AVPictureInPictureController?
    private var renderTimer: AnyCancellable?
    private weak var viewModel: NotchViewModel?

    override init() {
        super.init()
        configureAudioSession()
    }

    func bind(to viewModel: NotchViewModel) {
        self.viewModel = viewModel
        setupPiPController()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AudioSession setup error: \(error)")
        }
    }

    func setupPiPController() {
        displayLayer.videoGravity = .resizeAspect
        pushCurrentFrame()

        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            isPiPSupported = false
            return
        }
        isPiPSupported = true

        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: displayLayer,
            playbackDelegate: self
        )
        let controller = AVPictureInPictureController(contentSource: contentSource)
        controller.delegate = self
        if #available(iOS 14.2, *) {
            controller.canStartPictureInPictureAutomaticallyFromInline = true
        }
        self.pipController = controller

        renderTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.pushCurrentFrame()
            }
    }

    func togglePiP() {
        guard let controller = pipController else { return }
        pushCurrentFrame()
        if controller.isPictureInPictureActive {
            controller.stopPictureInPicture()
        } else {
            controller.startPictureInPicture()
        }
    }

    func pushCurrentFrame() {
        let size = CGSize(width: 600, height: 150)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIColor.black.setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 48).fill()

            UIColor(white: 0.22, alpha: 1.0).setStroke()
            let strokePath = UIBezierPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerRadius: 46)
            strokePath.lineWidth = 3
            strokePath.stroke()

            let vm = self.viewModel
            let title = vm?.trackTitle ?? "NotchIsland Active"
            let timerStr = (vm?.isTimerRunning == true) ? "⏱ \(vm?.formattedTimer ?? "05:00")" : "🔋 \(vm?.batteryLevel ?? 85)%"

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraph
            ]
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: UIColor.systemCyan,
                .paragraphStyle: paragraph
            ]

            NSString(string: "🎵 \(title)").draw(in: CGRect(x: 34, y: 34, width: 380, height: 40), withAttributes: titleAttrs)
            NSString(string: "\(vm?.trackArtist ?? "iPhone 11 Island")").draw(
                in: CGRect(x: 34, y: 80, width: 360, height: 34),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                    .foregroundColor: UIColor.lightGray
                ]
            )
            NSString(string: timerStr).draw(in: CGRect(x: 425, y: 54, width: 155, height: 40), withAttributes: subAttrs)
        }

        if let sampleBuffer = makeSampleBuffer(from: image) {
            if displayLayer.status == .failed {
                displayLayer.flush()
            }
            displayLayer.enqueue(sampleBuffer)
        }
    }

    private func makeSampleBuffer(from image: UIImage) -> CMSampleBuffer? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(buffer, [])
        let data = CVPixelBufferGetBaseAddress(buffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        if let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) {
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])

        var formatDescription: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            formatDescriptionOut: &formatDescription
        )
        guard let formatDesc = formatDescription else { return nil }

        let now = CMTime(seconds: CACurrentMediaTime(), preferredTimescale: 600)
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: now,
            decodeTimeStamp: .invalid
        )

        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: buffer,
            formatDescription: formatDesc,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        return sampleBuffer
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isPiPActive = true
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isPiPActive = false
    }
}

extension PiPIslandManager: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {}

    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: .zero, duration: CMTime(value: 3600 * 24, timescale: 1))
    }

    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {}

    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}

struct PiPLayerHostView: UIViewRepresentable {
    let layer: AVSampleBufferDisplayLayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        layer.frame = uiView.bounds
    }
}
