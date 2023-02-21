//
//  DeltaMetalView.swift
//
//
//  Created by Joseph Mattiello on 2/21/23.
//

#if os(macOS) || targetEnvironment(macCatalyst)

import Foundation
import Metal
import MetalKit
import os.log
import IOSurface

enum ScalingMode {
	case aspectFit
	case aspectFill
	case stretch
}

enum InterpolationMode {
	case linear
	case nearestNeighbor
}

struct RenderSettings {
	var displaySize = CGSize.zero
	var scalingMode = ScalingMode.aspectFit
	var interpolationMode = InterpolationMode.linear
	var autoRotate = true
	var mirrored = false
}

extension GameViewController { //: PVRenderDelegate {
//	func startRenderingOnAlternateThread() {
//		isRenderingOnAlternateThread = true
//		renderingQueue.async {
//			while self.isRenderingOnAlternateThread {
//				autoreleasepool {
//					[weak self] in
//					guard let self = self else { return }
//					self.update()
//					self.draw()
//					self.didRenderFrameOnAlternateThread()
//				}
//			}
//		}
//	}
	func startRenderingOnAlternateThread() {
		guard let emulatorCore = emulatorCore else {
			fatalError("Shouldn't be here?")
		}
		emulatorCore.videoManager.videoFormat.format = .openGLES

		let bufferSize = emulatorCore.videoManager.viewport.size

		// Setup framebuffer
		if alternateThreadFramebufferBack == 0 {
			glGenFramebuffers(1, &alternateThreadFramebufferBack)
		}
		glBindFramebuffer(GLenum(GL_FRAMEBUFFER), alternateThreadFramebufferBack)

		// Setup color textures to render into
		if alternateThreadColorTextureBack == 0 {
			let width = emulatorCore.preferredRenderingSize.width
			let height = emulatorCore.preferredRenderingSize.height

			if backingIOSurface == nil {
				let dict: [IOSurfacePropertyKey: Any] = [
					IOSurfacePropertyKey.width: NSNumber(value: width),
					IOSurfacePropertyKey.height: NSNumber(value: height),
					IOSurfacePropertyKey.bytesPerElement: NSNumber(value: 4)
				]

				backingIOSurface = .init(properties: dict)
			}
			backingIOSurface?.lock(seed: nil)

			glGenTextures(1, &alternateThreadColorTextureBack)
			glBindTexture(GLenum(GL_TEXTURE_2D), alternateThreadColorTextureBack)

			#if !targetEnvironment(macCatalyst) && !os(macOS)
			EAGLContext.current()?.texImageIOSurface(
				backingIOSurface!,
				target: Int(GLenum(GL_TEXTURE_2D)),
				internalFormat: Int(GL_RGBA),
				width: UInt32(GLsizei(width)),
				height: UInt32(GLsizei(height)),
				format: Int(GLenum(GL_RGBA)),
				type: Int(GLenum(GL_UNSIGNED_BYTE)),
				plane: 0)
			#else
			// TODO: This?
	//        [CAOpenGLLayer layer];
	//        CGLPixelFormatObj *pf;
	//        CGLTexImageIOSurface2D(self.mEAGLContext, GL_TEXTURE_2D, GL_RGBA, width, height, GL_RGBA, GL_UNSIGNED_BYTE, backingIOSurface, 0);
			#endif

			glBindTexture(GLenum(GL_TEXTURE_2D), 0)
			backingIOSurface?.unlock(seed: nil)


			let mtlDesc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: Int(width), height: Int(height), mipmapped: false)
			let device = gameView.metalView.device!
			let unmanaged = Unmanaged.passRetained(backingIOSurface!)
			let iosurfaceRef = unmanaged.toOpaque()
			backingMTLTexture = device.makeTexture(descriptor: mtlDesc, iosurface: iosurfaceRef as! IOSurfaceRef, plane: 0)
			unmanaged.release()
		}
		glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_2D), alternateThreadColorTextureBack, 0)

		// Setup depth buffer
		if alternateThreadDepthRenderbuffer == 0 {
			glGenRenderbuffers(1, &alternateThreadDepthRenderbuffer)
			glBindRenderbuffer(GLenum(GL_RENDERBUFFER), alternateThreadDepthRenderbuffer)
			glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT16), GLsizei(bufferSize.width), GLsizei(bufferSize.height))
			glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), alternateThreadDepthRenderbuffer)
		}

		glViewport(GLint(gameView.bounds.origin.x), GLint(gameView.bounds.origin.y), GLsizei(gameView.bounds.size.width), GLsizei(gameView.bounds.size.height))
	}

	func didRenderFrameOnAlternateThread() {
//		autoreleasepool {
//			if let texture = renderDestination?.texture {
//				commandQueue?.commit()
//
//				let drawable = metalLayer.nextDrawable()
//				let blitEncoder = commandQueue?.makeBlitCommandEncoder()
//
//				blitEncoder?.copy(from: texture,
//								  sourceSlice: 0,
//								  sourceLevel: 0,
//								  sourceOrigin: MTLOriginMake(0, 0, 0),
//								  sourceSize: MTLSizeMake(texture.width, texture.height, texture.depth),
//								  to: drawable!.texture,
//								  destinationSlice: 0,
//								  destinationLevel: 0,
//								  destinationOrigin: MTLOriginMake(0, 0, 0))
//				blitEncoder?.endEncoding()
//
//				metalLayer?.present(drawable!)
//				currentDrawable = drawable
//			}
//		}
	}

}

open class DeltaMetalView: MTKView {
	private let queue: DispatchQueue = DispatchQueue.init(label: "renderQueue", qos: .userInteractive)
	private var hasSuspended: Bool = false
	private let rgbColorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
	private let context: CIContext
	private let commandQueue: MTLCommandQueue
	private var nearestNeighborRendering: Bool
	private var integerScaling: Bool
	private var checkForRedundantFrames: Bool
	private var currentScale: CGFloat = 1.0
	private var viewportOffset: CGPoint = CGPoint.zero
	private var lastDrawableSize: CGSize = CGSize.zero
	private var tNesScreen: CGAffineTransform = CGAffineTransform.identity

	static private let elementLength: Int = 4
	static private let bitsPerComponent: Int = 8
	static private let imageSize: CGSize = CGSize(width: 480, height: 640)

	public init(frame frameRect: CGRect) {
		let dev: MTLDevice = MTLCreateSystemDefaultDevice()!
		let commandQueue = dev.makeCommandQueue()!
		self.context = CIContext.init(mtlCommandQueue: commandQueue, options: [.cacheIntermediates: false])
		self.commandQueue = commandQueue
		self.nearestNeighborRendering = true
		self.checkForRedundantFrames = true
		self.integerScaling = true
		super.init(frame: frameRect, device: dev)
		self.device = dev
		self.autoResizeDrawable = true
		self.drawableSize = DeltaMetalView.imageSize
		self.isPaused = true
		self.enableSetNeedsDisplay = false
		self.framebufferOnly = false
		self.delegate = self
		self.isOpaque = true
		self.clearsContextBeforeDrawing = false
		NotificationCenter.default.addObserver(self, selector: #selector(appResignedActive), name: UIApplication.willResignActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
	}

	required public init(coder: NSCoder) {
		let dev: MTLDevice = MTLCreateSystemDefaultDevice()!
		let commandQueue = dev.makeCommandQueue()!
		self.context = CIContext.init(mtlCommandQueue: commandQueue, options: [.cacheIntermediates: false])
		self.commandQueue = commandQueue
		self.nearestNeighborRendering = true
		self.checkForRedundantFrames = true
		self.integerScaling = true
		super.init(coder: coder)
		self.device = dev
		self.autoResizeDrawable = true
		self.drawableSize = DeltaMetalView.imageSize
		self.isPaused = true
		self.enableSetNeedsDisplay = false
		self.framebufferOnly = false
		self.delegate = self
		self.isOpaque = true
		self.clearsContextBeforeDrawing = false
		NotificationCenter.default.addObserver(self, selector: #selector(appResignedActive), name: UIApplication.willResignActiveNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(appBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)

	}

	
	var buffer: [UInt32] = [UInt32]() {
		didSet {
			guard !self.checkForRedundantFrames || self.drawableSize != self.lastDrawableSize || !self.buffer.elementsEqual(oldValue)
			else {
				return
			}

			self.queue.async { [weak self] in
				self?.draw()
			}
		}
	}
}

extension DeltaMetalView: MTKViewDelegate {
	public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
			// Implement any resizing logic here
	}

	public func draw(in view: MTKView) {
		guard let safeCurrentDrawable = self.currentDrawable,
			  let safeCommandBuffer = self.commandQueue.makeCommandBuffer()
		else {
			return
		}

		let image: CIImage
		let baseImage: CIImage = CIImage(bitmapData: NSData(bytes: &self.buffer, length: 640 * 480 * DeltaMetalView.elementLength) as Data, bytesPerRow: 640 * DeltaMetalView.elementLength, size: DeltaMetalView.imageSize, format: CIFormat.ARGB8, colorSpace: self.rgbColorSpace)

		if self.nearestNeighborRendering {
			image = baseImage.samplingNearest().transformed(by: self.tNesScreen)
		} else {
			image = baseImage.transformed(by: self.tNesScreen)
		}

		let renderDestination = CIRenderDestination(width: Int(self.drawableSize.width), height: Int(self.drawableSize.height), pixelFormat: self.colorPixelFormat, commandBuffer: safeCommandBuffer) {
			() -> MTLTexture in return safeCurrentDrawable.texture
		}

		do {
			_ = try self.context.startTask(toRender: image, to: renderDestination)
		} catch {
			os_log("%@", type: .error, error.localizedDescription)
		}

		safeCommandBuffer.present(safeCurrentDrawable)
		safeCommandBuffer.commit()

		self.lastDrawableSize = self.drawableSize
	}

	@objc private func appResignedActive() {
		self.queue.suspend()
		self.hasSuspended = true
	}

	@objc private func appBecameActive() {
		if self.hasSuspended {
			self.queue.resume()
			self.hasSuspended = false
		}
	}
}

#endif // #if os(macOS) || targetEnvironment(macCatalyst)
