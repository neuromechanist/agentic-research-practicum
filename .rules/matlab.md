# MATLAB + EEGLAB Development Standards

## Version & Environment
- **MATLAB:** R2023b or newer. Confirm local version on session start.
- **EEGLAB:** 2024+ with plugins: `Biosig`, `clean_rawdata`, `AMICA`, `IClabel`, `dipfit5`, `std_precomp`.
- **Driver:** `matlab-mcp-tools` (https://github.com/neuromechanist/matlab-mcp-tools) so Claude Code can drive MATLAB over MCP.
- **Xcode (for MEX builds on macOS):** `/Volumes/S1/Applications/Xcode.app`.

## Code Style
- **One function per preprocessing step.** Each step is CLI-callable and takes a struct or parsed name-value arg list.
- **No magic numbers.** Parameters that appear in `.context/research.md` must be read from an `opts` struct, not hard-coded mid-function.
- **Deterministic runs.** `rng('default')` at the top of any function that uses RNG (AMICA has its own seeding; document it).
- **Return paths, not state.** Functions should return the checkpoint file path; the caller re-loads from disk. Keeps phases composable.

## Project Layout
```
src/
└── matlab/
    ├── phase1_preprocess.m       # entrypoint, CLI-callable
    ├── phase2_amica.m
    ├── phase3_iclabel.m
    ├── phase4_epoch.m
    ├── phase5_ersp.m
    ├── phase6_stats.m
    └── +hbn/                     # package utilities
        ├── import_bids.m
        ├── expand_shot_events.m
        └── qa_channel_rejection.m
derivatives/                      # phase checkpoints (gitignored)
```

## CLI Callability
Each `phaseN_*.m` must accept name-value args and work from the shell:
```matlab
% phase1_preprocess.m
function checkpoint = phase1_preprocess(opts)
    arguments
        opts.BidsRoot (1,1) string = "/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf"
        opts.Task (1,1) string = "ThePresent"
        opts.Subjects string = string.empty
        opts.OutDir (1,1) string = "derivatives/preproc"
        opts.HpfHz (1,1) double = 1
        opts.LineNoiseHz (1,:) double = 60  % 100 Hz data; Nyquist = 50
    end
    % ...
end
```
Callable as:
```bash
matlab -batch "phase1_preprocess(BidsRoot='/path', Subjects=['sub-NDARAA948VFH'])"
```

## Parameter Logging
Every phase writes a `params.json` next to its checkpoint:
```matlab
jsonencode(opts, 'PrettyPrint', true) ...
```
Phases downstream of it MUST read `params.json` and re-use the same settings unless explicitly overridden.

## Error Handling
- No silent `try/catch` that swallows errors.
- Catch specifically, log via `warning('hbn:stage:reason', 'message')`, and re-throw unless the failure is a known per-subject skip.
- Per-subject skips go into a CSV alongside the checkpoint: `subject, stage, reason`.

## Testing
- Real BDF files only. `tests/matlab/` contains smoke tests that run one phase on one subject (first subject in the local R3) and assert checkpoint existence + param sanity.
- No synthetic EEG. If a test needs data we don't have, request it from the user; don't generate.

## EEGLAB Conventions
- **STUDY over ALLEEG** whenever a step is group-level (Phases 5-6).
- **Save `.set` + `.fdt`** via `pop_saveset` with versioned filenames: `sub-XXX_task-ThePresent_desc-<stage>_eeg.set`.
- **`pop_importbids`** is the only supported entry point. Never read `.bdf` directly bypassing BIDS metadata.

## Never Do This
- Never copy the reference pipeline script verbatim; re-derive each parameter.
- Never hard-code `/Volumes/S1/...` inside utility functions; pass via `opts.BidsRoot`.
- Never commit `.set`/`.fdt` files or anything under `derivatives/`.
- Never use `save`/`load` with workspace-level `who` dumps; always explicit variable names.
- Never call `clear all` or `close all` inside library functions.

## Documentation
- **Header block** on every function: one-line purpose, inputs, outputs, example.
- **`doc` strings** follow the MATLAB convention (H1 line + detailed description).

---
*One function per step. Real EEG only. Every parameter justified in research.md.*
