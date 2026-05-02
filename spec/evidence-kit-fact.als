// Alloy model demonstrating the fact-based approach for wrapper constraints.
// This version keeps the wraps relation general (Artifact) and uses a fact to
// express that wrappers should not wrap certain types. You can modify the fact
// later without changing the type signature.

 
abstract sig Artifact {}

sig RawAsset extends Artifact {}
sig Cast extends Artifact {}
sig Index extends Artifact {}
sig Manifest extends Artifact {}

sig Wrapper extends Artifact {
  wraps: one Artifact
}

// Fact: Wrappers should not wrap raw assets. This constraint is easy to modify
// later if you decide other artifact types should be disallowed or allowed.
fact NoWrapperWrapsRawAsset {
  all w: Wrapper | not (w.wraps in RawAsset)
}

fact EveryCastIsWrapped {
  all c: Cast | some w: Wrapper | w.wraps = c
}

// If you want to enforce that every Cast should eventually be wrapped, you can
// either add a separate fact (see below) or leave it as an assertion to test
// the behavior. Keeping it as an assertion lets you decide later whether you
// want to enforce it as a hard constraint or just check it.
assert EveryCastHasWrapper {
  all c: Cast | some w: Wrapper | w.wraps = c
}

// The following check will attempt to find a counterexample where a Cast
// exists without a wrapper. You can later enforce this as a fact instead.
 
 
check EveryCastHasWrapper for 22

