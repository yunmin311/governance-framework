# HTML Output Governance

Use for design, implementation, advisor reports, note pages, or any task that produces material HTML.

## Five gates

1. **H0 Preflight:** State role, output type, actual sources, canonical project file, baseline/version, allowed exploration, forbidden changes, targets, and file-placement plan.
2. **H1 Coverage:** Enumerate every page, first/middle/tail section, state, responsive width, shared component, and evidence source before full implementation.
3. **H2 System:** Reuse project tokens and components. Label rules `INHERITED`, `ADAPTED`, `EXPLORE`, or `EXCEPTION`.
4. **H3 Completeness:** Check content, hierarchy, density, tail quality, long text, empty/error/loading states, real assets, and component divergence.
5. **H4 Render:** Actually open or render the complete target at desktop and mobile widths; add a middle width for critical work. Source review or one selected screenshot is insufficient.

Unrendered visual output is `UNVERIFIED`.

## Role boundaries

- **Design:** Execute within the baseline; do not unfreeze or replace overall direction.
- **Main:** Implement approved content/design; technical completion is not visual approval.
- **Advisor:** Separate facts, judgments, recommendations, and unknowns; presentation cannot promote advice into approval.
- **Notes:** Improve reading and retrieval; never invent facts or sources to complete a layout.

## Tail-quality check

Compare first, middle, and tail sections for the same grid, typography, spacing, component grammar, content density, state coverage, and visual effort. Two or more systemic deviations trigger `BASELINE-RESET`.

Require `templates/HTML输出质量回执.yaml` for the final receipt. It lives in the framework `templates/`; if this skill is installed standalone (outside the framework, e.g. copied alone into `~/.claude/skills`), copy that template into the skill first, or keep the full framework accessible.
