function conf = initSml2opConfig(cfgPath)
% INITSML2OPCONFIG  Initialise the SML2OP Configuration and Logger singletons
% so that L1B objects, Filter, OceanFilter, and the grid pipeline can run
% from a non-SML2OP entry point.
%
% Mirrors the singleton init done in SML2OP/src/entrypoint.m (lines 6, 31)
% then mutates threshold properties to enforce the four filters the
% collocation pipeline cares about (SNR, Refl, Incidence, Ocean) while
% neutralising the rest plus the post-gridding QualityFlags setFlag loop
% inside L1BProductMeasurement.grid (lines 50-72).

    persistent initialised
    if isempty(initialised)
        sml2opSrc = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
                             '..', '..', 'SML2OP', 'src');
        if exist('Configuration', 'class') ~= 8
            addpath(genpath(sml2opSrc));
        end
        initialised = true;
    end

    conf = Configuration.instance(cfgPath);

    % SML2OP's Logger is needed by every Loggable subclass we build below.
    logPath = conf.LogsOutput;
    if ~exist(logPath, 'dir')
        mkdir(logPath);
    end
    Logger.instance(logPath, conf.LogsLevel, conf.OutputLevel);

    % Pin grid dimensions to 25 km EASE-Grid 2.0 (matches collocation pipeline).
    conf.SpatialResolution = 25;
    conf.Cols_n = 1388;
    conf.Rows_n = 584;

    % Only LHCP is gridded, matching the legacy "_1_L"/"_5_L" suffix usage.
    conf.Polarization = "left";

    % Active filters.
    conf.ThrSNR             = 0.5;
    conf.ThrRefl            = -45;
    conf.ThrSPIncidenceAngle = 45;

    % Disable the other SML2OP threshold filters (NaN means "skip" in
    % Processor.applyFilter; runFilterAndGrid replicates that guard).
    conf.ThrAntennaGainTowardsSpecularPoint = NaN;
    conf.ThrCoherency = NaN;
    conf.ThrDDM       = NaN;
    conf.ThrKurt      = NaN;
    conf.ThrRFI       = NaN;
    conf.ThrCA        = NaN;
    conf.ThrSnowIceCover = [];

    % Neutralise the QualityFlags setFlag loop in L1BProductMeasurement.grid
    % (Measurement.m:50-72). The loop body checks
    %   LinearStdReflectivity(col,row) > Thr_H_STD_*   and
    %   SNR(col,row)                   < Thr_L_SNR_*
    % Setting std thresholds to +Inf and SNR thresholds to -Inf makes both
    % comparisons unreachable, so QualityFlags stays all zero.
    conf.Thr_H_STD_L   = Inf;
    conf.Thr_H_STD_L_5 = Inf;
    conf.Thr_H_STD_R   = Inf;
    conf.Thr_L_SNR_L   = -Inf;
    conf.Thr_L_SNR_L_5 = -Inf;
    conf.Thr_L_SNR_R   = -Inf;
end
