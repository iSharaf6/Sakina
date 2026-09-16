import XCTest
@testable import Sakina

@MainActor
final class AgeAssuranceTests: XCTestCase {
    func testIneligibleAccountSkipsRegulatoryFeaturesAndAgeRequest() async throws {
        let check = AgeAssuranceCheck()
        var lookups = 0
        var requests = 0
        await check.run(requirement: {
            try await AgeAssuranceCheck.requiresSharing(eligibility: { false }, regulatoryRequirement: {
                lookups += 1
                return true
            })
        }, request: { requests += 1; return true })
        XCTAssertEqual(check.state, .complete)
        XCTAssertEqual(lookups, 0)
        XCTAssertEqual(requests, 0)
    }

    func testEligibleAccountStillChecksFeatureSpecificRequirement() async throws {
        let required = try await AgeAssuranceCheck.requiresSharing(eligibility: { true }, regulatoryRequirement: { false })
        XCTAssertFalse(required)
    }

    func testNonregulatedAccountDoesNotRequestAge() async {
        let check = AgeAssuranceCheck()
        var requests = 0
        await check.run(requirement: { false }, request: { requests += 1; return true })
        XCTAssertEqual(check.state, .complete)
        XCTAssertEqual(requests, 0)
    }

    func testSuccessfulCheckIsNotRepeatedDuringTheSession() async {
        let check = AgeAssuranceCheck()
        var requests = 0
        for _ in 0..<3 {
            await check.run(requirement: { true }, request: { requests += 1; return true })
        }
        XCTAssertEqual(check.state, .complete)
        XCTAssertEqual(requests, 1)
    }

    func testRequiredCheckMustSucceedAndCanBeRetried() async {
        let check = AgeAssuranceCheck()
        await check.run(requirement: { true }, request: { throw URLError(.notConnectedToInternet) })
        XCTAssertEqual(check.state, .retry(required: true))
        await check.run(retry: true, requirement: { true }, request: { true })
        XCTAssertEqual(check.state, .complete)
    }

    func testDecliningRequiredSharingDoesNotMarkCheckComplete() async {
        let check = AgeAssuranceCheck()
        await check.run(requirement: { true }, request: { false })
        XCTAssertEqual(check.state, .retry(required: true))
    }

    func testFailedRetryDoesNotDowngradeKnownRegionalRequirement() async {
        let check = AgeAssuranceCheck()
        await check.run(requirement: { true }, request: { false })
        await check.run(retry: true, requirement: {
            XCTAssertTrue(check.state.blocksAccess)
            throw URLError(.notConnectedToInternet)
        }, request: { true })
        XCTAssertEqual(check.state, .retry(required: true))
    }

    func testUnavailableRegionLookupDoesNotAssumeAgeSharingIsRequired() async {
        let check = AgeAssuranceCheck()
        await check.run(requirement: { throw URLError(.notConnectedToInternet) }, request: { true })
        XCTAssertEqual(check.state, .retry(required: false))
    }

    func testOnboardingDefersInsteadOfFailingOrPromptingTwice() async {
        let check = AgeAssuranceCheck()
        await check.run(requirement: { true }, request: { throw AgeAssuranceCheck.FlowError.presentationDeferred })
        XCTAssertEqual(check.state, .deferredRequired)
        await check.run(requirement: { true }, request: { true })
        XCTAssertEqual(check.state, .complete)
    }

    func testDeferredPresentationPreservesKnownRequirementIfLookupThenFails() async {
        let check = AgeAssuranceCheck()
        await check.run(requirement: { true }, request: { throw AgeAssuranceCheck.FlowError.presentationDeferred })
        await check.run(requirement: { throw URLError(.notConnectedToInternet) }, request: { true })
        XCTAssertEqual(check.state, .retry(required: true))
    }
}
