//
//  Settings.swift
//  TubeTender
//
//  Created by Til Blechschmidt on 10.01.19.
//  Copyright © 2019 Til Blechschmidt. All rights reserved.
//

import Foundation

enum Settings: SettingsKit {
    // Quality
    case DefaultQuality
    case MobileQuality
    case HDR
    case HighFPS

    // Playback
    case BackgroundPlayback
    case BackgroundPiP

    // App details
    case AppVersion

    var identifier: String {
        switch self {
        case .AppVersion:
            return "app_version"
        case .DefaultQuality:
            return "quality_default"
        case .MobileQuality:
            return "quality_mobile"
        case .HDR:
            return "quality_hdr"
        case .HighFPS:
            return "quality_highFps"
        case .BackgroundPlayback:
            return "playback_background"
        case .BackgroundPiP:
            return "background_pip"
        }
    }
}

/**
 *  Protocol for the SettingsKit enum
 */
public protocol SettingsKit: CustomStringConvertible {
    /// The identifier string for the Settings preference item
    var identifier: String { get }
}

// SettingsKit enum extension (a/k/a "where the magic happens")
public extension SettingsKit {

    /// Convenience typealias for subscribe() onChange closure
    typealias SettingChangeHandler = (_ newValue: AnyObject?) -> Void

    /// String description of the enum value
    var description: String {

        //guard let value = Self.get(self) else {
        guard let value = self.get() else {
            return "nil"
        }

        return "\(value)"
    }

    /// Local defaults reference
    private var defaults: UserDefaults { return UserDefaults.standard }


    // MARK: - Static Convenience Methods

    /**
     Fetch the current value for a given setting.

     - Parameter setting: The setting to fetch

     - Returns: The current setting value
     */
    static func get(setting: Self) -> AnyObject? {
        return setting.get()
    }

    /**
     Update the value of a given setting.

     - Parameters:
     - setting: The setting to update
     - value:   The value to store for the setting
     */
    static func set<T>(setting: Self, _ value: T) {
        setting.set(value: value)
    }

    /**
     Observe a given setting for changes. The `onChange` closure will be called,
     with the new setting value, whenever the setting value is changed either
     by the user, or progammatically.

     - Parameters:
     - setting:  The setting to observe
     - onChange: The closure to call when the setting's value is updated
     */
    static func subscribe(setting: Self, onChange: @escaping SettingChangeHandler) {
        setting.subscribe(onChange: onChange)
    }

    // MARK: - Instance Methods

    /**
     Fetch the current value for a given setting.

     __This is the instance method that is called by the static convenience method
     in the public API.__

     - Returns: The current setting value
     */
    private func get() -> AnyObject? {
        return defaults.object(forKey: identifier) as AnyObject?
    }

    /**
     Update the value of a given setting.

     > This is the instance method that is called by the static convenience method
     in the public API.

     - Parameter value: The value to store for the setting
     */
    private func set<T>(value: T) {
        if let boolVal = value as? Bool {
            defaults.set(boolVal, forKey: identifier)
        } else if let intVal = value as? Int {
            defaults.set(intVal, forKey: identifier)
        } else /*if let objectVal = value as? AnyObject */{
            defaults.set(value, forKey: identifier)
        }
    }


    /**
     Observe a given setting for changes. The `onChange` closure will be called,
     with the new setting value, whenever the setting value is changed either
     by the user, or progammatically.

     > This is the instance method that is called by the static convenience method
     in the public API.

     - Parameter onChange: The closure to call when the setting's value is updated
     */
    private func subscribe(onChange: @escaping SettingChangeHandler) {
        let center = NotificationCenter.default

        center.addObserver(forName: UserDefaults.didChangeNotification, object: defaults, queue: nil) { (notif) -> Void in
            if let defaults = notif.object as? UserDefaults {
                onChange(defaults.object(forKey: self.identifier) as AnyObject?)
            }
        }
    }

}
