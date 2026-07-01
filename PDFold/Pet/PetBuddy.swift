import AppKit
import Observation
import SwiftUI

enum PetEvent: CaseIterable {
    case highlight, comment, tag, sign, note, edit, ink, rotate, delete, export, save, addFile, search, greeting
}

enum PetLines {
    static let byEvent: [PetEvent: [String]] = [
        .highlight: ["Highlighted. Future-you will pretend they read the rest.", "That sentence never stood a chance.", "Tip: drag over text, then pick a color — highlights stack, so go easy.", "Yellow again? A classic never fails."],
        .comment: ["A comment — bold of you to leave a paper trail.", "Noted. Literally.", "Tip: tag a comment now and you'll find it in seconds later.", "Sharp feedback. Speaking of which… the dev would love yours 👀"],
        .tag: ["Tagged. Organized people are just tidy worriers with labels.", "Tip: reuse tags and your filters will thank you.", "One tag to rule them all."],
        .sign: ["Signed, sealed — hopefully not regretted.", "That's a legally-adjacent flourish right there.", "Tip: drag to resize the signature before you commit.", "Very official. Your future self approves."],
        .note: ["A sticky note. The Post-it lives on, digitally.", "Tip: notes stay put even after you rearrange pages."],
        .edit: ["Editing a PDF? Bold. They said it couldn't be done.", "Tip: click any text to tweak it in place.", "Rewriting history, one line at a time."],
        .ink: ["Freehand! Bob Ross would be proud.", "Tip: hold steady — undo is one ⌘Z away."],
        .rotate: ["Whoa, the page turned sideways. Better now?", "Tip: rotation applies only to the page you picked."],
        .delete: ["Gone. We don't talk about that page anymore.", "Tip: ⌘Z brings it back if you panic."],
        .export: ["Exported. Go attach it to something important.", "Tip: flatten before sharing so annotations stick."],
        .save: ["Saved. Responsible of you.", "Locked in. Nicely done."],
        .addFile: ["Two PDFs enter, one workspace leaves.", "Tip: drag pages between files to reshuffle."],
        .search: ["Looking for something? Aren't we all.", "Tip: results jump you straight to the page."],
        .greeting: ["Back again? I never left.", "Ready when you are."]
    ]

    static let feedback: [String] = [
        "Psst — PDFold is brand new. The developer would genuinely love your thoughts: umangdhawan97@gmail.com",
        "Enjoying this? Tell the human who made it: umangdhawan97@gmail.com — they read every message.",
        "You've done real work today. Worth a quick note? umangdhawan97@gmail.com"
    ]
}

enum PetBuddyHook {
    static func trigger(_ event: PetEvent) {
        guard isEnabled else { return }
        Task { @MainActor in
            PetBuddy.shared.trigger(event)
        }
    }

    private static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: "petEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "petEnabled")
    }
}

@MainActor @Observable final class PetBuddy {
    static let shared = PetBuddy()

    @ObservationIgnored @AppStorage("petEnabled") var isEnabledStorage = true
    @ObservationIgnored @AppStorage("petTriggerCount") private var triggerCountStorage = 0

    var isEnabled = true {
        didSet { isEnabledStorage = isEnabled }
    }
    var currentMessage: String?
    var isBubbleVisible = false

    let minInterval: TimeInterval = 6
    let displayDuration: TimeInterval = 4.5

    var lastShownAt: Date?
    var lastLine: String?
    var triggerCount = 0 {
        didSet { triggerCountStorage = triggerCount }
    }
    var lastFeedbackAt: Date?
    @ObservationIgnored var dismissWorkItem: DispatchWorkItem?

    private init() {
        isEnabled = isEnabledStorage
        triggerCount = triggerCountStorage
    }

    func trigger(_ event: PetEvent) {
        guard isEnabled else { return }

        let now = Date()
        if let lastShownAt, now.timeIntervalSince(lastShownAt) < minInterval {
            return
        }

        triggerCount += 1
        let shouldShowFeedback = triggerCount.isMultiple(of: 15) &&
            lastFeedbackAt.map { now.timeIntervalSince($0) > 8 * 60 } ?? true

        let sourceLines: [String]
        if shouldShowFeedback {
            sourceLines = PetLines.feedback
            lastFeedbackAt = now
        } else {
            sourceLines = PetLines.byEvent[event] ?? []
        }

        var line = sourceLines.randomElement()
        if line == lastLine, sourceLines.count > 1 {
            line = sourceLines.randomElement()
        }
        guard let selectedLine = line, !selectedLine.isEmpty else { return }

        currentMessage = selectedLine
        isBubbleVisible = true
        lastShownAt = now
        lastLine = selectedLine

        dismissWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.isBubbleVisible = false
            }
        }
        dismissWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration, execute: item)
    }

    func hush() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        isBubbleVisible = false
        currentMessage = nil
    }

    func disable() {
        isEnabled = false
        hush()
    }

    func enable() {
        isEnabled = true
    }
}

struct PetOverlay: View {
    @State private var buddy = PetBuddy.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if buddy.isEnabled {
            VStack(alignment: .trailing, spacing: .dsSM) {
                if buddy.isBubbleVisible, let message = buddy.currentMessage {
                    PetBubble(message: message)
                        .allowsHitTesting(false)
                        .transition(bubbleTransition)
                }
                PetView()
            }
            .animation(reduceMotion ? nil : .spring(response: 0.34, dampingFraction: 0.82), value: buddy.isBubbleVisible)
            .onAppear { buddy.trigger(.greeting) }
        }
    }

    private var bubbleTransition: AnyTransition {
        reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .trailing))
    }
}

struct PetBubble: View {
    let message: String

    private var feedbackURL: URL? {
        guard message.contains("umangdhawan97@gmail.com") else { return nil }
        return URL(string: "mailto:umangdhawan97@gmail.com")
    }

    var body: some View {
        Group {
            if let feedbackURL {
                Link(destination: feedbackURL) {
                    bubbleText
                }
                .buttonStyle(.plain)
            } else {
                bubbleText
            }
        }
        .padding(.horizontal, .dsMD)
        .padding(.vertical, .dsSM)
        .frame(maxWidth: 240, alignment: .leading)
        .background(Color.dsCard, in: RoundedRectangle(cornerRadius: .dsRadiusMd, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: .dsRadiusMd, style: .continuous)
                .strokeBorder(Color.dsSeparator, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
    }

    private var bubbleText: some View {
        Text(message)
            .font(.dsCaption())
            .foregroundStyle(Color.dsTextPrimary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct PetView: View {
    @State private var buddy = PetBuddy.shared
    @State private var isBreathing = false
    @State private var isBouncing = false
    @State private var isPopoverPresented = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldReduceMotion: Bool {
        reduceMotion || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    var body: some View {
        Button {
            isPopoverPresented.toggle()
        } label: {
            petIcon
                .frame(width: 38, height: 38)
                .padding(3)
                .background(Color.dsCard.opacity(0.92), in: RoundedRectangle(cornerRadius: .dsRadiusMd, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: .dsRadiusMd, style: .continuous)
                        .strokeBorder(Color.dsSeparator, lineWidth: 1)
                }
                .opacity(0.85)
                .shadow(color: .black.opacity(0.14), radius: 12, x: 0, y: 5)
                .scaleEffect(scale)
        }
        .buttonStyle(.plain)
        .help("Foldy — your PDFold buddy")
        .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
            VStack(alignment: .leading, spacing: .dsSM) {
                Button("Shush for now") {
                    buddy.hush()
                    isPopoverPresented = false
                }
                Button("Hide Foldy") {
                    buddy.disable()
                    isPopoverPresented = false
                }
                if let feedbackURL {
                    Link("Send Feedback", destination: feedbackURL)
                }
            }
            .padding(.dsMD)
            .background(Color.dsSurface)
        }
        .animation(shouldReduceMotion ? nil : .easeInOut(duration: 3).repeatForever(autoreverses: true), value: isBreathing)
        .animation(shouldReduceMotion ? nil : .spring(response: 0.22, dampingFraction: 0.42), value: isBouncing)
        .onAppear {
            guard !shouldReduceMotion else { return }
            isBreathing = true
        }
        .onChange(of: buddy.currentMessage) { _, _ in
            bounce()
        }
    }

    private var petIcon: some View {
        Group {
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "doc.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.dsAccent)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: .dsRadiusSm, style: .continuous))
    }

    private var feedbackURL: URL? {
        URL(string: "mailto:umangdhawan97@gmail.com")
    }

    private var scale: CGFloat {
        if isBouncing { return 1.12 }
        return isBreathing && !shouldReduceMotion ? 1.045 : 1.0
    }

    private func bounce() {
        guard !shouldReduceMotion else { return }
        isBouncing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [isBreathing] in
            guard self.isBreathing == isBreathing else { return }
            self.isBouncing = false
        }
    }
}
