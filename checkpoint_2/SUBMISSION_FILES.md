# Checkpoint 2 submission files

Submit the same GitHub repository used for Checkpoint 1, including the complete tracked contents of `checkpoint_2/` and the new repository-root Pixi configuration.

## Main report

`checkpoint_2/output/checkpoint2.html`

## Source and reproducibility

- `checkpoint_2/checkpoint2.qmd`
- `checkpoint_2/scripts/build_features.R`
- `checkpoint_2/scripts/modeling.R`
- `checkpoint_2/scripts/verify_outputs.R`
- `checkpoint_2/pixi.toml` and `checkpoint_2/pixi.lock`
- `checkpoint_2/.gitignore`, `README.md`, `SUBMISSION_FILES.md`, and `VERIFICATION.md`
- Repository-root `.gitignore`, `pixi.toml`, and `pixi.lock`

## Saved results and Checkpoint 3 handoff

Commit every file named `checkpoint_2/output/cp2_*`:

- `cp2_final_model.rds` — fitted ridge model and preprocessing bundle.
- `cp2_oof_predictions.csv` — five methods' held-out scores, outcomes, identifiers, and folds.
- `cp2_folds.csv` and `cp2_resampling_audit.rds` — fold assignments and training preprocessing/tuning.
- `cp2_comparison.csv`, `cp2_ridge_coefficients.csv`, `cp2_gam_smooths.csv`, and `cp2_partial_effects.csv` — numeric results.
- `cp2_all_coefficients.png`, `cp2_partial_effects.png`, and `cp2_roc.png` — standalone figures.
- `cp2_runtime.txt` — measured execution time.

The ignore rules keep local environments, downloaded raw data, and generated long/wide datasets out of Git while allowing all of the files above.

## Before final submission

Review the report's AI disclosure, interpretations, and model choice. The course requires your own understanding and judgment. After that review, from the repository root:

```sh
pixi run --locked checkpoint2
git add .gitignore pixi.toml pixi.lock checkpoint_2
git diff --cached --stat
git commit -m "Complete Checkpoint 2 model comparison and report"
git push origin main
git status --short
```

These commit/push commands are instructions for the existing `main` branch; they have not been run by Codex. Check the staged file list before committing. The course also requires a final clean working tree and pushed commit. No course-system submission has been made.
