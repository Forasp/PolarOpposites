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
