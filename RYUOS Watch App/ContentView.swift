import SwiftUI

private enum RYUOSTheme {
    static let blue = Color(red: 28 / 255, green: 176 / 255, blue: 246 / 255)
    static let navy = Color(red: 7 / 255, green: 24 / 255, blue: 43 / 255)
}

private struct ScreenBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        RYUOSTheme.navy
            .overlay {
                if !reduceTransparency {
                    RadialGradient(
                        colors: [RYUOSTheme.blue.opacity(0.28), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 150
                    )
                }
            }
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

// Keep styling on controls so labels retain their native button semantics.
private struct BrandControl: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var prominent = false

    func body(content: Content) -> some View {
        Group {
            if reduceTransparency {
                content
                    .buttonStyle(.bordered)
                    .background(prominent ? RYUOSTheme.blue : RYUOSTheme.navy, in: Capsule())
                    .overlay {
                        Capsule().strokeBorder(RYUOSTheme.blue, lineWidth: 1)
                            .allowsHitTesting(false)
                    }
            } else if prominent {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        }
        .tint(RYUOSTheme.blue)
        .foregroundStyle(prominent ? RYUOSTheme.navy : .white)
    }
}

private struct ControlLabel: View {
    let title: LocalizedStringKey
    let icon: String
    var large = false
    var prominent = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(prominent ? RYUOSTheme.navy : RYUOSTheme.blue)
                .accessibilityHidden(true)
            Text(title)
        }
            .font(.system(.headline, design: .rounded, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: large ? 48 : 36)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct HomeHeader: View {
    @ScaledMetric(relativeTo: .title2) private var mascotSize = 32

    var body: some View {
        HStack(spacing: 4) {
            Image("RYUOSDragon")
                .resizable()
                .scaledToFit()
                .frame(width: mascotSize, height: mascotSize)
                .accessibilityHidden(true)
            Text("RYUOS")
                .font(.system(.title2, design: .rounded, weight: .heavy))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct HomeRowLabel: View {
    let title: LocalizedStringKey
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(RYUOSTheme.blue)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 44)
    }
}

private struct HomeGlassStyle: ButtonStyle {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 22)
                    .fill(RYUOSTheme.navy)
                    .overlay {
                        if !reduceTransparency {
                            RoundedRectangle(cornerRadius: 22)
                                .fill(
                                    LinearGradient(
                                        colors: [RYUOSTheme.blue.opacity(0.5), RYUOSTheme.blue.opacity(0.07), RYUOSTheme.blue.opacity(0.25)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
            }
            .glassEffect(
                reduceTransparency ? .identity : .regular.tint(RYUOSTheme.blue.opacity(0.15)).interactive(),
                in: .rect(cornerRadius: 22)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        LinearGradient(
                            colors: [RYUOSTheme.blue, .white.opacity(0.55), RYUOSTheme.blue.opacity(0.35), RYUOSTheme.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .allowsHitTesting(false)
            }
            .shadow(color: RYUOSTheme.blue.opacity(reduceTransparency ? 0 : 0.3), radius: 6)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 6) {
                    HomeHeader()

                    NavigationLink {
                        MessengerView()
                    } label: {
                        HomeRowLabel(title: "Messenger", icon: "bubble.left.and.bubble.right.fill")
                    }
                    .buttonStyle(HomeGlassStyle())

                    NavigationLink {
                        TOCFLView()
                    } label: {
                        HomeRowLabel(title: "TOCFL", icon: "character.book.closed.fill")
                    }
                    .buttonStyle(HomeGlassStyle())

                    NavigationLink {
                        MoreAppsView()
                    } label: {
                        HomeRowLabel(title: "More Apps", icon: "square.grid.2x2.fill")
                    }
                    .buttonStyle(HomeGlassStyle())
                }
                .padding(.horizontal, 8)
                .padding(.top, 24)
                .padding(.bottom, 4)
            }
            // Keep only the clock's space instead of the navigation safe-area inset.
            .ignoresSafeArea(.container, edges: .top)
            .contentMargins(.top, 0, for: .scrollContent)
            .background { ScreenBackground() }
            .navigationTitle("")
            .toolbarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .fontDesign(.rounded)
        .foregroundStyle(.white)
        .tint(RYUOSTheme.blue)
        .preferredColorScheme(.dark)
    }
}

private struct PracticeCard {
    let word: String
    let pinyin: String
    let meaning: String
    let alternative: String
    let correctIsFirst: Bool

    static let deck = [
        PracticeCard(word: "通知", pinyin: "tōngzhī", meaning: "to notify", alternative: "to forget", correctIsFirst: true),
        PracticeCard(word: "準備", pinyin: "zhǔnbèi", meaning: "to prepare", alternative: "to travel", correctIsFirst: false),
        PracticeCard(word: "選擇", pinyin: "xuǎnzé", meaning: "to choose", alternative: "to borrow", correctIsFirst: true),
        PracticeCard(word: "練習", pinyin: "liànxí", meaning: "to practice", alternative: "to rest", correctIsFirst: false),
        PracticeCard(word: "完成", pinyin: "wánchéng", meaning: "to finish", alternative: "to begin", correctIsFirst: true)
    ]
}

private struct TOCFLView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var cardIndex = 0
    @State private var selectedFirst: Bool?
    @State private var feedbackTrigger = 0

    private var card: PracticeCard { PracticeCard.deck[cardIndex] }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 10) {
                    Text("\(cardIndex + 1) of \(PracticeCard.deck.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.8))
                        .id("top")

                    FlashcardView(card: card)

                    if let selectedFirst {
                        AnswerFeedback(card: card, isCorrect: selectedFirst == card.correctIsFirst)
                            .transition(.opacity)

                        Button {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                                cardIndex = (cardIndex + 1) % PracticeCard.deck.count
                                self.selectedFirst = nil
                                proxy.scrollTo("top", anchor: .top)
                            }
                        } label: {
                            ControlLabel(
                                title: cardIndex == PracticeCard.deck.count - 1 ? "Practice Again" : "Next",
                                icon: "arrow.right",
                                prominent: true
                            )
                        }
                        .modifier(BrandControl(prominent: true))
                    } else {
                        AnswerButton(title: card.correctIsFirst ? card.meaning : card.alternative) {
                            selectAnswer(first: true)
                        }
                        AnswerButton(title: card.correctIsFirst ? card.alternative : card.meaning) {
                            selectAnswer(first: false)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom)
            }
            .background { ScreenBackground() }
        }
        .navigationTitle("TOCFL")
        .sensoryFeedback(.selection, trigger: feedbackTrigger)
    }

    private func selectAnswer(first: Bool) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
            selectedFirst = first
        }
        feedbackTrigger += 1
    }
}

private struct FlashcardView: View {
    let card: PracticeCard

    var body: some View {
        Text(verbatim: card.word)
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            // An opaque surface keeps the word calm above the decorative glow.
            .background(RYUOSTheme.navy, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct AnswerButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(verbatim: title)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 36)
                .fixedSize(horizontal: false, vertical: true)
        }
        .modifier(BrandControl())
    }
}

private struct AnswerFeedback: View {
    let card: PracticeCard
    let isCorrect: Bool

    var body: some View {
        VStack(spacing: 6) {
            Label(isCorrect ? "Correct" : "Correct answer", systemImage: isCorrect ? "checkmark.circle.fill" : "arrow.uturn.backward.circle")
                .font(.caption.bold())
                .foregroundStyle(RYUOSTheme.blue)
            Text(verbatim: card.pinyin)
                .font(.headline)
            Text(verbatim: card.meaning)
                .font(.body)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct MoreAppsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: "square.grid.2x2")
                    .font(.largeTitle)
                    .foregroundStyle(RYUOSTheme.blue)
                    .accessibilityHidden(true)
                Text("Room for more")
                    .font(.headline.bold())
                Text("Future apps will appear here.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background { ScreenBackground() }
        .navigationTitle("More Apps")
    }
}

#Preview {
    ContentView()
}
