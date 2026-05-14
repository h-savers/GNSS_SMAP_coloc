function meas = buildMeasurementFromFlatMat(data, idx, suffix, parentChannel)
% BUILDMEASUREMENTFROMFLATMAT  Populate a Coherent L1BProductMeasurement
% from the flat HydroGNSS .mat per-channel fields at the given row indices.
%
% The flat .mat only has a single value per channel (no Coherent/Incoherent
% split), so this fills the Coherent measurement; Incoherent is left empty
% on the parent channel. SML2OP wants Reflectivity in dB, so the linear
% values in reflectivityLinear_<suffix> are converted with 10*log10
% (guarded for x>0, mirroring apply_general_filter.m:107-110). SNR stays
% in dB - L1BProductMeasurement.grid() will linearise it internally.

    meas = L1BProductMeasurement();
    meas.Name   = "Coherent";
    meas.parent = parentChannel;

    n = numel(idx);

    refl_linear = readField(data, "reflectivityLinear" + suffix, idx);
    reflDb = nan(n, 1);
    valid  = refl_linear > 0;
    reflDb(valid) = 10 * log10(refl_linear(valid));
    meas.ReflectionCoefficientAtSP = reflDb;

    meas.DDMSNRAtPeakSingleDDM        = readField(data, "SNR"               + suffix, idx);  % dB
    meas.AntennaGainTowardsSpecularPoint = readField(data, "rxAntennaGain"  + suffix, idx);
    meas.Coherency                    = readField(data, "coherencyRatio"   + suffix, idx);
    meas.PowerSpreadRatio             = readField(data, "powerRatio"       + suffix, idx);
    meas.Sigma0                       = readField(data, "NBRCS"            + suffix, idx);

    % Flag fields required so Filter's property-reflection doesn't see []
    % vectors of mismatched length. Their thresholds are NaN in
    % initSml2opConfig, so the filters never fire.
    z = zeros(n, 1);
    meas.DirectSignalInDDM = z;
    meas.HighNoiseKurtosis = z;
    meas.RFI_flag          = z;
    meas.CA_flag           = z;
    meas.LowAGSP           = z;
    meas.LowSNR            = z;
    meas.VeryLowSNR        = z;
    meas.LowOverallQuality = z;
end

function v = readField(data, name, idx)
    if isfield(data, char(name))
        v = double(data.(char(name))(idx));
        v = v(:);
    else
        v = nan(numel(idx), 1);
    end
end
