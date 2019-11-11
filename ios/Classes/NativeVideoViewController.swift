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
    private var viewId: Int64
    private var methodChannel: FlutterMethodChannel
    private var videoView: VideoView?
    
    init(frame:CGRect, viewId:Int64, registrar: FlutterPluginRegistrar) {
        self.viewId = viewId
        self.videoView = VideoView(frame: frame)
        self.methodChannel = FlutterMethodChannel(name: "native_video_view_\(viewId)", binaryMessenger: registrar.messenger())
        super.init()
        self.videoView?.addOnPreparedObserver(callback: self.onPrepared)
        self.videoView?.addOnFailedObserver(callback: self.onFailed(message:))
        self.videoView?.addOnCompletionObserver(callback: self.onCompletion)
        self.methodChannel.setMethodCallHandler(handle)
    }
    
    deinit {
        self.videoView = nil
        self.methodChannel.setMethodCallHandler(nil)
        NotificationCenter.default.removeObserver(self)
    }
    
    public func view() -> UIView {
        return videoView!
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
                    self.videoView?.configure(videoPath: path, isURL: isUrl)
                }
            }
            result(nil)
            break
        case "player#start":
            self.videoView?.play()
            result(nil)
            break
        case "player#pause":
            self.videoView?.pause(restart: false)
            result(nil)
            break
        case "player#stop":
            self.videoView?.stop()
            result(nil)
            break
        case "player#currentPosition":
            var arguments = Dictionary<String, Any>()
            arguments["currentPosition"] = self.videoView?.getCurrentPosition()
            result(arguments)
            break
        case "player#isPlaying":
            var arguments = Dictionary<String, Any>()
            arguments["isPlaying"] = self.videoView?.isPlaying()
            result(arguments)
            break
        case "player#seekTo":
            let arguments = call.arguments as? [String:Any]
            if let args = arguments {
                let position: Int64? = args["position"] as? Int64
                self.videoView?.seekTo(positionInMillis: position)
            }
            result(nil)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
    func onCompletion(){
        self.methodChannel.invokeMethod("player#onCompletion", arguments: nil)
    }
    
    func onPrepared(){
        var arguments = Dictionary<String, Any>()
        let height = self.videoView?.getVideoHeight()
        let width = self.videoView?.getVideoWidth()
        arguments["duration"] = self.videoView?.getDuration()
        arguments["height"] = height
        arguments["width"] = width
        self.methodChannel.invokeMethod("player#onPrepared", arguments: arguments)
    }
    
    func onFailed(message: String){
        var arguments = Dictionary<String, Any>()
        arguments["message"] = message
        self.methodChannel.invokeMethod("player#onError", arguments: arguments)
    }
}
