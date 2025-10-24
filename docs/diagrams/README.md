UML diagrams for the evidence-kit workflow

Files
- `evidence_workflow.puml` — PlantUML source showing capture → wrappers → packaging → Hunchly preview → investigator playback.

Render
- Install PlantUML and Graphviz, or use a VS Code PlantUML extension.

Command-line (requires plantuml jar + graphviz):

```bash
plantuml docs/diagrams/evidence_workflow.puml
```

Or with Docker:

```bash
docker run --rm -v "$PWD":/workspace plantuml/plantuml -tpng /workspace/docs/diagrams/evidence_workflow.puml
```

Notes
- The diagram is intentionally high-level and focuses on decision points relevant to Hunchly (sanitization stripping JS/WASM) and available mitigations (`*.static.html`, packaging).
- If you want a Mermaid variant or a PNG generated in-repo, tell me and I can add it.
