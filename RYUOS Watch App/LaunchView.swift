import SwiftUI

struct LaunchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShowingSplash = true

    var body: some View {
        ZStack {
            ContentView()
                .allowsHitTesting(!isShowingSplash)
                .accessibilityHidden(isShowingSplash)

            if isShowingSplash {
                LaunchArtwork()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            // Show once per app launch, not every time the wrist wakes the display.
            do {
                try await Task.sleep(for: .milliseconds(1400))
            } catch {
                return
            }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) {
                isShowingSplash = false
            }
        }
    }
}

private struct LaunchArtwork: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    private let skyBlue = Color(red: 28 / 255, green: 176 / 255, blue: 246 / 255)

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                Image("LaunchDragon")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: geometry.size.width * 0.65,
                           maxHeight: geometry.size.height * 0.62)
                    .scaleEffect(hasAppeared || reduceMotion ? 1 : 0.88)
                    .offset(y: hasAppeared || reduceMotion ? 0 : 5)
                    .accessibilityHidden(true)

                Text("RYUOS")
                    .font(.system(.title, design: .rounded, weight: .heavy))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(skyBlue.ignoresSafeArea())
        .overlay {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .strokeBorder(.white.opacity(0.75), lineWidth: 1.5)
                .padding(4)
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("RYUOS")
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.65, bounce: 0.18)) {
                hasAppeared = true
            }
        }
    }
}

#Preview("Launch artwork") {
    LaunchArtwork()
}

#Preview("Launch transition") {
    LaunchView()
}
