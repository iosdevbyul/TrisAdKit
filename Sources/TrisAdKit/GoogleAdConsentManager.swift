import GoogleUserMessagingPlatform
import UIKit

/// Request UMP consent on every application launch before requesting advertisements.
/// Call `prepareConsent` from the host app at an appropriate UI transition.
@MainActor
public final class GoogleAdConsentManager {
    public init() {}

    public var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }

    public var requiresPrivacyOptions: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    public func prepareConsent(from viewController: UIViewController? = nil) async throws {
        let parameters = RequestParameters()
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        try await ConsentForm.loadAndPresentIfRequired(from: viewController)
    }

    public func presentPrivacyOptions(from viewController: UIViewController? = nil) async throws {
        try await ConsentForm.presentPrivacyOptionsForm(from: viewController)
    }
}
