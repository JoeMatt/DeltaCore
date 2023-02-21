	//
	//  DeltaMetalView.swift
	//
	//
	//  Created by Joseph Mattiello on 2/21/23.
	//

import Foundation
import Metal
import MetalKit
import os.log

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
