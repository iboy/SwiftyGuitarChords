//
//  FunctionColorPreferences.swift
//  SwiftyGuitarChords
//
//  Created by Ian Grant on 08/06/2025.
//


import SwiftUI
import SwiftyChords

// MARK: - Function Color Preferences

struct FunctionColorPreferences: Codable {
    var root: ColorSetting = ColorSetting(color: Color(red: 1.0, green: 0.0, blue: 0.0))  // Red
    var second: ColorSetting = ColorSetting()      // Default (clear)
    var third: ColorSetting = ColorSetting()       // Default (clear)
    var fourth: ColorSetting = ColorSetting()      // Default (clear)
    var fifth: ColorSetting = ColorSetting()       // Default (clear)
    var sixth: ColorSetting = ColorSetting()       // Default (clear)
    var seventh: ColorSetting = ColorSetting()     // Default (clear)
    var flatSecond: ColorSetting = ColorSetting()  // Default (clear)
    var flatThird: ColorSetting = ColorSetting()   // Default (clear)
    var flatFifth: ColorSetting = ColorSetting()   // Default (clear)
    var flatSixth: ColorSetting = ColorSetting()   // Default (clear)
    var flatSeventh: ColorSetting = ColorSetting() // Default (clear)
    
    var colorizeEnabled: Bool = false
    
    // MARK: - Presets
    
    static let none = FunctionColorPreferences(colorizeEnabled: false)
    
    static let rootOnly = FunctionColorPreferences(
        root: ColorSetting(color: Color(red: 1.0, green: 0.0, blue: 0.0)),
        colorizeEnabled: true
    )
    
    static let structure = FunctionColorPreferences(
        root: ColorSetting(color: Color(red: 1.0, green: 0.0, blue: 0.0)),      // Red
        fifth: ColorSetting(color: Color(red: 1.0, green: 0.5, blue: 0.0)),     // Orange
        colorizeEnabled: true
    )
    
    static let chordTones = FunctionColorPreferences(
        root: ColorSetting(color: Color(red: 1.0, green: 0.0, blue: 0.0)),      // Red
        third: ColorSetting(color: Color(red: 0.76, green: 0.95, blue: 1.0)),   // Light Blue
        fifth: ColorSetting(color: Color(red: 1.0, green: 0.5, blue: 0.0)),     // Orange
        seventh: ColorSetting(color: Color(red: 0.56, green: 0.79, blue: 1.0)), // Blue
        colorizeEnabled: true
    )
    
    /// Get color for a specific scale degree
    func colorForScaleDegree(_ scaleDegree: String) -> Color? {
        guard colorizeEnabled else { return nil }
        
        switch scaleDegree {
        case "R":
            return root.isEnabled ? root.color : nil
        case "2", "9":
            return second.isEnabled ? second.color : nil
        case "3":
            return third.isEnabled ? third.color : nil
        case "4", "11":
            return fourth.isEnabled ? fourth.color : nil
        case "5":
            return fifth.isEnabled ? fifth.color : nil
        case "6", "13":
            return sixth.isEnabled ? sixth.color : nil
        case "7":
            return seventh.isEnabled ? seventh.color : nil
        case "♭2", "♭9":
            return flatSecond.isEnabled ? flatSecond.color : nil
        case "♭3", "♯9":
            return flatThird.isEnabled ? flatThird.color : nil
        case "♯4", "♭5":
            return flatFifth.isEnabled ? flatFifth.color : nil
        case "♭6", "♭13":
            return flatSixth.isEnabled ? flatSixth.color : nil
        case "♭7":
            return flatSeventh.isEnabled ? flatSeventh.color : nil
        default:
            return nil
        }
    }
}

// MARK: - Color Setting (enables/disables individual colors)

struct ColorSetting: Codable {
    var color: Color
    var isEnabled: Bool
    
    init(color: Color = .clear, isEnabled: Bool = false) {
        self.color = color
        self.isEnabled = isEnabled
    }
    
    init(color: Color) {
        self.color = color
        self.isEnabled = true
    }
}

// MARK: - Color Codable Support

extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let red = try container.decode(Double.self, forKey: .red)
        let green = try container.decode(Double.self, forKey: .green)
        let blue = try container.decode(Double.self, forKey: .blue)
        let alpha = try container.decodeIfPresent(Double.self, forKey: .alpha) ?? 1.0
        
        self.init(red: red, green: green, blue: blue, opacity: alpha)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Extract RGB components
        let uiColor = NSColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        try container.encode(Double(red), forKey: .red)
        try container.encode(Double(green), forKey: .green)
        try container.encode(Double(blue), forKey: .blue)
        try container.encode(Double(alpha), forKey: .alpha)
    }
}
