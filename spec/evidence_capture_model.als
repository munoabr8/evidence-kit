// Evidence Capture Model

// ---------- Basic Types ----------
sig Path {
  parent: lone Path
}

abstract sig Workflow {}
one sig Tests, Build, CI, Analysis extends Workflow {}

// ---------- Core Entities ----------
sig CaptureRun {
  root: one Path,
  artDir: one Path,
  workflow: one Workflow,
  produces: set Artifact
}

abstract sig Artifact {
  path: one Path,
  belongsTo: one CaptureRun
}

sig CaptureArtifact extends Artifact {
  wrapper: lone WrapperArtifact,
  sidecar: lone MetadataSidecar
}

sig WrapperArtifact extends Artifact {
  source: lone CaptureArtifact
}

sig MetadataSidecar {
  path: one Path,
  describes: lone CaptureArtifact,
  cwd: one Path
}

// ---------- Path Relationship ----------

pred under[p: Path, ancestor: Path] {
  p = ancestor or ancestor in p.^parent
}

// ---------- Invariants ----------

fact NoPathCycles {
  no p: Path | p in p.^parent
}

fact ArtDirWithinRoot {
  all r: CaptureRun |
    under[r.artDir, r.root]
}

fact ArtifactProducedByRun {
  all a: Artifact |
    a in a.belongsTo.produces
}

fact ArtifactUnderArtDir {
  all a: Artifact |
    under[a.path, a.belongsTo.artDir]
}

fact MetadataSidecarUnderArtDir {
  all m: MetadataSidecar |
    some m.describes implies under[m.path, m.describes.belongsTo.artDir]
}

fact MetadataCwdWithinRoot {
  all m: MetadataSidecar |
    some m.describes implies under[m.cwd, m.describes.belongsTo.root]
}

fact WrapperMatchesCapture {
  all c: CaptureArtifact |
    some c.wrapper implies c.wrapper.source = c
}

fact MetadataMatchesCapture {
  all c: CaptureArtifact |
    some c.sidecar implies c.sidecar.describes = c
}

fact WrapperBelongsToSameRun {
  all c: CaptureArtifact |
    some c.wrapper implies c.wrapper.belongsTo = c.belongsTo
}

fact UniqueWrapperPerCapture {
  all disj c1, c2: CaptureArtifact |
    some c1.wrapper and some c2.wrapper implies c1.wrapper != c2.wrapper
}

fact UniqueSidecarPerCapture {
  all disj c1, c2: CaptureArtifact |
    some c1.sidecar and some c2.sidecar implies c1.sidecar != c2.sidecar
}

// ---------- Failure States ----------

pred MissingWrapper {
  some c: CaptureArtifact | no c.wrapper
}

pred MissingSidecar {
  some c: CaptureArtifact | no c.sidecar
}

pred ArtifactOutsideArtDir {
  some a: Artifact |
    not under[a.path, a.belongsTo.artDir]
}

pred MetadataSidecarOutsideArtDir {
  some m: MetadataSidecar |
    some m.describes and not under[m.path, m.describes.belongsTo.artDir]
}

pred MetadataCwdOutsideRoot {
  some m: MetadataSidecar |
    some m.describes and not under[m.cwd, m.describes.belongsTo.root]
}

pred WrapperPointsToWrongCapture {
  some w: WrapperArtifact |
    some w.source and w.source.wrapper != w
}

// ---------- Example Scenario ----------

run {
  some CaptureRun
  some CaptureArtifact
} for 8

run MissingSidecar for 15
run MissingWrapper for 40

// ---------- Assertions ----------

assert WrapperPointsBackToCapture {
  all c: CaptureArtifact |
    some c.wrapper implies c.wrapper.source = c
}

check WrapperPointsBackToCapture for 8

assert MetadataSidecarPointsBackToCapture {
  all c: CaptureArtifact |
    some c.sidecar implies c.sidecar.describes = c
}

check MetadataSidecarPointsBackToCapture for 8
