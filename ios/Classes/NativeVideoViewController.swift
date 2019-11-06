//
//  NativeVideoViewController.swift
//  Runner
//
//  Created by Luis Jara Castillo on 11/4/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import Foundation
import AVFoundation
import Flutter

public class NativeVideoViewController: NSObject, FlutterPlatformView {
    private let frame: CGRect
    private let viewId: Int64
    private let registrar: FlutterPluginRegistrar
    private let methodChannel: FlutterMethodChannel
    private let layout: UIView
    private let videoPlayer: AVPlayer
    private let videoPlayerLayer: AVPlayerLayer
    private var initialized: Bool = false
    private var dataSource: String? = nil
    
    init(frame:CGRect, viewId:Int64, registrar: FlutterPluginRegistrar) {
        self.frame = frame
        self.viewId = viewId
        self.registrar = registrar
        self.layout = UIView(frame: frame)
        self.videoPlayer = AVPlayer(playerItem: nil)
        self.videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
        self.videoPlayerLayer.frame = layout.bounds
        self.layout.layer.addSublayer(videoPlayerLayer)
        self.methodChannel = FlutterMethodChannel(name: "native_video_view_\(viewId)", binaryMessenger: registrar.messenger())
        super.init()
        self.methodChannel.setMethodCallHandler(handle)
    }
    
    deinit {
        self.initialized = false
        self.methodChannel.setMethodCallHandler(nil)
        self.videoPlayer.removeObserver(self, forKeyPath: "status")
        self.stopPlayback()
    }
    
    public func view() -> UIView {
        return layout
    }
    
    func handle(call: FlutterMethodCall, result: FlutterResult) -> Void {
        switch(call.method){
        case "player#setVideoSource":
            let arguments = call.arguments as? [String:Any]
            if let args = arguments {
                let videoPath: String? = args["videoSource"] as? String
                let sourceType: String? = args["sourceType"] as? String
                if let path = videoPath{
                    print(sourceType)
                    let isUrl: Bool = sourceType != "asset" && sourceType != "file" ? true : false
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
            arguments["position"] = self.getCurrentPosition()
            print(self.getCurrentPosition())
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
                    self.videoPlayer.seek(to: CMTimeMakeWithSeconds(Float64(pos / 1000), 60000))
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
            print(path)
            print(isURL)
            print(uri?.absoluteString)
            self.videoPlayer.replaceCurrentItem(with: AVPlayerItem(url: uri!))
            // Notifies when the video finishes playing.
            NotificationCenter.default.addObserver(self, selector: Selector(("playerDidFinishPlaying")), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.videoPlayer.currentItem)
            self.dataSource = videoPath
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
    
    func playerDidFinishPlaying(note: NSNotification){
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
                arguments["height"] = self.videoPlayerLayer.videoRect.height
                arguments["width"] = self.videoPlayerLayer.videoRect.width
                print(arguments)
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
