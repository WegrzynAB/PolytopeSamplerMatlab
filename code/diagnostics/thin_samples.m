function [y] = thin_samples(x)
%y = thin_samples(x)
%extract independent samples by taking one sample every N/ess(x) many samples
% where ess(x) is the min(effectiveSampleSize(x))
%
%Input:
% x - a dim x N vector, where N is the length of the chain.
%
%Output:
% y - a dim x ess(x) vector.

ess = effective_sample_size(x);
gap = size(x,2)/min(ess);
y = x(:, ceil(0.1*size(x,2):gap:size(x,2)));
end
