//
//  NativeVideoVIewFactory.swift
//  Runner
//
//  Created by Luis Jara Castillo on 11/4/19.
//  Copyright © 2019 The Chromium Authors. All rights reserved.
//

import Foundation
import Flutter

public class NativeVideoViewFactory:NSObject, FlutterPlatformViewFactory {
    private let registrar: FlutterPluginRegistrar
    
    init(registrar:FlutterPluginRegistrar){
        self.registrar = registrar
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return NativeVideoViewController(frame: frame, viewId: viewId, registrar: registrar)
    }
}
