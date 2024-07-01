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
    
    @AppStorage("loginStatus") private var loginStatus: Bool = false
    
    var body: some View {
        ZStack {
            Color.gray
                .edgesIgnoringSafeArea(.all)
            
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .foregroundStyle(.linearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                .rotationEffect(.degrees(135))
                .offset(x: -50, y: -350)
                .frame(width: 1000, height: 500)
            
            VStack {
                Text("ExtraMile \(Image(systemName: "figure.run"))")
                    .foregroundStyle(.yellow)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .rotationEffect(.degrees(315))
                Spacer()
            }
            .padding(.top, 75)
            .padding(.leading, -200)
            
            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .foregroundStyle(.yellow)
                        .frame(width: 100, height: 35)
                        .rotationEffect(.degrees(135))
                    Spacer()
                }
                .padding(.leading, 275)
                .padding(.top, 0)
                
                HStack {
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .foregroundStyle(.yellow)
                        .frame(width: 100, height: 35)
                        .rotationEffect(.degrees(135))
                    Spacer()
                }
                .padding(.leading, 375)
                .padding(.top, -140)


                HStack {
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .foregroundStyle(.yellow)
                        .frame(width: 100, height: 35)
                        .rotationEffect(.degrees(135))
                    Spacer()
                }
                .padding(.leading, 475)
                .padding(.top, -250)

                HStack {
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .foregroundStyle(.yellow)
                        .frame(width: 100, height: 35)
                        .rotationEffect(.degrees(135))
                    Spacer()
                }
                .padding(.leading, 575)
                .padding(.top, -360)
                
                HStack {
                    RoundedRectangle(cornerRadius: 0, style: .continuous)
                        .foregroundStyle(.yellow)
                        .frame(width: 100, height: 35)
                        .rotationEffect(.degrees(135))
                    
                }
                .padding(.leading, 400)
                .padding(.top, -465)

                Spacer()
            }
            .padding(.top, 300)
            .padding(.leading, -50)
            
            
            VStack(alignment: .leading) {
                
                Text("Login")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.yellow)
                    .padding()
                    
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
                .frame(height: 45)
                .clipShape(.capsule)
                .padding()
                
            }
            .frame(maxWidth: 400, alignment: .leading)
            .padding(.top, 500)
        }
        .alert(errorMessage, isPresented: $showAlert) { }
        .overlay {
            if isLoading {
                LoadingScreen()
            }
        }
    }
    
    // Loading Screen
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
    
    func showError(_ message: String) {
        errorMessage = message
        showAlert.toggle()
        isLoading = false
    }
    
    //Login With Firebase
    func loginWithFirebase(_ authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as?
            ASAuthorizationAppleIDCredential {
            
            isLoading = true
            
            guard let nonce else {
//              fatalError("Invalid state: A login callback was received, but no login request was sent.")
                showError("Cannot process your request")
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
//              print("Unable to fetch identity token")
                showError("Cannot process your request")
              return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
//              print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                showError("Cannot process your request")
              return
            }
            // Initialize a Firebase credential, including the user's full name.
            let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                              rawNonce: nonce,
                                                              fullName: appleIDCredential.fullName)
            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { (authResult, error) in
              if let error {
                // Error. If error.code == .MissingOrInvalidNonce, make sure
                // you're sending the SHA256-hashed nonce as a hex string with
                // your request to Apple.
                showError(error.localizedDescription)
              }
              // User is signed in to Firebase with Apple.
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
        // Pick a random character from the set, wrapping around if needed.
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
