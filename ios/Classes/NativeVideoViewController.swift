//
//  NativeVideoViewController.swift
//  Runner
//
//  Created by Luis Jara Castillo on 11/4/19.
//

import Foundation
import Flutter
import AVFoundation

public class NativeVideoViewController: NSObject, FlutterPlatformView {
    private var viewId: Int64
    private var methodChannel: FlutterMethodChannel
    private var videoView: VideoView?
    private var requestAudioFocus: Bool = true
    private var mute: Bool = false
    private var volume: Double = 1.0

    init(frame: CGRect, viewId: Int64, registrar: FlutterPluginRegistrar) {
        self.viewId = viewId
        videoView = VideoView(frame: frame)
        methodChannel = FlutterMethodChannel(name: "native_video_view_\(viewId)", binaryMessenger: registrar.messenger())
        super.init()
        videoView?.addOnPreparedObserver {
            [weak self] () -> Void in
            self?.onPrepared()
        }
        videoView?.addOnFailedObserver {
            [weak self] (message: String) -> Void in
            self?.onFailed(message: message)
        }
        videoView?.addOnCompletionObserver {
            [weak self] () -> Void in
            self?.onCompletion()
        }
        methodChannel.setMethodCallHandler {
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            self?.handle(call: call, result: result)
        }
    }

    deinit {
//        videoView?.removeFromSuperview()
        videoView = nil
        methodChannel.setMethodCallHandler(nil)
        NotificationCenter.default.removeObserver(self)
    }

    public func view() -> UIView {
        return videoView!
    }

    func handle(call: FlutterMethodCall, result: FlutterResult) -> Void {
        switch (call.method) {
        case "player#setVideoSource":
            let arguments = call.arguments as? [String: Any]
            if let args = arguments {
                self.requestAudioFocus = args["requestAudioFocus"] as? Bool ?? false
                let videoPath: String? = args["videoSource"] as? String
                if let path = videoPath {
                    let sourceType: String? = args["sourceType"] as? String
                    let isUrl = sourceType == "VideoSourceType.network"
                    configurePlayer()
                    videoView?.configure(videoPath: path, isURL: isUrl)
                }
            }
            result(nil)
            break
        case "player#start":
            videoView?.play()
            result(nil)
            break
        case "player#pause":
            videoView?.pause(restart: false)
            result(nil)
            break
        case "player#stop":
            videoView?.stop()
            result(nil)
            break
        case "player#currentPosition":
            var arguments = Dictionary<String, Any>()
            arguments["currentPosition"] = videoView?.getCurrentPosition()
            result(arguments)
            break
        case "player#isPlaying":
            var arguments = Dictionary<String, Any>()
            arguments["isPlaying"] = videoView?.isPlaying()
            result(arguments)
            break
        case "player#seekTo":
            let arguments = call.arguments as? [String: Any]
            if let args = arguments {
                let position: Int64? = args["position"] as? Int64
                videoView?.seekTo(positionInMillis: position)
            }
            result(nil)
            break
        case "player#toggleSound":
            mute = !mute
            configureVolume()
            result(nil)
            break
        case "player#setVolume":
            let arguments = call.arguments as? [String: Any]
            if let args = arguments {
                if let volume = args["volume"] as? Double {
                    mute = false
                    self.volume = volume
                    configureVolume()
                }
            }
            result(nil)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }

    func configurePlayer() {
        handleAudioFocus()
        configureVolume()
    }

    func handleAudioFocus() {
        do {
            if requestAudioFocus {
//                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.mixWithOthers)
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.ambient)
            } else {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            }
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
    }

    func configureVolume() {
        if mute {
            videoView?.setVolume(volume: 0.0)
        } else {
            videoView?.setVolume(volume: volume)
        }
    }

    func onCompletion() {
        videoView?.stop()
        methodChannel.invokeMethod("player#onCompletion", arguments: nil)
    }

    func onPrepared() {
        var arguments = Dictionary<String, Any>()
        let height = videoView?.getVideoHeight()
        let width = videoView?.getVideoWidth()
        arguments["duration"] = videoView?.getDuration()
        arguments["height"] = height
        arguments["width"] = width
        methodChannel.invokeMethod("player#onPrepared", arguments: arguments)
    }

    func onFailed(message: String) {
        var arguments = Dictionary<String, Any>()
        arguments["message"] = message
        methodChannel.invokeMethod("player#onError", arguments: arguments)
    }
}
