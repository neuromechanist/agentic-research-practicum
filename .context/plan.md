# HBN ERSP Development Plan

## Project Overview
**Goal:** Compare 0-500 ms ERSP between shots opening with the boy vs shots opening with the puppy in HBN-EEG R3 "ThePresent".
**Timeline:** 6 phases (sub-issues). CI/CD defers to Week 4. Full 500 Hz run defers until pipeline is validated on local 100 Hz.
**Stack:** MATLAB + EEGLAB 2024+, AMICA, dipfit5, ICLabel, `std_precomp`. Driven from Claude Code via matlab-mcp-tools.
**Primary data:** `/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf` (184 subjects, 100 Hz BDF).

## Status Markers
`[ ]` pending · `[~]` in progress · `[x]` complete

## Pre-flight (Week 0)
- [x] Project brief read and `shot_events.tsv` available
- [x] Local R3 (100 Hz BDF) verified at `/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf`
- [x] CLAUDE.md, .rules/, .context/ initialized
- [ ] Git repo initialized and first commit
- [ ] EEGLAB 2024+ + plugins verified in MATLAB (Biosig, clean_rawdata, AMICA, ICLabel, dipfit5)
- [ ] matlab-mcp-tools connection tested
- [x] Contrast chosen: **Contrast 1 — Boy-only vs Puppy-only** (locked 2026-04-21, see `.context/ideas.md`)
- [x] Create GitHub repo (public): https://github.com/neuromechanist/agentic-research-practicum
- [x] Create epic issue #1 and Phase 1-6 sub-issues (#2-#7), linked via gh sub-issue

## Phase 1 — Preprocess R3
**Sub-issue:** #2 (epic #1)
**Entrypoint:** `src/matlab/phase1_preprocess.m`
**Inputs:** BIDS root `/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf`, task `ThePresent`.
**Steps:**
- [ ] `pop_importbids` with task filter and sidecar validation
- [ ] High-pass filter at 1 Hz (justify cutoff vs. 0.5 Hz in research.md)
- [ ] `cleanline` on 60/120/180 Hz (justify if 100 Hz data needs only 60)
- [ ] `clean_rawdata`: **channel rejection only**, no ASR, no interpolation yet
- [ ] Save cleaned ALLEEG to `derivatives/preproc/`
- [ ] Log per-subject channel-rejection counts + rationale
- [ ] Smoke test: pipeline runs on 3 subjects end-to-end before full 184
**Deliverable:** cleaned ALLEEG checkpoint + QA report (channels rejected per subject).

## Phase 2 — AMICA + dipfit
**Sub-issue:** #3 (epic #1)
**Entrypoint:** `src/matlab/phase2_amica.m`
**Steps:**
- [ ] Run AMICA per subject (start with 24-way parallel; document wall-time on local hardware)
- [ ] Save weights under `derivatives/amica/sub-XXX/`
- [ ] `pop_dipfit_settings` with standard MNI head model
- [ ] `pop_multifit` for dipole localization
- [ ] Attach to EEG sets, checkpoint
- [ ] Log AMICA convergence and rank reduction per subject
**Deliverable:** AMICA-decomposed ALLEEG with dipoles.

## Phase 3 — ICLabel + rejection
**Sub-issue:** #4 (epic #1)
**Entrypoint:** `src/matlab/phase3_iclabel.m`
**Steps:**
- [ ] `iclabel` on each subject
- [ ] Drop non-brain ICs at threshold 0.69 (justify vs 0.70/0.80)
- [ ] Checkpoint `derivatives/iclabel/`
- [ ] QA: brain-IC counts per subject, flag subjects with <5 brain ICs
**Deliverable:** brain-only IC sets.

## Phase 4 — Shot events + epoching
**Sub-issue:** #5 (epic #1)
**Entrypoint:** `src/matlab/phase4_epoch.m`
**Steps:**
- [ ] `expand_events` using `shot_events.tsv`; drop rows with `has_boy=n/a` AND `has_puppy=n/a`
- [ ] Epoch -0.6 to 0.6 s around `shots`
- [ ] Tag epochs with `has_boy`, `has_puppy`, `LLR`, `shot_number`
- [ ] Condition split per chosen contrast (see ideas.md)
- [ ] QA: trials-per-condition per subject; drop subjects below minimum (TBD, target >=10 trials per cond)
**Deliverable:** epoched set per subject with condition tags.

## Phase 5 — ERSP precompute + clustering
**Sub-issue:** #6 (epic #1)
**Entrypoint:** `src/matlab/phase5_ersp.m`
**Steps:**
- [ ] Build STUDY from epoched sets
- [ ] `std_precomp` ERSP: baseline -500 to -100 ms, analysis 0-500 ms, frequency range TBD in ideas.md
- [ ] Component clustering (k-means on dipole + scalp + ERSP features)
- [ ] Identify occipital and temporal clusters of interest
**Deliverable:** STUDY with precomputed ERSP and IC clusters.

## Phase 6 — Statistics + figures
**Sub-issue:** #7 (epic #1)
**Entrypoint:** `src/matlab/phase6_stats.m`
**Steps:**
- [ ] Group-level condition contrast per cluster (permutation test, FDR-corrected)
- [ ] LLR as covariate in GLM
- [ ] Cluster-of-maximal-effect figure (time-frequency + topography)
- [ ] Save manuscript-ready figures under `derivatives/figures/`
**Deliverable:** conditionwise ERSP-difference figure + stats table.

## Post-phase 6
- [ ] Validate on full 500 Hz R3 from S3 (only after local pipeline is signed off)
- [ ] Week 4: CI/CD (pre-commit, linting, GitHub Actions)

## Success Criteria
- [ ] All 6 phase PRs merged through `/review-pr`
- [ ] Checkpoints reproducible from intermediate derivatives
- [ ] Group ERSP figure and stats table produced
- [ ] R3-mini → full R3 transition requires only changing the BIDS root path

## Notes / Decisions
- Local data is 100 Hz full-R3 BDF, NOT the 20-subject R3-mini from the brief. Use a subset (e.g., first 20 subjects with complete `ThePresent` runs) for the dev loop, then fan out to all 184.
- Merge strategy: regular merge commits, not squash.
- Reference pipeline `~/Documents/git/HBN_BIDS_analysis/study_handy_scripts.m` is a known-good template; re-derive each parameter.
