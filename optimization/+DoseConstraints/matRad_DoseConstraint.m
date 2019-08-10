classdef (Abstract) matRad_DoseConstraint < matRad_DoseOptimizationFunction
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% matRad_DoseConstraint: Interface for optimization constraints.
%   This abstract base class provides the interface of constraints for
%   non-linear optimization.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2015 the matRad development team. 
% 
% This file is part of the matRad project. It is subject to the license 
% terms in the LICENSE file found in the top-level directory of this 
% distribution and at https://github.com/e0404/matRad/LICENSES.txt. No part 
% of the matRad project, including this file, may be copied, modified, 
% propagated, or distributed except according to the terms contained in the 
% LICENSE file.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
    %These should be abstract methods, however Octave can't parse them. As soon 
    %as Octave is able to do this, they should be made abstract again    
    methods %(Abstract)
        %returns the constraint function(s) value(s) for a given dose
        %vector. Needs to be implemented in sub-classes.
        function cDose        = computeDoseConstraintFunction(obj,dose)
          error('Function needs to be implemented!');
        end
        
        %return the (dose-dependent) constraint function jacobian for a
        %given dose vector. Needs to be implemented in sub-classes.
        function cDoseJacob   = computeDoseConstraintJacobian(obj,dose)
          error('Function needs to be implemented!');
        end
        
        %Returns upper bound(s) / max value(s) for constraint function(s)
        %Needs to be implemented in sub-classes.
        function cu           = upperBounds(obj,n)
          error('Function needs to be implemented!');
        end
        
        %Returns lower bound(s) / min value(s) for constraint function(s)
        %Needs to be implemented in sub-classes.
        function cl           = lowerBounds(obj,n)                
          error('Function needs to be implemented!');
        end
    end

    methods (Access = public)
        
        %returns the dose-gradient for the given dose vector. 
        %Implementation in subclasses only required if
        %no Hessian approximation shall be used. Will be ignored with
        %Quasi-Newton methods
        function fDoseHessian = computeDoseObjectiveHessian(obj,dose)
            fDoseHessian = NaN;
        end
       
        % default constructor of matRad_DoseConstraint
        function obj = matRad_DoseConstraint(inputArg)
            % superclass constructor is already called when this is line is reached
            % additional matRad_DoseConstraint constructor specific code goes here
        end
        
        function jStruct = getDoseConstraintJacobianStructure(obj,n)
        %return the structure of the (dose-dependent) constraint function 
        %jacobian for a given length n of the dose vector. Returns a
        %default of a jStruct
            jStruct = ones(n,1);
        end
        
        %Overloads the struct function to add Objective related information
        %to output struct
        function s = struct(obj)
            s = struct@matRad_DoseOptimizationFunction(obj);
        end
    end
end

