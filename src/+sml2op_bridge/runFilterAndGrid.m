function griddedProduct = runFilterAndGrid(product, seaMask)
% RUNFILTERANDGRID  Apply SML2OP's Filter (SNR, Reflectivity, Incidence)
% then OceanFilter to `product`, then call product.grid().
%
% Mirrors the active part of Processor.filter() (Processor.m:23-71) but
% sidesteps `Processor` construction so we don't have to load the
% neuralnetwork / semiempirical Algorithm tree. Each numeric threshold is
% guarded by ~isnan(thr), so initSml2opConfig can disable a filter by
% setting its threshold to NaN.
%
% Inputs
%   product : L1BProduct from buildL1BProductFromFlatMat
%   seaMask : (optional) 25-km EASE sea mask matrix; if omitted, loaded
%             from conf.StaticAuxiliarySeaMask.

    conf = Configuration.instance();

    if ~isnan(conf.ThrSNR)
        thr = conf.ThrSNR;
        Filter("DDMSNRAtPeakSingleDDM", @(x) x < thr).apply(product);
    end
    if ~isnan(conf.ThrRefl)
        thr = conf.ThrRefl;
        Filter("ReflectionCoefficientAtSP", @(x) x < thr).apply(product);
    end
    if ~isnan(conf.ThrSPIncidenceAngle)
        thr = conf.ThrSPIncidenceAngle;
        Filter("SPIncidenceAngle", @(x) x > thr).apply(product);
    end

    if nargin < 2 || isempty(seaMask)
        S = load(conf.StaticAuxiliarySeaMask, 'SEA_MASK_25km');
        seaMask = S.SEA_MASK_25km;
    end
    OceanFilter(seaMask).apply(product);

    griddedProduct = product.grid();
end
