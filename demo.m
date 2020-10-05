initSampler

%% Example 1: Sample uniform from a simplex
P = struct; d = 100;
P.Aineq = ones(1, d);
P.bineq = 1;
P.lb = zeros(d, 1);

o = sample(P, 100); % Number of samples = 100
s = thin_samples(o.samples);  % extract "independent" samples from the dependent samples
histogram(sum(s), 0.9:0.005:1)
title('distribution of l1 norm of simplex');
[pVal] = uniformtest(o, struct('toPlot', true));
drawnow()

%% Example 2: Sample uniform from Birkhoff polytope
P = struct; d = 10;
P.lb = zeros(d^2,1);
P.Aeq = sparse(2*d,d^2);
P.beq = ones(2*d,1);
for i=1:d
    P.Aeq(i,(i-1)*d+1:i*d) = 1;
    P.Aeq(d+i,i:d:d^2)=1;
end

opts = default_options();
opts.maxTime = 10; % Stop after 10 sec
fid = fopen('demo.log','w');
opts.outputFunc = @(tag, msg, varargin) {fprintf(fid, msg, varargin{:}); fprintf(msg, varargin{:})}; % output the results to the screen and demo.log
o = sample(P, +Inf, opts);
s = thin_samples(o.samples);
figure;
histogram(s(1,:))
title('marginal of first coordinate of Birkhoff polytope');
fclose(fid);
drawnow()

%% Example 3: Sample Gaussian distribution restricted on a hypercube
P = struct; d = 100;
P.lb = -ones(d,1);
P.ub = ones(d,1);
P.f = @(x) x'*x/2;
P.df = @(x) x;
P.ddf = @(x) ones(d,1);
P.dddf = @(x) zeros(d,1);

opts = default_options();
opts.maxStep = 10000; % Stop after 10000 iter
o = sample(P, +Inf, opts);
s = thin_samples(o.samples);
figure;
histogram(s(:))
title('Gaussian distribution restricted on [-1,1]');