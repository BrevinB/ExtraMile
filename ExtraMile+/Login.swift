//
//  Login.swift
//  ExtraMile+
//
//  Created by Brevin Blalock on 6/30/24.
//

import SwiftUI
import AuthenticationServices
import Firebase
import CryptoKit

struct Login: View {

    @Environment(\.colorScheme) private var scheme

    @State private var errorMessage: String = ""
    @State private var nonce: String?
    @State private var showAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var runnerOffset: CGFloat = 0
    @State private var appeared = false

    @AppStorage("loginStatus") private var loginStatus: Bool = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(white: 0.08), Color(white: 0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Road perspective
                roadView(width: width, height: height)

                // Content overlay
                VStack(spacing: 0) {
                    Spacer()

                    // Runner icon
                    runnerSection
                        .padding(.bottom, 32)

                    // Branding
                    brandingSection
                        .padding(.bottom, 12)

                    // Tagline
                    Text("Every mile counts.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 48)

                    // Sign In button
                    signInSection
                        .padding(.horizontal, 32)
                        .padding(.bottom, 60)
                }
            }
        }
        .alert(errorMessage, isPresented: $showAlert) { }
        .overlay {
            if isLoading {
                LoadingScreen()
            }
        }
        .onAppear {
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

    // MARK: - Road

    @ViewBuilder
    private func roadView(width: CGFloat, height: CGFloat) -> some View {
        let roadTopWidth: CGFloat = width * 0.08
        let roadBottomWidth: CGFloat = width * 1.4
        let roadTop: CGFloat = height * 0.08
        let roadBottom: CGFloat = height

        Canvas { context, size in
            // Road surface
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

            // Dashed center line with perspective
            let dashCount = 12
            for i in 0..<dashCount {
                let t1 = Double(i) / Double(dashCount)
                let t2 = (Double(i) + 0.45) / Double(dashCount)

                // Exponential interpolation for perspective effect
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

        // Vanishing point glow
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

    // MARK: - Runner

    private var runnerSection: some View {
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
    }

    // MARK: - Branding

    private var brandingSection: some View {
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
    }

    // MARK: - Sign In

    private var signInSection: some View {
        VStack(spacing: 16) {
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
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
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

    // MARK: - Helpers

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
              }
              loginStatus = true
              isLoading = false
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
    Login()
}
