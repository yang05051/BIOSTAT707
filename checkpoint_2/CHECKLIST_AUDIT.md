# Checkpoint 2 checklist audit

Audited 2026-10-18 against the live course checklist in Edge. The table follows the website's 54 shared and Checkpoint 2 checkboxes in order. `PASS` boxes were checked in Edge; `PENDING` and `N/A` boxes were left unchecked. The 27 Checkpoint 3 boxes were not changed because this submission covers Checkpoint 2 only.

Summary: **47 pass, 3 pending, 4 not applicable**. This is an audit of the prepared files, not a guarantee of a grade. The student must still review the interpretations and understand the code before submission.

| # | Section / requirement | Status | Evidence / reason |
|---|---|---|---|
| 1 | One readable report in accepted format, committed | PENDING | `output/checkpoint2.html` is complete, but it is not committed. |
| 2 | Short sections mirror checklist | PASS | `checkpoint2.qmd` and HTML contain sections 2.1–2.7. |
| 3 | Figures and tables explained and interpreted | PASS | Text accompanies Figures 1–3 and Tables 1–9, A1–A2, B1, C1. Tuning and sensitivity interpretations were made explicit during this audit. |
| 4 | Modeling decisions explained | PASS | Report explains features, missingness, median imputation, ridge penalty, GAM feature selection, forest search, and final selection rule. |
| 5 | Formatted tables | PASS | All report tables use `knitr::kable()`. Session information is technical metadata rather than an analysis table. |
| 6 | Acronyms defined at first use | PASS | AI, ICU, SAPS-I, SOFA, CSV, CV, GAM, REML, ROC, AUROC, SD, LASSO, GCS, BUN, HR, MAP, WBC, EDF, and HTML are expanded in report text/captions. |
| 7 | AI statement: tools, use, checks, strengths/weaknesses | PASS | Opening disclosure names OpenAI Codex and distinguishes computational validation from student review. |
| 8 | AI use disclosed; oral-check responsibility acknowledged | PASS | Opening disclosure and student-review section explicitly acknowledge responsibility. This does not certify that personal student review has occurred. |
| 9 | Same repository; separate checkpoint file | PASS | Original `BIOSTAT707` repository contains `checkpoint_1/` and `checkpoint_2/checkpoint2.qmd`. |
| 10 | Locked Pixi task runs report in one command | PASS | Root task sets `cwd = "checkpoint_2"`; local task also works. Root command passed, including in a fresh copy. |
| 11 | Ignore rules allow report to be committed | PASS | `.gitignore` allows the CP2 HTML and `cp2_*` artifacts; `git status` shows them. CP3 is not part of this submission. |
| 12 | Dependencies and lockfile updated and both committed | PENDING | Modeling packages and `r-tidyverse` are installed and locked in root/local manifests, but the files are not committed. |
| 13 | `r-tidyverse` dependency present | PASS | Included in root and local `pixi.toml` and matching lockfiles. |
| 14 | Input datasets only under data; artifacts only under output; relative paths | PASS | Feature builder reads `data/set-a/` and `data/Outcomes-a.txt`; report/model code writes under `output/`. No absolute paths in the task's analysis sources. Saved-model reload is in the separate post-render validator, not the grader's report task. |
| 15 | Fixed random seeds | PASS | Seed 7072026; deterministic stratified folds and explicit forest seeds. Repeated-run CSVs matched. |
| 16 | README command and measured runtime | PASS | README gives the locked command and about 3 minutes on this laptop, with measured runs 2.92 and 2.96 minutes. |
| 17 | Fresh clone test, clean tree, final commit pushed | PENDING | Fresh-copy locked run passed; working tree still has new uncommitted files and nothing has been pushed. |
| 18 | Death outcome joined by RecordID | PASS | `scripts/build_features.R` renames outcome fields and joins outcomes by `record_id`. |
| 19 | Row layout stated and checked | PASS | One row per stay; row count and unique identifiers checked. |
| 20 | Multiple rows grouped into same CV fold | N/A | There is exactly one row per stay. |
| 21 | Multiple-row predictions reduced to one per stay | N/A | There is exactly one row and one held-out prediction per stay. |
| 22 | Stay count, deaths, death percentage | PASS | Report: 4,000 stays, 554 deaths, 13.9%. |
| 23 | Checkpoint 1 cleaning carried forward/revised explicitly | PASS | Original bounds, sentinel handling, height/weight zero exclusion carried forward and documented; full bounds in Appendix B. |
| 24 | Predictors restricted to hours 0–48 | PASS | Raw timestamps checked; summaries use this window only. |
| 25 | Length of stay and survival excluded | PASS | Explicit exclusion vector in `scripts/modeling.R`. |
| 26 | SAPS-I/SOFA benchmarks, not predictors | PASS | Excluded from the feature matrix and evaluated separately. |
| 27 | ID excluded and ICU type categorical | PASS | `record_id` excluded; ICU type represented by fixed categorical indicators with an unknown category. |
| 28 | Predictor groups, reasons, total count | PASS | Table 2, 338 original columns, clinical rationale by summary group; Appendix A exact names. |
| 29 | Missingness predictors with explanation | PASS | Counts and ever-measured indicators; report explains monitoring and informative missingness. |
| 30 | Dropped variables and thresholds listed | PASS | No low-measurement-frequency exclusion. Constant encoded columns removed only inside training with SD <= 1e-10; full-refit exclusions listed in Table A2. |
| 31 | Stratified 5/10-fold CV split by stay | PASS | Five stratified folds; unique stay identifiers and fold file saved. |
| 32 | Same folds for every model | PASS | Single `outer_fold` vector and OOF table used for all five methods. |
| 33 | Preprocessing and selection fitted within training | PASS | Each inner/outer split fits medians, scaling and constant filtering on its own training rows. Independent checks compare saved outer medians with training medians. |
| 34 | Tuning nested or optimism acknowledged | PASS | Three-fold inner tuning for ridge/forest; training-only GAM REML. Model-family selection optimism also explicitly acknowledged. |
| 35 | Per-fold AUROC, mean and SD | PASS | Table 7 and `output/cp2_comparison.csv`; independently recomputed. |
| 36 | Penalized logistic regression on eligible predictors, inner tuning | PASS | Ridge (`alpha=0`); nine lambda values selected by inner-CV log loss. |
| 37 | Penalty named and justified | PASS | Report explains ridge for correlated summaries and shrinkage rather than sparse selection. |
| 38 | Full-refit comparable coefficient plot | PASS | Figure 1 shows largest 25; linked complete plot and CSV include all retained standardized coefficients. |
| 39 | LASSO/elastic-net retained predictors and stability | N/A | Ridge is used; it does not perform sparse variable selection. |
| 40 | Spline logistic model or logistic GAM | PASS | `mgcv::gam`, binomial family, cubic regression spline terms, training-only REML. |
| 41 | About 10–20 clinically selected GAM predictors | PASS | 15 original predictors listed, with clinical rationale. |
| 42 | At least three continuous partial effects with bands | PASS | GCS, lactate, MAP; centered log-odds contributions and approximate pointwise 95% bands, in original units. |
| 43 | Non-linearity and clinical interpretation for each plotted effect | PASS | GCS/lactate approximately linear; MAP nearly flat/shrunk; EDF and clinical interpretation discussed. |
| 44 | GAM uses same folds, per-fold AUROC | PASS | Common OOF table and Table 7. |
| 45 | Tree ensemble | PASS | `ranger` probability random forest. |
| 46 | Tuning grid stated and fitted inside training | PASS | 300 trees, depth 12; four combinations of mtry fraction and node size, with nested selection. |
| 47 | Early-stopping set within training | N/A | No early stopping is used. |
| 48 | Tree missing-value approach explained | PASS | Training-split median imputation with explicit missingness/count predictors. |
| 49 | Tree uses same folds, per-fold AUROC | PASS | Common OOF table and Table 7. |
| 50 | One table with all three models and two benchmarks, same folds | PASS | Table 7; missing benchmark scores handled with outer-training medians and complete-score sensitivity analysis on 3,733 stays. |
| 51 | All five OOF ROC curves in one plot | PASS | Figure 3 and `output/cp2_roc.png`. |
| 52 | Benchmark gains compared with fold variation | PASS | Table 8 and paragraph give paired mean gains and SD, with dependence caveat. |
| 53 | Final choice justified and refit on all set-a | PASS | Ridge selected by mean AUROC/simplicity rule, full-data lambda 0.1; preprocessing and model refit on set-a. |
| 54 | Fitted pipeline and all OOF predictions saved under output | PASS | `cp2_final_model.rds`, `cp2_oof_predictions.csv`, fold/audit files; standalone pipeline test passes without outcomes or IDs. |

The course's suggested tuning metric (log loss or Brier score) is a recommendation rather than a checkbox; ridge and forest use log loss. Only set-a was used. No Checkpoint 3 analysis was performed.
