# HydroGNSS / SMAP / SMOS / MODIS collocation: instructions

Repository: `GNSS_SMAP_coloc`, branch `master` (commit `b4baac9`, merged 11 September 2026).
Entry point: `src/Combining_Hydro.m`.

## 1. What the tool does

`Combining_Hydro` takes one extracted HydroGNSS dataset (a `.mat` file with one column per variable and one row per specular point), grids it onto the global EASE-Grid 2.0 25 km grid in 6-hour blocks, and stacks it day by day next to daily SMAP soil moisture, SMOS soil moisture and MODIS vegetation / land-surface-temperature products on the same grid. The result is one `.mat` file in which the same row index means the same day and the same 25 km cell for every dataset, so no further matching is needed.

## 2. Requirements

- MATLAB R2021b or newer. Only base MATLAB is needed; no toolbox. (The former Aerospace Toolbox dependency was removed in this version.)
- The repository on the MATLAB path: open `GNSS_SMAP_coloc.prj`, or run `addpath(genpath('<repo>\src'))`.
- One auxiliary file that is NOT in the repository: `SEA_MASK_20240212.mat` (variable `SEA_MASK_25km`, from the SML2OP auxiliary data). Its location is hard-coded in `src/Combining_Hydro.m` line 135 as `D:\Hamed\SML2OP\Auxiliary_Data\SEA_MASK_20240212.mat`. On another machine, either put the file at that path or edit that line.
- Memory: at save time every variable of one HydroGNSS product is held dense in RAM. Each variable needs `nDays x 810592 x 4 x 8` bytes (about 0.78 GB per variable for a 30-day run), so a month with 20 to 30 variables needs roughly 15 to 25 GB of RAM. Use shorter periods on smaller machines. Loading the output later has the same requirement (see section 9).

## 3. Input data layout

All three ancillary datasets use one folder per day, `<path>\<yyyy>\<m>\<d>\`, with month and day NOT zero-padded. June 1st 2026 is `2026\6\1`, not `2026\06\01`.

| Dataset | Folder | Files expected per day |
|---|---|---|
| SMAP L3 SM_P_E (9 km) | `smap_path\yyyy\m\d\` | one `SMAP_L3_SM_P_E_<date>_R*_NNN.h5`. If several granules exist (`_001`, `_002`), the highest `_NNN` is used. |
| SMOS CATDS L3 SM daily | `smos_path\yyyy\m\d\` | the ascending + descending pair `SM_OPER_MIR_CLF31A_*.DBL.nc` and `SM_OPER_MIR_CLF31D_*.DBL.nc`, or the new product code `CLF3SA` / `CLF3SD` (delivered since 20 May 2026). Both passes are required. |
| MODIS MOD09CMG (surface reflectance) | `modis_path\MOD09CMG\yyyy\m\d\` | one `MOD09CMG.A*.hdf` |
| MODIS MOD11C1 (land surface temperature) | `modis_path\MOD11C1\yyyy\m\d\` | one `MOD11C1.A*.hdf` |

Data for the TWO DAYS BEFORE `startDay` must also be present. They are read first and used to gap-fill the first days of the run (section 7). SMAP is mandatory for those two days as well.

## 4. HydroGNSS input file

`hydro_file` is one `.mat` file from the HydroGNSS extractor. Every variable is a column vector with one element per specular point. The pipeline relies on these fields:

- `specularPointLat`, `specularPointLon`: used for gridding and for the ocean mask.
- `constellation`: `"GPS"` or `"Galileo"` per record. Used to build the GPS-only and Galileo-only products.
- `SixHourDir`: one string per record of the form `yyyy-MM\dd\Hhh`, for example `2026-06\01\H06`. It selects the 6-hour block.
- `SNR_1_L`, `SNR_1_R`, `SNR_5_L`, `SNR_5_R` (dB), `reflectivityLinear_1_L` and the other channels (linear), `incidenceAngleDeg`, `timeUTC`, `qualityFlags`, `qualityFlags_2`.
- Any other per-record numeric variable is gridded and written to the output under the same name.
- Merged extracts that contain a `MergedFiles` provenance string are accepted; that field is ignored.

## 5. Configuration file

Copy `conf/configuration_Hydro_sample.cfg` and fill every key. All keys are mandatory, and the run stops immediately if a folder or file does not exist. Lines starting with `%` are ignored.

```
Target_Resolution=25
startDay=20260601
endDay=20260630
smap_path=S:\HydroGNSS_OrbitData\Data01Feb26\SMAP09
modis_path=S:\HydroGNSS_OrbitData\Data01Feb26\MODIS
smos_path=S:\HydroGNSS_OrbitData\Data01Feb26\SMOS
hydro_file=S:\HydroGNSS_OrbitData\ExtractedData\MergedHydr1&Hydr2_NewCollection3_26-08-28_18-25.mat
product_path=D:\collocated_data
SMAPQualityFlagFilter=yes
hydro_processing=yes
SMAP_resolution=9
```

| Key | Meaning |
|---|---|
| `Target_Resolution` | Output grid resolution in km. Only 25 is supported. |
| `startDay`, `endDay` | First and last day, `yyyymmdd`, inclusive, within one calendar year. |
| `smap_path`, `modis_path`, `smos_path` | Root folders described in section 3. |
| `hydro_file` | The HydroGNSS extract (section 4). |
| `product_path` | Existing folder where the output file is written. |
| `SMAPQualityFlagFilter` | `yes`: produce two SMAP versions, `Filtered_B0` (recommended quality, flag bit 0 clear) and `Filtered_B2` (retrieval successful, flag bit 2 clear). `no`: no SMAP flag filtering. |
| `hydro_processing` | `yes` to grid HydroGNSS. `no` to produce only the SMAP / SMOS / MODIS stacks. |
| `SMAP_resolution` | Resolution of the SMAP input files: 9 (SM_P_E) or 36 (SM_P). |

## 6. Running

```matlab
clear all                                              % required, see below
addpath(genpath('D:\...\GNSS_SMAP_coloc\src'))          % or open GNSS_SMAP_coloc.prj
Combining_Hydro('D:\...\conf\configuration_Hydro.cfg')
```

`clear all` is required before every run. The configuration reader is a singleton cached for the MATLAB session, so a second run with a different `.cfg` in the same session would silently reuse the first configuration.

Progress is printed as one line per day (`day : 01-Jun-2026`). Warnings about missing or unreadable files are printed inline (section 7).

## 7. Behaviour on missing or unreadable data

| Situation | Behaviour |
|---|---|
| SMOS day folder missing, only one of the A / D passes present, or a file that fails to read | Warning. The SMOS map for that day is all NaN. The run continues. |
| MODIS MOD09CMG or MOD11C1 missing, or a corrupt `.hdf` that fails in `hdfread` | Warning. The four MODIS variables for that day are all NaN. The run continues. |
| SMAP granule missing | Error with the date. SMAP is the reference product and is mandatory for every day, including the two days before `startDay`. |
| HydroGNSS 6-hour block with no data | Empty block (all NaN). The run continues. |

The `*_full_map` versions of the ancillary variables fill a NaN cell from the previous day, then from two days before. An isolated missing day is therefore recovered in the `_full_map` fields, while the plain fields contain only same-day data.

## 8. Processing summary

HydroGNSS, before gridding (`src/functions/apply_general_filter.m`), applied to the L1 left-hand channel `_1_L` only:

- `SNR_1_L` below 0.5 dB: the `_1_L` channel values are set to NaN.
- `reflectivityLinear_1_L` below -45 dB: the `_1_L` channel values are set to NaN.
- `incidenceAngleDeg` above 45 degrees: the track-level (non-channel) values are set to NaN.
- Specular point over the ocean (sea mask): all values are set to NaN.

Gridding: for every 6-hour block, all specular points falling in one 25 km cell are averaged. SNR is averaged in linear units and returned in dB. Quality flags are combined with a bitwise mode. `timeUTC` is averaged as POSIX time (seconds since 1970-01-01 UTC). Ocean cells are removed with `LandMask_EASEgrid25km.mat`. Three products are built: combined GPS+Galileo, GPS only, Galileo only.

SMOS (`src/io/SMOS_process.m`): per pass, a cell is kept when 0 <= SM <= 1 m^3/m^3, DQX <= 0.1 m^3/m^3, RFI probability <= 0.5, and `Science_Flags` bit 0 (`FL_NON_NOM`, non-nominal retrieval) is clear. The ascending and descending maps are then averaged per cell. Product codes CLF31 and CLF3S are both accepted; CLF31 is preferred when both are present.

MODIS (`src/io/MODIS_process.m`): NDVI and NDWI from MOD09CMG bands 1, 2 and 5, restricted to pixels flagged clear by the internal cloud mask, averaged to 25 km. LST average `(day + night) / 2` and LST difference `day - night`, in degrees Celsius, from MOD11C1 after screening with the QC bits, averaged to 25 km. All four are land-masked.

SMAP (`src/io/SMAP_read.m`, `src/io/SMAP_process.m`): AM and PM retrievals averaged, then averaged from the 9 km grid onto the 25 km grid. With `SMAPQualityFlagFilter=yes` the two filtered versions `Filtered_B0` and `Filtered_B2` are produced.

## 9. Output file

Name: `<product_path>\collocated_data_HydroGNSS_<yyyy>_days<DOY1>to<DOY2>_25km_GPS&Galileo.mat`, MAT v7.3. An existing file with the same name is overwritten. Example for June 2026: `collocated_data_HydroGNSS_2026_days152to181_25km_GPS&Galileo.mat`.

| Variable | Content |
|---|---|
| `Target_Resolution` | 25 |
| `hours` | `["H00","H06","H12","H18"]`, the meaning of the four columns of the HydroGNSS variables |
| `SMAPproduct_stacked` | With `SMAP_resolution=9` and filter `yes`: `.Filtered_B0.mean.<var>` and `.Filtered_B2.mean.<var>`, each N x 1. `<var>` is one of `latitude`, `longitude`, `soil_moisture`, `soil_moisture_error`, `vegetation_opacity`, `vegetation_water_content`, `roughness_coefficient`, `albedo`, plus `soil_moisture_full_map`, `vegetation_opacity_full_map`, `vegetation_water_content_full_map`. With filter `no` the fields are under `.mean.<var>`. |
| `SMOSproduct_stacked` | `.soil_moisture` and `.soil_moisture_full_map`, N x 1 |
| `MODISproduct_stacked` | `.Modis_ndvi`, `.Modis_ndwi`, `.Modis_LST_ave`, `.Modis_LST_dif` and their `_full_map` versions, N x 1 |
| `HydroGNSS_stacked` | One field per HydroGNSS variable, each N x 4 (combined GPS + Galileo). `year` is a scalar. |
| `HydroGNSS_GPS_stacked` | Same layout, GPS only |
| `HydroGNSS_Galileo_stacked` | Same layout, Galileo only |

N = nDays x 810592, where 810592 = 1388 columns x 584 rows of the 25 km grid.

### How the rows are collocated

Row `r` encodes the day and the grid cell:

```
r    = (day - 1) * 810592 + cell         day = 1 for startDay, 2 for the next day, ...
cell = (easeRow - 1) * 1388 + easeCol    column-major order of the 1388 x 584 grid
```

The same `r` refers to the same day and the same cell in every variable of every dataset. The four columns of a HydroGNSS variable are the 6-hour blocks H00, H06, H12 and H18 of that day. SMAP, SMOS and MODIS have one daily value per row. Cells with no observation are NaN, which is most rows.

Coordinates do not need to be decoded from the index: `HydroGNSS_stacked.specularPointLat` / `specularPointLon` give the mean specular point of each cell and block, and `SMAPproduct_stacked.<...>.latitude` / `longitude` give the mean SMAP pixel position in the cell.

`timeUTC` is POSIX time in seconds; convert with `datetime(t, 'ConvertFrom', 'posixtime')`.

Example: pair HydroGNSS reflectivity of the H06 block with SMAP soil moisture.

```matlab
f = 'collocated_data_HydroGNSS_2026_days152to181_25km_GPS&Galileo.mat';
H = load(f, 'HydroGNSS_stacked');   H = H.HydroGNSS_stacked;    % every field N x 4
S = load(f, 'SMAPproduct_stacked'); S = S.SMAPproduct_stacked;

h       = 2;                                                  % column 2 = H06
refl_dB = 10*log10(H.reflectivityLinear_1_L(:, h));           % N x 1
sm      = S.Filtered_B0.mean.soil_moisture;                   % N x 1, same rows
ok      = ~isnan(refl_dB) & ~isnan(sm);
scatter(sm(ok), refl_dB(ok), 4, '.');
xlabel('SMAP soil moisture (m^3/m^3)'); ylabel('HydroGNSS reflectivity (dB)');

% decode day and cell of the matched rows if needed
nCells  = 1388*584;
r       = find(ok);
dayIdx  = ceil(r / nCells);                                   % 1 = startDay
cell    = r - (dayIdx - 1)*nCells;
easeCol = mod(cell - 1, 1388) + 1;
easeRow = floor((cell - 1) / 1388) + 1;
```

To use a daily HydroGNSS value instead of one block, average over the four columns first: `mean(H.reflectivityLinear_1_L, 2, 'omitnan')`.

Loading `HydroGNSS_stacked` with `load` brings every variable of that product into memory (see the memory note in section 2). `matfile` cannot load a single field of a struct, so load one product at a time and clear it before loading the next.

## 10. What changed in this version (merged 11 September 2026)

- SMOS quality control also rejects non-nominal retrievals (`Science_Flags` bit `FL_NON_NOM`). Fewer but cleaner SMOS cells.
- The SMOS CLF3S product code, delivered since 20 May 2026, is accepted alongside CLF31.
- Missing or corrupt SMOS / MODIS days no longer stop the run. They become NaN days with a warning. A missing SMAP day gives a clear, dated error.
- The Aerospace Toolbox is no longer required.
- Merged HydroGNSS extracts that contain a `MergedFiles` field are accepted.

## 11. Known limitations

- Only the 25 km target grid is supported.
- The sea-mask path is hard-coded (section 2).
- A SMOS day with only one of the two passes is treated as missing.
- The HydroGNSS products in the output must be loaded whole; a full month needs tens of GB of RAM.
