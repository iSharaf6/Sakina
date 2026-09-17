import XCTest
@testable import Sakina

final class AccountAccessGateTests: XCTestCase {
    func testSignedOutOrMissingIdentityNeverExposesAnActiveLibrary() {
        let user = UUID()
        XCTAssertEqual(AccountAccessState.resolve(signedIn: false, userID: user, activeLibraryID: user,
            isPreparing: false, needsImportChoice: false, canUseLibrary: true, activationFinished: true), .signIn)
        XCTAssertEqual(AccountAccessState.resolve(signedIn: true, userID: nil, activeLibraryID: user,
            isPreparing: false, needsImportChoice: false, canUseLibrary: true, activationFinished: true), .signIn)
    }

    func testAnotherUsersReadyLibraryStaysBehindTheGate() {
        let user = UUID(), previousUser = UUID()
        XCTAssertEqual(AccountAccessState.resolve(signedIn: true, userID: user, activeLibraryID: previousUser,
            isPreparing: false, needsImportChoice: false, canUseLibrary: true, activationFinished: false), .preparing)
        XCTAssertEqual(AccountAccessState.resolve(signedIn: true, userID: user, activeLibraryID: previousUser,
            isPreparing: false, needsImportChoice: false, canUseLibrary: true, activationFinished: true), .unavailable)
    }

    func testPreparationAndImportChoiceTakePrecedenceOverReadyFlag() {
        let user = UUID()
        XCTAssertEqual(AccountAccessState.resolve(signedIn: true, userID: user, activeLibraryID: user,
            isPreparing: true, needsImportChoice: true, canUseLibrary: true, activationFinished: true), .preparing)
        XCTAssertEqual(AccountAccessState.resolve(signedIn: true, userID: user, activeLibraryID: user,
            isPreparing: false, needsImportChoice: true, canUseLibrary: true, activationFinished: true), .importChoice)
        XCTAssertEqual(AccountAccessState.resolve(signedIn: true, userID: user, activeLibraryID: user,
            isPreparing: false, needsImportChoice: false, canUseLibrary: true, activationFinished: true), .ready)
    }

    func testFailedActivationOffersRecoveryInsteadOfAnEndlessSpinner() {
        let user = UUID()
        XCTAssertEqual(AccountAccessState.resolve(signedIn: true, userID: user, activeLibraryID: user,
            isPreparing: false, needsImportChoice: false, canUseLibrary: false, activationFinished: true), .unavailable)
        XCTAssertEqual(AccountAccessState.resolve(signedIn: true, userID: user, activeLibraryID: user,
            isPreparing: true, needsImportChoice: false, canUseLibrary: false,
            activationFinished: true, hasPreparationError: true), .unavailable)
    }
}
