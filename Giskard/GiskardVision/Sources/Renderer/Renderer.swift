import Foundation
import MetalKit

public struct RendererClearColor: Sendable, Equatable {
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double

    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let purple = RendererClearColor(red: 0.45, green: 0.15, blue: 0.80, alpha: 1.0)

    var metal: MTLClearColor {
        MTLClearColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

public struct RendererConfiguration: Sendable, Equatable {
    public var clearColor: RendererClearColor
    public var preferredFramesPerSecond: Int

    public init(
        clearColor: RendererClearColor = .purple,
        preferredFramesPerSecond: Int = 60
    ) {
        self.clearColor = clearColor
        self.preferredFramesPerSecond = preferredFramesPerSecond
    }
}

public struct RendererVector2: Sendable, Equatable {
    public var x: Float
    public var y: Float

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }

    public static let zero = RendererVector2(x: 0, y: 0)
    public static let one = RendererVector2(x: 1, y: 1)
}

public struct RendererVector3: Sendable, Equatable {
    public var x: Float
    public var y: Float
    public var z: Float

    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }

    public static let zero = RendererVector3(x: 0, y: 0, z: 0)
    public static let one = RendererVector3(x: 1, y: 1, z: 1)
}

public struct RendererQuaternion: Sendable, Equatable {
    public var x: Float
    public var y: Float
    public var z: Float
    public var w: Float

    public init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }

    public static let identity = RendererQuaternion(x: 0, y: 0, z: 0, w: 1)
}

public struct RendererRect: Sendable, Equatable {
    public var x: Float
    public var y: Float
    public var width: Float
    public var height: Float

    public init(x: Float, y: Float, width: Float, height: Float) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct TextureHandle: Hashable, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
}

public struct MeshHandle: Hashable, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
}

public struct MaterialHandle: Hashable, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
}

public struct CameraHandle: Hashable, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }
}

public struct TextureUploadDescriptor: Equatable {
    public var width: Int
    public var height: Int
    public var pixelFormat: MTLPixelFormat

    public init(width: Int, height: Int, pixelFormat: MTLPixelFormat = .bgra8Unorm) {
        self.width = width
        self.height = height
        self.pixelFormat = pixelFormat
    }
}

public struct MeshUploadDescriptor: Equatable {
    public var vertexStride: Int
    public var primitiveType: MTLPrimitiveType
    public var indexType: MTLIndexType?

    public init(
        vertexStride: Int,
        primitiveType: MTLPrimitiveType = .triangle,
        indexType: MTLIndexType? = .uint32
    ) {
        self.vertexStride = vertexStride
        self.primitiveType = primitiveType
        self.indexType = indexType
    }
}

public struct MaterialUploadDescriptor: Sendable, Equatable {
    public var baseColor: RendererVector3
    public var opacity: Float
    public var metallic: Float
    public var roughness: Float

    public init(
        baseColor: RendererVector3 = .one,
        opacity: Float = 1,
        metallic: Float = 0,
        roughness: Float = 1
    ) {
        self.baseColor = baseColor
        self.opacity = opacity
        self.metallic = metallic
        self.roughness = roughness
    }
}

public struct CameraDescriptor: Sendable, Equatable {
    public var position: RendererVector3
    public var rotation: RendererQuaternion
    public var verticalFOVDegrees: Float
    public var nearPlane: Float
    public var farPlane: Float

    public init(
        position: RendererVector3 = .zero,
        rotation: RendererQuaternion = .identity,
        verticalFOVDegrees: Float = 60,
        nearPlane: Float = 0.1,
        farPlane: Float = 10_000
    ) {
        self.position = position
        self.rotation = rotation
        self.verticalFOVDegrees = verticalFOVDegrees
        self.nearPlane = nearPlane
        self.farPlane = farPlane
    }
}

public struct Renderable2DCommand: Sendable, Equatable {
    public var texture: TextureHandle
    public var position: RendererVector2
    public var size: RendererVector2
    public var scale: RendererVector2

    public init(
        texture: TextureHandle,
        position: RendererVector2,
        size: RendererVector2,
        scale: RendererVector2 = .one
    ) {
        self.texture = texture
        self.position = position
        self.size = size
        self.scale = scale
    }
}

public struct Renderable3DCommand: Sendable, Equatable {
    public var mesh: MeshHandle
    public var material: MaterialHandle
    public var position: RendererVector3
    public var rotation: RendererQuaternion
    public var scale: RendererVector3

    public init(
        mesh: MeshHandle,
        material: MaterialHandle,
        position: RendererVector3,
        rotation: RendererQuaternion,
        scale: RendererVector3 = .one
    ) {
        self.mesh = mesh
        self.material = material
        self.position = position
        self.rotation = rotation
        self.scale = scale
    }
}

public struct RenderCameraCommand: Sendable, Equatable {
    public var camera: CameraHandle
    public var targetTexture: TextureHandle

    public init(camera: CameraHandle, targetTexture: TextureHandle) {
        self.camera = camera
        self.targetTexture = targetTexture
    }
}

public struct PresentTextureCommand: Sendable, Equatable {
    public var texture: TextureHandle
    public var destination: RendererRect
    public var scale: Float

    public init(texture: TextureHandle, destination: RendererRect, scale: Float = 1) {
        self.texture = texture
        self.destination = destination
        self.scale = scale
    }
}

public struct RendererFrameSnapshot: Sendable, Equatable {
    public var renderable2DCount: Int
    public var renderable3DCount: Int
    public var hasCameraCommand: Bool
    public var hasPresentCommand: Bool
    public var issues: [String]

    public init(
        renderable2DCount: Int = 0,
        renderable3DCount: Int = 0,
        hasCameraCommand: Bool = false,
        hasPresentCommand: Bool = false,
        issues: [String] = []
    ) {
        self.renderable2DCount = renderable2DCount
        self.renderable3DCount = renderable3DCount
        self.hasCameraCommand = hasCameraCommand
        self.hasPresentCommand = hasPresentCommand
        self.issues = issues
    }
}

private struct MeshGPUResource {
    var vertexBuffer: MTLBuffer
    var indexBuffer: MTLBuffer?
    var indexCount: Int
    var descriptor: MeshUploadDescriptor
}

private struct FrameCommandPackage {
    var renderable2D: [Renderable2DCommand] = []
    var renderable3D: [Renderable3DCommand] = []
    var cameraCommand: RenderCameraCommand? = nil
    var presentCommand: PresentTextureCommand? = nil
}

private struct FallbackVertex {
    var x: Float
    var y: Float
    var red: Float
    var green: Float
    var blue: Float
    var alpha: Float
}

public final class Renderer: NSObject, MTKViewDelegate {
    public let device: MTLDevice
    public private(set) var configuration: RendererConfiguration
    public private(set) var lastSubmissionIssues: [String] = []
    public var lastFrameSnapshot: RendererFrameSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return frameSnapshot
    }

    private let commandQueue: MTLCommandQueue
    private let fallbackPipelineState: MTLRenderPipelineState?
    private weak var configuredView: MTKView?
    private let lock = NSLock()

    private var nextTextureHandle: UInt64 = 1
    private var nextMeshHandle: UInt64 = 1
    private var nextMaterialHandle: UInt64 = 1
    private var nextCameraHandle: UInt64 = 1

    private var textures: [TextureHandle: MTLTexture] = [:]
    private var meshes: [MeshHandle: MeshGPUResource] = [:]
    private var materials: [MaterialHandle: MaterialUploadDescriptor] = [:]
    private var cameras: [CameraHandle: CameraDescriptor] = [:]

    private var pendingCommands = FrameCommandPackage()
    private var submittedCommands: FrameCommandPackage? = nil
    private var hasFrameToRender = false
    private var frameSnapshot = RendererFrameSnapshot()

    public init?(
        device: MTLDevice? = MTLCreateSystemDefaultDevice(),
        configuration: RendererConfiguration = RendererConfiguration()
    ) {
        guard let device, let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        self.device = device
        self.commandQueue = commandQueue
        self.configuration = configuration
        self.fallbackPipelineState = Renderer.makeFallbackPipelineState(device: device)
    }

    public func updateConfiguration(_ configuration: RendererConfiguration) {
        self.configuration = configuration
    }

    public func configure(_ view: MTKView) {
        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.preferredFramesPerSecond = configuration.preferredFramesPerSecond
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        view.clearColor = configuration.clearColor.metal
        view.delegate = self
        configuredView = view
    }

    // MARK: Command Lifecycle

    public func beginReceivingCommands() {
        lock.lock()
        pendingCommands = FrameCommandPackage()
        lock.unlock()
    }

    public func endReceivingCommandsAndRenderFrame() {
        lock.lock()
        submittedCommands = pendingCommands
        hasFrameToRender = true
        lastSubmissionIssues = validate(commandPackage: pendingCommands)
        frameSnapshot = RendererFrameSnapshot(
            renderable2DCount: pendingCommands.renderable2D.count,
            renderable3DCount: pendingCommands.renderable3D.count,
            hasCameraCommand: pendingCommands.cameraCommand != nil,
            hasPresentCommand: pendingCommands.presentCommand != nil,
            issues: lastSubmissionIssues
        )
        lock.unlock()

        DispatchQueue.main.async { [weak self] in
            guard let self, let view = self.configuredView else {
                return
            }
            view.setNeedsDisplay(view.bounds)
        }
    }

    // MARK: GPU Resource Upload

    @discardableResult
    public func uploadTexture(bytes: Data, descriptor: TextureUploadDescriptor) -> TextureHandle? {
        guard descriptor.width > 0, descriptor.height > 0 else {
            return nil
        }

        let metalDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: descriptor.pixelFormat,
            width: descriptor.width,
            height: descriptor.height,
            mipmapped: false
        )
        metalDescriptor.usage = [.shaderRead, .renderTarget]

        guard let texture = device.makeTexture(descriptor: metalDescriptor) else {
            return nil
        }

        let bytesPerPixel = 4
        let bytesPerRow = descriptor.width * bytesPerPixel
        if bytes.count >= descriptor.height * bytesPerRow {
            bytes.withUnsafeBytes { rawBuffer in
                if let baseAddress = rawBuffer.baseAddress {
                    texture.replace(
                        region: MTLRegionMake2D(0, 0, descriptor.width, descriptor.height),
                        mipmapLevel: 0,
                        withBytes: baseAddress,
                        bytesPerRow: bytesPerRow
                    )
                }
            }
        }

        lock.lock()
        let handle = TextureHandle(rawValue: nextTextureHandle)
        nextTextureHandle += 1
        textures[handle] = texture
        lock.unlock()
        return handle
    }

    @discardableResult
    public func uploadMesh(
        vertexData: Data,
        indexData: Data? = nil,
        descriptor: MeshUploadDescriptor
    ) -> MeshHandle? {
        guard descriptor.vertexStride > 0 else {
            return nil
        }

        guard let vertexBuffer = device.makeBuffer(bytes: [UInt8](vertexData), length: vertexData.count) else {
            return nil
        }

        var indexBuffer: MTLBuffer? = nil
        var indexCount = 0

        if let indexData {
            indexBuffer = device.makeBuffer(bytes: [UInt8](indexData), length: indexData.count)
            if let indexType = descriptor.indexType {
                switch indexType {
                case .uint16:
                    indexCount = indexData.count / MemoryLayout<UInt16>.size
                case .uint32:
                    indexCount = indexData.count / MemoryLayout<UInt32>.size
                @unknown default:
                    indexCount = 0
                }
            }
        }

        let mesh = MeshGPUResource(
            vertexBuffer: vertexBuffer,
            indexBuffer: indexBuffer,
            indexCount: indexCount,
            descriptor: descriptor
        )

        lock.lock()
        let handle = MeshHandle(rawValue: nextMeshHandle)
        nextMeshHandle += 1
        meshes[handle] = mesh
        lock.unlock()
        return handle
    }

    @discardableResult
    public func uploadMaterial(_ descriptor: MaterialUploadDescriptor) -> MaterialHandle {
        lock.lock()
        let handle = MaterialHandle(rawValue: nextMaterialHandle)
        nextMaterialHandle += 1
        materials[handle] = descriptor
        lock.unlock()
        return handle
    }

    @discardableResult
    public func uploadCamera(_ descriptor: CameraDescriptor) -> CameraHandle {
        lock.lock()
        let handle = CameraHandle(rawValue: nextCameraHandle)
        nextCameraHandle += 1
        cameras[handle] = descriptor
        lock.unlock()
        return handle
    }

    // MARK: Enqueue Commands

    public func enqueueRenderable2D(_ command: Renderable2DCommand) {
        lock.lock()
        pendingCommands.renderable2D.append(command)
        lock.unlock()
    }

    public func enqueueRenderable3D(_ command: Renderable3DCommand) {
        lock.lock()
        pendingCommands.renderable3D.append(command)
        lock.unlock()
    }

    public func enqueueRenderCamera(_ command: RenderCameraCommand) {
        lock.lock()
        pendingCommands.cameraCommand = command
        lock.unlock()
    }

    public func enqueuePresentTexture(_ command: PresentTextureCommand) {
        lock.lock()
        pendingCommands.presentCommand = command
        lock.unlock()
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Resize handling later.
    }

    public func draw(in view: MTKView) {
        lock.lock()
        let shouldRender = hasFrameToRender
        let commands = submittedCommands
        hasFrameToRender = false
        lock.unlock()

        guard shouldRender else {
            return
        }

        guard
            let drawable = view.currentDrawable,
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            return
        }

        renderPassDescriptor.colorAttachments[0].clearColor = configuration.clearColor.metal

        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
            let commands,
            let fallbackPipelineState
        {
            encoder.setRenderPipelineState(fallbackPipelineState)
            let cameraPosition = activeCameraPosition(from: commands)

            for command in commands.renderable3D {
                let projection = projectWorldPosition(position: command.position, cameraPosition: cameraPosition)
                let scale = max(
                    0.02,
                    (command.scale.x + command.scale.y + command.scale.z) / 3 * 0.04 * projection.perspectiveScale
                )
                let rotationZ = yawRadians(from: command.rotation)
                drawFallbackQuad(
                    encoder: encoder,
                    center: projection.clipPosition,
                    halfSize: RendererVector2(x: scale, y: scale),
                    rotationRadians: rotationZ,
                    color: RendererVector4(x: 0.96, y: 0.58, z: 0.18, w: 1.0)
                )
            }

            for command in commands.renderable2D {
                let projection = projectWorldPosition(
                    position: RendererVector3(x: command.position.x, y: command.position.y, z: 0),
                    cameraPosition: cameraPosition
                )
                let halfWidth = max(0.02, command.size.x * command.scale.x * 0.01)
                let halfHeight = max(0.02, command.size.y * command.scale.y * 0.01)
                drawFallbackQuad(
                    encoder: encoder,
                    center: projection.clipPosition,
                    halfSize: RendererVector2(x: halfWidth, y: halfHeight),
                    rotationRadians: 0,
                    color: RendererVector4(x: 0.18, y: 0.78, z: 1.0, w: 1.0)
                )
            }

            if commands.renderable2D.isEmpty, commands.renderable3D.isEmpty, commands.presentCommand != nil {
                drawFallbackQuad(
                    encoder: encoder,
                    center: RendererVector2(x: 0, y: 0),
                    halfSize: RendererVector2(x: 0.15, y: 0.15),
                    rotationRadians: 0,
                    color: RendererVector4(x: 0.45, y: 0.45, z: 0.45, w: 1.0)
                )
            }

            encoder.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    private func validate(commandPackage: FrameCommandPackage) -> [String] {
        var issues: [String] = []

        if let cameraCommand = commandPackage.cameraCommand {
            if cameras[cameraCommand.camera] == nil {
                issues.append("Unknown camera handle: \(cameraCommand.camera.rawValue)")
            }
            if textures[cameraCommand.targetTexture] == nil {
                issues.append("Unknown camera target texture handle: \(cameraCommand.targetTexture.rawValue)")
            }
        }

        if let present = commandPackage.presentCommand {
            if textures[present.texture] == nil {
                issues.append("Unknown present texture handle: \(present.texture.rawValue)")
            }
        }

        for command in commandPackage.renderable2D {
            if textures[command.texture] == nil {
                issues.append("Unknown 2D texture handle: \(command.texture.rawValue)")
            }
        }

        for command in commandPackage.renderable3D {
            if meshes[command.mesh] == nil {
                issues.append("Unknown mesh handle: \(command.mesh.rawValue)")
            }
            if materials[command.material] == nil {
                issues.append("Unknown material handle: \(command.material.rawValue)")
            }
        }

        return issues
    }

    public func updateCamera(_ handle: CameraHandle, descriptor: CameraDescriptor) {
        lock.lock()
        defer { lock.unlock() }
        guard cameras[handle] != nil else {
            return
        }
        cameras[handle] = descriptor
    }

    private static func makeFallbackPipelineState(device: MTLDevice) -> MTLRenderPipelineState? {
        let shader = """
        #include <metal_stdlib>
        using namespace metal;

        struct FallbackVertex {
            float2 position;
            float4 color;
        };

        struct VertexOut {
            float4 position [[position]];
            float4 color;
        };

        vertex VertexOut fallbackVertex(const device FallbackVertex *vertices [[buffer(0)]], uint vid [[vertex_id]]) {
            VertexOut out;
            out.position = float4(vertices[vid].position, 0.0, 1.0);
            out.color = vertices[vid].color;
            return out;
        }

        fragment float4 fallbackFragment(VertexOut in [[stage_in]]) {
            return in.color;
        }
        """

        guard let library = try? device.makeLibrary(source: shader, options: nil),
            let vertex = library.makeFunction(name: "fallbackVertex"),
            let fragment = library.makeFunction(name: "fallbackFragment")
        else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private func activeCameraPosition(from commands: FrameCommandPackage) -> RendererVector3 {
        guard let cameraCommand = commands.cameraCommand,
            let camera = cameras[cameraCommand.camera]
        else {
            return .zero
        }
        return camera.position
    }

    private func projectWorldPosition(
        position: RendererVector3,
        cameraPosition: RendererVector3
    ) -> (clipPosition: RendererVector2, perspectiveScale: Float) {
        let worldScale: Float = 50
        let relativeZ = position.z - cameraPosition.z
        let perspectiveScale = 1 / max(0.35, 1 + relativeZ / 75)
        let x = ((position.x - cameraPosition.x) / worldScale) * perspectiveScale
        let y = ((position.y - cameraPosition.y) / worldScale) * perspectiveScale
        return (
            clipPosition: RendererVector2(x: x, y: y),
            perspectiveScale: perspectiveScale
        )
    }

    private func yawRadians(from rotation: RendererQuaternion) -> Float {
        let siny = 2 * (rotation.w * rotation.z + rotation.x * rotation.y)
        let cosy = 1 - 2 * (rotation.y * rotation.y + rotation.z * rotation.z)
        return atan2(siny, cosy)
    }

    private func drawFallbackQuad(
        encoder: MTLRenderCommandEncoder,
        center: RendererVector2,
        halfSize: RendererVector2,
        rotationRadians: Float,
        color: RendererVector4
    ) {
        let c = cos(rotationRadians)
        let s = sin(rotationRadians)

        func rotate(_ x: Float, _ y: Float) -> RendererVector2 {
            RendererVector2(x: x * c - y * s, y: x * s + y * c)
        }

        let bl = rotate(-halfSize.x, -halfSize.y)
        let br = rotate(halfSize.x, -halfSize.y)
        let tl = rotate(-halfSize.x, halfSize.y)
        let tr = rotate(halfSize.x, halfSize.y)

        let vertices: [FallbackVertex] = [
            FallbackVertex(
                x: center.x + bl.x,
                y: center.y + bl.y,
                red: color.x,
                green: color.y,
                blue: color.z,
                alpha: color.w
            ),
            FallbackVertex(
                x: center.x + br.x,
                y: center.y + br.y,
                red: color.x,
                green: color.y,
                blue: color.z,
                alpha: color.w
            ),
            FallbackVertex(
                x: center.x + tl.x,
                y: center.y + tl.y,
                red: color.x,
                green: color.y,
                blue: color.z,
                alpha: color.w
            ),
            FallbackVertex(
                x: center.x + br.x,
                y: center.y + br.y,
                red: color.x,
                green: color.y,
                blue: color.z,
                alpha: color.w
            ),
            FallbackVertex(
                x: center.x + tr.x,
                y: center.y + tr.y,
                red: color.x,
                green: color.y,
                blue: color.z,
                alpha: color.w
            ),
            FallbackVertex(
                x: center.x + tl.x,
                y: center.y + tl.y,
                red: color.x,
                green: color.y,
                blue: color.z,
                alpha: color.w
            ),
        ]

        encoder.setVertexBytes(
            vertices,
            length: vertices.count * MemoryLayout<FallbackVertex>.stride,
            index: 0
        )
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertices.count)
    }
}

private struct RendererVector4 {
    var x: Float
    var y: Float
    var z: Float
    var w: Float
}
