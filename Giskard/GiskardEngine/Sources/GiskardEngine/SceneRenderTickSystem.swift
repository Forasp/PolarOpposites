import Foundation
import Renderer

public final class SceneRenderTickSystem {
    private weak var renderer: Renderer?
    private var isEnabled = false

    private var fallbackTextureHandle: TextureHandle?
    private var fallbackMeshHandle: MeshHandle?
    private var fallbackMaterialHandle: MaterialHandle?
    private var cameraHandle: CameraHandle?

    public init(renderer: Renderer) {
        self.renderer = renderer
    }

    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    public func tick(scene: SceneFile, viewportSize: RendererVector2) {
        guard isEnabled, let renderer else {
            return
        }

        ensureFallbackResources(in: renderer)

        renderer.beginReceivingCommands()
        let targetTexture = fallbackTextureHandle ?? uploadFallbackTexture(in: renderer)
        let cameraNode = findFirstCameraNode(in: scene.entities)

        if let targetTexture {
            let descriptor = cameraNode.map(cameraDescriptor(from:)) ?? defaultCameraDescriptor()
            if let existing = cameraHandle {
                renderer.updateCamera(existing, descriptor: descriptor)
            } else {
                cameraHandle = renderer.uploadCamera(descriptor)
            }
            if let cameraHandle {
                renderer.enqueueRenderCamera(
                    RenderCameraCommand(camera: cameraHandle, targetTexture: targetTexture)
                )
            }
        }

        for node in scene.entities {
            traverseAndEnqueue(node, renderer: renderer)
        }

        if let targetTexture {
            renderer.enqueuePresentTexture(
                PresentTextureCommand(
                    texture: targetTexture,
                    destination: RendererRect(
                        x: 0,
                        y: 0,
                        width: max(1, viewportSize.x),
                        height: max(1, viewportSize.y)
                    ),
                    scale: 1
                )
            )
        }

        renderer.endReceivingCommandsAndRenderFrame()
    }

    private func ensureFallbackResources(in renderer: Renderer) {
        if fallbackTextureHandle == nil {
            fallbackTextureHandle = uploadFallbackTexture(in: renderer)
        }

        if fallbackMeshHandle == nil {
            // Placeholder handles keep command validation satisfied until authored assets are wired through.
            fallbackMeshHandle = renderer.uploadMesh(
                vertexData: Data(repeating: 0, count: MemoryLayout<Float>.size * 12),
                indexData: Data(repeating: 0, count: MemoryLayout<UInt16>.size * 6),
                descriptor: MeshUploadDescriptor(vertexStride: MemoryLayout<Float>.size * 3, indexType: .uint16)
            )
        }

        if fallbackMaterialHandle == nil {
            fallbackMaterialHandle = renderer.uploadMaterial(
                MaterialUploadDescriptor(
                    baseColor: RendererVector3(x: 0, y: 1, z: 1),
                    opacity: 1,
                    metallic: 0,
                    roughness: 1
                )
            )
        }
    }

    private func uploadFallbackTexture(in renderer: Renderer) -> TextureHandle? {
        let cyanPixel: [UInt8] = [0, 255, 255, 255]
        let bytes = Data(cyanPixel + cyanPixel + cyanPixel + cyanPixel)
        return renderer.uploadTexture(
            bytes: bytes,
            descriptor: TextureUploadDescriptor(width: 2, height: 2, pixelFormat: .rgba8Unorm)
        )
    }

    private func findFirstCameraNode(in nodes: [SceneEntityNode]) -> SceneEntityNode? {
        for node in nodes {
            if hasCapability("Camera", in: node.capabilities) {
                return node
            }
            if let nested = findFirstCameraNode(in: node.children) {
                return nested
            }
        }
        return nil
    }

    private func traverseAndEnqueue(_ node: SceneEntityNode, renderer: Renderer) {
        if hasCapability("Renderable2D", in: node.capabilities), let texture = fallbackTextureHandle {
            renderer.enqueueRenderable2D(
                Renderable2DCommand(
                    texture: texture,
                    position: RendererVector2(
                        x: Float(node.position[safe: 0] ?? 0),
                        y: Float(node.position[safe: 1] ?? 0)
                    ),
                    size: RendererVector2(x: 1, y: 1),
                    scale: RendererVector2(x: 1, y: 1),
                    rotation: RendererQuaternion(
                        x: Float(node.rotation[safe: 0] ?? 0),
                        y: Float(node.rotation[safe: 1] ?? 0),
                        z: Float(node.rotation[safe: 2] ?? 0),
                        w: Float(node.rotation[safe: 3] ?? 1)
                    )
                )
            )
        }

        if hasCapability("Renderable3D", in: node.capabilities),
            let mesh = fallbackMeshHandle,
            let material = fallbackMaterialHandle
        {
            renderer.enqueueRenderable3D(
                Renderable3DCommand(
                    mesh: mesh,
                    material: material,
                    position: RendererVector3(
                        x: Float(node.position[safe: 0] ?? 0),
                        y: Float(node.position[safe: 1] ?? 0),
                        z: Float(node.position[safe: 2] ?? 0)
                    ),
                    rotation: RendererQuaternion(
                        x: Float(node.rotation[safe: 0] ?? 0),
                        y: Float(node.rotation[safe: 1] ?? 0),
                        z: Float(node.rotation[safe: 2] ?? 0),
                        w: Float(node.rotation[safe: 3] ?? 1)
                    ),
                    scale: .one
                )
            )
        }

        for child in node.children {
            traverseAndEnqueue(child, renderer: renderer)
        }
    }

    private func cameraDescriptor(from node: SceneEntityNode) -> CameraDescriptor {
        CameraDescriptor(
            position: RendererVector3(
                x: Float(node.position[safe: 0] ?? 0),
                y: Float(node.position[safe: 1] ?? 0),
                z: Float(node.position[safe: 2] ?? 0)
            ),
            rotation: RendererQuaternion(
                x: Float(node.rotation[safe: 0] ?? 0),
                y: Float(node.rotation[safe: 1] ?? 0),
                z: Float(node.rotation[safe: 2] ?? 0),
                w: Float(node.rotation[safe: 3] ?? 1)
            )
        )
    }

    private func defaultCameraDescriptor() -> CameraDescriptor {
        CameraDescriptor(
            position: RendererVector3(x: 0, y: 0, z: -25),
            rotation: .identity,
            verticalFOVDegrees: 60,
            nearPlane: 0.1,
            farPlane: 10_000
        )
    }

    private func hasCapability(_ capability: String, in capabilities: [String]) -> Bool {
        capabilities.contains {
            $0.caseInsensitiveCompare(capability) == .orderedSame
        }
    }
}

private extension Array where Element == Double {
    subscript(safe index: Int) -> Double? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}
