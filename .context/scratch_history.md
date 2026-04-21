# HBN ERSP Scratch History

## Purpose
Log failed attempts, parameter values that didn't work, and dead ends. Every row here prevents a future session from repeating the same loop. Include error messages verbatim when possible.

## Template
```
### Attempt: [short name]
**Date:** YYYY-MM-DD
**Phase:** [1-6 or pre-flight]
**Goal:** What we were trying to achieve
**Command / config:** verbatim if relevant
**Symptom:** error message, metric, or observable
**Root cause:** why it didn't work (or "unresolved")
**Resolution:** what we did instead, or "moved on"
**Lesson:** key takeaway
```

## Entries

### Attempt: spectopo nfft/overlap overrides
**Date:** 2026-04-21
**Phase:** 1
**Goal:** Reduce PSD noise by passing explicit `nfft` and `overlap` to `spectopo` inside `hbn.save_psd_figure`.
**Command:** `spectopo(..., 'nfft', 256, 'overlap', 128)`
**Symptom:** `pwelch` raised "The number of samples to overlap must be less than the length of the segments." spectopo's internal segment length differs from the nfft we passed in.
**Root cause:** `spectopo` computes its own Welch-segment size from `pnts` and `srate`; overriding `overlap` breaks the invariant `overlap < segment_length`.
**Resolution:** drop the custom `nfft`/`overlap`, rely on spectopo defaults.
**Lesson:** prefer EEGLAB defaults unless we have a measurement-driven reason to override.

### Attempt: Custom two-panel PSD plot (mean + min/max envelope)
**Date:** 2026-04-21
**Phase:** 1
**Goal:** Distinct visual signature per cleaning stage, cheaper than spectopo's multi-channel render.
**Symptom:** user preferred the canonical EEGLAB spectopo render; custom plot added complexity without matching the team's reading habit.
**Resolution:** switched to `spectopo(..., 'plot','on')`, grabbed `gcf`, annotated with `sgtitle`, saved via `exportgraphics` at 150 DPI.
**Lesson:** default to the EEGLAB-native visualization users expect; custom styling should come later if it adds interpretability.

### Observation: dual `_channels.tsv` / `_eeg_channels.tsv` per subject
**Date:** 2026-04-21
**Phase:** 1
**Context:** Local BIDS dataset at `/Volumes/S1/Datasets/HBN/L100/R3_L100_bdf` carries two channel TSVs per run: `_channels.tsv` (EEG-typed) and `_eeg_channels.tsv` (EMG-typed). The latter is a conversion artifact from `emgio` (SET -> BDF). `pop_importbids` reads the canonical `_channels.tsv` and ignores the non-spec sibling, so no action needed for Phase 1. Flag here in case a future pipeline step reads per-run TSVs directly.

### Observation: Cz reference rejected by clean_rawdata
**Date:** 2026-04-21
**Phase:** 1
**Context:** Cz is the dataset's original reference (`EEGReference: "Cz"`), so its samples are flat by construction. `clean_rawdata` correctly flags it as a bad channel. This matches the reference-pipeline behavior. Downstream ICA and ERSP are reference-independent. If we later want scalp-space signal at Cz for visualization, re-reference to common-average BEFORE `clean_rawdata` in a parallel branch.

### Observation: pop_importbids imports every subject even when downstream filter keeps 1
**Date:** 2026-04-21
**Phase:** 1
**Context:** `pop_importbids(..., 'bidstask',{'ThePresent'}, ...)` imports all 170 eligible subjects into `_bids_import_scratch/` (~1.7 GB) regardless of our `SmokeSubjectCount` limit, because the filter runs post-import via `std_rmdat`. For Stage A/B this means every run re-pays the import cost. Options considered: (a) invoke pop_importbids per subject via a temp BIDS root (expensive metadata parsing), (b) cache scratch between runs (done implicitly; scratch stays under `derivatives/` which is gitignored). Chose to accept the cost for now; revisit if wall-time becomes painful on repeated Stage A runs.

## Common Pitfalls to Watch For

### Pitfall: cleanline at Nyquist-exceeding harmonics on 100 Hz data
**Symptoms:** cleanline runs without complaint but produces no noticeable change in the PSD around 120/180 Hz (because those frequencies don't exist in 100 Hz data).
**Cause:** Copying the reference pipeline's 60/120/180 Hz list without adjusting for sampling rate.
**Solution:** 60 Hz only at 100 Hz; full list at 500 Hz. Documented in research.md.

### Pitfall: AMICA wall-time on full R3
**Expected:** 184 subjects × 24-way AMICA is multi-hour.
**Cause:** AMICA is iterative and data-size bound; 100 Hz helps but 128 channels still dominate.
**Preempt:** Time AMICA on first 3 subjects before launching the full batch; if >4 h / subject, tier down to 16-way or batch on NSG.

### Pitfall: Shot event drift (`match_diff_s > 1.0`)
**Symptoms:** 3 rows in `shot_events.tsv` have their `has_boy`/`has_puppy` set to `n/a`. If we relax the 1.0 s threshold during analysis, the labels may come from a shot that's not what was actually on screen.
**Solution:** Keep 1.0 s threshold unless we hand-verify the affected rows against the original image descriptions. Log any relaxation here.

## Library/Tool Issues

_None yet._

## Debugging Notes

_None yet._

## Lessons Summary

_Populate after Phase 1 closes._
