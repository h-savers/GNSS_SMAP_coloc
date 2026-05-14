function channel = buildChannelFromFlatMat(data, idx, suffix, signalFrequency, polarisation, parentTrack)
% BUILDCHANNELFROMFLATMAT  Build one L1BProductChannel populated with a
% Coherent measurement (single value per SP from the flat .mat). Incoherent
% is left empty so Channel.grid() and OceanFilter.apply() skip it via
% their existing isempty() guards.
%
% signalFrequency must be one of the strings tested in
% L1BProductMeasurement.grid(): "GPS_L1", "GPS_L5", "Galileo_E1", "Galileo_E5".
% polarisation must be "LHCP" or "RHCP".

    channel = L1BProductChannel();
    channel.parent             = parentTrack;
    channel.SignalFrequency    = signalFrequency;
    channel.SignalPolarisation = polarisation;
    channel.Signal             = signalFrequency + "_" + polarisation;
    channel.Name               = channel.Signal;

    channel.Coherent = sml2op_bridge.buildMeasurementFromFlatMat( ...
        data, idx, suffix, channel);
    % channel.Incoherent left as default {} - guarded downstream.
end
