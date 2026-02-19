//
//  SceneRenderView.swift
//  Giskard
//
//  Created by Timothy Powell on 8/26/25.
//


import SwiftUI
import MetalKit
import Renderer

#if os(macOS)

public typealias NativeView = NSView
public typealias NativeApplication = NSApplication
public typealias ViewRepresentable = NSViewRepresentable
public typealias ViewControllerRepresentable = NSViewControllerRepresentable

#elseif os(iOS)

public typealias NativeView = UIView
public typealias NativeApplication = UIApplication
public typealias ViewRepresentable = UIViewRepresentable
public typealias ViewControllerRepresentable = UIViewControllerRepresentable

#endif

struct SceneRenderView: ViewRepresentable {

#if os(macOS)
    final class Coordinator: NSObject {
        let renderer: Renderer?

        override init() {
            renderer = Renderer(configuration: .init(clearColor: .purple, preferredFramesPerSecond: 60))
            super.init()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.renderer?.device)
        context.coordinator.renderer?.configure(view)

        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.renderer?.configure(nsView)
    }
#elseif os(iOS)
    final class Coordinator: NSObject {
        let renderer: Renderer? = Renderer(configuration: .init(clearColor: .purple, preferredFramesPerSecond: 60))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.renderer?.device)
        context.coordinator.renderer?.configure(view)
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer?.configure(uiView)
    }
#endif
}
