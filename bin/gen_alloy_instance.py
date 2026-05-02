#!/usr/bin/env python3

from pathlib import Path
import argparse
import re


def alloy_name(path: Path) -> str:
    name = "_".join(path.parts)
    name = re.sub(r"[^A-Za-z0-9_]", "_", name)
    name = re.sub(r"_+", "_", name).strip("_")

    if not name or name[0].isdigit():
        name = f"P_{name}"

    return name


def classify(path: Path) -> str:
    """
    Classify filesystem entries before emitting Alloy.

    Meaning:
      capture            -> .cast file, modeled as CaptureArtifact
      wrapper            -> .cast.html file, modeled as WrapperArtifact
      metadata_sidecar   -> .meta.txt file, modeled as MetadataSidecar
      support            -> known support files, observed but not modeled
      ignore             -> intentionally ignored junk/temp files
      unknown_observed   -> observed but not yet assigned semantic responsibility
    """
    name = path.name

    if name.startswith(".") or name.endswith(".bak"):
        return "ignore"
    if name.endswith(".cast.html"):
        return "wrapper"
    if name.endswith(".cast"):
        return "capture"
    if name.endswith(".meta.txt"):
        return "metadata_sidecar"
    if name.endswith((".js", ".css", ".json")):
        return "support"

    return "unknown_observed"


def capture_stem(path: Path) -> str:
    if not path.name.endswith(".cast"):
        raise ValueError(f"not a capture artifact: {path}")
    return path.name.removesuffix(".cast")


def wrapper_stem(path: Path) -> str:
    if not path.name.endswith(".cast.html"):
        raise ValueError(f"not a wrapper artifact: {path}")
    return path.name.removesuffix(".cast.html")


def metadata_stem(path: Path) -> str:
    if not path.name.endswith(".meta.txt"):
        raise ValueError(f"not a metadata sidecar: {path}")
    return path.name.removesuffix(".meta.txt")


def emit_one_sig(lines: list[str], names: list[str], parent_sig: str) -> None:
    if names:
        lines.append(f"one sig {', '.join(names)} extends {parent_sig} {{}}")
        lines.append("")


def print_file_list(title: str, files: list[Path], root: Path) -> None:
    if not files:
        return

    print(title)
    for f in files:
        print(f"  - {f.relative_to(root)}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", required=True)
    parser.add_argument("--artifacts", required=True)
    parser.add_argument("--out", default="./spec/instance_generated.als")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    artifacts = Path(args.artifacts).resolve()
    out = Path(args.out)

    if not root.exists():
        raise SystemExit(f"ROOT does not exist: {root}")

    if not artifacts.exists():
        raise SystemExit(f"ART_DIR does not exist: {artifacts}")

    if not artifacts.is_dir():
        raise SystemExit(f"ART_DIR is not a directory: {artifacts}")

    if not artifacts.is_relative_to(root):
        raise SystemExit(f"ART_DIR must be under ROOT: {artifacts} not under {root}")

    files = sorted(p for p in artifacts.iterdir() if p.is_file())
    classified = {f: classify(f) for f in files}

    capture_files = [f for f in files if classified[f] == "capture"]
    wrapper_files = [f for f in files if classified[f] == "wrapper"]
    sidecar_files = [f for f in files if classified[f] == "metadata_sidecar"]

    ignored_files = [f for f in files if classified[f] == "ignore"]
    support_files = [f for f in files if classified[f] == "support"]
    unknown_observed_files = [f for f in files if classified[f] == "unknown_observed"]

    capture_stems = {capture_stem(c) for c in capture_files}
    wrapper_by_stem = {wrapper_stem(f): f for f in wrapper_files}
    sidecar_by_stem = {metadata_stem(f): f for f in sidecar_files}

    modeled_capture_files = capture_files

    used_wrapper_files = [
        wrapper_by_stem[capture_stem(f)]
        for f in modeled_capture_files
        if capture_stem(f) in wrapper_by_stem
    ]

    used_sidecar_files = [
        sidecar_by_stem[capture_stem(f)]
        for f in modeled_capture_files
        if capture_stem(f) in sidecar_by_stem
    ]

    orphan_wrapper_files = [
        f for f in wrapper_files
        if wrapper_stem(f) not in capture_stems
    ]

    orphan_sidecar_files = [
        f for f in sidecar_files
        if metadata_stem(f) not in capture_stems
    ]

    modeled_paths = []
    modeled_paths.extend(modeled_capture_files)
    modeled_paths.extend(used_wrapper_files)
    modeled_paths.extend(used_sidecar_files)

    path_atoms = {
        root: "Root",
        artifacts: "ArtifactsDir",
    }

    for p in modeled_paths:
        if p in path_atoms:
            continue
        path_atoms[p] = alloy_name(p.relative_to(root))

    capture_atoms = {
        f: alloy_name(f.relative_to(root)) + "Capture"
        for f in modeled_capture_files
    }

    wrapper_atoms = {
        f: alloy_name(f.relative_to(root)) + "Wrapper"
        for f in used_wrapper_files
    }

    sidecar_atoms = {
        f: alloy_name(f.relative_to(root)) + "Sidecar"
        for f in used_sidecar_files
    }

    all_artifact_atoms = list(capture_atoms.values()) + list(wrapper_atoms.values())

    lines: list[str] = []
    lines.append("open evidence_capture_model")
    lines.append("")

    emit_one_sig(lines, list(path_atoms.values()), "Path")
    emit_one_sig(lines, list(capture_atoms.values()), "CaptureArtifact")
    emit_one_sig(lines, list(wrapper_atoms.values()), "WrapperArtifact")
    emit_one_sig(lines, list(sidecar_atoms.values()), "MetadataSidecar")

    lines.append("fact GeneratedPaths {")
    lines.append("  ArtifactsDir.parent = Root")

    for p in modeled_paths:
        lines.append(f"  {path_atoms[p]}.parent = ArtifactsDir")

    lines.append("}")
    lines.append("")

    lines.append("fact GeneratedCaptureArtifacts {")
    for capture in modeled_capture_files:
        stem = capture_stem(capture)

        lines.append(f"  {capture_atoms[capture]}.path = {path_atoms[capture]}")

        if stem in wrapper_by_stem:
            wrapper = wrapper_by_stem[stem]
            lines.append(f"  {capture_atoms[capture]}.wrapper = {wrapper_atoms[wrapper]}")
        else:
            lines.append(f"  no {capture_atoms[capture]}.wrapper")

        if stem in sidecar_by_stem:
            sidecar = sidecar_by_stem[stem]
            lines.append(f"  {capture_atoms[capture]}.sidecar = {sidecar_atoms[sidecar]}")
        else:
            lines.append(f"  no {capture_atoms[capture]}.sidecar")

    lines.append("}")
    lines.append("")

    lines.append("fact GeneratedWrapperArtifacts {")
    for capture in modeled_capture_files:
        stem = capture_stem(capture)

        if stem not in wrapper_by_stem:
            continue

        wrapper = wrapper_by_stem[stem]
        lines.append(f"  {wrapper_atoms[wrapper]}.path = {path_atoms[wrapper]}")
        lines.append(f"  {wrapper_atoms[wrapper]}.source = {capture_atoms[capture]}")

    lines.append("}")
    lines.append("")

    lines.append("fact GeneratedMetadataSidecars {")
    for capture in modeled_capture_files:
        stem = capture_stem(capture)

        if stem not in sidecar_by_stem:
            continue

        sidecar = sidecar_by_stem[stem]
        lines.append(f"  {sidecar_atoms[sidecar]}.path = {path_atoms[sidecar]}")
        lines.append(f"  {sidecar_atoms[sidecar]}.describes = {capture_atoms[capture]}")
        lines.append(f"  {sidecar_atoms[sidecar]}.cwd = Root")

    lines.append("}")
    lines.append("")

    lines.append("fact GeneratedCaptureRun {")
    lines.append("  one r: CaptureRun {")
    lines.append("    r.root = Root")
    lines.append("    r.artDir = ArtifactsDir")

    if all_artifact_atoms:
        lines.append(f"    r.produces = {' + '.join(all_artifact_atoms)}")
    else:
        lines.append("    no r.produces")

    lines.append("  }")
    lines.append("}")
    lines.append("")

    lines.append(
        f"run {{}} for exactly {len(path_atoms)} Path, "
        "exactly 1 CaptureRun, "
        f"exactly {len(capture_atoms)} CaptureArtifact, "
        f"exactly {len(wrapper_atoms)} WrapperArtifact, "
        f"exactly {len(sidecar_atoms)} MetadataSidecar"
    )
    lines.append("")

    lines.append(
        f"run MissingSidecar for exactly {len(path_atoms)} Path, "
        "exactly 1 CaptureRun, "
        f"exactly {len(capture_atoms)} CaptureArtifact, "
        f"exactly {len(wrapper_atoms)} WrapperArtifact, "
        f"exactly {len(sidecar_atoms)} MetadataSidecar"
    )
    lines.append("")

    lines.append(
        f"run MissingWrapper for exactly {len(path_atoms)} Path, "
        "exactly 1 CaptureRun, "
        f"exactly {len(capture_atoms)} CaptureArtifact, "
        f"exactly {len(wrapper_atoms)} WrapperArtifact, "
        f"exactly {len(sidecar_atoms)} MetadataSidecar"
    )
    lines.append("")

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines), encoding="utf-8")

    captures_missing_wrapper = [
        f for f in modeled_capture_files if capture_stem(f) not in wrapper_by_stem
    ]

    captures_missing_sidecar = [
        f for f in modeled_capture_files if capture_stem(f) not in sidecar_by_stem
    ]

    print(f"[alloy] wrote {out}")
    print(f"[alloy] files scanned: {len(files)}")
    print(f"[alloy] captures modeled: {len(modeled_capture_files)}")
    print(f"[alloy] wrappers modeled: {len(wrapper_atoms)}")
    print(f"[alloy] metadata sidecars modeled: {len(sidecar_atoms)}")
    print(f"[alloy] captures missing wrapper: {len(captures_missing_wrapper)}")
    print(f"[alloy] captures missing sidecar: {len(captures_missing_sidecar)}")
    print(f"[alloy] ignored: {len(ignored_files)}")
    print(f"[alloy] support-only: {len(support_files)}")
    print(f"[alloy] unknown-observed: {len(unknown_observed_files)}")
    print(f"[alloy] orphan wrappers: {len(orphan_wrapper_files)}")
    print(f"[alloy] orphan sidecars: {len(orphan_sidecar_files)}")

    print_file_list("[alloy] warning: captures missing wrapper:", captures_missing_wrapper, root)
    print_file_list("[alloy] warning: captures missing metadata_sidecar:", captures_missing_sidecar, root)
    print_file_list("[alloy] unknown-observed files:", unknown_observed_files, root)
    print_file_list("[alloy] orphan wrapper files:", orphan_wrapper_files, root)
    print_file_list("[alloy] orphan metadata_sidecar files:", orphan_sidecar_files, root)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
