//
//  DeltaMetalView.swift
//  
//
//  Created by Joseph Mattiello on 2/21/23.
//

import Foundation
import MetalKit

open class DeltaMetalView: MTKView {
	private var renderer: DeltaRenderer

	required public init(coder: NSCoder) {
		self.renderer = DeltaRenderer()
		super.init(coder: coder)

		self.device = MTLCreateSystemDefaultDevice()
		self.delegate = self.renderer
	}
}

open class DeltaRenderer: NSObject, MTKViewDelegate {
	public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
		// Implement any resizing logic here
	}

	public func draw(in view: MTKView) {
		// Implement your Metal rendering code here
	}
}
