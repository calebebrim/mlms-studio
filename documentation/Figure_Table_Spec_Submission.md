# MS-ML Studio — specification for journal figures and tables (KDEA-4)

**Scope:** Align assets cited in `documentation/Article_Improved.md` with typical journal requirements (resolution, fonts, color, file format, third-party credits). **Workspace status:** no raster/vector exports are present yet; figures must be generated from MATLAB sessions and/or archived results.

**Target formats (confirm with target journal author guidelines):**

- Line art / diagrams: vector PDF or EPS, or TIFF ≥1200 dpi at final size.
- Halftone (screenshots): TIFF ≥300 dpi at final column or page width.
- Text in figures: sans-serif (e.g. Arial or Helvetica), ≥8 pt at final size; axis labels readable at column width.
- Color: colorblind-safe palettes for scatter/PCA (e.g. Wong palette, or distinct hues + shapes); avoid red–green only.
- **Icoshift [10]:** Methods already cite Tomasi *et al.* (2011). Any screenshot or diagram that includes third-party UI or branding from Icoshift should retain attribution in the figure caption or acknowledgements as required by the licensor.

---

## Tables

| ID | Location in draft | Status | Notes |
| --- | --- | --- | --- |
| **Table 1** | §1.2, §4.3 | Draft in `documentation/tables/Table1_Yang2009_adapted.md` | Adapted from Yang *et al.* [8]; include code legend or supplementary table. |
| **Table 2** | §3.2 | In `Article_Improved.md` | Typeset for journal; verify italics for species names. |
| **Table 3** | §3.3 | In `Article_Improved.md` | Same as above. |

---

## Figures — inventory from `Article_Improved.md`

| Fig | Topic (from manuscript) | Suggested source / owner | Repro hints (codebase) |
| --- | --- | --- | --- |
| **3** | MS-ML UI + workflow | **Dr. Leo Tancredi** — screenshot + schematic | `mlmssoftware-code-r7/GUI/main_gui.m`; workflow may be one composite panel. |
| **4** | Two-column text spectrum example | Leo — example file + plot or screenshot | `fn_raw_file2w.m`, sample raw text spectrum if available in repo or dataset. |
| **7** | Reshaping 28k → 1k–20k bins | Leo — line plots | Reshape pipeline in §2.3.3 / `fn_reshape.m`; needs one representative spectrum. |
| **9** | FMA peak selection, *w* ∈ {10,100,200,500} | Leo | `fn_mmv_fuzzy.m`, `fn_pks_mmf_window_comparison.m`, `plot_peaks_selection_preview.m` |
| **10** | K-fold inside GA loop | Leo | `plot_cross_validation_performace.m`, `fn_cross_validation_selector.m` |
| **17** | Feature extraction optimization progress | Leo — GUI capture | During GA run in GUI. |
| **18** | Four-panel GUI overview | Leo — high-res screenshot | Same as Fig 3 panel content; avoid low-res capture. |
| **20a–d** | PCA on extracted features (four species) | **Dr. Petra Johansen** (metrics) + Leo (layout) | `plot_svd2_classes.m`; requires saved feature matrices + labels per experiment. |
| **21–22** | Confusion *A. veronii/sobria* train / test | Petra + Leo | From `nn_test.m` / training reports; numbers in text must match figure. |
| **23–24** | Confusion *A. hydrophila* train / test | Petra + Leo | Same. |
| **25–26** | Confusion *A. caviae* train / test | Petra + Leo | Same. |
| **27–28** | Confusion *A. trota* train / test | Petra + Leo | Same. |

---

## Data availability note

Held-out metrics and matrices depend on the *Aeromonas* dataset [19] and exact training runs. **Comunicação Científica** should lock figure numbering after all panels are final. If raw prediction exports are missing, Petra’s team should regenerate from the same splits as Table 2 (90/10).

---

## Suggested caption stubs (edit after figures exist)

- **Figure 3.** MS-ML Studio graphical interface and end-to-end workflow (preprocessing → feature extraction → classification).
- **Figure 20.** PCA of extracted features (PC1 vs PC2) for one-against-all experiments: (a) *A. veronii/sobria*, (b) *A. hydrophila*, (c) *A. caviae*, (d) *A. trota*.
- **Figures 21–28.** Confusion matrices for training and test sets (specify *n* in each caption to match §3.4).

---

## Handoffs (K-Dense Lab)

- **Dr. Leo Tancredi:** all MATLAB/GUI exports, line art, multi-panel layout, final PDF/TIFF per journal checklist.
- **Dr. Petra Johansen:** numerical consistency (Table 3 vs confusion matrices vs PCA inputs), optional CIs/bootstrap if journal requests.
- **Dr. Omar Farouk:** not required for this manuscript (no maps).

**Repository paths for this deliverable:** `documentation/Figure_Table_Spec_Submission.md`, `documentation/tables/Table1_Yang2009_adapted.md`.
