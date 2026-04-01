# MS-ML Studio: An open-source MATLAB tool for unified mass-spectrometry preprocessing, feature extraction, and classification

**Calebe Elias Ribeiro Brima¹, Marilson Reque¹, Cibelle B. Dallagassa³, Cyntia M. T. Fadel-Picheth³, Luciano F. Huergo², Roberto Tadeu Raittz¹**

¹ Departamento de Bioinformática, Universidade Federal do Paraná, Brazil
² Setor Litoral, Universidade Federal do Paraná, Brazil
³ Departamento de Patologia Médica, Universidade Federal do Paraná, Brazil

*Correspondence: raittz@ufpr.br*

*Note (branding): **MS-ML Studio** denotes the software described in this manuscript; the version-controlled distribution is maintained under the **MLMS Studio** project name in the public repository (see Availability).*

### Author metadata (ORCID, affiliations, roles — pre-submission checklist)

Confirm with all principal investigators before submission: (i) final author order; (ii) **ORCID** for each author; (iii) full institutional affiliation (department, university, city, Brazil); (iv) **CRediT** role statements if required by the target journal; (v) corresponding author and stable institutional e-mail (currently raittz@ufpr.br — validate); (vi) funding and conflict-of-interest statements updated for the chosen venue.

---

## Abstract

Although many mass-spectrometry (MS) preprocessing and peak-detection tools exist, few free, open-source options integrate raw-spectral import, discriminant feature learning, and classifier training in one interactive graphical workflow for users without programming expertise. **MS-ML Studio** is an open-source MATLAB application that unifies preprocessing (normalization, reshaping, optional alignment), three complementary, cross-validated feature extractors (correlation-based peak selection, Watch Points, Feature Resonance with genetic-algorithm optimization), and multilayer perceptron (MLP) classification with in-GUI visualization. As a **reference proof-of-concept**—not a clinical validation—we applied the pipeline to intact-cell MALDI-TOF spectra of four *Aeromonas* species in one-against-all tasks; held-out test accuracies ranged from 82.1% to 100% (F1-scores 0.769–1.000), with the smallest test partition (*A. veronii*/*sobria*, *n* = 30) warranting cautious interpretation. Source code and executable are distributed under an open-source license at **[TODO: public repository URL, e.g. https://github.com/org/mlms-studio]**, with a versioned archive and **DOI [TODO: https://doi.org/10.xxxx/zenodo.xxxxx after Zenodo deposit]** for long-term citation in line with journal requirements.

**Keywords:** mass spectrometry; machine learning; feature extraction; peak selection; biomarker discovery; MALDI-TOF; bacterial identification; open-source software

---

## 1. Introduction

### 1.1 Mass Spectrometry in Biomedical Research

Mass spectrometry (MS) measures mass-to-charge ratios of ionized analytes and underpins proteomics, metabolomics, and microbial identification workflows [1]. Matrix-assisted laser desorption/ionization time-of-flight (MALDI-TOF) MS is now widely used for rapid bacterial identification from intact-cell fingerprints [3,4]. Across domains, comparable computational stages recur: import, preprocessing, feature extraction, and supervised or statistical classification—steps whose quality strongly affects downstream accuracy [5,8]. The present work focuses on **software** that makes this full chain accessible in one graphical environment rather than on new MS instrumentation or large-scale clinical benchmarking.

### 1.2 Existing Software Landscape and Its Limitations

A variety of software tools address subsets of the MS analysis pipeline. Instrument-specific proprietary solutions — such as Ciphergen ProteinChip software [6] and MALDI Biotyper (Bruker Daltonics) [7] — provide integrated workflows but restrict users to vendor-specific data formats and algorithms. Platform-independent open-source tools, including MZmine 2 [9], OpenMS, Cromwell, and XCMS (Table 1), offer flexible preprocessing algorithms encompassing smoothing (moving-average, Gaussian, and wavelet-based methods), baseline correction, and peak detection. However, these tools generally do not incorporate GA-based or correlation-driven feature extraction coupled to machine learning classifiers in a unified graphical interface accessible to laboratory biologists without programming expertise.

Feature extraction from MS data poses challenges distinct from general dimensionality reduction: spectral peaks must be aligned across samples with varying m/z resolution, informative peaks must be distinguished from noise and non-discriminant background, and the resulting feature representation must generalize across training and validation partitions to avoid overfitting. Genetic Algorithm (GA)-based approaches to biomarker discovery have shown promise [11,17], as has the use of cross-validation within the feature extraction loop [17]. Nevertheless, implementations are typically distributed as standalone scripts or require custom integration, presenting a significant barrier to adoption.

### 1.3 Contribution of This Work

We developed MS-ML Studio to address the gap between instrument-specific proprietary suites and fragmented open-source components. Our contributions are as follows:

1. **Unified pipeline**: A single MATLAB graphical application that covers all steps from raw spectral import through MLP-based classification and result visualization.
2. **Novel feature extraction strategies**: Three complementary methods — correlation-based Best Peaks Selection, Watch Points with fuzzy triangular weighting, and Feature Resonance using GA-optimized multi-sinusoidal functions — each guided by K-fold cross-validation to control overfitting.
3. **Platform independence**: The tool handles raw two-column text spectra from any MS platform, without dependence on proprietary data formats.
4. **Illustrative performance**: On the reference intact-cell MALDI-TOF *Aeromonas* case study (§2.1–3), test-set accuracies of 82–100% show that the pipeline can perform competitively under transparent settings; features remain exportable to external classifiers via WEKA.
5. **Open source**: Full source code and compiled executable are publicly available, enabling reproducibility and extension by the community.

---

## 2. Materials and Methods

### 2.1 Data

The following **reference case study** illustrates MS-ML Studio on published intact-cell MALDI-TOF data; it is intended as **proof-of-concept software validation**, not as a standalone clinical or epidemiological study. All mass spectra were acquired on a Bruker MALDI-TOF analyzer from intact bacterial cells of four *Aeromonas* species: *A. hydrophila*, *A. caviae*, *A. veronii*/*sobria*, and *A. trota*. Sample preparation, bacterial culture, and original spectral acquisition followed the protocol described by Surek *et al.* (2010) [19]. A total of 567 spectra were available across the four species (316 for the *A. veronii*/*sobria* group). For each of four one-against-all classification experiments, 90% of the available spectra were reserved for feature extraction and classifier training; the remaining 10% were withheld as a blind test set (Table 2).

### 2.2 MS-ML Studio Architecture

MS-ML Studio comprises two components: the MS-ML Library, a set of modular MATLAB functions implementing all algorithmic steps, and the MS-ML User Interface (Figure 3), a MATLAB GUIDE-based graphical application that exposes library functionality through interactive controls. The overall workflow (Figure 3) is organized into three phases: (1) preprocessing, (2) feature extraction with cross-validation, and (3) neural network training and classification.

### 2.3 Preprocessing

#### 2.3.1 Data Import

Input spectra are plain-text files with two whitespace-delimited columns: m/z values and relative intensities (Figure 4). This format is instrument-agnostic and can be exported from most MS platforms. There is no built-in converter for proprietary formats such as mzML or mzXML; conversion must be performed with external tools prior to import.

#### 2.3.2 Intensity Normalization

Intensity normalization rescales each spectrum's intensity vector to the range [0, 1] using the min–max formula:

$$N(x, x_{\max}, x_{\min}) = \frac{x_i - x_{\min}}{x_{\max} - x_{\min}} \tag{1}$$

where $x$ is the intensity vector and $i$ indexes each data point. This step equalizes the dynamic range across spectra acquired under potentially differing instrument gain settings.

#### 2.3.3 Spectral Reshaping

High-resolution spectra may contain tens of thousands of data points per spectrum, incurring excessive computational cost and rendering element-wise alignment impractical. The reshaping operation maps each spectrum onto a user-defined grid of $W$ evenly spaced bins spanning the global m/z range of the experiment:

$$G(x; W, x_{\max}, x_{\min}) = \text{round}\left(W \cdot N(x; x_{\max}, x_{\min})\right) \tag{2}$$

For each bin $i \in \{1, \ldots, W\}$, the output intensity is the maximum of all input intensities whose rounded grid index equals $i$, and the output m/z is the mean of the corresponding input m/z values (Algorithm 1). Reshaping simultaneously achieves dimensionality reduction and coarse alignment of peak positions across spectra with differing m/z ranges or sampling densities. Figure 7 illustrates the effect of reshaping a 28,000-point spectrum to resolutions of 1 k, 5 k, 10 k, 15 k, and 20 k; spectral morphology is preserved at resolutions ≥ 5 k, while the 1 k resolution introduces minor peak-shape distortion.

**Algorithm 1: Spectral Reshaping**
```
Input:  sii (intensity vector), smz (m/z vector), W (target resolution)
Output: nii (new intensity vector), nmz (new m/z vector)

gmax ← max(smz);  gmin ← min(smz)
g ← G(smz, W, gmax, gmin)
gmx ← max(g)
for i = 1 to gmx do
    gidx ← find(g == i)
    nii(i) ← max(sii(gidx))
    nmz(i) ← mean(smz(gidx))
end
```

*Note*: reshaping parameters (e.g., peak-detection window widths) must be re-tuned when the target resolution $W$ changes substantially, because peak density scales with $W$.

#### 2.3.4 Peak Alignment

Spectral alignment is applied after reshaping using the Icoshift algorithm [10], which employs gap insertion to maximize the correlation between spectra at user-selected m/z windows. Alignment is optional when the mass spectrometer provides internal calibration sufficient for peak reproducibility across runs.

#### 2.3.5 Peak Selection via Fuzzy Moving Average

The first step toward reducing spectral dimensionality to discriminant features is peak detection. MS-ML Studio implements a Fuzzy Moving Average (FMA) detector that computes, for each spectral position $p$, a weighted local average:

$$S(x; p, w) = \frac{\sum_{i=p-w}^{p+w} x_i \cdot T(2w+1, i)}{2w+1}, \quad p \in \mathbb{N}^* \mid 1 \leq p-w,\; p+w \leq S \tag{3}$$

where $w$ is the half-width of the triangular window, $x$ is the normalized intensity vector, and $T(L, i)$ is the triangular weighting function defined in Equations 4–5 (§2.5). Intensity values exceeding $S(x; p, w)$ at local maxima are retained as candidate peaks. The window width $w$ controls selectivity: small $w$ captures fine-grained peaks including noise; large $w$ retains only dominant spectral features. Figure 9 illustrates peak selection results for $w \in \{10, 100, 200, 500\}$.

### 2.4 Best Peaks Selection

From the set of candidate peaks identified by FMA, the Best Peaks Selection step identifies the subset most discriminant for classification. Two methods are provided:

**Correlation-based selection**: For each candidate peak position $j$, the Pearson correlation between the presence/absence vector of peak $j$ across all training spectra and the binary class label vector is computed. Peaks whose absolute correlation exceeds a user-specified threshold $\tau$ are retained.

**Probability-based selection**: The discriminancy score for peak position $i$ is:

$$D(x; i) = P(x_{(C,i)}) - \sum P(x_{(\neg C,i)}) \tag{4}$$

$$E(x) = \max(D(x)) \tag{5}$$

where $C$ denotes the target class, $\neg C$ the remaining classes, and $x$ is a binary vector encoding peak presence (1) or absence (0) at position $i$. Positions where $E(x)$ exceeds the cut-line threshold are selected. This method quantifies class exclusivity: a peak that appears frequently in class $C$ and rarely in other classes scores highly.

Both methods produce a ranked list of discriminant spectral positions that serve as anchors for the subsequent feature extraction strategies.

### 2.5 Feature Extraction

To avoid overfitting, all feature extraction algorithms embed K-fold cross-validation within the optimization loop (Figure 10): at each iteration of the GA, the training set is split into a training fold and a validation fold; the selected feature configuration is accepted as the current best only if the mean of training and validation correlations improves over the previous best.

#### 2.5.1 Watch Points

The Watch Points method generates features that summarize spectral information in the neighborhood of selected peak positions. Each watch point $k$ centered at position $c_k$ is associated with a triangular weighting window of half-width $L_k$:

For $L$ odd:
$$w(L, n) = \begin{cases} \frac{2n}{L+1} & 1 \leq n \leq \frac{L+1}{2} \\ 2 - \frac{2n}{L+1} & \frac{L+1}{2}+1 \leq n \leq L \end{cases} \tag{6}$$

For $L$ even:
$$w(L, n) = \begin{cases} \frac{2n-1}{L} & 1 \leq n \leq \frac{L}{2} \\ 2 - \frac{2n-1}{L} & \frac{L}{2}+1 \leq n \leq L \end{cases} \tag{7}$$

The feature value for watch point $k$ on spectrum $s$ is:

$$W_k = \sum w_k \cdot p \tag{8}$$

where $p$ is the binary peak-presence vector from §2.4 padded to the same length as $w_k$. Watch point center positions are initialized from the Best Peaks Selection output; the GA optimizes the window half-widths $\{L_k\}$ to maximize the mean absolute Pearson correlation between $\{W_k\}$ and class labels across all watch points.

#### 2.5.2 Feature Resonance

Feature Resonance encodes spectral peak information as the projection of peaks onto a sum of $M$ sinusoidal waves, where the wave parameters are optimized by the GA:

$$S(x; \mathbf{a}, \mathbf{b}, \mathbf{c}) = \sum_{i=1}^{M} \left( a_i \cdot \sin(b_i + c_i \cdot x) \right) \tag{9}$$

The fitness function returned to the GA is the absolute mean Pearson correlation $|\text{corr}(S(x; \mathbf{a}, \mathbf{b}, \mathbf{c}))|$ between the projection values and class labels. Three variants are implemented: (i) Feature Resonance on selected m/z values; (ii) Feature Resonance on best-peak intensities; (iii) Feature Resonance on best-peak m/z values. The number of waves $M$ is set by the user and controls the expressiveness of the feature function. A fourth variant combines Watch Points and Feature Resonance by applying the sinusoidal projection to watch-point feature vectors rather than raw spectral positions.

### 2.6 Classification

Extracted features from all enabled extractors are concatenated into a single feature matrix and passed to a multilayer perceptron (MLP) classifier implemented in the MS-ML Library (`nn_train.m`, `nn_test.m`). The MLP is trained using MATLAB's Neural Network Toolbox with a Levenberg–Marquardt backpropagation algorithm. The training/test split follows the 90%/10% per-species partition described in §2.1. Extracted features can also be exported in ARFF format for evaluation with alternative classifiers in WEKA.

### 2.7 Performance Metrics

Classification performance was evaluated using accuracy, precision, recall, and F1-score as defined by Powers (2011) [20]:

$$\text{Accuracy} = \frac{TP + TN}{N} \tag{10}$$

$$\text{Precision} = \frac{TP}{TP + FP} \tag{11}$$

$$\text{Recall} = \frac{TP}{TP + FN} \tag{12}$$

$$\text{F1} = \frac{2 \cdot \text{Precision} \cdot \text{Recall}}{\text{Precision} + \text{Recall}} \tag{13}$$

where $TP$, $TN$, $FP$, $FN$ denote true positives, true negatives, false positives, and false negatives, respectively, and $N$ is the total number of test samples.

---

## 3. Results

### 3.1 Software Overview

The result of this research is MS-ML Studio, which comprises the MS-ML Library — a collection of modular MATLAB functions — and an interactive graphical user interface (Figure 18). The interface is divided into four panels: (1) Preprocessing, (2) Peaks Selection, (3) Feature Extraction, and (4) Classification. All steps are accessible through point-and-click controls, with parameters exposed as editable fields. Real-time visualization of preprocessing steps, feature extraction optimization progress (Figure 17), and classification results (confusion matrices, PCA scatter plots) is provided within the interface.

Long-term distribution follows §Availability (versioned repository plus archived **DOI**); replace **TODO** placeholders there before submission.

### 3.2 Experimental setup (reference case study)

The subsections below report performance on the **reference** intact-cell dataset described in §2.1 to demonstrate end-to-end behavior; sample sizes—especially the *A. veronii*/*sobria* test set (*n* = 30)—are adequate for software illustration but **not** for broad generalization claims. We performed classification experiments using MALDI-TOF spectra from four *Aeromonas* species:

- *A. hydrophila*
- *A. caviae*
- *A. veronii*/*sobria*
- *A. trota*

Four one-against-all binary classification problems were formulated, one per species. For each experiment, 90% of spectra served as the training set for feature extraction and MLP training; the remaining 10% were held out as an independent test set (Table 2). Each species was compared against all others combined as the negative class.

**Table 2. Dataset partitioning for each one-against-all classification experiment.**

| Species | Training Set (n) | Test Set (n) | Total (n) |
|---|---|---|---|
| *A. hydrophila* | 511 | 56 | 567 |
| *A. caviae* | 511 | 56 | 567 |
| *A. veronii*/*sobria* | 286 | 30 | 316 |
| *A. trota* | 511 | 56 | 567 |

*Note: The different totals for A. veronii/sobria reflect the available sample size for that species group.*

### 3.3 Classification Performance

Table 3 summarizes precision, recall, accuracy, and F1-score on both training and test sets for all four classification experiments. Test set F1-scores ranged from 0.769 (*A. veronii/sobria*) to 1.000 (*A. trota*). All four test experiments exceeded 82% accuracy, and three of four test experiments exceeded 89% accuracy.

**Table 3. Classification performance of MS-ML Studio for each Aeromonas one-against-all experiment.**

| Species | Set | Recall | Precision | Accuracy | F1-Score |
|---|---|---|---|---|---|
| *A. hydrophila* | Training | 0.889 | 0.956 | 0.898 | 0.921 |
| | Test | 0.895 | 0.971 | 0.911 | 0.931 |
| *A. caviae* | Training | 0.902 | 0.839 | 0.843 | 0.869 |
| | Test | 0.838 | 0.886 | 0.821 | 0.861 |
| *A. veronii*/*sobria* | Training | 0.952 | 0.819 | 0.944 | 0.881 |
| | Test | 0.833 | 0.714 | 0.900 | 0.769 |
| *A. trota* | Training | 1.000 | 0.762 | 0.990 | 0.865 |
| | Test | 1.000 | 1.000 | 1.000 | 1.000 |

Test set performance is derived from held-out spectra not seen during feature extraction or MLP training.

### 3.4 Feature Extraction Configurations

#### 3.4.1 *A. veronii*/*sobria*

Three feature extractors were applied: "FR Selected M/Z" (training correlation 0.67), "FR Best Peaks Intensity" (threshold 0.18; training correlation 0.66), and "FR Best Peaks M/Z" (thresholds 0.12, 0.16, 0.20, 0.25; correlations 0.77, 0.78, 0.48, 0.63). The PCA projection (Figure 20a) shows a partially separable structure, consistent with the lower F1-score of this species pair relative to *A. trota*. On the training set (n = 286), 62 *A. veronii/sobria* spectra were correctly classified, 2 were missed, 10 false positives occurred, and 212 negatives were correctly rejected (Figure 21). On the test set (n = 30), all 4 target-class spectra were correctly classified with 3 false positives (Figure 22).

#### 3.4.2 *A. hydrophila*

"FR Best Peaks M/Z" was applied with four correlation thresholds (0.11, 0.12, 0.15, 0.16), yielding training correlations of 0.66, 0.64, 0.57, and 0.56 respectively. PCA shows clear class separation (Figure 20b). The training confusion matrix (n = 511) recorded 292 true positives, 23 false negatives, 25 false positives, and 171 true negatives (Figure 23). The test confusion matrix (n = 56) recorded 33 true positives, 2 false negatives, 2 false positives, and 19 true negatives (Figure 24), yielding the second-highest test F1-score (0.931).

#### 3.4.3 *A. caviae*

Four feature extractors were combined: "FR Selected M/Z," "FR Best Peaks M/Z" at thresholds 0.12, 0.16, 0.20, and "FR Best Peaks Intensities" at threshold 0.18. Training (n = 511): 296 TP, 29 FN, 21 FP, 165 TN (Figure 25). Test (n = 56): 33 TP, 2 FN, 4 FP, 17 TN (Figure 26), for test accuracy 82.1% and F1-score 0.861.

#### 3.4.4 *A. trota*

"FR Selected M/Z" (correlation 0.57) and "FR Best Peaks M/Z" at thresholds 0.12, 0.20, 0.40 (correlations 0.33, 0.11, 0.68) were used. Despite the lower training-set feature correlations, the held-out test set achieved perfect classification: 2 TP, 0 FN, 0 FP, 54 TN (n = 56; Figure 28). The training set (n = 511) also showed strong performance: 16 TP, 5 FN, 0 FP, 490 TN (Figure 27).

### 3.5 Principal Component Analysis Visualization

PCA projections of the two leading principal components computed from extracted features illustrate the quality of class separation achieved by MS-ML Studio (Figure 20). In all four cases, the extracted features produce better class separation in the reduced-dimension space compared to the raw spectral data, confirming that the feature extraction pipeline captures biologically discriminant information rather than spectral noise. The clearest separation was observed for *A. trota* (Figure 20d), consistent with its perfect test performance. Some overlap is visible for *A. veronii/sobria* and *A. caviae* (Figures 20a, 20c), reflecting the greater phenotypic similarity within the *Aeromonas* genus.

---

## 4. Discussion

### 4.1 Overall Performance

MS-ML Studio achieved competitive classification performance across all four *Aeromonas* species tested, with test-set accuracies ranging from 82.1% (*A. caviae*) to 100% (*A. trota*) and F1-scores from 0.769 to 1.000 (Table 3). These results are consistent with — and in several cases superior to — those reported by comparable studies using MALDI-TOF MS of intact bacterial cells for species-level identification. For example, Böhme *et al.* (2010) [2] demonstrated species-level differentiation of gram-negative food-borne pathogens by MALDI-TOF fingerprinting, and Croxatto *et al.* (2012) [4] validated MALDI-TOF for routine clinical identification. Our results on *Aeromonas* extend this evidence to a multi-species problem within a single genus, where spectral similarity is expected to be higher and classification consequently more challenging.

The performance variability across species is biologically meaningful. *A. trota* achieved perfect test separation, suggesting that its spectral fingerprint is highly distinctive within this dataset. In contrast, *A. veronii/sobria* produced the lowest test F1-score (0.769), consistent with the established phenotypic overlap between these two closely related phylogroups [19]. The *A. caviae* result (82.1% test accuracy) also reflects known genetic heterogeneity within this species group. These observations suggest that the classification difficulty correlates with phylogenetic relatedness, a pattern that should be investigated with larger, more phylogenetically diverse datasets in future work.

### 4.2 Feature Extraction Strategies

A key contribution of MS-ML Studio is its three complementary feature extraction approaches. Each strategy encodes spectral information differently: Best Peaks Selection provides a sparse, interpretable representation grounded in class-discriminant peak positions; Watch Points integrate neighborhood information around selected peaks using fuzzy triangular windows; and Feature Resonance projects peak information onto a compact nonlinear basis optimized by the GA. The combination of multiple feature types in a single feature vector — as applied in most of our experiments — leverages the complementarity of these representations and generally outperforms any single extractor alone. This finding aligns with the feature ensemble literature, where diverse feature types capturing different aspects of data structure tend to yield more robust classifiers [17].

The use of K-fold cross-validation within the GA fitness loop is critical for preventing overfitting during feature extraction. Without this mechanism, the GA could trivially learn to fit the training set by selecting peaks that are uninformative for unseen data. The cross-validation constraint ensures that features generalize to validation samples and, by extension, to held-out test samples — as confirmed by the consistent training-to-test performance transfer observed in Table 3.

### 4.3 Comparison with Existing Tools

Table 1 (adapted from Yang, He and Yu [8]) summarizes preprocessing strategies used by existing MS analysis tools. While tools such as MZmine 2 [9], OpenMS, and XCMS offer sophisticated preprocessing and peak detection pipelines, none provides the complete integration of GA-based feature extraction with embedded neural network training in a single GUI application. MZmine 2 supports identification against public metabolomics databases (HMDB, KEGG, METLIN, PubChem) [12-15] and random-sample consensus peak alignment, but delegates classification to external tools. MS-ML Studio's direct coupling of preprocessing, discriminant feature learning, and MLP classification within a single reproducible session eliminates manual data transfer between tools and reduces the risk of analysis errors at interface boundaries.

Feature export to WEKA from MS-ML Studio further extends the tool's utility: users can leverage MS-ML's specialized feature extraction while applying any of WEKA's large library of classifiers (SVM, Random Forest, Naïve Bayes, etc.) to the resulting feature matrices. This hybrid approach may yield further accuracy improvements beyond what the embedded MLP achieves, as demonstrated by the general principle that different classifiers exploit feature information differently.

### 4.4 Limitations

Several limitations of this study and the current software version should be acknowledged.

**Dataset size**: The *Aeromonas* dataset is relatively small (316–567 spectra per experiment). While results are promising, validation on larger and more diverse datasets — including data from multiple instruments, sample preparations, and laboratories — is necessary to establish generalizability. The notably small test set for *A. veronii/sobria* (n = 30) means that the F1-score of 0.769, while informative, carries substantial uncertainty.

**Input format restriction**: MS-ML Studio currently requires spectra in a plain two-column text format. While this is instrument-agnostic, it requires upstream conversion from mzML, mzXML, and other standard formats, which adds a step for users unfamiliar with format conversion utilities.

**MATLAB dependency**: MS-ML Studio is implemented in MATLAB and requires either a MATLAB license or the free MATLAB Runtime environment for the compiled GUI executable. A future reimplementation in a fully open-source language (e.g., Python) would broaden accessibility.

**Single classifier**: The embedded MLP provides one classification option. While WEKA export addresses this limitation partially, a fully integrated multi-classifier comparison module would strengthen the analytical framework.

**No statistical significance testing**: The current evaluation reports point-estimate performance metrics without confidence intervals or statistical significance tests comparing species or configurations. Future releases should include bootstrap confidence intervals and permutation tests for reported metrics.

### 4.5 Future Directions

Several avenues for future development are planned. First, integration of standard MS file format parsers (mzML, mzXML) will eliminate the format conversion barrier for new users. Second, expansion of the feature extraction module to include wavelet packet decomposition — which has shown strong performance in colorectal cancer biomarker detection [17] — may improve results for species with high spectral similarity. Third, the addition of unsupervised analysis capabilities (hierarchical clustering, t-SNE visualization) would extend utility to exploratory studies without predefined class labels. Fourth, application to clinically relevant identification problems — including multi-drug-resistant pathogen identification and cancer serum proteomics — will test the generalizability of the platform to high-stakes use cases. Finally, a multi-class extension of the current one-against-all scheme, incorporating probabilistic class scoring, would enable direct species-level assignments rather than a series of binary decisions.

---

## 5. Conclusion

We have presented MS-ML Studio, a free and open-source platform that integrates all computational steps of mass spectrometry data analysis — from raw spectral import through feature extraction to MLP classification — within a single interactive MATLAB GUI. The platform introduces three complementary feature extraction strategies (Best Peaks Selection, Watch Points, and Feature Resonance), each guided by K-fold cross-validation within a genetic algorithm optimization loop to encourage generalization. On a **reference proof-of-concept** intact-cell MALDI-TOF task involving four *Aeromonas* species, held-out test accuracies of 82–100% and F1-scores of 0.769–1.000 illustrate that the unified pipeline can reach competitive performance under transparent, reproducible settings; larger, multi-site studies remain necessary to support clinical claims.

The modular architecture of MS-ML Studio — with separate, composable library functions for each analysis step — makes it readily extensible, and the WEKA feature export capability allows integration with the broader machine learning ecosystem. By unifying a previously fragmented software landscape within an accessible graphical interface, MS-ML Studio lowers the barrier to MS-based machine learning analysis for laboratory scientists without specialized programming backgrounds. We anticipate that this platform will prove useful across diverse MS applications, from clinical microbiology to metabolomics and proteomics-based disease diagnostics.

---

## Availability

**Software**: Source code and compiled executable for **MS-ML Studio** (MLMS Studio repository) are released under an open-source license **[TODO: specify BSD-3-Clause, GPL-3.0, or other license approved by UFPR/project policy]**. Replace the following placeholders after creating a public repository and a Zenodo (or equivalent) archive linked to a tagged release:

- **Repository (versioned release):** [TODO: e.g. `https://github.com/<org>/mlms-studio/releases/tag/vX.Y.Z`]
- **Archived record (citable DOI):** [TODO: `https://doi.org/10.xxxx/zenodo.xxxxx`]

**Recommended citation sentence for abstract and cover letter:** *“Source code and executable are available under [license] at [repository URL] and archived at https://doi.org/10.xxxx/zenodo.xxxxx.”*

**Data**: The *Aeromonas* MALDI-TOF spectra used in this **case study** are derived from the dataset originally described by Surek *et al.* (2010) [19] and are available upon request from the corresponding author.

---

## Conflict of Interest

The authors declare no conflict of interest.

---

## Acknowledgements

The authors thank M. Surek for providing the *Aeromonas* MALDI-TOF dataset. This work was supported by Universidade Federal do Paraná.

---

## References

[1] Arnold RJ, Jayasankar N, Aggarwal D, Tang H, Radivojac P. A machine learning approach to predicting peptide fragmentation spectra. *Pac Symp Biocomput.* 2006:219-230.

[2] Böhme K, Fernández-No IC, Barros-Velázquez J, Gallardo JM, Calo-Mata P, Cañas B. Species differentiation of seafood spoilage and pathogenic gram-negative bacteria by MALDI-TOF mass fingerprinting. *J Proteome Res.* 2010;9(6):3169-3183.

[3] Krishnamurthy T, Ross PL. Rapid identification of bacteria by direct matrix-assisted laser desorption/ionization mass spectrometric analysis of whole cells. *Rapid Commun Mass Spectrom.* 1996;10(15):1992-1996.

[4] Croxatto A, Prod'hom G, Greub G. Applications of MALDI-TOF mass spectrometry in clinical diagnostic microbiology. *FEMS Microbiol Rev.* 2012;36(2):380-407.

[5] Wagner M, Naik D, Pothen A. Protocols for disease classification from mass spectrometry data. *Proteomics.* 2003;3(9):1692-1698.

[6] Conrads TP, Fusaro VA, Ross S, et al. High-resolution serum proteomic features for ovarian cancer detection. *Endocr Relat Cancer.* 2004;11(2):163-178.

[7] Buchan BW, Riebe KM, Ledeboer NA. Comparison of the MALDI Biotyper system using Sepsityper specimen processing to routine microbiological methods for identification of bacteria from positive blood culture bottles. *J Clin Microbiol.* 2012;50(2):346-352.

[8] Yang C, He Z, Yu W. Comparison of public peak detection algorithms for MALDI mass spectrometry data analysis. *BMC Bioinformatics.* 2009;10:4.

[9] Pluskal T, Castillo S, Villar-Briones A, Oresic M. MZmine 2: modular framework for processing, visualizing, and analyzing mass spectrometry-based molecular profile data. *BMC Bioinformatics.* 2010;11:395.

[10] Tomasi G, Savorani F, Engelsen SB. Icoshift: an effective tool for the alignment of chromatographic data. *J Chromatogr A.* 2011;1218(43):7832-7840.

[11] Armananzas R, Saeys Y, Inza I, et al. Peakbin selection in mass spectrometry data using a consensus approach with estimation of distribution algorithms. *IEEE/ACM Trans Comput Biol Bioinform.* 2011;8(3):760-774.

[12] Wishart DS, Knox C, Guo AC, et al. HMDB: a knowledgebase for the human metabolome. *Nucleic Acids Res.* 2009;37(Suppl 1):D603-D610.

[13] Ogata H, Goto S, Sato K, Fujibuchi W, Bono H, Kanehisa M. KEGG: Kyoto encyclopedia of genes and genomes. *Nucleic Acids Res.* 1999;27(1):29-34.

[14] Smith CA, O'Maille G, Want EJ, et al. METLIN: a metabolite mass spectral database. *Ther Drug Monit.* 2005;27(6):747-751.

[15] Wang Y, Xiao J, Suzek TO, Zhang J, Wang J, Bryant SH. PubChem: a public information system for analyzing bioactivities of small molecules. *Nucleic Acids Res.* 2009;37(Suppl 2):W623-W633.

[16] Law V, Knox C, Djoumbou Y, et al. DrugBank 4.0: shedding new light on drug metabolism. *Nucleic Acids Res.* 2014;42(D1):D1091-D1097.

[17] Liu Y, Aickelin U, Feyereisl J, Durrant LG. Wavelet feature extraction and genetic algorithm for biomarker detection in colorectal cancer data. *Knowl Based Syst.* 2013;37:502-514.

[18] Yu JS, Ongarello S, Fiedler R, et al. Ovarian cancer identification based on dimensionality reduction for high-throughput mass spectrometry data. *Bioinformatics.* 2005;21(10):2200-2209.

[19] Surek M, Vizzotto BS, Souza EM, et al. Identification and antimicrobial susceptibility of *Aeromonas* spp. isolated from stool samples of Brazilian subjects with diarrhoea and healthy controls. *J Med Microbiol.* 2010;59(4):373-374.

[20] Powers DMW. Evaluation: from precision, recall and F-measure to ROC, informedness, markedness and correlation. *J Mach Learn Technol.* 2011;2(1):37-63.
