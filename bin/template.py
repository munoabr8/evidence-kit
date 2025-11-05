#!/usr/bin/env python3
"""
Tiny template loader for simple placeholder substitution.

Placeholders use the form %%KEY%% and will be replaced with the
corresponding mapping value converted to str. This keeps templates
safe from accidental Python/format interpolation and avoids conflicts
with brace-heavy JS snippets.
"""
from typing import Mapping

def render_template(template_path: str, mapping: Mapping[str, object]) -> str:
    """Read template_path and replace placeholders of the form %%KEY%%.

    mapping keys should be the placeholder names (without the %% markers).
    Values will be converted to str.
    """
    with open(template_path, 'r', encoding='utf-8') as f:
        s = f.read()
    for k, v in mapping.items():
        token = f"%%{k}%%"
        s = s.replace(token, str(v))
    return s
