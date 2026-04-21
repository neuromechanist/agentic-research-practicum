# HBN ERSP Design Ideas

## Purpose
Capture high-level design choices for the boy-vs-puppy ERSP contrast before implementation. Each choice should be revisited in plan mode and locked before the matching phase PR opens.

## Core Concepts

### Vision
**Goal:** Establish whether the first 500 ms of EEG after a movie-shot onset differs between shots that open with the boy and shots that open with the puppy, in HBN-EEG R3 "ThePresent".
**Principles:**
- Classical EEGLAB pipeline; no deep learning this sprint.
- Each phase produces a reproducible checkpoint under `derivatives/`.
- Parameters are justified in `.context/research.md` before being used in code.

## Contrast Decision

Three candidates from the brief (counts from the 49 trusted `shot_events.tsv` rows):

| # | Contrast | Trials | Strengths | Risks |
|---|----------|--------|-----------|-------|
| 1 | Boy-only vs Puppy-only (`has_boy=1 & has_puppy=0` vs `has_boy=0 & has_puppy=1`) | 20 vs 15 | Cleanest social-stimulus contrast; no overlap | Low trial count, may need group-level pooling |
| 2 | Puppy-present vs Puppy-absent | 18 vs 31 | Highest trial count | Scene content confounds; "absent" is heterogeneous |
| 3 | Boy-present vs Puppy-present | 23 vs 18 | Symmetric social cues | 3-shot overlap; condition non-exclusive |

**Locked decision (2026-04-21):** **Contrast 1 — Boy-only vs Puppy-only** (`has_boy=1 AND has_puppy=0` vs `has_boy=0 AND has_puppy=1`).
**Rationale:** Cleanest social-stimulus contrast, mutually exclusive conditions. Trial count (20 vs 15 shots on the stim side) is low but feasible at the group level across 184 subjects. Revisit the trial-count floor after Phase 4 QA, not the contrast itself.

## Analysis Window and Baseline
- **Analysis window:** 0-500 ms post shot onset (fixed per brief).
- **Baseline:** -500 to -100 ms pre shot onset (fixed per brief).
- **Epoch window:** -600 to +600 ms to give the baseline + analysis room and avoid edge artifacts in wavelet ERSP.
- **Consideration:** shot durations range 1-5 s; epochs shouldn't overlap consecutive-shot baselines. Phase 4 QA should flag and drop epochs where a prior shot onset falls inside the baseline window.

## LLR Handling
- `LLR` (log luminance ratio) captures low-level brightness change and is a known driver of early visual ERSP.
- **Plan:** include `LLR` as a continuous regressor of no interest in the group-level GLM (Phase 6), not as a trial-rejection criterion.
- **Alternative rejected:** matching conditions on LLR quantile would halve an already small trial count.

## Component Clustering Strategy
- **Features:** dipole location + scalp topography + spectral signature at rest. ERSP itself is NOT a clustering feature (would circularly bias the contrast).
- **Clusters of interest:** occipital (early visual response) and temporal (social / face processing).
- **K:** start with k=10, refine if clusters merge or fragment.

## Trial-count Floor
- Minimum per condition per subject: tentative 10 trials.
- Below floor → drop subject from group stats but keep IC cluster data for the non-affected cluster analyses.
- Revisit after Phase 4 empirical counts.

## Data Tier Strategy
- Dev loop: 20-subject slice of the local 100 Hz BDF (first 20 with complete `ThePresent` runs).
- Integration: all 184 local subjects at 100 Hz.
- Validation: full 500 Hz R3 from S3 after local pipeline signs off.
- **Rationale:** 100 Hz is sufficient for ERSP up to ~40 Hz (Nyquist considerations); beta/low-gamma verification requires the 500 Hz pass.

## Figure Plan
- **Main figure:** time-frequency panel + scalp topography at the cluster of maximal effect, two conditions side by side + difference map.
- **Supplementary:** ERSP per cluster, trial-count table, LLR distribution per condition.

## Open Questions
- [ ] Frequency range for ERSP precompute — 4-40 Hz (default) or narrow to theta/alpha (4-13 Hz) based on literature?
- [ ] Wavelet cycles — fixed 3 or linearly increasing 3-8? Increasing cycles reduces high-frequency variance but inflates low-frequency latency uncertainty.
- [ ] Should we include `video_start` / `video_stop` markers in any supplementary analysis? (Currently ignored.)
- [ ] Subject-level exclusion: do we use the HBN `participants.tsv` data-quality flags, or only our own post-clean_rawdata channel-rejection metric?

## Future Possibilities (out of scope)
- Inter-subject correlation (ISC) of ERSP across shots.
- Extending to other HBN movies — explicitly out of scope per brief.
- HED-based parametric analyses of the existing annotations.
