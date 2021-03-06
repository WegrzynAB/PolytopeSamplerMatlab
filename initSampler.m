function initSampler(recompile)
addpath(genpath(fullfile('code')));

addpath(fullfile('coverage'));
addpath(fullfile('coverage', 'problems'));

% check if the solver exists
if (~(nargin == 1 && recompile) && exist('CSolver_double') == 3)
    try
        x = CSolver_double('init', uint64(randi(2^32-1,'uint32')), speye(3));
        CSolver_double('delete', x);
        recompile = false;
    catch
        recompile = true;
    end
else
    recompile = true;
end

if (recompile)
    [path,~,~] = fileparts(mfilename('fullpath'));
    path = fullfile(path, 'code', 'solver');
    
    if (isempty(mex.getCompilerConfigurations('C++','Selected')))
        error('No C++ mex compiler is available.');
    end
    
    compiler = mex.getCompilerConfigurations('C++','Selected').ShortName;
    if (contains(compiler, 'MSVCPP'))
        mex_with_fmath = ...
            'mex -R2018a -silent -g COMPFLAGS="$COMPFLAGS /O2 /arch:AVX2 /GL /fp:fast"';
        mex_no_fmath = ...
            'mex -R2018a -silent -g COMPFLAGS="$COMPFLAGS /O2 /arch:AVX2 /GL"';
        oext = '.obj';
    elseif (contains(compiler, 'Clang++'))
        mex_with_fmath = ...
            'mex -R2018a -silent -O CFLAGS="$CFLAGS -march=native -ffast-math"';
        mex_no_fmath = ...
            'mex -R2018a -silent -O CFLAGS="$CFLAGS -march=native"';
        oext = '.o';
    elseif (contains(compiler, 'g++'))
        mex_with_fmath = ...
            'mex -R2018a -silent -O CFLAGS="$CFLAGS -march=native -ffast-math"';
        mex_no_fmath = ...
            'mex -R2018a -silent -O CFLAGS="$CFLAGS -march=native"';
        oext = '.o';
    else
        error('Currently, we only support MSVCPP, Clang++ or g++ as the compiler.');
    end
    obj = '%path/qd/util%oext %path/qd/bits%oext %path/qd/dd_real%oext %path/qd/dd_const%oext %path/qd/qd_real%oext %path/qd/qd_const%oext';

    %% CSolver_double
    c = {'%mex_fmath -output %path/CSolver_double %path/CSolver_double.cpp'};

    %% CSolver_dd
    c{end+1} = '%mex_no_fmath -c -outdir %path/qd %path/qd/util.cc';
    c{end+1} = '%mex_no_fmath -c -outdir %path/qd %path/qd/bits.cc';
    c{end+1} = '%mex_no_fmath -c -outdir %path/qd %path/qd/dd_real.cc';
    c{end+1} = '%mex_no_fmath -c -outdir %path/qd %path/qd/dd_const.cc';
    c{end+1} = '%mex_no_fmath -c -outdir %path/qd %path/qd/qd_real.cc';
    c{end+1} = '%mex_no_fmath -c -outdir %path/qd %path/qd/qd_const.cc';
    c{end+1} = '%mex_no_fmath -output %path/CSolver_dd %path/CSolver_dd.cpp %obj';

    %% replace keywords
    keywords = {'%path', '%mex_fmath', '%mex_no_fmath', '%obj', '%oext'};
    replaces = {path, mex_with_fmath, mex_no_fmath, obj, oext};
    replaces = replace(replaces, keywords, replaces);

    for i = 1:length(c)
        c{i} = replace(c{i}, keywords, replaces);
    end

    %% Run the commands
    for i = 1:length(c)
        disp(c{i})
        eval(c{i});
    end
end