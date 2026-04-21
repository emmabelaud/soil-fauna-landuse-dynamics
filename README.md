# From pixels to patterns : **High-throughput in-situ imaging unveils soil fauna dynamics in agroforestry systems**

------------------------------------------------------------------------

This repository contains the R scripts associated with the publication *"From pixels to patterns: high-throughput in-situ imaging unveils soil fauna dynamics over a year in agroforestry systems"*, currently in preparation. The study uses continuous in situ imaging at high temporal resolution to investigate how land-use shapes the environmental drivers of soil invertebrate activity in a Mediterranean agroforestry context.

------------------------------------------------------------------------

## Study description

Soil invertebrate communities were monitored at 6-hour resolution over nearly two years using underground scanners deployed across two contrasted land-use positions within the same agroforestry system: position **C** (managed — cultivated cover) and position **A** (unmanaged — tree cover with herbaceous vegetation). By combining faunal activity time series with continuous measurements of root dynamics and paired microclimate indices, we apply a rolling-window piecewise SEM to characterise both the direction and the temporal variability of causal pathways linking edaphic conditions to soil faunal activity. The rolling-window approach — fitting the model repeatedly on successive overlapping time windows rather than on the full series — is central to the study design: it yields a distribution of standardised path coefficients over time, capturing how the strength and sign of causal links fluctuate across seasons and disturbance events.

------------------------------------------------------------------------

## Study site

The study was conducted at the experimental agroforestry site DIAMs (Dispositif Instrumenté en Agroforesterie Méditerranéenne sous contrainte hydrique) established in 2017 at the experimental station of INRAe (UE Diascope, Mauguio, France, 43.612°N; 3.976°E), under a semi-arid Mediterranean climate characterized by dry, hot summers and mild, wet winters (mean annual temperature 15.7 °C, mean annual precipitation 511 mm (Martin-Blangy et al., 2025). The soils are classified as Skeletic Rhodic Luvisols (IUSS Working group WRB 2014), due to the high proportions of stones (60% and more), a red color and a clayed layer (\>47%) deeper than 100 cm (Siegwart et al. 2023).

The system combines annual crop rotations with rows of black locust (Robinia pseudoacacia L.) spaced 17 m apart, each row bordered by a 2 m-wide permanent grass strip maintained under the canopy. During the 2023–2024 cropping season, durum wheat (Triticum durum Desf.) was sown on 14 December 2023 and harvested on 8 July 2024, followed by sorghum (Sorghum bicolor (L.) Moench) sown on 15 July, mown on 22 November, and shallow-tilled on 25 November 2024. To ensure establishment, the sorghum was irrigated three times (July 17, July 22, and Aug 12, 2024). Chickpea (Cicer arietinum L.) was subsequently sown on 14 March 2025 and harvest on 10 July 2025. The two land-use types compared throughout this study are hereafter referred to as treed (areas located directly beneath tree rows) and cultivated (areas located in the open cropped area) located at 4 m far from the tree rows, at least.

------------------------------------------------------------------------

## Research questions and hypotheses under development

H1 — Land-use type directly structures faunal activity in a non-stationary manner, with frequent reversals in sign and magnitude of land-use effects across seasons and management phases. 

H2 — Land-use effects are predominantly indirect: while agricultural management generally amplifies thermal variability and dampens moisture fluctuations (via irrigation), shifting the dominant driver from resource supply toward abiotic forcing, these relationships exhibit significant temporal complexity. 

H3 — Land-use intensification compresses taxonomic response. We expect that periods of high land-use constraints lead to a convergence of taxon-specific responses, thereby reducing the functional dispersion of responses across the community  

------------------------------------------------------------------------

## Causal model (piecewise SEM)

![SEM diagram](images/image.png)

The model is fitted independently on overlapping rolling time windows. All variables are z-score standardised prior to modelling, making path coefficients directly comparable across taxa and predictors.

**Tier 1 — land use shapes microclimate**

```         
microclimate_1 ← β₁ · land_use
microclimate_2 ← β₂ · land_use
```

**Tier 2 — microclimate × land use drives root growth**

```         
root ← β₃ · mc₁ + β₄ · mc₂ + β₅ · land_use
```

**Tier 3 — microclimate + root × land use drives fauna**

```         
fauna ← β₆ · mc₁ + β₇ · mc₂ + β₈ · root + β₉ · land_use
```

Each equation includes a nested random intercept (`orientation / depth`) and an AR(1) correlation structure to account for temporal autocorrelation within scanner groups. A residual covariance term (`microclimate_1 %~~% microclimate_2`) captures shared physical drivers not represented by the binary land-use contrast.

------------------------------------------------------------------------

## Pipeline

| Script | Role | Key output |
|------------------------|------------------------|------------------------|
| `1_database_edition.qmd` | Fauna, microclimate, root, and season assembly | `SEM_database.csv` |
| `2_SEM_diagnostic.qmd` | Sensitivity analysis — window × completeness × transformation (120 combinations) | `model_parameters.txt` |
| `3_SEM_modelisation.qmd` | Full rolling-window SEM across all taxa | `SEM_results_database.csv` |
| `4_SEM_results_analysis.qmd` | Figures and tables for H1–H3 | TIFF figures |

Scripts must be run in order. Script 2 is computationally intensive (120 parameter combinations × 50 sampled windows each).

``` r
quarto::quarto_render("scripts/1_database_edition.qmd")
quarto::quarto_render("scripts/2_SEM_diagnostic.qmd")
quarto::quarto_render("scripts/3_SEM_modelisation.qmd")
quarto::quarto_render("scripts/4_SEM_results_analysis.qmd")
```

------------------------------------------------------------------------

## Repository structure

```         
project/
├── data/
│   ├── fauna_data.csv
│   ├── root_pixels_count.csv
│   ├── Diams_AF1W_soil.csv
│   └── Diams_AF1W_air.csv
├── output/                          # generated, not versioned
│   ├── SEM_database.csv
│   ├── SEM_results_database.csv
│   ├── model_parameters.txt
│   └── *.tiff
└── scripts/
    ├── 1_database_edition.qmd
    ├── 2_SEM_diagnostic.qmd
    ├── 3_SEM_modelisation.qmd
    └── 4_SEM_results_analysis.qmd
```
