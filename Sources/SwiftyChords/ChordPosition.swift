import Foundation
import CoreGraphics

#if os(macOS)
import AppKit
#else
import UIKit
#endif


// MARK: - ChordPosition
public struct ChordPosition: Codable, Identifiable, Equatable {

    public init(id: UUID = UUID(), frets: [Int], fingers: [Int], baseFret: Int, barres: [Int], capo: Bool? = nil, midi: [Int], key: Chords.Key, suffix: Chords.Suffix) {
        self.id = id
        self.frets = frets
        self.fingers = fingers
        self.baseFret = baseFret
        self.barres = barres
        self.capo = capo
        self.midi = midi
        self.key = key
        self.suffix = suffix
    }

    public var id: UUID = UUID()

    public let frets: [Int]
    public let fingers: [Int]
    public let baseFret: Int
    public let barres: [Int]
    public var capo: Bool?
    public let midi: [Int]
    public let key: Chords.Key
    public let suffix: Chords.Suffix

    static private let numberOfStrings = 6 - 1
    static private let numberOfFrets = 5

    private enum CodingKeys: String, CodingKey {
        case frets, fingers, baseFret, barres, capo, midi, key, suffix
    }

    /// This is THE place to pull out a CAShapeLayer that includes all parts of the chord chart. This is what to use when adding a layer to your UIView/NSView.
    /// - Parameters:
    ///   - rect: The area for which the chord will be drawn to. This determines it's size. Chords have a set aspect ratio, and so the size of the chord will be based on the shortest side of the rect.
    ///   - showFingers: Determines if the finger numbers should be drawn on top of the dots. Default `true`.
    ///   - chordName: Determines if the chord name should be drawn above the chord. Choosing this option will reduce the size of the chord chart slightly to account for the text. Default `true`. The display mode can be set for Key and Suffix. Default  `rawValue`
    ///   - forPrint: If set to `true` the diagram will be colored Black, not matter the users device settings. If set to false, the color of the diagram will match the system label color. Dark text for light mode, and Light text for dark mode. Default `false`.
    ///   - mirror: For lefthanded users. This will flip the chord along its y axis. Default `false`.
    /// - Returns: A CAShapeLayer that can be added as a sublayer to a view, or rendered to an image.
    public func chordLayer(
        rect: CGRect,
        showFingers: Bool = true,
        chordName: Chords.Name = Chords.Name(),
        forPrint: Bool = false,
        mirror: Bool = false,
        showNut: Bool = true,
        displayMode: ChordDisplayMode = .fingers,     // 🆕 NEW: What to show on dots
        tuningOverride: GuitarTuning? = nil           // 🆕 NEW: Runtime tuning override
    ) -> CAShapeLayer {
        return privateLayer(
            rect: rect,
            showFingers: showFingers,
            chordName: chordName,
            forScreen: !forPrint,
            mirror: mirror,
            showNut: showNut,
            displayMode: displayMode,                 // 🆕 Pass through
            tuningOverride: tuningOverride            // 🆕 Pass through
            
        )
    }

    /// Now deprecated. Please see the chordLayer() function.
    /// - Parameters:
    ///   - rect: The area for which the chord will be drawn to. This determines it's size. Chords have a set aspect ratio, and so the size of the chord will be based on the shortest side of the rect.
    ///   - showFingers: Determines if the finger numbers should be drawn on top of the dots. Default `true`.
    ///   - showChordName: Determines if the chord name should be drawn above the chord. Choosing this option will reduce the size of the chord chart slightly to account for the text. Default `true`.
    ///   - forPrint: If set to `true` the diagram will be colored Black, not matter the users device settings. If set to false, the color of the diagram will match the system label color. Dark text for light mode, and Light text for dark mode. Default `false`.
    ///   - mirror: For lefthanded users. This will flip the chord along its y axis. Default `false`.
    /// - Returns: A CAShapeLayer that can be added as a sublayer to a view, or rendered to an image.
    @available(*, deprecated, message: "Chord name can be formatted now.", renamed: "chordLayer")
    public func shapeLayer(rect: CGRect, showFingers: Bool = true, showChordName: Bool = true, forPrint: Bool = false, mirror: Bool = false) -> CAShapeLayer {
        return privateLayer(rect: rect, showFingers: showFingers, chordName: Chords.Name(show: showChordName, key: .raw, suffix: .raw), forScreen: !forPrint, mirror: mirror)
    }

    /// Now deprecated. Please see the chordLayer() function.
    /// - Parameters:
    ///   - rect: The area for which the chord will be drawn to. This determines it's size. Chords have a set aspect ratio, and so the size of the chord will be based on the shortest side of the rect.
    ///   - showFingers: Determines if the finger numbers should be drawn on top of the dots.
    ///   - showChordName: Determines if the chord name should be drawn above the chord. Choosing this option will reduce the size of the chord chart slightly to account for the text.
    ///   - forScreen: This takes care of Dark/Light mode. If it's on device ONLY, set this to true. When adding to a PDF, you'll want to set this to false.
    ///   - mirror: For lefthanded users. This will flip the chord along its y axis.
    /// - Returns: A CAShapeLayer that can be added to a view, or rendered to an image.
    @available(*, deprecated, message: "For screen should have been defaulted to 'true'. Also; chord name can be formatted now.", renamed: "chordLayer")
    public func layer(rect: CGRect, showFingers: Bool, showChordName: Bool, forScreen: Bool, mirror: Bool = false) -> CAShapeLayer {
        return privateLayer(rect: rect, showFingers: showFingers, chordName: Chords.Name(show: showChordName, key: .raw, suffix: .raw), forScreen: forScreen, mirror: mirror)
    }

    // Update the privateLayer method signature and pass parameters to dotsLayer:

    private func privateLayer(
        rect: CGRect,
        showFingers: Bool,
        chordName: Chords.Name,
        forScreen: Bool,
        mirror: Bool = false,
        showNut: Bool = true,
        displayMode: ChordDisplayMode = .fingers,     // 🆕 NEW
        tuningOverride: GuitarTuning? = nil           // 🆕 NEW
    ) -> CAShapeLayer {
        // Determine which tuning to use
        let effectiveTuning = tuningOverride ?? .standard
        let heightMultiplier: CGFloat = chordName.show ? 1.3 : 1.2
        let horScale = rect.height / heightMultiplier
        let scale = min(horScale, rect.width)
        let newHeight = scale * heightMultiplier
        let size = CGSize(width: scale, height: newHeight)

        let stringMargin = size.width / 10
        let fretMargin = size.height / 10

        let fretLength = size.width - (stringMargin * 2)
        let stringLength =
            size.height - (fretMargin * (chordName.show ? 2.8 : 2))
        let origin = CGPoint(
            x: rect.origin.x,
            y: chordName.show ? fretMargin * 1.2 : 0
        )

        let fretSpacing = stringLength / CGFloat(ChordPosition.numberOfFrets)
        let stringSpacing = fretLength / CGFloat(ChordPosition.numberOfStrings)

        let fretConfig = LineConfig(
            spacing: fretSpacing,
            margin: fretMargin,
            length: fretLength,
            count: ChordPosition.numberOfFrets
        )
        let stringConfig = LineConfig(
            spacing: stringSpacing,
            margin: stringMargin,
            length: stringLength,
            count: ChordPosition.numberOfStrings
        )

        
        
        
        let layer = CAShapeLayer()
        let stringsAndFrets = stringsAndFretsLayer(
            fretConfig: fretConfig,
            stringConfig: stringConfig,
            origin: origin,
            forScreen: forScreen,
            showNut: showNut
        )
        let barre = barreLayer(
            fretConfig: fretConfig,
            stringConfig: stringConfig,
            origin: origin,
            showFingers: showFingers,
            forScreen: forScreen,
            displayMode: displayMode
        )
        let dots = dotsLayer(
            stringConfig: stringConfig,
            fretConfig: fretConfig,
            origin: origin,
            showFingers: showFingers,
            forScreen: forScreen,
            rect: rect,
            mirror: mirror,
            displayMode: displayMode,        // 🆕 NEW
            tuning: effectiveTuning          // 🆕 NEW
        )

        layer.addSublayer(stringsAndFrets)
        layer.addSublayer(barre)
        layer.addSublayer(dots)

        if chordName.show {
            let shapeLayer = nameLayer(
                fretConfig: fretConfig,
                origin: origin,
                center: size.width / 2 + origin.x,
                forScreen: forScreen,
                name: chordName
            )
            layer.addSublayer(shapeLayer)
        }

        layer.frame = CGRect(x: 0, y: 0, width: scale, height: newHeight)

        return layer
    }

    private func stringsAndFretsLayer(
        fretConfig: LineConfig,
        stringConfig: LineConfig,
        origin: CGPoint,
        forScreen: Bool,
        showNut: Bool = true
    ) -> CAShapeLayer {
        let layer = CAShapeLayer()
        // 🆕 ADD THIS DEBUG:
            print("🎨 stringsAndFretsLayer: forScreen=\(forScreen)")
        
        let resolvedPrimaryColor: CGColor
        if forScreen {
            // Save current appearance
            let previousAppearance = NSAppearance.current
            
            // Set current appearance for color resolution
            NSAppearance.current = NSApp.effectiveAppearance
            
            // Get the color in the correct appearance context
            let color = NSColor.labelColor.cgColor
            
            // Restore previous appearance
            NSAppearance.current = previousAppearance
            
            resolvedPrimaryColor = color
        } else {
            resolvedPrimaryColor = SWIFTColor.black.cgColor
        }

        // 🆕 ADD THIS DEBUG:
           print("🎨 Raw primaryColor: \(resolvedPrimaryColor)")
           print("🎨 Current appearance: \(NSApp.effectiveAppearance.name)")
           print("🎨 Label color right now: \(NSColor.labelColor)")
        
        print("🎨 stringsAndFretsLayer: forScreen=\(forScreen)")
        print("🎨 NSColor.labelColor: \(NSColor.labelColor)")
        print("🎨 Converted to CGColor: \(NSColor.labelColor.cgColor)")  // 🆕 This is the key!
        print("🎨 Actually using: \(resolvedPrimaryColor)")
        print("🎨 Current appearance: \(NSApp.effectiveAppearance.name)")
        
           
        // Strings
        let stringPath = CGMutablePath()

        for string in 0...stringConfig.count {
            let x =
                stringConfig.spacing * CGFloat(string) + stringConfig.margin
                + origin.x
            stringPath.move(to: CGPoint(x: x, y: fretConfig.margin + origin.y))
            stringPath.addLine(
                to: CGPoint(
                    x: x,
                    y: stringConfig.length + fretConfig.margin + origin.y
                )
            )
        }

        let stringLayer = CAShapeLayer()
        stringLayer.path = stringPath
        stringLayer.lineWidth = stringConfig.spacing / 24
        stringLayer.strokeColor = resolvedPrimaryColor
        layer.addSublayer(stringLayer)

        // Frets
        let fretLayer = CAShapeLayer()

        for fret in 0...fretConfig.count {
            let fretPath = CGMutablePath()
            let lineWidth: CGFloat

            // 🎯 NUT CONTROL LOGIC: Only show thick nut line when showNut is true AND at position 1
            if baseFret == 1 && fret == 0 && showNut {
                lineWidth = fretConfig.spacing / 5  // Thick nut line
            } else {
                lineWidth = fretConfig.spacing / 24  // Regular fret line
            }

            // Draw fret number
            if baseFret != 1 {
                let txtLayer = CAShapeLayer()
                let txtFont = SWIFTFont.systemFont(
                    ofSize: fretConfig.margin * 0.5
                )
                let txtRect = CGRect(
                    x: 0,
                    y: 0,
                    width: stringConfig.margin,
                    height: fretConfig.spacing
                )
                let transX = stringConfig.margin / 5 + origin.x
                let transY =
                    origin.y + (fretConfig.spacing / 2) + fretConfig.margin
                let txtPath = "\(baseFret)".path(
                    font: txtFont,
                    rect: txtRect,
                    position: CGPoint(x: transX, y: transY)
                )
                txtLayer.path = txtPath
                txtLayer.fillColor = resolvedPrimaryColor
                fretLayer.addSublayer(txtLayer)
            }

            let y =
                fretConfig.spacing * CGFloat(fret) + fretConfig.margin
                + origin.y
            let x = origin.x + stringConfig.margin
            fretPath.move(to: CGPoint(x: x, y: y))
            fretPath.addLine(to: CGPoint(x: fretConfig.length + x, y: y))

            let fret = CAShapeLayer()
            fret.path = fretPath
            fret.lineWidth = lineWidth
            fret.lineCap = .square
            fret.strokeColor = resolvedPrimaryColor
            fretLayer.addSublayer(fret)
        }

        layer.addSublayer(fretLayer)

        return layer
    }

    private func nameLayer(fretConfig: LineConfig, origin: CGPoint, center: CGFloat, forScreen: Bool, name: Chords.Name) -> CAShapeLayer {

        //let primaryColor = forScreen ? NSColor.labelColor.cgColor : SWIFTColor.black.cgColor
        //let primaryColor = forScreen ? primaryColor.cgColor : SWIFTColor.black.cgColor

        // REPLACE WITH:
        let primaryColor: CGColor
        if forScreen {
            let previousAppearance = NSAppearance.current
            NSAppearance.current = NSApp.effectiveAppearance
            let color = NSColor.labelColor.cgColor
            NSAppearance.current = previousAppearance
            primaryColor = color
        } else {
            primaryColor = SWIFTColor.black.cgColor
        }
        
        
        
        var displayKey: String {
            switch name.key {
            case .raw:
                return key.rawValue
            case .accessible:
                return key.display.accessible
            case .symbol:
                return key.display.symbol
            }
        }
        var displaySuffix: String {
            switch name.suffix {
            case .raw:
                return suffix.rawValue
            case .short:
                return suffix.display.short
            case .symbolized:
                return suffix.display.symbolized
            case .altSymbol:
                return suffix.display.altSymbol
            }
        }
        let txtFont = SWIFTFont.systemFont(ofSize: fretConfig.margin, weight: .medium)
        let txtRect = CGRect(x: 0, y: 0, width: fretConfig.length, height: fretConfig.margin + origin.y)
        let transY = (origin.y + fretConfig.margin) * 0.35
        let txtPath = (displayKey + " " + displaySuffix).path(font: txtFont, rect: txtRect, position: CGPoint(x: center, y: transY))
        let shape = CAShapeLayer()
        shape.path = txtPath
        shape.fillColor = primaryColor
        return shape
    }

    private func barreLayer(
        fretConfig: LineConfig,
        stringConfig: LineConfig,
        origin: CGPoint,
        showFingers: Bool,
        forScreen: Bool,
        displayMode: ChordDisplayMode = .fingers
    ) -> CAShapeLayer {
        let layer = CAShapeLayer()

        let primaryColor: CGColor
        let backgroundColor: CGColor

        if forScreen {
            // Force appearance context for both colors
            let previousAppearance = NSAppearance.current
            NSAppearance.current = NSApp.effectiveAppearance
            
            let resolvedPrimaryColor = NSColor.labelColor.cgColor
            let resolvedBackgroundColor = NSColor.windowBackgroundColor.cgColor
            
            NSAppearance.current = previousAppearance
            
            primaryColor = resolvedPrimaryColor
            backgroundColor = resolvedBackgroundColor
        } else {
            primaryColor = SWIFTColor.black.cgColor
            backgroundColor = SWIFTColor.white.cgColor
        }

        for barre in barres {
            let barrePath = CGMutablePath()

            // draw barre behind all frets that are above the barre chord
            var startIndex = (frets.firstIndex { $0 == barre } ?? 0)
            let barreFretCount = frets.filter { $0 == barre }.count
            var length = 0

            for index in startIndex..<frets.count {
                let dot = frets[index]
                if dot >= barre {
                    length += 1
                } else if dot < barre && length < barreFretCount {
                    length = 0
                    startIndex = index + 1
                } else {
                    break
                }
            }

            let offset = stringConfig.spacing / 7
            let startingX = CGFloat(startIndex) * stringConfig.spacing + stringConfig.margin + (origin.x + offset)
            let y = CGFloat(barre) * fretConfig.spacing + fretConfig.margin - (fretConfig.spacing / 2) + origin.y

            barrePath.move(to: CGPoint(x: startingX, y: y))

            let endingX = startingX + (stringConfig.spacing * CGFloat(length)) - stringConfig.spacing - (offset * 2)
            barrePath.addLine(to: CGPoint(x: endingX, y: y))

            let barreLayer = CAShapeLayer()
            barreLayer.path = barrePath
            barreLayer.lineCap = .round
            barreLayer.lineWidth = fretConfig.spacing * 0.65
            barreLayer.strokeColor = primaryColor

            layer.addSublayer(barreLayer)

            if showFingers && displayMode != .notesNoOctave && displayMode != .functions && displayMode != .blank {
                let fingerLayer = CAShapeLayer()
                let txtFont = SWIFTFont.systemFont(ofSize: stringConfig.margin, weight: .medium)
                let txtRect = CGRect(x: 0, y: 0, width: stringConfig.spacing, height: fretConfig.spacing)
                let transX = startingX + ((endingX - startingX) / 2)
                let transY = y

                if let fretIndex = frets.firstIndex(of: barre) {
                    let txtPath = "\(fingers[fretIndex])".path(font: txtFont, rect: txtRect, position: CGPoint(x: transX, y: transY))
                    fingerLayer.path = txtPath
                }
                fingerLayer.fillColor = backgroundColor
                layer.addSublayer(fingerLayer)
            }
        }

        return layer
    }

    private func dotsLayer(
        stringConfig: LineConfig,
        fretConfig: LineConfig,
        origin: CGPoint,
        showFingers: Bool,
        forScreen: Bool,
        rect: CGRect,
        mirror: Bool,
        displayMode: ChordDisplayMode = .fingers,     // 🆕 NEW
        tuning: GuitarTuning = .standard              // 🆕 NEW
    ) -> CAShapeLayer {
        
        let layer = CAShapeLayer()

        let primaryColor: CGColor
        let backgroundColor: CGColor

        if forScreen {
            // Force appearance context for both colors
            let previousAppearance = NSAppearance.current
            NSAppearance.current = NSApp.effectiveAppearance
            
            let resolvedPrimaryColor = NSColor.labelColor.cgColor
            let resolvedBackgroundColor = NSColor.windowBackgroundColor.cgColor
            
            NSAppearance.current = previousAppearance
            
            primaryColor = resolvedPrimaryColor
            backgroundColor = resolvedBackgroundColor
        } else {
            primaryColor = SWIFTColor.black.cgColor
            backgroundColor = SWIFTColor.white.cgColor
        }
        
        for index in 0..<frets.count {
            let fret = frets[index]

            // Draw circle above nut ⭕️
            if fret == 0 {
                let size = fretConfig.spacing * 0.33
                let circleX = ((CGFloat(index) * stringConfig.spacing + stringConfig.margin) - size / 2 + origin.x).shouldMirror(mirror, offset: rect.width - size)
                let circleY = fretConfig.margin - size * 1.6 + origin.y

                let center = CGPoint(x: circleX, y: circleY)
                let frame = CGRect(origin: center, size: CGSize(width: size, height: size))

                let circle = CGMutablePath(roundedRect: frame, cornerWidth: frame.width/2, cornerHeight: frame.height/2, transform: nil)

                let circleLayer = CAShapeLayer()
                circleLayer.path = circle
                circleLayer.lineWidth = fretConfig.spacing / 24
                circleLayer.strokeColor = primaryColor
                circleLayer.fillColor = backgroundColor

                layer.addSublayer(circleLayer)

                continue
            }

            // Draw cross above nut ❌
            if fret == -1 {
                let size = fretConfig.spacing * 0.33
                let crossX = ((CGFloat(index) * stringConfig.spacing + stringConfig.margin) - size / 2 + origin.x).shouldMirror(mirror, offset: rect.width - size)
                let crossY = fretConfig.margin - size * 1.6 + origin.y

                let center = CGPoint(x: crossX, y: crossY)
                let frame = CGRect(origin: center, size: CGSize(width: size, height: size))

                let cross = CGMutablePath()

                cross.move(to: CGPoint(x: frame.minX, y: frame.minY))
                cross.addLine(to: CGPoint(x: frame.maxX, y: frame.maxY))

                cross.move(to: CGPoint(x: frame.maxX, y: frame.minY))
                cross.addLine(to: CGPoint(x: frame.minX, y: frame.maxY))

                let crossLayer = CAShapeLayer()
                crossLayer.path = cross
                crossLayer.lineWidth = fretConfig.spacing / 24

                crossLayer.strokeColor = primaryColor

                layer.addSublayer(crossLayer)

                continue
            }

            if barres.contains(fret) {
                // 🆕 NEW: In notes mode, draw individual dots instead of barre
                if displayMode == .notesNoOctave || displayMode == .functions {
                    print("🎯 Drawing individual note dot instead of barre for string \(index + 1)")
                    // DON'T continue - let it fall through to draw individual dot below
                } else {
                    // Original barre logic - skip drawing individual dots
                    if index + 1 < frets.count {
                        let next = index + 1
                        if frets[next] >= fret {
                            continue  // Skip drawing individual dot
                        }
                    }

                    if index - 1 > 0 {
                        let prev = index - 1
                        if frets[prev] >= fret {
                            continue  // Skip drawing individual dot
                        }
                    }
                }
            }

            let dotY = CGFloat(fret) * fretConfig.spacing + fretConfig.margin - (fretConfig.spacing / 2) + origin.y
            let dotX = (CGFloat(index) * stringConfig.spacing + stringConfig.margin + origin.x).shouldMirror(mirror, offset: rect.width)

            let dotPath = CGMutablePath()
            dotPath.addArc(center: CGPoint(x: dotX, y: dotY), radius: fretConfig.spacing * 0.35, startAngle: 0, endAngle: .pi * 2, clockwise: true)

            let dotLayer = CAShapeLayer()
            dotLayer.path = dotPath
            dotLayer.fillColor = primaryColor

            layer.addSublayer(dotLayer)

            // Use display text based on mode
            if showFingers  {
                // Get the display text for this string
                let displayTexts = getDisplayText(mode: displayMode, tuning: tuning)
                let displayText = displayTexts[index] ?? "\(fingers[index])"
                
                // 🆕 DYNAMIC FONT SIZING based on text length and content
                let baseFontSize = stringConfig.margin
                let fontSize: CGFloat
                
                // Adjust font size based on text characteristics
                if displayText.count <= 1 {
                    // Single character (finger numbers, single notes like "C", "E")
                    fontSize = baseFontSize
                } else if displayText.count == 2 && (displayText.contains("♭") || displayText.contains("♯")) {
                    // Accidental notes like "B♭", "F♯"
                    fontSize = baseFontSize * 0.75
                } else if displayText.contains("\n") {
                    // Multi-line text (both mode)
                    fontSize = baseFontSize * 0.6
                } else {
                    // Other cases (shouldn't happen but fallback)
                    fontSize = baseFontSize * 0.8
                }

                let txtFont = SWIFTFont.systemFont(
                    ofSize: fontSize,
                    weight: .medium
                )
                let txtRect = CGRect(
                    x: 0,
                    y: 0,
                    width: stringConfig.spacing,
                    height: fretConfig.spacing
                )

                print("🎵 Display mode: \(displayMode), Text: '\(displayText)', Font size: \(fontSize)")

                let txtPath = displayText.path(
                    font: txtFont,
                    rect: txtRect,
                    position: CGPoint(x: dotX, y: dotY)
                )
                let txtLayer = CAShapeLayer()
                txtLayer.path = txtPath
                txtLayer.fillColor = backgroundColor

                layer.addSublayer(txtLayer)
            }
        }

        return layer
    }

    // 🆕 CHORD THEORY FUNCTIONS - ADD INSIDE ChordPosition STRUCT
        
        /// Get scale degree functions for each string (1, ♭3, 5, ♭7, etc.)
        func getScaleDegrees(tuning: GuitarTuning = .standard) -> [String?] {
            let noteNames = getNoteNamesOnly(tuning: tuning)
            let rootNote = key.display.symbol
            
            return noteNames.map { noteName in
                guard let note = noteName else { return nil }
                return calculateScaleDegree(note: note, root: rootNote, suffix: suffix)
            }
        }
        
        private func calculateScaleDegree(note: String, root: String, suffix: Chords.Suffix) -> String {
            let rootSemitone = noteToSemitone(root)
            let noteSemitone = noteToSemitone(note)
            let interval = (noteSemitone - rootSemitone + 12) % 12
            return intervalToScaleDegree(interval: interval, chordType: suffix)
        }
        
        private func noteToSemitone(_ noteName: String) -> Int {
            let noteMap: [String: Int] = [
                "C": 0, "C♯": 1, "D♭": 1,
                "D": 2, "D♯": 3, "E♭": 3,
                "E": 4,
                "F": 5, "F♯": 6, "G♭": 6,
                "G": 7, "G♯": 8, "A♭": 8,
                "A": 9, "A♯": 10, "B♭": 10,
                "B": 11
            ]
            
            let normalizedNote = noteName
                .replacingOccurrences(of: "#", with: "♯")
                .replacingOccurrences(of: "b", with: "♭")
            
            return noteMap[normalizedNote] ?? 0
        }
        
        private func intervalToScaleDegree(interval: Int, chordType: Chords.Suffix) -> String {
            switch interval {
            case 0: return "R"
            case 1: return "♭2"
            case 2:
                if isExtendedChord(chordType) {
                    return "9"
                } else {
                    return "2"
                }
            case 3:
                if isMinorChord(chordType) || isDiminishedChord(chordType) {
                    return "♭3"
                } else if isExtendedChord(chordType) && hasSharpNine(chordType) {
                    return "♯9"
                } else {
                    return "♯2"
                }
            case 4: return "3"
            case 5:
                if isExtendedChord(chordType) && hasEleventh(chordType) {
                    return "11"
                } else {
                    return "4"
                }
            case 6:
                if isDiminishedChord(chordType) {
                    return "♭5"
                } else if isAugmentedChord(chordType) {
                    return "♯5"
                } else if isExtendedChord(chordType) && hasSharpEleventh(chordType) {
                    return "♯11"
                } else {
                    return "♭5"
                }
            case 7: return "5"
            case 8:
                if isAugmentedChord(chordType) {
                    return "♯5"
                } else {
                    return "♭6"
                }
            case 9:
                if isExtendedChord(chordType) && hasThirteenth(chordType) {
                    return "13"
                } else {
                    return "6"
                }
            case 10:
                if hasSeventh(chordType) {
                    return "♭7"
                } else if isExtendedChord(chordType) && hasFlatNine(chordType) {
                    return "♭9"
                } else {
                    return "♯6"
                }
            case 11:
                if hasMajorSeventh(chordType) {
                    return "7"
                } else {
                    return "♭7"
                }
            default: return "?"
            }
        }
        
        // MARK: - Helper Functions
        
        private func isMinorChord(_ suffix: Chords.Suffix) -> Bool {
            return suffix.group == .minor
        }
        
        private func isDiminishedChord(_ suffix: Chords.Suffix) -> Bool {
            return suffix.group == .diminished
        }
        
        private func isAugmentedChord(_ suffix: Chords.Suffix) -> Bool {
            return suffix.group == .augmented
        }
        
        private func isExtendedChord(_ suffix: Chords.Suffix) -> Bool {
            switch suffix {
            case .nine, .augNine, .sevenFlatNine, .sevenSharpNine, .majorNine, .minorNine,
                 .eleven, .nineSharpEleven, .majorEleven, .minorEleven, .minorMajorEleven,
                 .thirteen, .majorThirteen:
                return true
            default:
                return false
            }
        }
        
        private func hasSeventh(_ suffix: Chords.Suffix) -> Bool {
            switch suffix {
            case .seven, .sevenFlatFive, .augSeven, .sevenFlatNine, .sevenSharpNine,
                 .sevenSharpFive, .minorSeven, .minorSevenFlatFive, .minorMajorSeven,
                 .minorMajorSeventFlatFive:
                return true
            default:
                return false
            }
        }
        
        private func hasMajorSeventh(_ suffix: Chords.Suffix) -> Bool {
            switch suffix {
            case .majorSeven, .majorSevenFlatFive, .majorSevenSharpFive,
                 .minorMajorSeven, .minorMajorSeventFlatFive:
                return true
            default:
                return false
            }
        }
        
        private func hasSharpNine(_ suffix: Chords.Suffix) -> Bool {
            return suffix == .sevenSharpNine
        }
        
        private func hasFlatNine(_ suffix: Chords.Suffix) -> Bool {
            return suffix == .sevenFlatNine
        }
        
        private func hasEleventh(_ suffix: Chords.Suffix) -> Bool {
            switch suffix {
            case .eleven, .nineSharpEleven, .majorEleven, .minorEleven, .minorMajorEleven:
                return true
            default:
                return false
            }
        }
        
        private func hasSharpEleventh(_ suffix: Chords.Suffix) -> Bool {
            return suffix == .nineSharpEleven
        }
        
        private func hasThirteenth(_ suffix: Chords.Suffix) -> Bool {
            switch suffix {
            case .thirteen, .majorThirteen:
                return true
            default:
                return false
            }
        }
    
    
}


// MARK: - Guitar Tuning System

public struct GuitarTuning {
    public let name: String
    public let noteNames: [String]  // ["E", "A", "D", "G", "B", "E"]
    
    public init(name: String, noteNames: [String]) {
        self.name = name
        self.noteNames = noteNames
    }
    
    // Add the missing static methods
        static func noteNameToMIDI(_ noteName: String, octave: Int) -> Int {
            let noteValues: [String: Int] = [
                "C": 0, "C♯": 1, "D♭": 1, "D": 2, "D♯": 3, "E♭": 3,
                "E": 4, "F": 5, "F♯": 6, "G♭": 6, "G": 7, "G♯": 8,
                "A♭": 8, "A": 9, "A♯": 10, "B♭": 10, "B": 11
            ]
            let baseNote = noteValues[noteName] ?? 0
            return (octave + 1) * 12 + baseNote
        }
        
        static func defaultOctaveForString(_ stringIndex: Int) -> Int {
            let octaves = [2, 2, 3, 3, 3, 4]  // E2, A2, D3, G3, B3, E4
            return octaves[min(stringIndex, octaves.count - 1)]
        }
        
    
        // Convert note names to MIDI for calculations
        public var midiNotes: [Int] {
            return noteNames.enumerated().map { index, noteName in
            Self.noteNameToMIDI(noteName, octave: Self.defaultOctaveForString(index))
        }
    }
    
    
    
    // MARK: - Preset Tunings
    
    // Standard and Basic Variations
    public static let standard = GuitarTuning(name: "Standard", noteNames: ["E", "A", "D", "G", "B", "E"])
    public static let halfStepDown = GuitarTuning(name: "Half step down", noteNames: ["E♭", "A♭", "D♭", "G♭", "B♭", "E♭"])
    public static let halfStepUp = GuitarTuning(name: "Half step up", noteNames: ["F", "A♯", "D♯", "G♯", "C", "F"])
    public static let fullStepDown = GuitarTuning(name: "Full step down", noteNames: ["D", "G", "C", "F", "A", "D"])
    
    // Drop Tunings
    public static let dropD = GuitarTuning(name: "Drop D", noteNames: ["D", "A", "D", "G", "B", "E"])
    public static let dropC = GuitarTuning(name: "Drop C", noteNames: ["C", "G", "C", "F", "A", "D"])
    public static let dropCSharp = GuitarTuning(name: "Drop C♯", noteNames: ["C♯", "G♯", "C♯", "F♯", "A♯", "D♯"])
    public static let dropCSharpAlt = GuitarTuning(name: "Drop C♯ (Alt)", noteNames: ["C♯", "A", "D", "G", "B", "E"])
    public static let dropB = GuitarTuning(name: "Drop B", noteNames: ["B", "G♭", "B", "E", "A♭", "D♭"])
    public static let dropA = GuitarTuning(name: "Drop A", noteNames: ["A", "E", "A", "D", "G♭", "B"])
    
    // Open Tunings
    public static let openG = GuitarTuning(name: "Open G", noteNames: ["D", "G", "D", "G", "B", "D"])
    public static let openF = GuitarTuning(name: "Open F", noteNames: ["F", "A", "C", "F", "C", "F"])
    public static let openE = GuitarTuning(name: "Open E", noteNames: ["E", "B", "E", "G♯", "B", "E"])
    public static let openD = GuitarTuning(name: "Open D", noteNames: ["D", "A", "D", "F♯", "A", "D"])
    public static let openC = GuitarTuning(name: "Open C", noteNames: ["C", "G", "C", "G", "C", "E"])
    public static let openA = GuitarTuning(name: "Open A", noteNames: ["E", "A", "E", "A", "C♯", "E"])
    
    // Special Tunings
    public static let dadgad = GuitarTuning(name: "DADGAD", noteNames: ["D", "A", "D", "G", "A", "D"])
    
    // Convenience array for picker/menu usage
    public static let allPresets: [GuitarTuning] = [
        .standard,
        .halfStepDown,
        .halfStepUp,
        .fullStepDown,
        .dropD,
        .dropC,
        .dropCSharp,
        .dropCSharpAlt,
        .dropB,
        .dropA,
        .openG,
        .openF,
        .openE,
        .openD,
        .openC,
        .openA,
        .dadgad
    ]

}

extension GuitarTuning: Equatable, Hashable {
    public static func == (lhs: GuitarTuning, rhs: GuitarTuning) -> Bool {
        return lhs.name == rhs.name && lhs.noteNames == rhs.noteNames
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(noteNames)
    }
}

public extension ChordPosition {
    
    /// Get note names with intelligent enharmonic spelling
    func getStringNotes(tuning: GuitarTuning = .standard) -> [String?] {
        // NEW: Determine spelling preference based on chord key and type
        let useFlats = determineAccidentalPreference()
        
        return frets.enumerated().map { stringIndex, fret in
            if fret == -1 {
                return nil  // Muted string
            } else {
                let openStringMIDI = tuning.midiNotes[stringIndex]
                let noteMIDI = openStringMIDI + (baseFret - 1) + fret
                return Self.midiToNoteName(noteMIDI, useFlats: useFlats)  // 🆕 Pass useFlats
            }
        }
    }
    
    
    /// Get note names with music theory-based enharmonic spelling
    func getStringNotes(tuning: GuitarTuning = .standard, useFlats: Bool = false) -> [String?] {
        // 🎯 MUSIC THEORY APPROACH: Base on key signatures
        let intelligentUseFlats: Bool
        
        if useFlats {
            // Explicit override
            intelligentUseFlats = true
        } else {
            // Apply key signature logic based only on the key
            intelligentUseFlats = determineAccidentalPreference()
        }
        
        return frets.enumerated().map { stringIndex, fret in
            if fret == -1 {
                return nil  // Muted string
            } else {
                let openStringMIDI = tuning.midiNotes[stringIndex]
                let noteMIDI = openStringMIDI + (baseFret - 1) + fret
                return Self.midiToNoteName(noteMIDI, useFlats: intelligentUseFlats)
            }
        }
    }

    /// Determine accidental preference based on music theory key signatures
    private func determineAccidentalPreference() -> Bool {
        // Check explicit key preferences first
        switch key {
        // Sharp family keys - always use sharps
        case .g, .d, .a, .e, .b, .fSharp, .cSharp:
            return false // Use sharps
            
        // Flat family keys - always use flats
        case .f, .bFlat, .eFlat, .aFlat, .dFlat, .gFlat:
            return true // Use flats
            
        // Special case: C can be either
        case .c:
            // C major = neutral, C minor = flat family (relative to Eb major)
            return suffix.group == .minor || suffix.group == .diminished
            
        default:
            // Default to sharps for any other cases
            return false
        }
    }
    
    /// Get note names without octave numbers, with intelligent spelling
    func getNoteNamesOnly(tuning: GuitarTuning = .standard, useFlats: Bool = false) -> [String?] {
        return getStringNotes(tuning: tuning, useFlats: useFlats).map { noteName in
            guard let name = noteName else { return nil }
            // Remove octave number (keep just note name)
            return String(name.dropLast(1))
        }
    }
    
    /// Enhanced MIDI to note name conversion with proper enharmonic spelling
    static func midiToNoteName(_ midiNote: Int, useFlats: Bool = false) -> String {
        let noteNames = useFlats ?
            ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"] :
            ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
        
        let noteIndex = midiNote % 12
        let octave = (midiNote / 12) - 1
        return "\(noteNames[noteIndex])\(octave)"
    }
    
    /// Get display text for each string based on mode (with intelligent spelling)
    func getDisplayText(mode: ChordDisplayMode, tuning: GuitarTuning = .standard, useFlats: Bool = false) -> [String?] {
        let noteNames = mode == .notesNoOctave ?
            getNoteNamesOnly(tuning: tuning, useFlats: useFlats) :
            getStringNotes(tuning: tuning, useFlats: useFlats)
        
        return frets.enumerated().map { stringIndex, fret in
            if fret == -1 {
                return nil  // Muted string
            }
            
            switch mode {
            case .fingers:
                return "\(fingers[stringIndex])"
            case .notesNoOctave:
                return noteNames[stringIndex]
            case .functions:
                let scaleDegrees = getScaleDegrees(tuning: tuning)
                return scaleDegrees[stringIndex]
            case .blank:
                return ""  // 🆕 Empty string = plain circle
            //case .both:
            //    if let noteName = noteNames[stringIndex] {
            //        return "\(noteName)\n\(fingers[stringIndex])"
            //    } else {
            //        return "\(fingers[stringIndex])"
            //    }
            }
        }
    }

}

// MARK: - Chord Display Modes and Note Analysis

public enum ChordDisplayMode: String, CaseIterable {
    case fingers = "Fingers"
    case notesNoOctave = "Notes"
    case functions = "Functions"
    case blank = "Blank"
    
    public var description: String {
        return self.rawValue
    }
}

enum NoteRole {
    case root
    case third
    case fifth
    case seventh
    case other
    
    var color: NSColor {
        switch self {
        case .root: return .systemRed
        case .third: return .systemBlue
        case .fifth: return .systemGreen
        case .seventh: return .systemPurple
        case .other: return .labelColor
        }
    }
}

extension ChordPosition {
    
    /// Analyze note roles based on chord key
    func analyzeNoteRoles(tuning: GuitarTuning = .standard) -> [NoteRole?] {
        let noteNames = getNoteNamesOnly(tuning: tuning)
        let rootNote = key.display.symbol.replacingOccurrences(of: "♯", with: "#").replacingOccurrences(of: "♭", with: "b")
        
        return noteNames.map { noteName in
            guard let note = noteName else { return nil }
            
            // Simple note role analysis (can be enhanced)
            let normalizedNote = note.replacingOccurrences(of: "♯", with: "#").replacingOccurrences(of: "♭", with: "b")
            
            if normalizedNote.contains(rootNote) {
                return .root
            }
            
            // TODO: Add more sophisticated interval analysis
            // For now, just mark root notes
            return .other
        }
    }
    
    /// Get display text for each string based on mode
    func getDisplayText(mode: ChordDisplayMode, tuning: GuitarTuning = .standard) -> [String?] {
        let noteNames = mode == .notesNoOctave ?
            getNoteNamesOnly(tuning: tuning) :
            getStringNotes(tuning: tuning)
        
        return frets.enumerated().map { stringIndex, fret in
            if fret == -1 {
                return nil  // Muted string
            }
            
            switch mode {
            case .fingers:
                return "\(fingers[stringIndex])"
            case .notesNoOctave:
                return noteNames[stringIndex]
            case .functions:  // 🆕 ADD THIS CASE!
                let scaleDegrees = getScaleDegrees(tuning: tuning)
                return scaleDegrees[stringIndex]
            case .blank:
                return ""  // 🆕 Empty string = plain circle
            //case .both:
            //    if let noteName = noteNames[stringIndex] {
            //        return "\(noteName)\n\(fingers[stringIndex])"
            //    } else {
            //        return "\(fingers[stringIndex])"
            //    }
            }
        }
    }
}

extension CGFloat {
    func shouldMirror(_ mirror: Bool, offset: CGFloat) -> CGFloat {
        if mirror {
            return self * -1 + offset
        } else {
            return self
        }
    }
}
