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

public final class Renderer: NSObject, MTKViewDelegate {
    public let device: MTLDevice
    public private(set) var configuration: RendererConfiguration

    private let commandQueue: MTLCommandQueue

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
    }

    public func updateConfiguration(_ configuration: RendererConfiguration) {
        self.configuration = configuration
    }

    public func configure(_ view: MTKView) {
        view.device = device
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth32Float
        view.preferredFramesPerSecond = configuration.preferredFramesPerSecond
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        view.clearColor = configuration.clearColor.metal
        view.delegate = self
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Resize handling later.
    }

    public func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer()
        else { return }

        renderPassDescriptor.colorAttachments[0].clearColor = configuration.clearColor.metal

        if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            encoder.endEncoding()
        }

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
