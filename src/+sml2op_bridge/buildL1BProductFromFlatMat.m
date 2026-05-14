function product = buildL1BProductFromFlatMat(data, abs_idx, constellation_idx)
% BUILDL1BPRODUCTFROMFLATMAT  Build an SML2OP L1BProduct containing one
% Track per constellation populated from the flat HydroGNSS .mat at the
% given row indices.
%
% Inputs
%   data              : the loaded flat .mat struct.
%   abs_idx           : row indices into `data` (e.g. the H06 block).
%   constellation_idx : string array same length as abs_idx, values "GPS"/"Galileo".
%
% Output
%   product.tracks = {gpsTrack, galileoTrack} - both always present;
%   either may have TrackSize=0 if that constellation has no rows in
%   abs_idx, which L1BProductTrack.grid handles via its early-return.

    abs_idx = abs_idx(:);
    constellation_idx = constellation_idx(:);

    product = L1BProduct();
    product.Name = "FlatMatBridge";

    % Receiver positions live on the parent product; tracks index them via
    % `correspondences`. Provide the full per-row vectors so any track row
    % can be looked up.
    n_full = numel(data.specularPointLat);
    product.ReceiverPositionX = getOrNaN(data, 'ReceiverPositionX_all', n_full);
    product.ReceiverPositionY = getOrNaN(data, 'ReceiverPositionY_all', n_full);
    product.ReceiverPositionZ = getOrNaN(data, 'ReceiverPositionZ_all', n_full);

    gpsIdx     = abs_idx(constellation_idx == "GPS");
    galileoIdx = abs_idx(constellation_idx == "Galileo");

    gpsTrack     = sml2op_bridge.buildTrackFromFlatMat(data, gpsIdx,     "GPS",     product);
    galileoTrack = sml2op_bridge.buildTrackFromFlatMat(data, galileoIdx, "Galileo", product);

    product.tracks = {gpsTrack, galileoTrack};
end

function v = getOrNaN(data, name, n)
    if isfield(data, name)
        v = double(data.(name));
        v = v(:);
    else
        v = nan(n, 1);
    end
end
