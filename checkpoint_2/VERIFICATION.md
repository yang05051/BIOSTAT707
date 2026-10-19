# Checkpoint 2 verification

Verified on 2026-10-18 in the America/New_York time zone.

## Completed computational checks

- The source data contains exactly 4,000 unique set-a stays and 554 in-hospital deaths; record files match outcome identifiers.
- All recorded times are within hours 0–48, and the carried-forward plausibility bounds and missing codes are applied before summaries.
- There is one modeling row per stay, 338 original predictor columns, and no identifier, outcome, length of stay, survival, SAPS-I, or SOFA predictor.
- Five outer folds stratify deaths. All methods use the same fold assignments and patients.
- Ridge and random-forest tuning uses three inner folds. Each inner split fits its own preprocessing. GAM smoothness estimation uses training observations only.
- SAPS-I has 190 missing scores; SOFA has 144. Missing benchmark values use the corresponding outer training fold's median. A sensitivity analysis compares all methods on the 3,733 stays with both scores observed.
- Every stay has held-out predictions for all three models and scores for both benchmarks.
- An independent R process recomputed all 25 fold AUROCs from the saved prediction CSV and checked every mean and sample standard deviation.
- The saved pipeline predicts using feature columns alone in a separate R session, without outcome, benchmark, or identifier columns.
- Saved outer-fold medians were independently compared with medians calculated from the corresponding training observations.
- Reloaded-model predictions match the original in-memory fitted model predictions within `1e-12`.
- A fresh local clone of the original repository, with the new submission files copied in and raw data linked, ran the repository-root `pixi run --locked checkpoint2` task successfully. No precomputed results were supplied.
- Fresh-copy and original-run fold assignments, predictions, and comparison results were compared for reproducibility.
- The rendered report contains the expected sections, interpreted tables, embedded main figures, and no unresolved inline R expressions. The standalone ROC and GAM figures were visually inspected. The complete coefficient PNG is linked from the report and included in the submission files.
- Checkpoint 1's tracked files were not modified. Raw data and environments remain ignored, while the HTML report and required saved artifacts are visible to Git.

The first complete analysis run took 2.40 minutes; the fresh-copy run took 2.96 minutes, with another run sharing the computer. The current final-run timing is in `output/cp2_runtime.txt`. Downloading data and installing the locked environment are additional setup costs.

## Main results

| Method | Mean outer-fold AUROC | Sample SD |
|---|---:|---:|
| Ridge | 0.841 | 0.008 |
| GAM | 0.784 | 0.017 |
| Random forest | 0.841 | 0.019 |
| SAPS-I | 0.646 | 0.023 |
| SOFA | 0.620 | 0.028 |

The selection rule chooses ridge, refit on all of set-a with inner-CV-selected penalty 0.1. `output/cp2_final_model.rds` includes the fitted preprocessing and prediction interface for Checkpoint 3. Only set-a and Outcomes-a.txt were downloaded or read.

## Data provenance

Public source: https://physionet.org/files/challenge-2012/1.0.0/ . Downloaded 2026-10-18.

| File | SHA-256 |
|---|---|
| `set-a.tar.gz` | `8cb250f179cd0952b4b9ebcf8954b63d70383131670fac1cfee13deaa13ca920` |
| `Outcomes-a.txt` | `2613ea60ccda29f87571a7d6b09ad130858a8ccd66325bd073365925026883c2` |

## Remaining human actions

Review the code, report, AI disclosure, and clinical interpretations so that the judgments are your own and you can explain the analysis. Then commit and push the prepared files using `SUBMISSION_FILES.md`. Codex has not committed, pushed, or submitted this work to a course system. The working tree intentionally contains the prepared new files for review; the course's final clean-tree and pushed-commit requirement remains for that final submission step.
