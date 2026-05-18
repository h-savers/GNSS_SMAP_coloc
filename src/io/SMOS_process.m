function SMOSproduct_atResolution = SMOS_process(file_path_smos_a, file_path_smos_d)
% SMOS_process Read SMOS CATDS L3 daily soil moisture (ascending +
% descending), apply quality control to each pass independently, then
% combine into a single daily map.
%
% Inputs
%   file_path_smos_a : full path to MIR_CLF31A .DBL.nc (ascending, ~6 AM)
%   file_path_smos_d : full path to MIR_CLF31D .DBL.nc (descending, ~6 PM)
%
% Output
%   SMOSproduct_atResolution.soil_moisture : (numcols*numrows) x 1 column
%       vector of QC-filtered, A/D-combined daily soil moisture (m^3/m^3)
%       on the EASE-Grid 2.0 25 km global grid (1388 cols x 584 rows),
%       column-major, rows running north -> south to match the SMAP /
%       HydroGNSS orientation used by the rest of the pipeline.
%
% QC applied separately to A and D before combination:
%   * physical SM range  [SM_MIN, SM_MAX]
%   * retrieval DQX      Soil_Moisture_Dqx <= DQX_MAX
%   * RFI probability    Rfi_Prob          <= RFI_MAX
% Combination:
%   per-cell mean of valid A and D (NaN if both invalid).

% --- QC thresholds (CATDS / SMOS L3 user guide defaults) ---
SM_MIN  = 0.0;     % m^3/m^3, physical lower bound
SM_MAX  = 1.0;     % m^3/m^3, physical upper bound
DQX_MAX = 0.1;    % m^3/m^3, recommended uncertainty cutoff
RFI_MAX = 0.5;    % 0-1, recommended RFI-probability cutoff

% --- read + QC each pass ---
sm_a = read_and_qc_SMOS(file_path_smos_a, SM_MIN, SM_MAX, DQX_MAX, RFI_MAX);
sm_d = read_and_qc_SMOS(file_path_smos_d, SM_MIN, SM_MAX, DQX_MAX, RFI_MAX);

sm_a=flip(sm_a');
sm_d=flip(sm_d');
% --- combine A and D into a daily map ---
sm_daily = mean(cat(3, sm_a, sm_d), 3, 'omitnan');   % numcols x numrows

% % % --- reorient to (numrows x numcols), rows north -> south ---
% % sm_daily = sm_daily';                                % 584 x 1388
% % if lat(1) < lat(end)                                 % file stores S -> N
% %     sm_daily = flipud(sm_daily);                     % flip rows to N -> S
% % end

sm_daily=sm_daily';
SMOSproduct_atResolution.soil_moisture = sm_daily(:);
end


function sm = read_and_qc_SMOS(ncfile, smMin, smMax, dqxMax, rfiMax)
% Read one SMOS L3 daily file and return QC-filtered SM as a (lon x lat)
% double matrix. ncread auto-applies scale_factor, add_offset, and
% replaces _FillValue with NaN for floating-point output.

sm  = double(ncread(ncfile, 'Soil_Moisture'));
dqx = double(ncread(ncfile, 'Soil_Moisture_Dqx'));
rfi = double(ncread(ncfile, 'Rfi_Prob'));

sm(sm  < smMin | sm  > smMax)     = NaN;
sm(dqx > dqxMax) = NaN;
sm(rfi > rfiMax) = NaN;
end
