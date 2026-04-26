abstract sig Artifact {}

sig RawAsset extends Artifact {}
sig Cast extends Artifact {}
sig Wrapper extends Artifact {
  wraps: one Artifact
}
sig Index extends Artifact {
  linksTo: set Artifact
}
sig Manifest extends Artifact {
  references: set RawAsset
}

fact WrapperHasTarget {
  all w: Wrapper | one w.wraps
}

fact NoWrapperWrapsRawAsset {
  all w: Wrapper | not (w.wraps in RawAsset)
}

fact EveryCastIsWrapped {
  all c: Cast | some w: Wrapper | w.wraps = c
}

assert ExactlyOneWrapperPerCast {
  all c: Cast | one w: Wrapper | w.wraps = c
}

assert NoOrphanWrappers {
  all w: Wrapper | w.wraps in Cast
}

fact AtMostOneWrapperPerCast {
  all c: Cast | lone w: Wrapper | w.wraps = c
}

check ExactlyOneWrapperPerCast for 5