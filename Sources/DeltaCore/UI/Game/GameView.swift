//
//  GameView.swift
//  DeltaCore
//
//  Created by Riley Testut on 3/16/15.
//  Copyright (c) 2015 Riley Testut. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif
import CoreImage
import AVFoundation
#if targetEnvironment(macCatalyst) || os(macOS)
import OpenGL.GLTypes
import OpenGL.GL3
import OpenGL
import GLUT
import Metal
import MetalKit
#else
import GLKit
#endif

// Create wrapper class to prevent exposing GLKView (and its annoying deprecation warnings) to clients.
#if targetEnvironment(macCatalyst) || os(macOS)
private class GameViewMetalViewDelegate: NSObject, MTKViewDelegate
{
	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		assertionFailure("Do something?")
	}

	func draw(in view: MTKView) {
		self.gameView?.metalView(view)
	}

    weak var gameView: GameView?

    init(gameView: GameView)
    {
        self.gameView = gameView
    }
}
#else
private class GameViewGLKViewDelegate: NSObject, GLKViewDelegate
{
    weak var gameView: GameView?
    
    init(gameView: GameView)
    {
        self.gameView = gameView
    }
    
    func glkView(_ view: GLKView, drawIn rect: CGRect)
    {
        self.gameView?.glkView(view, drawIn: rect)
    }
}
#endif

public enum SamplerMode
{
    case linear
    case nearestNeighbor
}

#if os(macOS)
public extension NSView {
	public func setNeedsLayout() { self.needsLayout = true }
}
#endif

public class GameView: UIView
{
    @NSCopying public var inputImage: CIImage? {
        didSet {
            if self.inputImage?.extent != oldValue?.extent
            {
                DispatchQueue.main.async {
                    self.setNeedsLayout()
                }
            }
            
            self.update()
        }
    }
    
    @NSCopying public var filter: CIFilter? {
        didSet {
            guard self.filter != oldValue else { return }
            self.update()
        }
    }
    
    public var samplerMode: SamplerMode = .nearestNeighbor {
        didSet {
            self.update()
        }
    }
    
    public var outputImage: CIImage? {
        guard let inputImage = self.inputImage else { return nil }
        
        var image: CIImage?
        
        switch self.samplerMode
        {
        case .linear: image = inputImage.samplingLinear()
        case .nearestNeighbor: image = inputImage.samplingNearest()
        }
                
        if let filter = self.filter
        {
            filter.setValue(image, forKey: kCIInputImageKey)
            image = filter.outputImage
        }
        
        return image
    }
    
#if targetEnvironment(macCatalyst) || os(macOS)
	internal let metalView: MTKView
	private lazy var metalViewDelegate = GameViewMetalViewDelegate(gameView: self)
#else
    internal var eaglContext: EAGLContext {
        get { return self.glkView.context }
        set {
            os_unfair_lock_lock(&self.lock)
            defer { os_unfair_lock_unlock(&self.lock) }
            
            self.didLayoutSubviews = false
            
            // For some reason, if we don't explicitly set current EAGLContext to nil, assigning
            // to self.glkView may crash if we've already rendered to a game view.
            EAGLContext.setCurrent(nil)
            
            self.glkView.context = GLContext(api: .openGLES3, sharegroup: newValue.sharegroup)!
            self.context = self.makeContext()
            
            DispatchQueue.main.async {
                // layoutSubviews() must be called after setting self.eaglContext before we can display anything.
                self.setNeedsLayout()
            }
        }
    }
        
    private let glkView: GLKView
    private lazy var glkViewDelegate = GameViewGLKViewDelegate(gameView: self)
#endif
    private lazy var context: CIContext = self.makeContext()
    
    private var lock = os_unfair_lock()
    private var didLayoutSubviews = false
    
    public override init(frame: CGRect)
    {
#if !targetEnvironment(macCatalyst) && !os(macOS)
        let eaglContext = EAGLContext(api: .openGLES3)!
        self.glkView = GLKView(frame: CGRect.zero, context: eaglContext)
		#else
		let device: MTLDevice? = MTLCreateSystemDefaultDevice()
		self.metalView = .init(frame: .zero, device: device)
		#endif
        super.init(frame: frame)
        
        self.initialize()
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
#if !targetEnvironment(macCatalyst) && !os(macOS)
        let eaglContext = EAGLContext(api: .openGLES3)!
        self.glkView = GLKView(frame: CGRect.zero, context: eaglContext)
#else
		let device: MTLDevice? = MTLCreateSystemDefaultDevice()
		self.metalView = .init(frame: .zero, device: device)
#endif
        super.init(coder: aDecoder)
        
        self.initialize()
    }
    
    private func initialize()
    {        
		#if os(macOS) || targetEnvironment(macCatalyst)
		self.metalView.frame = self.bounds
		#if targetEnvironment(macCatalyst)
		self.metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		#else
		self.metalView.autoresizingMask = [.width, .height]
		#endif
		self.metalView.delegate = self.metalViewDelegate
		self.metalView.enableSetNeedsDisplay = false
		self.addSubview(self.metalView)
		#else
        self.glkView.frame = self.bounds
		self.glkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.glkView.delegate = self.glkViewDelegate
        self.glkView.enableSetNeedsDisplay = false
        self.addSubview(self.glkView)
		#endif
    }

	#if os(macOS)
	override public func viewDidMoveToWindow() {
		if let window = self.window {
//			self.metalView.scaleUnitSquare(to: window.screen?.frame.size)
			self.metalView.layer?.contentsScale = window.screen?.backingScaleFactor ?? 1.0
			self.update()
		}
	}

	override public func layoutSubtreeIfNeeded() {
		super.layoutSubtreeIfNeeded()
		self.metalView.isHidden = (self.outputImage == nil)
		self.didLayoutSubviews = true
	}
	#else
    public override func didMoveToWindow()
    {
        if let window = self.window
        {
			#if targetEnvironment(macCatalyst)
			self.metalView.contentScaleFactor = window.screen.scale
			#else
            self.glkView.contentScaleFactor = window.screen.scale
			#endif
			self.update()
        }
    }
    
    public override func layoutSubviews()
    {
        super.layoutSubviews()

#if targetEnvironment(macCatalyst)
		self.metalView.isHidden = (self.outputImage == nil)
#else
		self.glkView.isHidden = (self.outputImage == nil)
#endif

        self.didLayoutSubviews = true
    }
	#endif
}

#if canImport(UIKit)
public extension GameView
{
    func snapshot() -> UIImage?
    {
        // Unfortunately, rendering CIImages doesn't always work when backed by an OpenGLES texture.
        // As a workaround, we simply render the view itself into a graphics context the same size
        // as our output image.
        //
        // let cgImage = self.context.createCGImage(outputImage, from: outputImage.extent)
        
        guard let outputImage = self.outputImage else { return nil }

        let rect = CGRect(origin: .zero, size: outputImage.extent.size)
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
        
        let snapshot = renderer.image { (context) in
#if targetEnvironment(macCatalyst)
			self.metalView.drawHierarchy(in: rect, afterScreenUpdates: false)
#else
			self.glkView.drawHierarchy(in: rect, afterScreenUpdates: false)
#endif
        }
        
        return snapshot
    }
    
    func update(for screen: ControllerSkin.Screen)
    {
        var filters = [CIFilter]()
        
        if let inputFrame = screen.inputFrame
        {
            let cropFilter = CIFilter(name: "CICrop", parameters: ["inputRectangle": CIVector(cgRect: inputFrame)])!
            filters.append(cropFilter)
        }
        
        if let screenFilters = screen.filters
        {
            filters.append(contentsOf: screenFilters)
        }
        
        // Always use FilterChain since it has additional logic for chained filters.
        let filterChain = filters.isEmpty ? nil : FilterChain(filters: filters)
        self.filter = filterChain
    }
}
#endif // UIKit

private extension GameView
{
    func makeContext() -> CIContext
    {
#if targetEnvironment(macCatalyst) || os(macOS)
        //        let context = CIContext(mtlDevice: mtlDevice)
#else
        let context = CIContext(eaglContext: self.glkView.context, options: [.workingColorSpace: NSNull()])
#endif
        return context
    }
    
    func update()
    {
        // Calling display when outputImage is nil may crash for OpenGLES-based rendering.
        guard self.outputImage != nil else { return }
        
        os_unfair_lock_lock(&self.lock)
        defer { os_unfair_lock_unlock(&self.lock) }
        
        // layoutSubviews() must be called after setting self.eaglContext before we can display anything.
        // Otherwise, the app may crash due to race conditions when creating framebuffer from background thread.
        guard self.didLayoutSubviews else { return }

		#if os(macOS) || targetEnvironment(macCatalyst)
		self.metalView.display(self.layer)
		#else
        self.glkView.display()
		#endif
    }
}

private extension GameView
{
#if targetEnvironment(macCatalyst) || os(macOS)
	func metalView(_ view: MTKView)
	{
		glClearColor(0.0, 0.0, 0.0, 1.0)
		glClear(UInt32(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))

		if let outputImage = self.outputImage
		{
			let bounds = CGRect(x: 0, y: 0, width: self.metalView.drawableSize.width, height: self.metalView.drawableSize.height)
			self.context.draw(outputImage, in: bounds, from: outputImage.extent)
		}
	}
#else
    func glkView(_ view: GLKView, drawIn rect: CGRect)
    {
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(UInt32(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        
        if let outputImage = self.outputImage
        {
            let bounds = CGRect(x: 0, y: 0, width: self.glkView.drawableWidth, height: self.glkView.drawableHeight)
            self.context.draw(outputImage, in: bounds, from: outputImage.extent)
        }
    }
#endif
}
