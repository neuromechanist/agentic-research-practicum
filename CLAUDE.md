# HBN ERSP: Boy-Shot vs Puppy-Shot Instructions

## Project Context
**Purpose:** Test whether the first 500 ms of EEG responses differ when a movie shot begins with the boy vs the puppy during passive viewing of "The Present" (HBN-EEG R3). Metric: event-related spectral perturbation (ERSP) aligned to shot onsets.

**Stack:**
- MATLAB + EEGLAB 2024+ (Biosig, clean_rawdata, AMICA, ICLabel, dipfit5, std_precomp)
- matlab-mcp-tools (https://github.com/neuromechanist/matlab-mcp-tools) to drive MATLAB from Claude Code over MCP
- BIDS (ds005507), HED 8.3.0 events
- Python helpers (UV) only if a MATLAB-only path is painful (e.g., shot-event expansion prototyping); MATLAB is primary.

**Architecture:** One MATLAB function per preprocessing step, all callable from the CLI. STUDY-level EEGLAB recipe. Derivatives checkpointed after each phase so any stage can be re-entered without redoing the earlier ones.

## Data Locations

- **Local R3 (primary dev data):** `/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf`
  - 184 subjects, **100 Hz BDF**, full R3 downsampled (converted from SET via `emgio`, bids-matlab-tools 9.1).
  - NOT the 20-subject R3-mini described in the brief. Still ~100 Hz, but every R3 subject is present.
  - Task of interest: `ThePresent` only.
- **Stimulus-side events:** `shot_events.tsv` at repo root (49 trusted rows after `match_diff_s > 1.0 s` invalidation).
- **Reference pipeline:** `~/Documents/git/HBN_BIDS_analysis/study_handy_scripts.m` (known-working recipe; re-derive each step with explicit parameter justification, do not copy verbatim).
- **Full 500 Hz R3:** S3 `s3://fcp-indi/data/Projects/HBN/BIDS_EEG/cmi_bids_R3` (only after pipeline validated on local 100 Hz).

## Derivatives Layout
```
derivatives/
├── preproc/        # Phase 1: BIDS import, 1 Hz HPF, cleanline, clean_rawdata channel rejection
├── amica/          # Phase 2: AMICA weights + dipfit
├── iclabel/        # Phase 3: IC classification, non-brain drop
├── epochs/         # Phase 4: shot-expanded events, epochs -0.6 to 0.6 s
├── ersp/           # Phase 5: STUDY-level ERSP precompute, IC clusters
└── figures/        # Phase 6: group stats, condition-contrast figures
```

## Development Workflow
1. **Check context:** `.context/plan.md` for current phase and tasks
2. **Design decisions:** `.context/ideas.md` (contrast choice, baseline window, LLR handling)
3. **Pipeline notes and refs:** `.context/research.md`
4. **Branch per phase:** `gh issue develop <issue-number>` from `develop` (or `main` if no dev track yet)
5. **One function per preprocessing step**, CLI-callable, deterministic
6. **Checkpoint after each phase** under `derivatives/<stage>/`
7. **Document failures:** log in `.context/scratch_history.md` immediately
8. **Commit:** atomic, <50 chars, no emojis, no AI attribution
9. **PR:** reference parent epic issue, include parameter justifications
10. **Review:** `/review-pr` with all subagents; address all non-false-positive findings

## Phase Sketch (see `.context/plan.md` for active tasks)
1. Preprocess R3: BIDS import, 1 Hz HPF, cleanline 60/120/180, channel rejection (clean_rawdata)
2. AMICA (24-way parallel) + dipfit5 (`pop_dipfit_settings` + `pop_multifit`)
3. ICLabel classification (brain threshold 0.69), non-brain component rejection
4. `expand_events` with `shot_events.tsv` → `pop_epoch` -0.6 to 0.6 s around `shots`
5. `std_precomp` ERSP on 0-500 ms with baseline -500 to -100 ms; IC clustering
6. Group contrasts, cluster-level stats, manuscript-ready figure

## Contrast (locked)
**Contrast 1 — Boy-only vs Puppy-only** (decided 2026-04-21):
- Boy-only: `has_boy=1 AND has_puppy=0` (20 stim-side shots)
- Puppy-only: `has_boy=0 AND has_puppy=1` (15 stim-side shots)
- Mutually exclusive, cleanest social-stimulus contrast.
- `LLR` (log luminance ratio) included as a continuous regressor of no interest in the group-level GLM.
- Alternatives considered and rejected: Contrast 2 (puppy-present vs absent; scene confound), Contrast 3 (boy vs puppy present; 3-shot overlap). See `.context/ideas.md`.

## [CRITICAL] Core Principles

### NO MOCKS — Test on Real EEG
Real BDF files and real shot events only. If a test would only pass with synthetic data, don't write it. See `.rules/testing.md`.

### No Technical Debt Across Phases
Each phase PR is self-contained and complete. No "fix later" notes carried into the next phase. Re-derive parameters; don't silently inherit from the reference pipeline.

### Commits & Git
Atomic, <50 chars, no emojis, no AI attribution. `[x]` for completed tasks in markdown, not checkmark emojis. See `.rules/git.md`.

### Writing
No em-dashes (commas or semicolons). Define abbreviations on first use (e.g., "event-related spectral perturbation (ERSP)").

## [NEVER DO THIS]
- Never generalize to other HBN movies in this project (`ThePresent` only)
- Never do deep learning in Phase 1-6 (classical EEGLAB pipeline)
- Never do custom HED work here (use events as-provided)
- Never run on full 500 Hz R3 before the pipeline validates on local 100 Hz
- Never use mocks, stubs, or fake EEG in tests
- Never use `pip`/`conda`/`virtualenv` for Python helpers (UV only)
- Never commit raw EEG, secrets, or `.env`
- Never add backward-compatibility shims; replace directly

## Rules Directory
- `.rules/matlab.md` — MATLAB + EEGLAB conventions (function-per-step, parameter logging)
- `.rules/testing.md` — NO MOCK policy applied to EEG
- `.rules/git.md` — branching, atomic commits, PR rules
- `.rules/code_review.md` — `/review-pr` workflow
- `.rules/documentation.md` — README gets someone running in <5 min
- `.rules/self_improve.md` — learning from each phase
- `.rules/serena_mcp.md` — code intelligence (if used)
- `.rules/python.md` — only if Python helpers appear
- CI/CD deferred to Week 4 per brief; `.rules/ci_cd.md` reference only.

## Context Files
- `.context/plan.md` — phase-by-phase task list, current status
- `.context/ideas.md` — contrast choice, baseline, LLR handling, design tradeoffs
- `.context/research.md` — reference pipeline steps, HBN/EEGLAB/AMICA/ICLabel citations, shot-event data-quality notes
- `.context/scratch_history.md` — failed attempts (AMICA convergence, ICLabel thresholds, epoch artifacts)

## Quick Commands
```bash
# MATLAB over MCP (matlab-mcp-tools must be running)
# Each phase has one entrypoint function under src/matlab/phaseN_*.m

# Local dataset sanity check
ls /Volumes/S1/Datasets/HBN/L100/R3_L100_bdf/ | grep '^sub-' | wc -l   # expect 184
head -5 shot_events.tsv

# Python helper envs (only if needed)
uv sync && uv run pytest
uv run ruff check --fix . && uv run ruff format .
```

## Outputs Expected
- Group-level ERSP maps per condition on 0-500 ms, baseline -500 to -100 ms
- Cluster-level stats across occipital/temporal IC clusters
- Conditionwise ERSP-difference figure at cluster of maximal effect
- Saved STUDY with `_amica`, `_iclabel`, `_clustered`, `_epoched` intermediates under `derivatives/`

---
Reference: `project_brief.md` is the authoritative spec; this file operationalizes it.
