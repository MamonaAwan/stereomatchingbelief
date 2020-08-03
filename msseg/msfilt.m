% Performing mean_shift image filtering using EDISON code implementation
% of Comaniciu's paper with a MEX wrapper from Shai Bagon. links at bottom
% of help
%
% Usage:
%   [F L] = msfilt(I,hs,hr)
%    
% Inputs:
%   I  - original image in RGB or grayscale
%   hs - spatial bandwith for mean shift analysis
%   hr - range bandwidth for mean shift analysis
%
% Outputs:
%   F  - segmented image
%
% Links:
% Comaniciu's Paper
%  http://www.caip.rutgers.edu/riul/research/papers/abstract/mnshft.html
% EDISON code
%  http://www.caip.rutgers.edu/riul/research/code/EDISON/index.html
% Shai's mex wrapper code
%  http://www.wisdom.weizmann.ac.il/~bagon/matlab.html
%
% Author:
%  This file and re-wrapping by Shawn Lankton (www.shawnlankton.com)
%  Dec. 2007
%------------------------------------------------------------------------

function F = msfilt(I,hs,hr)
  gray = 0;
  if(size(I,3)==1)
    gray = 1;
    I = repmat(I,[1 1 3]);
  end
  
  if(nargin < 3)
    hs = 10; hr = 7;
  end
  
  [fimg labels modes regsize grad conf] = edison_wrapper(I,@RGB2Luv,...
                 'steps', 1, 'SpatialBandWidth',hs,'RangeBandWidth',hr);

  F = Luv2RGB(fimg);

  if(gray == 1)
    F = F(:,:,1);
  end
