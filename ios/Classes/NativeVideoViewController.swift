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
    private let layout: UIView
    private let videoPlayer: AVPlayer?
    private let videoPlayerLayer: AVPlayerLayer
    
    init(frame:CGRect, viewId:Int64, registrar: FlutterPluginRegistrar) {
        self.frame = frame
        self.viewId = viewId
        self.registrar = registrar
        self.layout = UIView(frame: frame)
        self.videoPlayer = nil
        self.videoPlayerLayer = AVPlayerLayer(player: videoPlayer)
        self.videoPlayerLayer.frame = frame
    }
    
    public func view() -> UIView {
        return layout
    }
}
