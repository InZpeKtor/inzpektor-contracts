// Proof of Clean Hands Circuit
// This circuit verifies that a user passes all compliance checks:
// 1. KYC (Know Your Customer) verification
// 2. OFAC (Office of Foreign Assets Control) sanctions check
// 3. USDC blacklist check
//
// The circuit ensures privacy by not revealing which specific check failed,
// only whether the user has "clean hands" (passes all checks) or not.

fn main(
    // Private inputs (witness)
    kyc_passed: bool,                // true if user passed KYC
    ofac_passed: bool,               // true if user is NOT on OFAC list
    usdc_not_blacklisted: bool,      // true if user is NOT on USDC blacklist
) -> pub bool {

    // Verify that all compliance checks passed
    // All three flags must be true for clean hands
    let all_checks_passed = kyc_passed & ofac_passed & usdc_not_blacklisted;

    // Return the result: true only if all checks passed
    all_checks_passed
}

#[test]
fn test_all_checks_passed() {
    let kyc_passed = true;
    let ofac_passed = true;
    let usdc_not_blacklisted = true;

    let result = main(kyc_passed, ofac_passed, usdc_not_blacklisted);
    assert(result == true);
}

#[test]
fn test_kyc_failed() {
    let kyc_passed = false;  // KYC failed
    let ofac_passed = true;
    let usdc_not_blacklisted = true;

    let result = main(kyc_passed, ofac_passed, usdc_not_blacklisted);
    assert(result == false);
}

#[test]
fn test_ofac_failed() {
    let kyc_passed = true;
    let ofac_passed = false;  // On OFAC list
    let usdc_not_blacklisted = true;

    let result = main(kyc_passed, ofac_passed, usdc_not_blacklisted);
    assert(result == false);
}

#[test]
fn test_usdc_blacklisted() {
    let kyc_passed = true;
    let ofac_passed = true;
    let usdc_not_blacklisted = false;  // On USDC blacklist

    let result = main(kyc_passed, ofac_passed, usdc_not_blacklisted);
    assert(result == false);
}

#[test]
fn test_multiple_failures() {
    let kyc_passed = false;
    let ofac_passed = false;
    let usdc_not_blacklisted = false;

    let result = main(kyc_passed, ofac_passed, usdc_not_blacklisted);
    assert(result == false);
}
