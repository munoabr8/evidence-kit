open evidence_capture_model

one sig Root, ArtifactsDir, RunCast, RunWrapper, RunMeta extends Path {}

one sig RunCastArtifact, RunWrapperArtifact, RunMetaArtifact extends Artifact {}
one sig RunCastMetadata, RunWrapperMetadata, RunMetaMetadata extends Metadata {}

fact ExamplePaths {
  ArtifactsDir.parent = Root
  RunCast.parent = ArtifactsDir
  RunWrapper.parent = ArtifactsDir
  RunMeta.parent = ArtifactsDir
}

fact ExampleArtifacts {
  RunCastArtifact.path = RunCast
  RunWrapperArtifact.path = RunWrapper
  RunMetaArtifact.path = RunMeta

  RunCastArtifact.metadata = RunCastMetadata
  RunWrapperArtifact.metadata = RunWrapperMetadata
  RunMetaArtifact.metadata = RunMetaMetadata
}

fact ExampleCaptureRun {
  one r: CaptureRun {
    r.root = Root
    r.artDir = ArtifactsDir
    r.produces = RunCastArtifact + RunWrapperArtifact + RunMetaArtifact
  }
}

run {} for exactly 5 Path, exactly 1 CaptureRun, exactly 3 Artifact, exactly 3 Metadata



pred BrokenArtifactOutsideArtDir {
  some a: Artifact |
    not under[a.path, a.belongsTo.artDir]
}

run BrokenArtifactOutsideArtDir for exactly 5 Path, exactly 1 CaptureRun, exactly 3 Artifact, exactly 3 Metadata





pred BrokenMetadataCwdOutsideRoot {
  some a: Artifact |
    not under[a.metadata.cwd, a.belongsTo.root]
}

run BrokenMetadataCwdOutsideRoot for exactly 5 Path, exactly 1 CaptureRun, exactly 3 Artifact, exactly 3 Metadata