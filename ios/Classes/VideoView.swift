//
//  VideoView.swift
//  native_video_view
//
//  Created by Luis Jara Castillo on 11/4/19.
//

import UIKit
import AVFoundation

class VideoView: UIView {
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var videoAsset: AVAsset?
    private var initialized: Bool = false
    private var onPrepared: (() -> Void)? = nil
    private var onFailed: ((String) -> Void)? = nil
    private var onCompletion: (() -> Void)? = nil

    required init?(coder: NSCoder) {
        fatalError("init(coder:) - use init(frame:) instead")
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        initVideoPlayer()
        configureVideoLayer()
    }

    deinit {
        removeOnFailedObserver()
        removeOnPreparedObserver()
        removeOnCompletionObserver()
        player?.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
        stop()
        initialized = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
        playerLayer?.removeAllAnimations()
    }

    private func initVideoPlayer() {
        player = AVPlayer(playerItem: nil)
        player?.addObserver(self, forKeyPath: "status", options: [], context: nil)
        initialized = true
    }

    private func configureVideoLayer() {
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resize
        if let playerLayer = playerLayer {
            layer.addSublayer(playerLayer)
        }
    }

    func configure(videoPath: String?, isURL: Bool) {
        if let path = videoPath,
           let uri: URL = isURL ? URL(string: path) : URL(fileURLWithPath: path) {
            videoAsset = AVAsset(url: uri)
            player?.replaceCurrentItem(with: AVPlayerItem(asset: videoAsset!))
            // Notifies when the video finishes playing.
            NotificationCenter.default.addObserver(self, selector: #selector(onVideoCompleted(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        }
    }

    func play() {
        if !isPlaying() && videoAsset != nil {
            player?.play()
        }
    }

    func pause(restart: Bool) {
        player?.pause()
        if (restart) {
            player?.seek(to: CMTime.zero)
        }
    }

    func stop() {
        pause(restart: true)
    }

    func isPlaying() -> Bool {
        return player?.rate != 0 && player?.error == nil
    }

    func setVolume(volume: Double) {
        player?.volume = Float(volume)
    }

    func getDuration() -> Int64 {
        let durationObj = player?.currentItem?.asset.duration
        return transformCMTime(time: durationObj)
    }

    func getCurrentPosition() -> Int64 {
        let currentTime = player?.currentItem?.currentTime()
        return transformCMTime(time: currentTime)
    }

    func getVideoHeight() -> Double {
        var height: Double = 0.0
        let videoTrack = getVideoTrack()
        if videoTrack != nil {
            height = Double(videoTrack?.naturalSize.height ?? 0.0)
        }
        return height
    }

    func getVideoWidth() -> Double {
        var width: Double = 0.0
        let videoTrack = getVideoTrack()
        if videoTrack != nil {
            width = Double(videoTrack?.naturalSize.width ?? 0.0)
        }
        return width
    }

    func getVideoTrack() -> AVAssetTrack? {
        var videoTrack: AVAssetTrack? = nil
        let tracks = videoAsset?.tracks(withMediaType: .video)
        if tracks != nil && tracks!.count > 0 {
            videoTrack = tracks![0]
        }
        return videoTrack
    }

    private func transformCMTime(time: CMTime?) -> Int64 {
        var ts: Double = 0
        if let obj = time {
            ts = CMTimeGetSeconds(obj) * 1000
        }
        return Int64(ts)
    }

    func seekTo(positionInMillis: Int64?) {
        if let pos = positionInMillis {
            player?.seek(to: CMTimeMake(value: pos, timescale: 1000), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }

    func addOnPreparedObserver(callback: @escaping () -> Void) {
        onPrepared = callback
    }

    func removeOnPreparedObserver() {
        onPrepared = nil
    }

    private func notifyOnPreparedObserver() {
        if onPrepared != nil {
            onPrepared!()
        }
    }

    func addOnFailedObserver(callback: @escaping (String) -> Void) {
        onFailed = callback
    }

    func removeOnFailedObserver() {
        onFailed = nil
    }

    private func notifyOnFailedObserver(message: String) {
        if onFailed != nil {
            onFailed!(message)
        }
    }

    func addOnCompletionObserver(callback: @escaping () -> Void) {
        onCompletion = callback
    }

    func removeOnCompletionObserver() {
        onCompletion = nil
    }

    private func notifyOnCompletionObserver() {
        if onCompletion != nil {
            onCompletion!()
        }
    }

    @objc func onVideoCompleted(notification: NSNotification) {
        notifyOnCompletionObserver()
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            let status = player!.status
            switch (status) {
            case .unknown:
                print("Status unknown")
                break
            case .readyToPlay:
                notifyOnPreparedObserver()
                break
            case .failed:
                if let error = player?.error {
                    let errorMessage = error.localizedDescription
                    notifyOnFailedObserver(message: errorMessage)
                }
                break
            default:
                print("Status unknown")
                break
            }
        }
    }
}
