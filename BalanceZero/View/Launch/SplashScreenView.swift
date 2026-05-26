import SwiftUI

struct SplashScreenView: View {
    let onDismiss: () -> Void
    @State private var visible = false

    var body: some View {
        ZStack {
            Color(hex: "0C1220")
                .ignoresSafeArea()

            RadialGradient(
                colors: [Color(hex: "1e3a8a").opacity(0.45), .clear],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                SplashIconView()

                Text("BalanceZero")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .scaleEffect(visible ? 1 : 0.82)
            .opacity(visible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                visible = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                onDismiss()
            }
        }
    }
}

// MARK: - Icon graphic

private struct SplashIconView: View {
    // Mirrors V1 icon layout at half scale (512 → 256)
    private let d: CGFloat = 256
    private var s: CGFloat { d / 512 }

    var body: some View {
        ZStack {
            // ── Card (back) ──────────────────────────────────────────────
            RoundedRectangle(cornerRadius: 22 * s, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: "002daa"), Color(hex: "2347d8")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(width: 316 * s, height: 200 * s)
                // Top specular highlight
                .overlay(alignment: .top) {
                    Color.white.opacity(0.07)
                        .frame(height: 56 * s)
                }
                // EMV chip
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 4 * s, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(hex: "D4AF37"), Color(hex: "A07800")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 36 * s, height: 28 * s)
                        .padding(.leading, 34 * s)
                        .padding(.top, 37 * s)
                }
                // Balance placeholder bars
                .overlay(alignment: .bottomLeading) {
                    VStack(alignment: .leading, spacing: 8 * s) {
                        RoundedRectangle(cornerRadius: 3 * s)
                            .fill(Color.white.opacity(0.25))
                            .frame(width: 96 * s, height: 8 * s)
                        RoundedRectangle(cornerRadius: 3 * s)
                            .fill(Color.white.opacity(0.16))
                            .frame(width: 62 * s, height: 8 * s)
                    }
                    .padding(.leading, 34 * s)
                    .padding(.bottom, 16 * s)
                }
                .rotationEffect(.degrees(-9))
                .offset(y: (368 - 256) * s)   // card center was at y=368 in 512-canvas

            // ── Zero "0" ring (front) ────────────────────────────────────
            RoundedRectangle(cornerRadius: 80 * s, style: .continuous)
                .stroke(Color.white, lineWidth: 36 * s)
                .frame(width: 160 * s, height: 224 * s)
                .offset(y: (186 - 256) * s)   // zero center was at y=186 in 512-canvas
        }
        .frame(width: d, height: d)
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView(onDismiss: {})
}
