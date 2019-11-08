//
//  NativeVideoViewController.swift
//  Runner
//
//  Created by Luis Jara Castillo on 11/4/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import Foundation
import Flutter
import AVFoundation

public class NativeVideoViewController: NSObject, FlutterPlatformView {
    private let frame: CGRect
    private let viewId: Int64
    private let methodChannel: FlutterMethodChannel
    private let videoView: UIView
    private let videoPlayer: AVPlayer
    private let videoPlayerLayer: AVPlayerLayer
    private var initialized: Bool = false
    private var dataSource: String? = nil
    
    init(frame:CGRect, viewId:Int64, registrar: FlutterPluginRegistrar) {
        self.frame = frame
        self.viewId = viewId
        self.videoView = UIView(frame: frame)
        self.videoPlayer = AVPlayer(playerItem: nil)
        self.videoPlayerLayer = AVPlayerLayer(player: self.videoPlayer)
        self.videoPlayerLayer.frame = self.videoView.bounds
        self.videoView.layer.addSublayer(videoPlayerLayer)
        self.methodChannel = FlutterMethodChannel(name: "native_video_view_\(viewId)", binaryMessenger: registrar.messenger())
        super.init()
        self.methodChannel.setMethodCallHandler(handle)
    }
    
    deinit {
        self.initialized = false
        self.methodChannel.setMethodCallHandler(nil)
        self.videoPlayer.removeObserver(self, forKeyPath: "status")
        NotificationCenter.default.removeObserver(self)
        self.stopPlayback()
    }
    
    public func view() -> UIView {
        return videoView
    }
    
    func handle(call: FlutterMethodCall, result: FlutterResult) -> Void {
        switch(call.method){
        case "player#setVideoSource":
            let arguments = call.arguments as? [String:Any]
            if let args = arguments {
                let videoPath: String? = args["videoSource"] as? String
                let sourceType: String? = args["sourceType"] as? String
                if let path = videoPath{
                    let isUrl: Bool = sourceType == "VideoSourceType.network" ? true : false
                    initVideo(videoPath: path, isURL: isUrl)
                }
            }
            result(nil)
            break
        case "player#start":
            self.startPlayback()
            result(nil)
            break
        case "player#pause":
            self.pausePlayback(restart: false)
            result(nil)
            break
        case "player#stop":
            self.stopPlayback()
            result(nil)
            break
        case "player#currentPosition":
            var arguments = Dictionary<String, Any>()
            arguments["currentPosition"] = self.getCurrentPosition()
            result(arguments)
            break
        case "player#isPlaying":
            var arguments = Dictionary<String, Any>()
            arguments["isPlaying"] = self.isPlaying()
            result(arguments)
            break
        case "player#seekTo":
            let arguments = call.arguments as? [String:Any]
            if let args = arguments {
                let position: Int64? = args["position"] as? Int64
                if let pos = position {
                    self.videoPlayer.seek(to: CMTimeMake(pos, 1000), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
                }
            }
            result(nil)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    func initVideoPlayer(){
        self.videoPlayer.addObserver(self, forKeyPath: "status", options: [], context: nil)
        self.initialized = true
    }
    
    func initVideo(videoPath:String?, isURL: Bool){
        if !initialized {
            self.initVideoPlayer()
        }
        if let path = videoPath {
            let uri: URL? = isURL ? URL(string: path) : URL(fileURLWithPath: path)
            self.videoPlayer.replaceCurrentItem(with: AVPlayerItem(url: uri!))
            // Notifies when the video finishes playing.
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(notification:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer.currentItem)
            self.dataSource = path
        }		
    }
    
    func startPlayback(){
        if !self.isPlaying() && self.dataSource != nil {
            self.videoPlayer.play()
        }
    }
    
    func pausePlayback(restart:Bool){
        self.videoPlayer.pause()
        if(restart){
            self.videoPlayer.seek(to: kCMTimeZero)
        }
    }
    
    func stopPlayback(){
        self.pausePlayback(restart: true)
    }
    
    func isPlaying() -> Bool{
        return self.videoPlayer.rate != 0 && self.videoPlayer.error == nil
    }
    
    func getDuration()-> Int64 {
        let durationObj = self.videoPlayer.currentItem?.asset.duration
        return self.transformCMTime(time: durationObj)
    }
    
    func getCurrentPosition() -> Int64 {
        let currentTime = self.videoPlayer.currentItem?.currentTime()
        return self.transformCMTime(time: currentTime)
    }
    
    func transformCMTime(time:CMTime?) -> Int64 {
        var ts : Double = 0
        if let obj = time {
            ts = CMTimeGetSeconds(obj) * 1000
        }
        return Int64(ts)
    }
    
    @objc func playerDidFinishPlaying(notification: NSNotification){
        self.methodChannel.invokeMethod("player#onCompletion", arguments: nil)
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            let status = self.videoPlayer.status
            switch(status){
            case .unknown:
                print("Status unknown")
            case .readyToPlay:
                var arguments = Dictionary<String, Any>()
                arguments["duration"] = self.getDuration()
                arguments["height"] = self.videoPlayer.currentItem?.presentationSize.height ?? 0
                arguments["width"] = self.videoPlayer.currentItem?.presentationSize.width ?? 0
                self.methodChannel.invokeMethod("player#onPrepared", arguments: arguments)
                break
            case .failed:
                self.dataSource = nil
                var arguments = Dictionary<String, Any>()
                if let error = self.videoPlayer.error{
                    arguments["message"] = error.localizedDescription
                }
                self.methodChannel.invokeMethod("player#onError", arguments: arguments)
                break
            }
        }
    }
}
