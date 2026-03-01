//
//  SceneRenderView.swift
//  Giskard
//
//  Created by Timothy Powell on 8/26/25.
//


import SwiftUI
import MetalKit
import Renderer
import GiskardEngine

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
        private var tickSystem: SceneRenderTickSystem?
        private var timer: Timer?

        override init() {
            renderer = Renderer(configuration: .init(clearColor: .purple, preferredFramesPerSecond: 60))
            if let renderer {
                tickSystem = SceneRenderTickSystem(renderer: renderer)
            }
            super.init()
        }

        deinit {
            timer?.invalidate()
        }

        func startTicking(view: MTKView) {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self, weak view] _ in
                guard let self, let view else {
                    return
                }
                tickFrame(viewSize: view.drawableSize)
            }
        }

        private func tickFrame(viewSize: CGSize) {
            guard let renderer, let tickSystem else {
                return
            }
            guard let sceneURL = GiskardApp.selectedSceneFileURL,
                let data = FileSys.shared.ReadFile(sceneURL.path),
                let scene = try? JSONDecoder().decode(SceneFile.self, from: data)
            else {
                tickSystem.setEnabled(false)
                return
            }

            tickSystem.setEnabled(true)
            tickSystem.tick(
                scene: scene,
                viewportSize: RendererVector2(
                    x: Float(max(viewSize.width, 1)),
                    y: Float(max(viewSize.height, 1))
                )
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.renderer?.device)
        context.coordinator.renderer?.configure(view)
        context.coordinator.startTicking(view: view)

        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.renderer?.configure(nsView)
    }
#elseif os(iOS)
    final class Coordinator: NSObject {
        let renderer: Renderer? = Renderer(configuration: .init(clearColor: .purple, preferredFramesPerSecond: 60))
        private var tickSystem: SceneRenderTickSystem?
        private var timer: Timer?

        override init() {
            super.init()
            if let renderer {
                tickSystem = SceneRenderTickSystem(renderer: renderer)
            }
        }

        deinit {
            timer?.invalidate()
        }

        func startTicking(view: MTKView) {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self, weak view] _ in
                guard let self, let view else {
                    return
                }
                tickFrame(viewSize: view.drawableSize)
            }
        }

        private func tickFrame(viewSize: CGSize) {
            guard let renderer, let tickSystem else {
                return
            }
            guard let sceneURL = GiskardApp.selectedSceneFileURL,
                let data = FileSys.shared.ReadFile(sceneURL.path),
                let scene = try? JSONDecoder().decode(SceneFile.self, from: data)
            else {
                tickSystem.setEnabled(false)
                return
            }

            tickSystem.setEnabled(true)
            tickSystem.tick(
                scene: scene,
                viewportSize: RendererVector2(
                    x: Float(max(viewSize.width, 1)),
                    y: Float(max(viewSize.height, 1))
                )
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.renderer?.device)
        context.coordinator.renderer?.configure(view)
        context.coordinator.startTicking(view: view)
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.renderer?.configure(uiView)
    }
#endif
}
