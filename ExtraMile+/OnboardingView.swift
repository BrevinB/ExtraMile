//
//  OnboardingView.swift
//  ExtraMile+
//
//  Created on 2/16/26.
//

import SwiftUI
import AuthenticationServices
import Firebase
import CryptoKit

struct OnboardingView: View {
    @AppStorage("loginStatus") private var loginStatus: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("mileageGoal") private var mileageGoal: Int = 365
    @AppStorage("weeklyGoal") private var weeklyGoal: Double = 15.0

    @State private var currentPage = 0
    @State private var selectedGoal: Int = 365

    // Auth state
    @State private var nonce: String?
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var showPaywall: Bool = false

    // Animation state
    @State private var runnerOffset: CGFloat = 0
    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                // Shared background
                LinearGradient(
                    colors: [Color(white: 0.08), Color(white: 0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Road perspective (shared across all pages)
                roadView(width: width, height: height)

                // Paged content
                TabView(selection: $currentPage) {
                    welcomePage
                        .tag(0)

                    goalPage
                        .tag(1)

                    signInPage
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
        }
        .alert(errorMessage, isPresented: $showAlert) { }
        .fullScreenCover(isPresented: $showPaywall) {
            // On dismiss, finish onboarding
            loginStatus = true
            hasCompletedOnboarding = true
        } content: {
            PaywallView()
        }
        .overlay {
            if isLoading {
                LoadingScreen()
            }
        }
        .onAppear {
            // Yellow page dots
            UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.systemYellow
            UIPageControl.appearance().pageIndicatorTintColor = UIColor.systemYellow.withAlphaComponent(0.3)

            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                appeared = true
            }
            withAnimation(
                .easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
            ) {
                runnerOffset = -8
            }
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Runner icon
            ZStack {
                Circle()
                    .fill(.yellow.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 30)

                Image(systemName: "figure.run")
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(.yellow)
                    .offset(y: runnerOffset)
                    .shadow(color: .yellow.opacity(0.4), radius: 16, y: 4)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)
            .padding(.bottom, 32)

            // Branding
            VStack(spacing: 6) {
                Text("ExtraMile")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                RoundedRectangle(cornerRadius: 2)
                    .fill(.yellow)
                    .frame(width: 40, height: 3)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.bottom, 12)

            Text("Every mile counts.")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.bottom, 48)

            // Get Started button
            Button {
                withAnimation {
                    currentPage = 1
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(Color.yellow, in: Capsule())
            .padding(.horizontal, 32)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Page 2: Goal Setup

    private var goalPage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 12) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.yellow)

                Text("Set Your Goal")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Choose a yearly mileage target")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.bottom, 32)

            // Goal preset cards
            VStack(spacing: 12) {
                goalCard(miles: 365, title: "Mile a Day")
                goalCard(miles: 500, title: "500 Mile Club")
                goalCard(miles: 1000, title: "1000 Mile Challenge")
                goalCard(miles: 2026, title: "Year in Miles")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)

            // Continue button
            Button {
                mileageGoal = selectedGoal
                weeklyGoal = Double(selectedGoal) / 52.0
                withAnimation {
                    currentPage = 2
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(Color.yellow, in: Capsule())
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    private func goalCard(miles: Int, title: String) -> some View {
        let isSelected = selectedGoal == miles

        return Button {
            selectedGoal = miles
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(miles) mi")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .yellow : .white.opacity(0.3))
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Page 3: Sign In

    private var signInPage: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 56))
                .foregroundStyle(.yellow)
                .padding(.bottom, 20)

            Text("Sign In")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.bottom, 8)

            Text("Sign in to sync your runs across devices")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 48)

            // Sign In with Apple
            SignInWithAppleButton(.signIn) { request in
                let nonce = randomNonceString()
                self.nonce = nonce
                request.requestedScopes = [.email, .fullName]
                request.nonce = sha256(nonce)
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    loginWithFirebase(authorization)
                case .failure(let error):
                    showError(error.localizedDescription)
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Road

    @ViewBuilder
    private func roadView(width: CGFloat, height: CGFloat) -> some View {
        let roadTopWidth: CGFloat = width * 0.08
        let roadBottomWidth: CGFloat = width * 1.4
        let roadTop: CGFloat = height * 0.08
        let roadBottom: CGFloat = height

        Canvas { context, size in
            var roadPath = Path()
            let centerX = size.width / 2
            roadPath.move(to: CGPoint(x: centerX - roadTopWidth / 2, y: roadTop))
            roadPath.addLine(to: CGPoint(x: centerX + roadTopWidth / 2, y: roadTop))
            roadPath.addLine(to: CGPoint(x: centerX + roadBottomWidth / 2, y: roadBottom))
            roadPath.addLine(to: CGPoint(x: centerX - roadBottomWidth / 2, y: roadBottom))
            roadPath.closeSubpath()

            context.fill(roadPath, with: .linearGradient(
                Gradient(colors: [
                    Color(white: 0.18),
                    Color(white: 0.12)
                ]),
                startPoint: CGPoint(x: centerX, y: roadTop),
                endPoint: CGPoint(x: centerX, y: roadBottom)
            ))

            // Left edge
            var leftEdge = Path()
            leftEdge.move(to: CGPoint(x: centerX - roadTopWidth / 2 + 4, y: roadTop))
            leftEdge.addLine(to: CGPoint(x: centerX - roadBottomWidth / 2 + 20, y: roadBottom))
            context.stroke(leftEdge, with: .color(.white.opacity(0.15)), lineWidth: 2)

            // Right edge
            var rightEdge = Path()
            rightEdge.move(to: CGPoint(x: centerX + roadTopWidth / 2 - 4, y: roadTop))
            rightEdge.addLine(to: CGPoint(x: centerX + roadBottomWidth / 2 - 20, y: roadBottom))
            context.stroke(rightEdge, with: .color(.white.opacity(0.15)), lineWidth: 2)

            // Dashed center line
            let dashCount = 12
            for i in 0..<dashCount {
                let t1 = Double(i) / Double(dashCount)
                let t2 = (Double(i) + 0.45) / Double(dashCount)
                let y1 = roadTop + pow(t1, 1.6) * (roadBottom - roadTop)
                let y2 = roadTop + pow(t2, 1.6) * (roadBottom - roadTop)
                let progress1 = (y1 - roadTop) / (roadBottom - roadTop)
                let progress2 = (y2 - roadTop) / (roadBottom - roadTop)
                let dashWidth1 = 2 + progress1 * 6
                let dashWidth2 = 2 + progress2 * 6
                let opacity = 0.15 + progress1 * 0.45

                var dashPath = Path()
                dashPath.move(to: CGPoint(x: centerX - dashWidth1 / 2, y: y1))
                dashPath.addLine(to: CGPoint(x: centerX + dashWidth1 / 2, y: y1))
                dashPath.addLine(to: CGPoint(x: centerX + dashWidth2 / 2, y: y2))
                dashPath.addLine(to: CGPoint(x: centerX - dashWidth2 / 2, y: y2))
                dashPath.closeSubpath()
                context.fill(dashPath, with: .color(.yellow.opacity(opacity)))
            }
        }
        .ignoresSafeArea()

        RadialGradient(
            colors: [.yellow.opacity(0.2), .clear],
            center: .center,
            startRadius: 0,
            endRadius: 80
        )
        .frame(width: 160, height: 160)
        .position(x: width / 2, y: height * 0.08)
        .blur(radius: 20)
    }

    // MARK: - Loading Screen

    @ViewBuilder
    func LoadingScreen() -> some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            ProgressView()
                .frame(width: 45, height: 45)
                .background(.background, in: .rect(cornerRadius: 5))
        }
    }

    // MARK: - Auth Helpers

    func showError(_ message: String) {
        errorMessage = message
        showAlert.toggle()
        isLoading = false
    }

    func loginWithFirebase(_ authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as?
            ASAuthorizationAppleIDCredential {

            isLoading = true

            guard let nonce else {
                showError("Cannot process your request")
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                showError("Cannot process your request")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                showError("Cannot process your request")
                return
            }
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                              rawNonce: nonce,
                                                              fullName: appleIDCredential.fullName)
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error {
                    showError(error.localizedDescription)
                    return
                }
                isLoading = false
                showPaywall = true
            }
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError(
                "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
            )
        }

        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

#Preview {
    OnboardingView()
}
