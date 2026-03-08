import Testing
import MetalKit
import Renderer
@testable import GiskardEngine

@Test func sceneTickSubmits2DAnd3DCommands() throws {
    let renderer = try #require(Renderer(device: MTLCreateSystemDefaultDevice()))
    let tickSystem = SceneRenderTickSystem(renderer: renderer)
    tickSystem.setEnabled(true)

    let scene = SceneFile(
        sceneName: "Preview",
        entities: [
            SceneEntityNode(
                name: "Camera",
                isPhysical: false,
                position: [0, 0, -25],
                rotation: [0, 0, 0, 1],
                capabilities: ["Camera"]
            ),
            SceneEntityNode(
                name: "Sprite",
                isPhysical: false,
                position: [-8, 4, 0],
                rotation: [0, 0, 0, 1],
                capabilities: ["Renderable2D"]
            ),
            SceneEntityNode(
                name: "Mesh",
                isPhysical: false,
                position: [8, -4, 10],
                rotation: [0, 0, 0, 1],
                capabilities: ["Renderable3D"]
            ),
        ]
    )

    tickSystem.tick(scene: scene, viewportSize: RendererVector2(x: 1280, y: 720))

    let snapshot = renderer.lastFrameSnapshot
    #expect(snapshot.renderable2DCount == 1)
    #expect(snapshot.renderable3DCount == 1)
    #expect(snapshot.hasCameraCommand)
    #expect(snapshot.hasPresentCommand)
    #expect(snapshot.issues.isEmpty)
}

@Test func sceneTickFallsBackToDefaultCameraWhenSceneHasNoCamera() throws {
    let renderer = try #require(Renderer(device: MTLCreateSystemDefaultDevice()))
    let tickSystem = SceneRenderTickSystem(renderer: renderer)
    tickSystem.setEnabled(true)

    let scene = SceneFile(
        sceneName: "No Camera",
        entities: [
            SceneEntityNode(
                name: "Sprite",
                isPhysical: false,
                position: [0, 0, 0],
                rotation: [0, 0, 0, 1],
                capabilities: ["Renderable2D"]
            )
        ]
    )

    tickSystem.tick(scene: scene, viewportSize: RendererVector2(x: 640, y: 480))

    let snapshot = renderer.lastFrameSnapshot
    #expect(snapshot.renderable2DCount == 1)
    #expect(snapshot.renderable3DCount == 0)
    #expect(snapshot.hasCameraCommand)
    #expect(snapshot.hasPresentCommand)
    #expect(snapshot.issues.isEmpty)
}
