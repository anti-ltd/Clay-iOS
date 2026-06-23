/**
 Aquarium block — a living-water decoration drawn entirely from vector art:
 hand-built fish (clownfish, blue tang, pufferfish) with gradient bodies, fins,
 stripes and eyes swim across bright glassy water above a reef of seaweed,
 coral and rocks. No bitmap assets — every creature is SwiftUI `Path` geometry,
 so it stays crisp at any widget size and themes with the scene.

 Two animation seams, because the two hosts differ wildly in capability:

 - **In-app preview** runs an internal `TimelineView(.animation)`, so the fish
   swim continuously (tails flick), and a tap makes them dart. Pure
   presentation.
 - **Home-screen widget** can't animate continuously, so it's *interactive*:
   the whole tank is a `Button(intent:)`. A tap fires `AquariumSwimIntent`,
   which bumps a per-tank "swim phase" persisted in the App Group and reloads
   the widget. The fish are positioned views with stable identity, so WidgetKit
   animates them gliding from their old spots to the new phase-derived spots — a
   real swim, triggered by the tap, without opening the app.

 Everything per-fish is derived deterministically (from the instance id, and in
 the widget also the swim phase) so a tank is reproducible frame to frame.
 */
import SwiftUI
import AppIntents
import WidgetKit
import iUXiOS

public struct AquariumConfig: Codable, Hashable, Sendable {
    /// Water palette: "tropical" | "reef" | "deep" | "sunset".
    public var scene: String
    /// 1…8 fish (scaled per family at render time).
    public var fishCount: Int
    public var showsBubbles: Bool
    /// Bottom-of-tank reef (seaweed / coral / rocks). Field kept named
    /// `showsPlants` for config back-compat with earlier recipes.
    public var showsPlants: Bool

    public init(
        scene: String = "tropical",
        fishCount: Int = 4,
        showsBubbles: Bool = true,
        showsPlants: Bool = true
    ) {
        self.scene = scene
        self.fishCount = fishCount
        self.showsBubbles = showsBubbles
        self.showsPlants = showsPlants
    }
}

public enum AquariumBlock: BlockModule {
    public static let kind = BlockKind.aquarium
    public static let displayName = "Aquarium"
    public static let systemImage = "fish"
    public static let defaultConfig = AquariumConfig()
    public static let dataNeeds: Set<DataNeed> = []
    public static let supportedFamilies: Set<WidgetFamilyKey> = [.small, .medium, .large]

    @MainActor
    public static func render(
        config: AquariumConfig,
        style: ResolvedBlockStyle,
        snapshot: BlockDataSnapshot,
        context: BlockRenderContext
    ) -> AnyView {
        AnyView(AquariumBlockView(
            config: config,
            family: context.family,
            seed: context.instanceID.stableSeed,
            instanceID: context.instanceID,
            isInWidget: context.isInWidget))
    }

    @MainActor
    public static func configEditor(config: Binding<AquariumConfig>) -> AnyView {
        AnyView(AquariumConfigEditor(config: config))
    }
}

// MARK: - Tap interactivity (widget)

/// Per-tank "swim phase", persisted in the App Group so a widget tap survives
/// the process boundary into the timeline provider's next render.
public enum AquariumState {
    private static var defaults: UserDefaults? { UserDefaults(suiteName: ClayKit.appGroupID) }
    private static func key(_ id: String) -> String { "aquarium.phase.\(id)" }

    public static func phase(_ id: String) -> Int { defaults?.integer(forKey: key(id)) ?? 0 }

    public static func bump(_ id: String) {
        guard let defaults else { return }
        defaults.set(phase(id) &+ 1, forKey: key(id))
    }
}

/// Fired by tapping the tank in a home-screen widget: advances the swim phase
/// and reloads, so the fish re-school. `openAppWhenRun = false` keeps the tap
/// inside the widget instead of launching Clay.
public struct AquariumSwimIntent: AppIntent {
    public static let title: LocalizedStringResource = "Swim"
    public static let openAppWhenRun = false

    @Parameter(title: "Tank")
    public var instanceID: String

    public init() {}
    public init(instanceID: String) { self.instanceID = instanceID }

    public func perform() async throws -> some IntentResult {
        // Just mutate state. WidgetKit auto-refreshes the widget in place after
        // an interactive intent and animates the view diff (the fish glide to
        // their new spots). A manual reloadTimelines would instead rebuild the
        // whole entry, which cross-fades — the fade we're trying to avoid.
        AquariumState.bump(instanceID)
        AnalyticsStore.shared.recordAquariumSwim(tankID: instanceID)
        return .result()
    }
}

// MARK: - Palette

private struct AquariumPalette {
    let waterTop: Color
    let waterMid: Color
    let waterBottom: Color
    let sand: Color

    static func of(_ scene: String) -> AquariumPalette {
        switch scene {
        case "reef":
            AquariumPalette(
                waterTop: Color(red: 0.80, green: 0.97, blue: 0.98),
                waterMid: Color(red: 0.35, green: 0.80, blue: 0.86),
                waterBottom: Color(red: 0.14, green: 0.52, blue: 0.66),
                sand: Color(red: 0.96, green: 0.88, blue: 0.66))
        case "deep":
            AquariumPalette(
                waterTop: Color(red: 0.42, green: 0.66, blue: 0.84),
                waterMid: Color(red: 0.16, green: 0.36, blue: 0.62),
                waterBottom: Color(red: 0.05, green: 0.12, blue: 0.30),
                sand: Color(red: 0.55, green: 0.60, blue: 0.70))
        case "sunset":
            AquariumPalette(
                waterTop: Color(red: 1.00, green: 0.88, blue: 0.74),
                waterMid: Color(red: 0.96, green: 0.62, blue: 0.52),
                waterBottom: Color(red: 0.52, green: 0.32, blue: 0.56),
                sand: Color(red: 0.95, green: 0.80, blue: 0.62))
        default: // tropical
            AquariumPalette(
                waterTop: Color(red: 0.84, green: 0.95, blue: 1.00),
                waterMid: Color(red: 0.46, green: 0.78, blue: 0.96),
                waterBottom: Color(red: 0.20, green: 0.52, blue: 0.82),
                sand: Color(red: 0.97, green: 0.90, blue: 0.70))
        }
    }
}

// MARK: - Fish species (vector art recipes)

private struct FishSpecies {
    var aspect: Double          // body height / length
    var body: [Color]           // vertical gradient, top → bottom
    var tailColor: Color
    var finColor: Color
    var stripes: [Double]       // x-centres as fraction of length (−0.4…0.4); empty = none
    var stripeColor: Color
    var stripeOutline: Color
    var spiky: Bool             // pufferfish

    static let all: [FishSpecies] = [
        // Clownfish — orange with white bands.
        FishSpecies(
            aspect: 0.60,
            body: [Color(red: 1.0, green: 0.66, blue: 0.26), Color(red: 0.95, green: 0.40, blue: 0.06)],
            tailColor: Color(red: 0.98, green: 0.46, blue: 0.10),
            finColor: Color(red: 0.97, green: 0.42, blue: 0.08),
            stripes: [0.26, -0.02, -0.28],
            stripeColor: .white,
            stripeOutline: Color(red: 0.25, green: 0.10, blue: 0.02).opacity(0.55),
            spiky: false),
        // Blue tang — deep blue body, yellow tail.
        FishSpecies(
            aspect: 0.70,
            body: [Color(red: 0.30, green: 0.62, blue: 0.98), Color(red: 0.10, green: 0.26, blue: 0.66)],
            tailColor: Color(red: 1.0, green: 0.83, blue: 0.22),
            finColor: Color(red: 1.0, green: 0.83, blue: 0.22),
            stripes: [],
            stripeColor: .clear,
            stripeOutline: .clear,
            spiky: false),
        // Pufferfish — round, yellow, spiky.
        FishSpecies(
            aspect: 0.86,
            body: [Color(red: 1.0, green: 0.86, blue: 0.40), Color(red: 0.92, green: 0.62, blue: 0.14)],
            tailColor: Color(red: 0.95, green: 0.70, blue: 0.20),
            finColor: Color(red: 0.95, green: 0.70, blue: 0.20),
            stripes: [],
            stripeColor: .clear,
            stripeOutline: .clear,
            spiky: true),
    ]
}

// MARK: - Deterministic per-fish parameters

private struct Fish: Identifiable {
    let id: Int
    var band: Double      // 0…1 vertical centre (above the sand)
    var amp: Double       // vertical bob amplitude (fraction of height)
    var bobFreq: Double
    var speed: Double     // signed fraction of width per second
    var size: Double      // body length as fraction of min(w,h)
    var phase: Double
    var startX: Double    // 0…1
    var dartX: Double     // tap-dart horizontal direction (-1…1)
    var dartY: Double     // tap-dart vertical direction (-1…1)
    var species: Int
}

/// Small deterministic LCG so a given seed always yields the same tank.
private struct Seeded {
    var state: UInt64
    init(_ s: UInt64) { state = s == 0 ? 0x9E3779B97F4A7C15 : s }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(UInt64(1) << 53)
    }
    mutating func range(_ lo: Double, _ hi: Double) -> Double { lo + next() * (hi - lo) }
}

// MARK: - Renderer

private struct AquariumBlockView: View {
    let config: AquariumConfig
    let family: WidgetFamilyKey
    let seed: UInt64
    let instanceID: UUID
    let isInWidget: Bool

    /// In-app dart state (interaction only; never touched by the widget path).
    @State private var lastTap: Double?
    @State private var tapSeed: UInt64 = 0

    /// iOS clear / tinted home-screen mode recolours opaque content to a single
    /// luminance tint — a full-bleed water fill would become a white blob. In
    /// any non-fullColor mode we render transparent glass-friendly silhouettes
    /// instead, so the Liquid Glass shows through.
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var accent: Bool { isInWidget && renderingMode != .fullColor }

    private var palette: AquariumPalette { .of(config.scene) }

    private var fishCount: Int {
        let base = max(1, min(8, config.fishCount))
        switch family {
        case .small: return max(1, min(base, 3))
        case .large: return min(base + 2, 10)
        default: return base
        }
    }

    private func fish() -> [Fish] {
        var rng = Seeded(seed)
        let speciesCount = FishSpecies.all.count
        return (0..<fishCount).map { i in
            var dr = Seeded(seed &+ UInt64(i) &* 0x9E3779B1 &+ tapSeed)
            return Fish(
                id: i,
                band: rng.range(0.10, 0.64),
                amp: rng.range(0.02, 0.07),
                bobFreq: rng.range(0.5, 1.2),
                speed: rng.range(0.05, 0.15) * (rng.next() < 0.5 ? -1 : 1),
                size: rng.range(0.10, 0.17),
                phase: rng.range(0, 6.28),
                startX: rng.next(),
                dartX: dr.range(-1, 1),
                dartY: dr.range(-0.7, 0.7),
                species: Int(rng.next() * Double(speciesCount)) % speciesCount)
        }
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            // Subtle rim only in full colour; in clear/tinted mode it reads as
            // an ugly extra frame inside the system's own glass, so drop it.
            .overlay {
                if !accent {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.7), .white.opacity(0.05)],
                                startPoint: .top, endPoint: .bottom),
                            lineWidth: 1)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if isInWidget {
            Button(intent: AquariumSwimIntent(instanceID: instanceID.uuidString)) {
                widgetTank
            }
            .buttonStyle(.plain)
        } else {
            previewTank
        }
    }

    // MARK: In-app preview — continuous swim + tap-to-dart

    private var previewTank: some View {
        GeometryReader { geo in
            let size = geo.size
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    SceneryView(palette: palette, seed: seed, family: family,
                                showsBubbles: config.showsBubbles, showsPlants: config.showsPlants,
                                accent: accent, size: size, t: t)
                    ForEach(fish()) { f in
                        let p = cruisePosition(f, size: size, t: t)
                        let flick = sin(t * 6 + f.phase) * 0.10
                        fishView(species: f.species, len: f.size * min(size.width, size.height),
                                 facingRight: p.facingRight, flick: flick)
                            .position(p.center)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            lastTap = Date().timeIntervalSinceReferenceDate
            tapSeed = tapSeed &+ 0x9E3779B97F4A7C15
            AnalyticsStore.shared.recordAquariumSwim(tankID: instanceID.uuidString)
        }
    }

    // MARK: Widget — static scenery + positioned fish WidgetKit can animate

    private var widgetTank: some View {
        let phase = AquariumState.phase(instanceID.uuidString)
        return GeometryReader { geo in
            let size = geo.size
            ZStack {
                SceneryView(palette: palette, seed: seed, family: family,
                            showsBubbles: config.showsBubbles, showsPlants: config.showsPlants,
                            accent: accent, size: size, t: 0)
                ForEach(fish()) { f in
                    let spot = schoolPosition(f, size: size, phase: phase)
                    // Face the way it's actually swimming: compare to where it
                    // was last phase so the glide and the heading agree.
                    let prev = schoolPosition(f, size: size, phase: phase - 1)
                    let facingRight = spot.center.x >= prev.center.x
                    fishView(species: f.species, len: f.size * min(size.width, size.height),
                             facingRight: facingRight, flick: 0.05)
                        .position(spot.center)
                }
            }
            .animation(.spring(response: 0.9, dampingFraction: 0.7), value: phase)
        }
    }

    // MARK: Fish view

    /// One vector fish as a self-contained view so WidgetKit can animate its
    /// `.position` between snapshots (the glide that reads as swimming).
    private func fishView(species: Int, len: Double, facingRight: Bool, flick: Double) -> some View {
        let spec = FishSpecies.all[species % FishSpecies.all.count]
        let h = len * spec.aspect
        return Canvas { ctx, canvasSize in
            FishDraw.draw(into: &ctx, spec: spec,
                          center: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
                          len: len, h: h, flick: flick, accent: accent)
        }
        .frame(width: len * 1.7, height: h * 1.9)
        // Fish are drawn facing right; mirror when swimming left. A touch
        // bigger in clear mode so the school has more presence on glass.
        .scaleEffect(x: (facingRight ? 1 : -1) * (accent ? 1.2 : 1), y: accent ? 1.2 : 1)
        .shadow(color: .black.opacity(accent ? 0 : 0.20), radius: len * 0.05, x: 0, y: len * 0.04)
    }

    // MARK: Position maths

    private func swimTopFraction(_ size: CGSize) -> Double { (size.height * 0.82) / size.height }

    /// Continuous cruise position (+ tap dart) for the in-app preview.
    private func cruisePosition(_ f: Fish, size: CGSize, t: Double)
        -> (center: CGPoint, facingRight: Bool)
    {
        let tau = 0.45, burstV = 1.6
        var dashX = 0.0, dashY = 0.0, dashVel = 0.0
        if let tap = lastTap {
            let dt = max(0, t - tap)
            let decay = exp(-dt / tau)
            dashX = f.dartX * burstV * tau * (1 - decay)
            dashY = f.dartY * burstV * tau * (1 - decay) * 0.5
            dashVel = f.dartX * burstV * decay
        }
        let margin = f.size, span = 1 + margin * 2
        var fx = (f.startX + f.speed * t + dashX + margin).truncatingRemainder(dividingBy: span)
        if fx < 0 { fx += span }
        let x = (fx - margin) * size.width
        let band = min(max(f.band + dashY, 0.08), swimTopFraction(size) - 0.06)
        let y = (band + sin(t * f.bobFreq + f.phase) * f.amp) * size.height
        let facingRight = (f.speed + dashVel) >= 0
        return (CGPoint(x: x, y: y), facingRight)
    }

    /// Discrete position for the widget, re-rolled each swim phase. WidgetKit
    /// animates the move from the previous phase's spot to this one.
    private func schoolPosition(_ f: Fish, size: CGSize, phase: Int)
        -> (center: CGPoint, facingRight: Bool)
    {
        var r = Seeded(seed &+ UInt64(f.id) &* 0x9E3779B1 &+ UInt64(bitPattern: Int64(phase)) &* 0xD1B54A32D192ED03)
        let x = r.range(0.12, 0.88) * size.width
        let y = r.range(0.10, swimTopFraction(size) - 0.06) * size.height
        let facingRight = r.next() < 0.5
        return (CGPoint(x: x, y: y), facingRight)
    }
}

// MARK: - Fish vector drawing

private enum FishDraw {
    /// Draws a right-facing fish centred at `center`. Body length `len`, body
    /// height `h`; `flick` (≈ −0.1…0.1) wags the tail.
    static func draw(
        into ctx: inout GraphicsContext, spec: FishSpecies,
        center: CGPoint, len: Double, h: Double, flick: Double, accent: Bool
    ) {
        let cx = center.x, cy = center.y
        func p(_ dx: Double, _ dy: Double) -> CGPoint { CGPoint(x: cx + dx * len, y: cy + dy * h) }

        // In clear/tinted mode the system recolours by luminance, so we draw a
        // white form. Keep a top→bottom gradient (even in accent) so the fish
        // has volume instead of reading as a flat blob.
        let bodyShading: GraphicsContext.Shading = accent
            ? .linearGradient(Gradient(colors: [.white.opacity(0.95), .white.opacity(0.62)]),
                              startPoint: p(0, -0.5), endPoint: p(0, 0.5))
            : .linearGradient(Gradient(colors: spec.body), startPoint: p(0, -0.5), endPoint: p(0, 0.5))
        let tailC: Color = accent ? .white.opacity(0.78) : spec.tailColor
        let finC: Color = accent ? .white.opacity(0.72) : spec.finColor

        // Pufferfish — gentle rounded nubs around the body, not harsh spikes.
        if spec.spiky {
            let rx = 0.42 * len, ry = 0.44 * h
            for i in 0..<10 {
                let a = Double(i) / 10 * 2 * .pi
                let base = CGPoint(x: cx + cos(a) * rx, y: cy + sin(a) * ry)
                let nubR = 0.06 * h
                ctx.fill(Path(ellipseIn: CGRect(x: base.x - nubR, y: base.y - nubR, width: nubR * 2, height: nubR * 2)),
                         with: .color(finC.opacity(accent ? 0.7 : 0.9)))
            }
        }

        // Caudal (tail) fin — a clean fan off a narrow peduncle.
        var tail = Path()
        tail.move(to: p(-0.42, -0.08))
        tail.addLine(to: p(-0.66, -0.30 + flick))
        tail.addQuadCurve(to: p(-0.66, 0.30 + flick), control: p(-0.50, 0.0))
        tail.addLine(to: p(-0.42, 0.08))
        tail.closeSubpath()
        ctx.fill(tail, with: .color(tailC))

        // Dorsal fin (top) — low, smooth arc.
        var dorsal = Path()
        dorsal.move(to: p(0.14, -0.30))
        dorsal.addQuadCurve(to: p(-0.22, -0.26), control: p(-0.04, -0.50))
        dorsal.closeSubpath()
        ctx.fill(dorsal, with: .color(finC.opacity(accent ? 0.7 : 0.9)))

        // Body — an elegant almond: pointed nose, widest mid, narrow peduncle.
        var body = Path()
        body.move(to: p(0.54, 0.0))
        body.addCurve(to: p(-0.42, -0.10), control1: p(0.30, -0.46), control2: p(-0.12, -0.44))
        body.addQuadCurve(to: p(-0.42, 0.10), control: p(-0.50, 0.0))
        body.addCurve(to: p(0.54, 0.0), control1: p(-0.12, 0.44), control2: p(0.30, 0.46))
        body.closeSubpath()
        ctx.fill(body, with: bodyShading)

        // Belly sheen + stripes, clipped to the body (full-colour only).
        if !accent {
            var inner = ctx
            inner.clip(to: body)
            let belly = Path(ellipseIn: CGRect(
                x: cx - 0.30 * len, y: cy + 0.04 * h, width: 0.7 * len, height: 0.5 * h))
            inner.fill(belly, with: .color(.white.opacity(0.18)))
            for sxFrac in spec.stripes {
                let sx = cx + sxFrac * len
                let outline = Path(CGRect(x: sx - 0.075 * len, y: cy - 0.7 * h, width: 0.15 * len, height: 1.4 * h))
                inner.fill(outline, with: .color(spec.stripeOutline))
                let band = Path(CGRect(x: sx - 0.045 * len, y: cy - 0.7 * h, width: 0.09 * len, height: 1.4 * h))
                inner.fill(band, with: .color(spec.stripeColor))
            }
        }

        // Pectoral fin — a small swept blade on the flank.
        var pec = Path()
        pec.move(to: p(0.16, 0.02))
        pec.addQuadCurve(to: p(-0.02, 0.30), control: p(-0.08, 0.10))
        pec.addQuadCurve(to: p(0.16, 0.02), control: p(0.22, 0.20))
        pec.closeSubpath()
        ctx.fill(pec, with: .color(finC.opacity(accent ? 0.55 : 0.8)))

        // Eye near the nose.
        let eye = p(0.34, -0.06)
        let eyeR = 0.16 * h
        if accent {
            // Punch a clean hole so the glass shows through — the strongest
            // "this is a fish" cue in a monochrome silhouette.
            var hole = ctx
            hole.blendMode = .destinationOut
            hole.fill(Path(ellipseIn: CGRect(x: eye.x - eyeR, y: eye.y - eyeR, width: eyeR * 2, height: eyeR * 2)),
                      with: .color(.black))
        } else {
            ctx.fill(Path(ellipseIn: CGRect(x: eye.x - eyeR, y: eye.y - eyeR, width: eyeR * 2, height: eyeR * 2)),
                     with: .color(.white))
            let pupR = eyeR * 0.58
            ctx.fill(Path(ellipseIn: CGRect(x: eye.x - pupR + eyeR * 0.18, y: eye.y - pupR, width: pupR * 2, height: pupR * 2)),
                     with: .color(.black.opacity(0.9)))
            let hiR = eyeR * 0.26
            ctx.fill(Path(ellipseIn: CGRect(x: eye.x - hiR - eyeR * 0.05, y: eye.y - hiR - eyeR * 0.25, width: hiR * 2, height: hiR * 2)),
                     with: .color(.white.opacity(0.95)))
        }
    }
}

// MARK: - Scenery (water, gloss, light shafts, reef, bubbles, sand)

private struct SceneryView: View {
    let palette: AquariumPalette
    let seed: UInt64
    let family: WidgetFamilyKey
    let showsBubbles: Bool
    let showsPlants: Bool
    let accent: Bool
    let size: CGSize
    let t: Double

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height, m = min(w, h)
            let sandTop = h * 0.9

            if !accent {
                // Water — three-stop gradient (bright surface → deep → lighter near sand).
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                    Gradient(stops: [
                        .init(color: palette.waterTop, location: 0.0),
                        .init(color: palette.waterMid, location: 0.45),
                        .init(color: palette.waterBottom, location: 1.0)]),
                    startPoint: CGPoint(x: w / 2, y: 0), endPoint: CGPoint(x: w / 2, y: h)))

                // Surface gloss.
                ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h * 0.4)), with: .linearGradient(
                    Gradient(colors: [.white.opacity(0.45), .white.opacity(0.0)]),
                    startPoint: CGPoint(x: w / 2, y: 0), endPoint: CGPoint(x: w / 2, y: h * 0.4)))

                // Light shafts.
                for i in 0..<3 {
                    let cx = w * (0.2 + 0.3 * Double(i)) + sin(t * 0.2 + Double(i)) * w * 0.04
                    var beam = Path()
                    beam.move(to: CGPoint(x: cx - m * 0.05, y: 0))
                    beam.addLine(to: CGPoint(x: cx + m * 0.05, y: 0))
                    beam.addLine(to: CGPoint(x: cx + m * 0.14, y: sandTop))
                    beam.addLine(to: CGPoint(x: cx - m * 0.14, y: sandTop))
                    beam.closeSubpath()
                    ctx.fill(beam, with: .color(.white.opacity(0.06)))
                }
            } else {
                // Clear/tinted mode: a faint frosted water body so the tank
                // reads as a tank, not empty glass with specks. Low alpha keeps
                // the Liquid Glass showing through.
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                    Gradient(colors: [.white.opacity(0.22), .white.opacity(0.06)]),
                    startPoint: CGPoint(x: w / 2, y: 0), endPoint: CGPoint(x: w / 2, y: h)))
                // Surface highlight band.
                ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h * 0.22)), with: .linearGradient(
                    Gradient(colors: [.white.opacity(0.25), .white.opacity(0.0)]),
                    startPoint: CGPoint(x: w / 2, y: 0), endPoint: CGPoint(x: w / 2, y: h * 0.22)))
            }

            // Sand floor — gentle dunes. (Faint glass line in accent mode.)
            var floor = Path()
            floor.move(to: CGPoint(x: 0, y: h))
            floor.addLine(to: CGPoint(x: 0, y: sandTop))
            let humps = 5
            for s in 0...humps {
                let x = w * Double(s) / Double(humps)
                let y = sandTop + sin(Double(s) * 1.3) * m * 0.012
                floor.addLine(to: CGPoint(x: x, y: y))
            }
            floor.addLine(to: CGPoint(x: w, y: h))
            floor.closeSubpath()
            if accent {
                ctx.fill(floor, with: .color(.white.opacity(0.4)))
            } else {
                ctx.fill(floor, with: .linearGradient(
                    Gradient(colors: [palette.sand, palette.sand.opacity(0.78)]),
                    startPoint: CGPoint(x: w / 2, y: sandTop), endPoint: CGPoint(x: w / 2, y: h)))
            }

            // Reef — seaweed, coral, rocks rising from the sand.
            if showsPlants {
                drawReef(into: &ctx, w: w, h: h, m: m, sandTop: sandTop)
            }

            // Bubbles (above the reef).
            if showsBubbles {
                var br = Seeded(seed &* 13 &+ 3)
                let count = family == .small ? 6 : 14
                for _ in 0..<count {
                    let x = br.range(0.05, 0.95) * w
                    let rad = br.range(0.008, 0.022) * m
                    let speed = br.range(0.06, 0.16) * h
                    let off = br.next() * h
                    let raw = off + t * speed
                    let y = h - raw.truncatingRemainder(dividingBy: h + rad * 2) + rad
                    let wob = sin(t * 2 + off) * m * 0.01
                    let dot = Path(ellipseIn: CGRect(
                        x: x + wob - rad, y: y - rad, width: rad * 2, height: rad * 2))
                    ctx.stroke(dot, with: .color(.white.opacity(0.4)), lineWidth: 1)
                    ctx.fill(dot, with: .color(.white.opacity(0.12)))
                }
            }
        }
    }

    private func drawReef(into ctx: inout GraphicsContext, w: Double, h: Double, m: Double, sandTop: Double) {
        var pr = Seeded(seed &* 7 &+ 11)
        let n = family == .small ? 2 : (family == .large ? 5 : 4)

        for i in 0..<n {
            let x = (((Double(i) + 0.5) / Double(n)) + pr.range(-0.03, 0.03)) * w
            let kind = pr.next()
            if kind < 0.5 {
                // Seaweed — two swaying blades with a green gradient.
                let height = pr.range(0.20, 0.36) * h
                let sway = pr.range(0.7, 1.2)
                for blade in 0..<2 {
                    let bx = x + (Double(blade) - 0.5) * m * 0.05
                    var path = Path()
                    path.move(to: CGPoint(x: bx, y: sandTop))
                    let segs = 8
                    for s in 1...segs {
                        let f = Double(s) / Double(segs)
                        let y = sandTop - height * f
                        let xx = bx + sin(t * sway + f * 3.0 + Double(blade)) * (m * 0.05) * f
                        path.addLine(to: CGPoint(x: xx, y: y))
                    }
                    let weedShading: GraphicsContext.Shading = accent
                        ? .color(.white.opacity(0.75))
                        : .linearGradient(
                            Gradient(colors: [Color(red: 0.10, green: 0.55, blue: 0.35),
                                              Color(red: 0.30, green: 0.78, blue: 0.45)]),
                            startPoint: CGPoint(x: bx, y: sandTop),
                            endPoint: CGPoint(x: bx, y: sandTop - height))
                    ctx.stroke(path, with: weedShading,
                        style: StrokeStyle(lineWidth: m * 0.03, lineCap: .round, lineJoin: .round))
                }
            } else if kind < 0.8 {
                // Coral — a fan of branches.
                let size = pr.range(0.12, 0.18) * m
                let coral = accent ? Color.white.opacity(0.75) : Color(red: 0.96, green: 0.46, blue: 0.55)
                for b in -2...2 {
                    let ang = Double(b) * 0.34 - .pi / 2
                    let tip = CGPoint(x: x + cos(ang) * size, y: sandTop + sin(ang) * size)
                    var br = Path()
                    br.move(to: CGPoint(x: x, y: sandTop))
                    br.addQuadCurve(to: tip, control: CGPoint(x: x + Double(b) * size * 0.18, y: sandTop - size * 0.5))
                    ctx.stroke(br, with: .color(coral), style: StrokeStyle(lineWidth: size * 0.16, lineCap: .round))
                    ctx.fill(Path(ellipseIn: CGRect(x: tip.x - size * 0.1, y: tip.y - size * 0.1, width: size * 0.2, height: size * 0.2)),
                             with: .color(coral.opacity(0.9)))
                }
            } else {
                // Rock.
                let size = pr.range(0.08, 0.13) * m
                let rock = Path(ellipseIn: CGRect(x: x - size, y: sandTop - size * 0.7, width: size * 2, height: size * 1.2))
                let rockShading: GraphicsContext.Shading = accent
                    ? .color(.white.opacity(0.6))
                    : .linearGradient(
                        Gradient(colors: [Color(red: 0.55, green: 0.57, blue: 0.62),
                                          Color(red: 0.34, green: 0.36, blue: 0.42)]),
                        startPoint: CGPoint(x: x, y: sandTop - size), endPoint: CGPoint(x: x, y: sandTop))
                ctx.fill(rock, with: rockShading)
            }
        }
    }
}

// MARK: - Config editor

private struct AquariumConfigEditor: View {
    @Binding var config: AquariumConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OptionChips(
                options: [("Tropical", "tropical"), ("Reef", "reef"),
                          ("Deep", "deep"), ("Sunset", "sunset")],
                selection: $config.scene)
                .padding(.vertical, UX.rowVPadding)
            Divider()
            HStack {
                Text("Fish")
                Spacer()
                ThemedStepper(value: $config.fishCount, in: 1...8)
            }
            .padding(.vertical, UX.rowVPadding)
            Divider()
            ToggleRow("Bubbles", isOn: $config.showsBubbles)
            Divider()
            ToggleRow(
                "Reef",
                subtitle: "Seaweed, coral & rocks. Tap the tank to make the fish swim — on the home screen too.",
                isOn: $config.showsPlants)
        }
    }
}
