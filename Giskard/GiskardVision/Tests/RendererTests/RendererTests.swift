import Testing
import MetalKit
@testable import Renderer

@Test func updatesRendererConfiguration() {
    let renderer = Renderer(device: MTLCreateSystemDefaultDevice())
    #expect(renderer != nil)
    #expect(renderer?.configuration.clearColor == .purple)

    renderer?.updateConfiguration(.init(clearColor: .init(red: 1, green: 0, blue: 0), preferredFramesPerSecond: 30))
    #expect(renderer?.configuration.clearColor == .init(red: 1, green: 0, blue: 0))
    #expect(renderer?.configuration.preferredFramesPerSecond == 30)
}

@Test func recordsFrameSnapshotForSubmittedCommands() throws {
    let renderer = try #require(Renderer(device: MTLCreateSystemDefaultDevice()))
    let texture = try #require(
        renderer.uploadTexture(
            bytes: Data([255, 255, 255, 255]),
            descriptor: TextureUploadDescriptor(width: 1, height: 1, pixelFormat: .rgba8Unorm)
        )
    )
    let mesh = try #require(
        renderer.uploadMesh(
            vertexData: Data(repeating: 0, count: MemoryLayout<Float>.size * 12),
            indexData: Data(repeating: 0, count: MemoryLayout<UInt16>.size * 6),
            descriptor: MeshUploadDescriptor(vertexStride: MemoryLayout<Float>.size * 3, indexType: .uint16)
        )
    )
    let material = renderer.uploadMaterial(.init())
    let camera = renderer.uploadCamera(.init())

    renderer.beginReceivingCommands()
    renderer.enqueueRenderable2D(
        Renderable2DCommand(
            texture: texture,
            position: RendererVector2(x: 0, y: 0),
            size: RendererVector2(x: 10, y: 10)
        )
    )
    renderer.enqueueRenderable3D(
        Renderable3DCommand(
            mesh: mesh,
            material: material,
            position: RendererVector3(x: 0, y: 0, z: 0),
            rotation: .identity
        )
    )
    renderer.enqueueRenderCamera(
        RenderCameraCommand(camera: camera, targetTexture: texture)
    )
    renderer.enqueuePresentTexture(
        PresentTextureCommand(
            texture: texture,
            destination: RendererRect(x: 0, y: 0, width: 100, height: 100)
        )
    )
    renderer.endReceivingCommandsAndRenderFrame()

    let snapshot = renderer.lastFrameSnapshot
    #expect(snapshot.renderable2DCount == 1)
    #expect(snapshot.renderable3DCount == 1)
    #expect(snapshot.hasCameraCommand)
    #expect(snapshot.hasPresentCommand)
    #expect(snapshot.issues.isEmpty)
}
