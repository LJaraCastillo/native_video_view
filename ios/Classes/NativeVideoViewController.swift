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
            let arguments: NSDictionary? = call.arguments as? NSDictionary
            if let args = arguments {
                let videoPath: String? = args["videoSource"] as? String
                let sourceType: String? = args["sourceType"] as? String
                if let path = videoPath{
                    let isUrl: Bool = sourceType != "asset" && sourceType != "file" ? true : false
                    initVideo(videoPath: path, isURL: isUrl)
                }
            }
            result(nil)
            break
        default:
            result(FlutterMethodNotImplemented)
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
        }
    }

    func stopPlayback(){
        
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            let status = self.videoPlayer.status
            switch(status){
            case .unknown:
                print("Status unknown")
            case .readyToPlay:
                let arguments: NSDictionary = NSDictionary()
                let duration: Int64 = self.getDuration()
                let height: CGFloat = self.videoPlayerLayer.videoRect.height
                let width: CGFloat = self.videoPlayerLayer.videoRect.width
                arguments.setValue(duration, forKey: "duration")
                arguments.setValue(height, forKey: "height")
                arguments.setValue(width, forKey: "width")
                self.methodChannel.invokeMethod("player#onPrepared", arguments: arguments)
            case .failed:
                let arguments: NSDictionary = NSDictionary()
                if let error = self.videoPlayer.error{
                    arguments.setValue(error.localizedDescription, forKey: "message")
                }
                methodChannel.invokeMethod("player#onError", arguments: arguments)
            }
        }
    }
    
    func getDuration()-> Int64{
        let durationObj = self.videoPlayer.currentItem?.asset.duration
        var duration : Double = 0
        if let obj = durationObj {
            duration = CMTimeGetSeconds(obj) * 1000
        }
        return Int64(duration)
    }
}
