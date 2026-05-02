abstract sig Modality {}

one sig TerminalRecording, HtmlDocument, TextLog, JsonMetadata,
        StaticAsset, ImageCapture, ScreenCapture extends Modality {}

abstract sig Artifact {
  modality: one Modality
}

sig RawAsset extends Artifact {}
sig Cast extends Artifact {}
sig Index extends Artifact {}
sig Manifest extends Artifact {}
sig Wrapper extends Artifact {
  wraps: one Artifact
}

fact CastHasTerminalRecording {
  all c: Cast | c.modality = TerminalRecording
}
assert EveryCastHasAWrapper {
  all c: Cast | some w: Wrapper | w.wraps = c
}

fact WrapperHasHtmlDocument {
  all w: Wrapper | w.modality = HtmlDocument
}

fact IndexHasHtmlDocument {
  all i: Index | i.modality = HtmlDocument
}

fact WrapperTargetConstraints {
  no w: Wrapper | w in w.wraps
  all w: Wrapper | w.wraps not in Wrapper
}

fact WrapperMayOnlyWrapPrimaryArtifacts {
  all w: Wrapper | w.wraps in Cast + RawAsset
}

check EveryCastHasAWrapper for 3