//
// DLTAMuteSwitchMonitor.swift
// Copyright (c) 2023 Joseph Mattiello
// Based on code from DLTAMuteSwitchMonitor.h
// Copyright © 2020 Riley Testut. All rights reserved.
//

import Foundation
import AudioToolbox
import notify

public final class DLTAMuteSwitchMonitor {

    // MARK: - Singleton

    public static let shared = DLTAMuteSwitchMonitor()

    // MARK: - Public Properties

    public var isMuted: Bool {
        didSet {
            if oldValue != isMuted {
                isMutedChangedHandler?(isMuted)
            }
        }
    }

    public typealias MutedChangedHandler = ((Bool) -> Void)
    public var isMutedChangedHandler: MutedChangedHandler? = nil

    // MARK: - Private Properties

    private var notifyToken: Int32 = 0
    private var isMonitoring = false

    // MARK: - Initializers

    public init(changeHandler : MutedChangedHandler? = nil) {
        self.isMutedChangedHandler = changeHandler
        isMuted = true
    }

    deinit {
    }

    // MARK: - Public Methods

    public func startMonitoring(muteHandler: @escaping (Bool) -> Void) {
        if isMonitoring {
            return
        }
        isMonitoring = true
        isMutedChangedHandler = muteHandler

		weak var weakSelf = self

        func updateMutedState() {
			guard let self = weakSelf else { return }
            var state: UInt64 = 0
            let result = notify_get_state(self.notifyToken, &state)
            guard result == NOTIFY_STATUS_OK else {
                print("Error getting mute switch state: \(result)")
                return
            }

            self.isMuted = state == 0
            isMutedChangedHandler?(self.isMuted)
        }

        notify_register_dispatch("com.apple.springboard.ringerstate", &notifyToken, DispatchQueue.main)
		{ _ in
			guard weakSelf != nil else { return }
            updateMutedState()
        }

        updateMutedState()
    }

    public func stopMonitoring() {
        if !isMonitoring {
            return
        }
        isMonitoring = false
        notify_cancel(self.notifyToken)
    }
}
