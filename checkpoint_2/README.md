# BIOSTAT 707 Checkpoint 2

The written report is `output/checkpoint2.html`. Open it in a browser; it embeds its main figures and tables. The complete coefficient plot is a separate linked PNG in the same output directory. This project carries forward the exact Checkpoint 1 cleaning and feature definitions, independently rebuilding them from raw set-a files.

## Run

From the repository root:

```sh
pixi run --locked checkpoint2
```

Or, from `checkpoint_2/`:

```sh
pixi run --locked checkpoint2
```

The root manifest sets the task working directory to `checkpoint_2/`. The local manifest also supports running this directory on its own. Both manifests and lockfiles must be committed. The task regenerates the report, features, cross-validation predictions, figures, audit files, and fitted pipeline. Seeds are fixed. No precomputed results or Checkpoint 1 outputs are required. The measured complete analysis takes about 3 minutes on this laptop (2.92 minutes in the final preparation run and 2.96 minutes in a fresh copy). Runtime is recorded in `output/cp2_runtime.txt`; initial dependency installation is additional.

## Data setup (once, excluded from Git)

Only set-a is used. Keep the 4,000 record files under `data/set-a/` and `Outcomes-a.txt` under `data/`. Public downloads:

```sh
mkdir -p data
curl -L --fail https://physionet.org/files/challenge-2012/1.0.0/set-a.tar.gz -o data/set-a.tar.gz
curl -L --fail https://physionet.org/files/challenge-2012/1.0.0/Outcomes-a.txt -o data/Outcomes-a.txt
tar -xzf data/set-a.tar.gz -C data
```

Run these setup commands from `checkpoint_2/` before the analysis. They have already been completed in the prepared folder. Do not download set-b or set-c for Checkpoint 2.

Source: Silva I et al. (2012), *Predicting in-hospital mortality of ICU patients: The PhysioNet/Computing in Cardiology Challenge 2012*, Computing in Cardiology 39:245–248. https://physionet.org/content/challenge-2012/1.0.0/ . Open Data Commons Attribution License v1.0.

## Files to submit through the same repository as Checkpoint 1

- `checkpoint2.qmd`: report source and analysis entry point.
- `scripts/build_features.R`: original cleaning and feature construction.
- `scripts/modeling.R`: fold-safe preprocessing, nested tuning, model fits, figures, and serialization checks.
- `pixi.toml`, `pixi.lock`, `.gitignore`, and this README.
- `output/checkpoint2.html`: required rendered report.
- `output/cp2_final_model.rds`: fitted pipeline for Checkpoint 3.
- `output/cp2_oof_predictions.csv`: all five held-out scores, labels, IDs, and folds.
- The other `output/cp2_*.csv`, `.rds`, `.png`, and `cp2_runtime.txt`: results, complete coefficients, figures, saved folds, and resampling audit.
- At repository root: `pixi.toml`, `pixi.lock`, and `.gitignore`, enabling the grader's command from the root.

Do not commit `data/`, `.pixi/`, `.quarto/`, `output/set-a_long.csv`, or `output/set-a_wide.csv`. They are generated or local data. The ignore rules allow the report and all required Checkpoint 3 artifacts to be committed.

## Checkpoint 3 prediction interface

Build the identical wide feature columns for the new cohort with the carried-forward cleaning definitions, then load the saved bundle and call:

```r
library(glmnet)
library(mgcv)
library(ranger)
bundle <- readRDS('output/cp2_final_model.rds')
risk <- bundle$predict_risk(bundle, new_wide)
```

`new_wide` must contain the original predictor names; it need not include outcomes or benchmark scores. The bundle applies training medians, encoding, centering, scaling, and column filtering from set-a. Do not recompute fitted preprocessing or retrain the model on later cohorts. The raw feature-building script currently points to set-a deliberately; reuse the same definitions with the appropriate raw-data paths for Checkpoint 3.

## Review and submission

The report discloses substantial Codex assistance and distinguishes automated validation from student review. Read the report and code, verify the interpretations, and make clinical judgments your own before submitting. The course may use an oral check. This preparation does not submit to a course system or push to GitHub.

The complete final verification uses a fresh local clone with copied submission files and linked raw data, runs the locked task, and checks the saved model in a separate R session. See `VERIFICATION.md` for the completed checks and measured runtime.
