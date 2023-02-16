//
//  GameWindow.swift
//  DeltaCore
//
//  Created by Riley Testut on 8/11/22.
//  Copyright © 2022 Riley Testut. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#else
import AppKit
public typealias UIView = NSView
public typealias UIViewController = NSViewController
public typealias UIWindow = NSWindow
public typealias UIResponder = NSResponder
public typealias UIApplication = NSApplication
public typealias UIApplicationDelegate = NSApplicationDelegate
public typealias EAGLContext = NSOpenGLContext
public typealias UIAlert = NSAlert
public typealias UICollectionView = NSCollectionView
public typealias UICollectionViewCell = NSCollectionViewItem
public typealias UICollectionViewDelegate = NSCollectionViewDelegate
public typealias UICollectionViewDataSource = NSCollectionViewDataSource
public typealias UICollectionViewFlowLayout = NSCollectionViewFlowLayout
public typealias UITableView = NSTableView
public typealias UITableViewController = NSTableViewViewController
public typealias UICollectionViewController = NSCollectionViewController


public typealias UITableViewCell = NSTableCellView
public typealias UITableViewDelegate = NSTableViewDelegate
public typealias UITableViewDataSource = NSTableViewDataSource
public typealias UIAlertAction = NSActionCell
//public typealias UIAlertAction.Style = NSActionCell.CellType
public typealias UIImage = NSImage
public typealias UIImageView = NSImageView
public typealias UILabel = NSTextField
public typealias UIColor = NSColor
public typealias UILayoutGuide = NSLayoutGuide
public typealias UIGestureRecognizerDelegate = NSGestureRecognizerDelegate
public typealias UITapGestureRecognizer = NSClickGestureRecognizer
public typealias UIEvent = NSEvent
public typealias UIEdgeInsets = NSEdgeInsets
public typealias UIStoryboard = NSStoryboard
public typealias UIStoryboardSegue = NSStoryboardSegue


public class NSTableViewViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
	public var delegate: NSTableViewDelegate? {
		get {
			return tableView.delegate
		}
		set {
			tableView.delegate = newValue
		}
	}

	public var dataSource: NSTableViewDataSource? {
		get {
			return tableView.dataSource
		}
		set {
			tableView.dataSource = newValue
		}
	}

	public var tableView: NSTableView! = {
		let cv: NSTableView = .init()
		cv.delegate = self
		cv.dataSource = self
		return cv
	}()
}

public class NSCollectionViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource {
	public func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		return dataSource.collectionView(collectionView, numberOfItemsInSection: section)
	}

	public func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		return dataSource.collectionView(collectionView, itemForRepresentedObjectAt: indexPath)
	}

	public var delegate: NSCollectionViewDelegate? {
		get {
			return collectionView.delegate
		}
		set {
			collectionView.delegate = newValue
		}
	}

	public var dataSource: NSCollectionViewDataSource {
		get {
			return collectionView.dataSource!
		}
		set {
			collectionView.dataSource = newValue
		}
	}

	public lazy var collectionView: NSCollectionView! = {
		let cv: NSCollectionView = NSCollectionView()
		cv.delegate = self
		cv.dataSource = self
		return cv
	}()
}
#endif
import DeltaTypes

public class GameWindow: UIWindow
{
    override open func _restoreFirstResponder()
    {
        guard #available(iOS 16, *), let firstResponder = self._lastFirstResponder else { return super._restoreFirstResponder() }
#if canImport(UIKit)
        if firstResponder is ControllerView
        {
            // HACK: iOS 16 beta 5 aggressively tries to restore ControllerView as first responder, even when we've explicitly resigned it as first responder.
            // This can result in the keyboard controller randomly appearing even when user is using another app in the foreground with Stage Manager.
            // As a workaround, we just ignore _restoreFirstResponder() calls when ControllerView was the last first responder and manage it ourselves.
            return
        }
#endif
        
        return super._restoreFirstResponder()
    }
}
