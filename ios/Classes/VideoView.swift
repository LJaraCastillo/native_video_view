//
//  VideoView.swift
//  native_video_view
//
//  Created by Luis Jara Castillo on 11/4/19.
//

import UIKit
import AVFoundation

class VideoView : UIView {
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var videoAsset: AVAsset?
    private var initialized: Bool = false
    private var onPrepared: (()-> Void)? = nil
    private var onFailed: ((String) -> Void)? = nil
    private var onCompletion: (() -> Void)? = nil
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
    
    deinit {
        self.removeOnFailedObserver()
        self.removeOnPreparedObserver()
        self.removeOnCompletionObserver()
        self.player?.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
        self.stop()
        self.initialized = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.configureVideoLayer()
    }
    
    func configure(videoPath: String?, isURL: Bool){
        if !initialized {
            self.initVideoPlayer()
        }
        if let path = videoPath {
            let uri: URL? = isURL ? URL(string: path) : URL(fileURLWithPath: path)
            let asset = AVAsset(url: uri!)
            player?.replaceCurrentItem(with: AVPlayerItem(asset: asset))
            self.videoAsset = asset
            self.configureVideoLayer()
            // Notifies when the video finishes playing.
            NotificationCenter.default.addObserver(self, selector: #selector(onVideoCompleted(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: self.player?.currentItem)
        }
    }
    
    private func configureVideoLayer(){
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = bounds
        playerLayer?.videoGravity = .resize
        if let playerLayer = self.playerLayer {
            self.clearSubLayers()
            layer.addSublayer(playerLayer)
        }
    }
    
    private func clearSubLayers(){
        layer.sublayers?.forEach{
            $0.removeFromSuperlayer()
        }
    }
    
    private func initVideoPlayer(){
        self.player = AVPlayer(playerItem: nil)
        self.player?.addObserver(self, forKeyPath: "status", options: [], context: nil)
        self.initialized = true
    }
    
    func play(){
        if !self.isPlaying() && self.videoAsset != nil {
            self.player?.play()
        }
    }
    
    func pause(restart:Bool){
        self.player?.pause()
        if(restart){
            self.player?.seek(to: kCMTimeZero)
        }
    }
    
    func stop(){
        self.pause(restart: true)
    }
    
    func isPlaying() -> Bool{
        return self.player?.rate != 0 && self.player?.error == nil
    }

    func setVolume(volume:Double){
        self.player?.volume = Float(volume)
    }
    
    func getDuration()-> Int64 {
        let durationObj = self.player?.currentItem?.asset.duration
        return self.transformCMTime(time: durationObj)
    }
    
    func getCurrentPosition() -> Int64 {
        let currentTime = self.player?.currentItem?.currentTime()
        return self.transformCMTime(time: currentTime)
    }
    
    func getVideoHeight() -> Double {
        var height: Double = 0.0
        let videoTrack = self.getVideoTrack()
        if videoTrack != nil {
            height = Double(videoTrack?.naturalSize.height ?? 0.0)
        }
        return height
    }
    
    func getVideoWidth() -> Double {
        var width: Double = 0.0
        let videoTrack = self.getVideoTrack()
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
    
    private func transformCMTime(time:CMTime?) -> Int64 {
        var ts : Double = 0
        if let obj = time {
            ts = CMTimeGetSeconds(obj) * 1000
        }
        return Int64(ts)
    }
    
    func seekTo(positionInMillis: Int64?){
        if let pos = positionInMillis {
            self.player?.seek(to: CMTimeMake(pos, 1000), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
    }
    
    func addOnPreparedObserver(callback: @escaping ()->Void){
        self.onPrepared = callback
    }
    
    func removeOnPreparedObserver() {
        self.onPrepared = nil
    }
    
    private func notifyOnPreaparedObserver(){
        if onPrepared != nil {
            self.onPrepared!()
        }
    }
    
    func addOnFailedObserver(callback: @escaping (String)->Void){
        self.onFailed = callback
    }
    
    func removeOnFailedObserver() {
        self.onFailed = nil
    }
    
    private func notifyOnFailedObserver(message: String){
        if onFailed != nil {
            self.onFailed!(message)
        }
    }
    
    func addOnCompletionObserver(callback: @escaping ()->Void){
        self.onCompletion = callback
    }
    
    func removeOnCompletionObserver() {
        self.onCompletion = nil
    }
    
    private func notifyOnCompletionObserver(){
        if onCompletion != nil {
            self.onCompletion!()
        }
    }
    
    @objc func onVideoCompleted(notification:NSNotification){
        self.notifyOnCompletionObserver()
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            let status = self.player!.status
            switch(status){
            case .unknown:
                print("Status unknown")
                break
            case .readyToPlay:
                self.notifyOnPreaparedObserver()
                break
            case .failed:
                if let error = self.player?.error{
                    let errorMessage = error.localizedDescription
                    self.notifyOnFailedObserver(message: errorMessage)
                }
                break
             default:
                print("Status unknown")
                break
            }
        }
    }
}
