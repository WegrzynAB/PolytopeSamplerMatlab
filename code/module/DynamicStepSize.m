classdef DynamicStepSize < handle
    properties
        sampler
        opts
        
        consecutiveBadStep
        iterSinceShrink
        rejectSinceShrink
        ODEStepSinceShrink
        
        % store a good restart point (x,v)
        stableX
        stableV
    end
    
    methods
        function o = DynamicStepSize(sampler)
            o.sampler = sampler;
            o.opts = sampler.opts.DynamicStepSize;
            o.consecutiveBadStep = 0;
            o.iterSinceShrink = 0;
            o.rejectSinceShrink = 0;
            o.ODEStepSinceShrink = 0;
        end
        
        function o = initialize(o)
            o.stableX = o.sampler.x;
            o.stableV = o.sampler.v;
        end
        
        function o = propose(o)
            if o.sampler.prob > 0.7 && o.sampler.ODEStep < o.sampler.opts.maxODEStep
                o.stableX = o.sampler.x;
                o.stableV = o.sampler.v;
            end
        end
        
        function o = step(o)
            s = o.sampler;
            
            if s.prob < 0.5 || s.ODEStep == s.opts.maxODEStep
                o.consecutiveBadStep = o.consecutiveBadStep + 1;
            else
                o.consecutiveBadStep = 0;
            end
            
            o.iterSinceShrink = o.iterSinceShrink + 1;
            o.rejectSinceShrink = o.rejectSinceShrink + 1-s.prob;
            o.ODEStepSinceShrink = o.ODEStepSinceShrink + s.ODEStep;
            
            % Shrink the step during the warmup phase
            if (~s.freezed)
                shrink = 0;
                shiftedIter = o.iterSinceShrink + 20 / (1-s.momentum);

                targetProbability = (1-s.momentum)^(2/3) / 2;
                if (o.rejectSinceShrink > targetProbability  * shiftedIter)
                    shrink = sprintf('Failure Probability is %.4f, which is larger than the target %.4f', o.rejectSinceShrink / o.iterSinceShrink, targetProbability);
                end

                if (o.consecutiveBadStep > o.opts.maxConsecutiveBadStep)
                    shrink = sprintf('Consecutive %i Bad Steps', o.consecutiveBadStep);
                end
                
                if (o.ODEStepSinceShrink > o.opts.targetODEStep * shiftedIter)
                    shrink = sprintf('ODE solver requires %.4f steps in average, which is larger than the target %.4f', o.ODEStepSinceShrink / o.iterSinceShrink, o.opts.targetODEStep);
                end

                if ischar(shrink)
                    %s.x = o.stableX; s.v = o.stableV;
                    
                    o.iterSinceShrink = 0;
                    o.rejectSinceShrink = 0;
                    o.ODEStepSinceShrink = 0;
                    o.consecutiveBadStep = 0;
                    
                    s.stepSize = s.stepSize / o.opts.shrinkFactor;
                    s.momentum = 1 - min(1, s.stepSize / s.opts.effectiveStepSize);
                    
                    s.log('DynamicStepSize:step', 'Step shrinks to h = %f\n', s.stepSize, shrink);

                    if s.stepSize < o.opts.minStepSize
                        s.log('warning', 'Algorithm fails to converge even with step size h = %f.\n', s.stepSize);
                        s.terminate = true;
                    end
                end

                o.iterSinceShrink = o.iterSinceShrink + 1;
            elseif o.consecutiveBadStep > o.opts.maxConsecutiveBadStep
                s.x = mean(s.samples, 2);
                s.v = s.ham.resample(s.x, zeros(size(s.x)), 0);
                s.log('DynamicStepSize:step', 'Sampler reset to the center gravity due to consecutive bad steps.\n');
                
                o.iterSinceShrink = 0;
                o.rejectSinceShrink = 0;
                o.ODEStepSinceShrink = 0;
                o.consecutiveBadStep = 0;
            end
        end
        
        function o = finalize(o)
            
        end
    end
end