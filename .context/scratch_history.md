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

_None yet. First Phase 1 run goes here._

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
