# HBN ERSP Research Notes

## Purpose
Log pipeline decisions, parameter justifications, and references. Every non-default parameter in a phase PR should trace back to a line here.

## Dataset Facts
- **Local path:** `/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf` — 184 subjects, 100 Hz, BDF converted from SET via `emgio` (bids-matlab-tools 9.1). BIDS 1.9.0, HED 8.3.0. License CC-BY-SA 4.0.
- **Task of interest:** `ThePresent` (~3.5 min Pixar short, passive viewing).
- **Subjects per participants.tsv:** 184 rows + header; actual subject dirs: 184. Brief claimed 183; spot-checked difference, likely the extra subject was added between the brief and the local conversion.
- **Sampling rate:** 100 Hz local. Nyquist = 50 Hz. Adequate for theta/alpha/low-beta ERSP; gamma requires the 500 Hz S3 run.
- **Channels:** 128 EEG, Geodesic Sensor Net HydroCel.

## Events and Shot-level Expansion
- BIDS `_events.tsv` has only coarse task markers (`start_trial`, `stop_trial`), not shot onsets.
- `shot_events.tsv` (repo root) is stimulus-side, generated against the EventFormer neural-vocabulary annotation set (Shirazi lab, unpublished).
- **Key columns:** `onset`, `duration`, `shot_number`, `LLR`, `has_boy`, `has_puppy`, `match_diff_s`.
- **Provisional keyword rules** for labels:
  - `has_boy` ← regex `\b(boy|child|kid)\b` on image description
  - `has_puppy` ← regex `\b(puppy|dog)\b`
- **Data-quality rule (from brief):** rows with `match_diff_s > 1.0 s` have `has_boy`/`has_puppy` set to `n/a`. 1.0 s is a conservative cutoff because shots are typically 1-5 s.
- **Counts:** 56 shots total, 52 annotated, 49 trusted, 3 high-drift (invalidated), 4 unmatched. Among 49 trusted: boy=23, puppy=18, both=3, neither=7.

## Reference Pipeline (from `~/Documents/git/HBN_BIDS_analysis/study_handy_scripts.m`)

Known-working recipe on this dataset; re-derive each parameter with justification, do not copy verbatim.

1. `pop_importbids` — BIDS-to-EEGLAB, filter to `ThePresent`
2. `pop_eegfiltnew` high-pass 1 Hz — removes drift, stabilizes ICA
3. `cleanline` at 60/120/180 Hz — line-noise regression
4. `clean_rawdata` with channel rejection only (no ASR, no interpolation yet) — preserves trials for ICA
5. AMICA, 24-way parallel — higher-quality decomposition than Infomax on HBN data
6. `pop_dipfit_settings` + `pop_multifit` — standard MNI boundary element model
7. ICLabel — brain threshold 0.69 (tune; 0.80 is common but loses borderline brain ICs)
8. `expand_events` with `shot_events.tsv` — injects `shots` events at onsets
9. `pop_epoch` -0.6 to 0.6 s around `shots`
10. `std_precomp` ERSP — baseline -500 to -100 ms, window 0-500 ms

## Parameter Justifications (fill per phase PR)

### Phase 1
- **HPF 1 Hz vs 0.5 Hz:** 1 Hz is the AMICA/ICA convention; 0.5 Hz preserves low-frequency ERP but introduces drift into ICA. We keep 1 Hz for decomposition; if Phase 6 needs 0.5 Hz data for ERP visualization, run a parallel filter pass on cleaned sets.
- **Cleanline skipped at 100 Hz:** 60 Hz (US line fundamental) is already above Nyquist (50 Hz) after the 500 -> 100 Hz anti-alias downsample that produced the local BDF files; 120 Hz and 180 Hz were never in the band. Running cleanline at 100 Hz is a no-op; the step is gated behind `opts.RunCleanline || EEG.srate >= 500` and reports `cleanline_status=skipped_nyquist` in the QA CSV. The full reference-pipeline cleanline call (bandwidth 2, p=0.05, tau=100, winsize=4, winstep=1, linefreqs=[60 120 180], scanforlines on, newversion true) re-activates automatically for the 500 Hz S3 validation run.
- **clean_rawdata channels only:** per brief. `FlatlineCriterion='off', ChannelCriterion=0.8, LineNoiseCriterion=5, Highpass='off', BurstCriterion='off', WindowCriterion='off', BurstRejection='off', Distance='Euclidian', fusechanrej=1`. ASR and windowed rejection are deferred; if we need them later, apply to cleaned sets as a parallel branch.
- **Channel list dynamic (`1:EEG.nbchan`):** the reference script hard-coded `1:128` but the local data carries 129 channels (128 EEG + Cz reference). Dynamic sizing also makes the function reusable on datasets with different montages.
- **Cz reference electrode is rejected at this stage:** Cz is the original reference in the BIDS dataset (`EEGReference: "Cz"`) so its data is flat; `clean_rawdata` correctly flags it. This is expected and matches the reference pipeline's output. Downstream ICA and ERSP are reference-independent; if scalp data at Cz is needed later, re-reference (e.g., to common-average) before rejection in a parallel pass.
- **Subject inclusion filter:** `participants.tsv` column `ThePresent == "available"` only. "caution" and "unavailable" are excluded. "caution" subjects can be revisited post-Phase 3 once the IC-count distribution is known.

### Phase 2
- **AMICA 24-way parallel:** starting point; log wall-time on local hardware and downgrade if memory-bound.
- **Dipfit head model:** standard 10-05 MNI + BEM; HBN uses Geodesic Sensor Net so elec positions need conversion, check the reference pipeline for the electrode file.

### Phase 3
- **ICLabel threshold 0.69:** reference pipeline default. At 0.80 we lose ~15% more brain ICs on HBN adolescent data (Shirazi anecdote — confirm empirically in Phase 3 QA).

### Phase 5
- **ERSP freq range:** default 4-40 Hz covers theta through gamma1. At 100 Hz the upper bound is 50 Hz Nyquist, so 4-40 is safe with headroom.
- **Wavelet cycles:** decide between fixed 3 vs linearly increasing 3-8. Trade-off captured in ideas.md.

## References
- Shirazi SY et al., *HBN-EEG: A Curated Collection*, bioRxiv 2024. DOI: [10.1101/2024.10.03.615261](https://doi.org/10.1101/2024.10.03.615261)
- Alexander LM et al., *The Healthy Brain Network*, Sci Data 2017. DOI: [10.1038/sdata.2017.181](https://doi.org/10.1038/sdata.2017.181)
- Delorme A, Makeig S, *EEGLAB*, J Neurosci Methods 2004.
- Palmer JA et al., *AMICA*, 2012.
- Pion-Tonachini L et al., *ICLabel*, NeuroImage 2019. DOI: [10.1016/j.neuroimage.2019.05.026](https://doi.org/10.1016/j.neuroimage.2019.05.026)
- Dataset DOI: [10.18112/openneuro.ds005507.v1.0.1](https://doi.org/10.18112/openneuro.ds005507.v1.0.1)

## Tools
- **matlab-mcp-tools:** https://github.com/neuromechanist/matlab-mcp-tools
- **Reference script:** `~/Documents/git/HBN_BIDS_analysis/study_handy_scripts.m`
- **EEGLAB install path:** `/Users/yahya/Documents/git/eeg/eeglab` (version "dev"). Plugins (verified as of Phase 1 merge): Biosig 3.8.4, clean_rawdata, ICLabel, dipfit, firfilt, EEG-BIDS 10.2, nsgportal 2.1.1, nwbio 1.2, AMICA (cloned from sccn/amica, x86_64 Mach-O runs via Rosetta on Apple Silicon), cleanline (cloned from sccn/cleanline)
- **EEGLAB plugins required:** Biosig, clean_rawdata, AMICA, ICLabel, dipfit, cleanline, firfilt, EEG-BIDS
- **S3 bucket (deferred):** `s3://fcp-indi/data/Projects/HBN/BIDS_EEG/cmi_bids_R3`

## Technical Decisions Log

### Use 100 Hz local BDF for dev loop
**Date:** 2026-04-21
**Options Considered:**
- Option 1: Download R3-mini 20-subj from S3 — matches brief but duplicates already-local data.
- Option 2: Use local `L100_bdf` full-R3 (184 subjects, 100 Hz) — already present, larger N, slightly different from brief's "mini".
**Choice:** Option 2 on first 20 subjects for dev, fan out to 184 for integration, defer 500 Hz S3 until Phase 6.
**Reasoning:** Avoid redundant download. The trade-off is that the local data isn't exactly the 20-subject mini the brief references; we name this distinction explicitly so future-you doesn't expect brief-level numbers.

### Cleanline skipped entirely at 100 Hz
**Date:** 2026-04-21
**Reasoning:** Even 60 Hz exceeds the 50 Hz Nyquist at 100 Hz sampling. The anti-alias filter applied during the upstream 500 -> 100 Hz downsample removed 60 Hz content, so cleanline at 100 Hz is a pure no-op. `hbn.conditional_cleanline` now returns immediately with `status="skipped_nyquist"` whenever `EEG.srate < 500` and `opts.RunCleanline` is false. The full cleanline call with linefreqs=[60 120 180] re-activates automatically at 500 Hz.

### `participants.tsv` flag as inclusion filter
**Date:** 2026-04-21
**Reasoning:** HBN exposes per-task availability in `participants.tsv` (values: `available` / `caution` / `unavailable`). For Phase 1 we include only `available` rows. `caution` rows are revisited post-Phase 3 once IC counts per subject are known; a subject that loses many channels here and few brain ICs in Phase 3 is a double-hit and should be dropped from the group stats.

### Stage A / B empirical channel-rejection counts
**Date:** 2026-04-21
**Observation:** first three eligible subjects (sub-NDARAA948VFH, sub-NDARAC853DTE, sub-NDARAD774HAZ) lost 6, 17, and 31 channels respectively (of 129). The 24% rejection rate on the third subject is high but not catastrophic; their post-rejection PSD still shows a clean 1/f shape with an alpha peak. We keep `ChannelCriterion=0.8` as the first pass and revisit if Phase 3 shows this subject as a brain-IC outlier.
