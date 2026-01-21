//
//  AuthenticationManager.swift
//  HabitTracker
//
//  Created by Sebastián Kučera on 13.01.2026.
//

import Foundation
import AuthenticationServices
import Security
import Combine

// MARK: - User Model

struct AppUser: Codable {
    let id: String
    var email: String?
    var firstName: String?
    var lastName: String?
    var signInDate: Date

    var displayName: String {
        if let firstName = firstName, !firstName.isEmpty {
            if let lastName = lastName, !lastName.isEmpty {
                return "\(firstName) \(lastName)"
            }
            return firstName
        }
        return "User"
    }
}

// MARK: - Authentication Manager

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isSignedIn: Bool = false
    @Published var currentUser: AppUser?

    /// True if user continued as guest (not signed in with Apple)
    var isGuestUser: Bool {
        // Guest users don't have their ID stored in keychain
        return isSignedIn && getUserID() == nil
    }

    private let userDefaultsKey = "currentUser"
    private let keychainService = "com.habitflow.auth"
    private let keychainAccount = "appleUserID"

    init() {
        loadUser()
        setupCredentialRevocationObserver()
    }

    // MARK: - Public Methods

    /// Handle Sign in with Apple result
    func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                processAppleCredential(appleIDCredential)
            }

        case .failure(let error):
            // User cancelled or other error
            #if DEBUG
            let authError = error as? ASAuthorizationError
            if authError?.code == .canceled {
                print("User cancelled Sign in with Apple")
            } else {
                print("Sign in failed: \(error.localizedDescription)")
            }
            #endif
        }
    }

    /// Sign in without Apple (skip)
    func signInAsGuest() {
        let guestUser = AppUser(
            id: UUID().uuidString,
            email: nil,
            firstName: nil,
            lastName: nil,
            signInDate: Date()
        )

        saveUser(guestUser)
        isSignedIn = true
        currentUser = guestUser
    }

    /// Sign out user
    func signOut() {
        deleteUserID()
        clearUser()
        isSignedIn = false
        currentUser = nil
    }

    /// Check if Apple ID credential is still valid
    func checkCredentialState() async {
        guard let userID = getUserID() else {
            return
        }

        let provider = ASAuthorizationAppleIDProvider()

        do {
            let state = try await provider.credentialState(forUserID: userID)

            await MainActor.run {
                switch state {
                case .authorized:
                    // User is still authorized
                    break
                case .revoked:
                    // User revoked authorization - sign out
                    signOut()
                case .notFound:
                    // Credential not found
                    break
                case .transferred:
                    // User transferred to different team
                    break
                @unknown default:
                    break
                }
            }
        } catch {
            #if DEBUG
            print("Failed to check credential state: \(error)")
            #endif
        }
    }

    // MARK: - Private Methods

    private func processAppleCredential(_ credential: ASAuthorizationAppleIDCredential) {
        let userID = credential.user

        // Save user ID to Keychain
        saveUserID(userID)

        // Create user object
        // Note: email and fullName are only provided on FIRST sign-in
        let user = AppUser(
            id: userID,
            email: credential.email,
            firstName: credential.fullName?.givenName,
            lastName: credential.fullName?.familyName,
            signInDate: Date()
        )

        // If we already have a user with this ID, preserve existing name/email
        // (since Apple only sends them on first sign-in)
        if let existingUser = currentUser, existingUser.id == userID {
            let mergedUser = AppUser(
                id: userID,
                email: credential.email ?? existingUser.email,
                firstName: credential.fullName?.givenName ?? existingUser.firstName,
                lastName: credential.fullName?.familyName ?? existingUser.lastName,
                signInDate: existingUser.signInDate
            )
            saveUser(mergedUser)
            currentUser = mergedUser
        } else {
            saveUser(user)
            currentUser = user
        }

        isSignedIn = true

        #if DEBUG
        // Log for debugging
        print("Signed in user: \(user.id)")
        if let email = user.email {
            print("Email: \(email)")
        }
        if let name = user.displayName as String? {
            print("Name: \(name)")
        }
        #endif
    }

    private func setupCredentialRevocationObserver() {
        NotificationCenter.default.addObserver(
            forName: ASAuthorizationAppleIDProvider.credentialRevokedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.signOut()
            }
        }
    }

    // MARK: - User Persistence (UserDefaults)

    private func saveUser(_ user: AppUser) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(AppUser.self, from: data) {
            currentUser = user
            isSignedIn = true
        }
    }

    private func clearUser() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }

    // MARK: - Keychain (User ID Storage)

    private func saveUserID(_ userID: String) {
        guard let data = userID.data(using: .utf8) else { return }

        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        #if DEBUG
        if status != errSecSuccess {
            print("Failed to save user ID to Keychain: \(status)")
        }
        #endif
    }

    private func getUserID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let userID = String(data: data, encoding: .utf8) else {
            return nil
        }

        return userID
    }

    private func deleteUserID() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        SecItemDelete(query as CFDictionary)
    }
}
