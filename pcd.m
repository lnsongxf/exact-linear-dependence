function [pr,eta,cs] = pcd(X,Y,W,taper_method_str,mv_correction)
%PCD Partial correlation decomposition for vector AR processes.
%   R = PCD(X,Y) returns the KL-by-1 vector of the partial correlation
%   decomposition between the N-by-K matrix X and the N-by-L matrix
%   Y, where KL=K*L. Columns of X and Y correspond to time series
%   and rows correspond to time indices.
%
%   R = PCD(X,Y,W,...) returns the partial correlation decomposition
%   between X and Y conditioned on the N-by-C matrix W.
%
%   [R,ETA] = PCD(...) also returns the KL-by-1 vector ETA, the vector
%   of variances for each independent partial correlation in R. 
%
%   [R,ETA,CS] = PCD(...) also returns the KL-by-1 vector CS, the vector
%   specifying the dimension of the multivariate condtiional process
%   going into each computation of R.
%
%   [...] = PCD(...,TAPER) optional string specifying the taper method used
%   for inferring the autocorrelation function for Bartlett''s formula using one
%   of the following techniques:
%     - 'none' (default)
%     - 'tukey'
%     - 'parzen'
%     - 'bartlett'
%
%   [...] = PCD(...,BARTLETT) optional logical specifying whether to use
%   the multivariate version of Bartlett''s formula. false (default) means
%   use the original formula and true means use Roy''s multivariate formula.
%   The latter is only useful for partial correlations but there is no significance
%   testing set up for it yet.
%
%   See also <a href="matlab:help mvmi">mvmi</a>, <a href="matlab:help mvgc">mvgc</a>, <a href="matlab:help significance">significance</a>

% ------------------------------------------------------------------------------
% Copyright (C) 2020, Oliver M. Cliff <oliver.m.cliff@gmail.com>,
%
% If you use this code for your research, please cite the following paper:
%
% Oliver M. Cliff, Leonardo Novelli, Ben D Fulcher, James M. Shine,
% Joseph T. Lizier, "Exact Inference of Linear Dependence for Multiple
% Autocorrelated Time Series," arXiv preprint arXiv:2003.03887 (2020).
%
% This function is free software: you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free Software
% Foundation, either version 3 of the License, or (at your option) any later
% version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License along with
% this program. If not, see <http://www.gnu.org/licenses/>.
% ------------------------------------------------------------------------------

if nargin < 3
  W = [];
end

if nargin < 4
  taper = 0;
else
  switch taper_method_str
    case 'none'
      taper = 0;
    case 'tukey'
      taper = 1;
    case 'parzen'
      taper = 2;
    case 'bartlett'
      taper = 3;
  end
end

if nargin < 5
  mv_correction = false;
end

T = size(X,1); % Dataset length
k = size(X,2); % Dimension of X
l = size(Y,2); % Dimension of Y

all_resids = zeros(T,k*l,2);
pr = zeros(k*l,1); % Partial correlations
cs = zeros(k*l,1); % Number of conditionals

for j = 1:k
  X_j = X(:,j);
  for i = 1:l
    ij = ((j-1)*l)+i;
    
    Y_i = Y(:,i);
    C_ij = [W,Y(:,1:i-1),X(:,1:j-1)];

    % Compute and store residuals
    eXjZ = X_j - C_ij*(C_ij\X_j);
    eYiZ = Y_i - C_ij*(C_ij\Y_i);
    
    all_resids(:,ij,1) = eXjZ;
    all_resids(:,ij,2) = eYiZ;

    % Parcorrs are correlation b/w residuals
    pr(ij) = corr(eXjZ,eYiZ);
    
    % Number of conditions
    cs(ij) = size(C_ij,2);
  end
end

% Compute Bartlett corrections here so we don't have to pass back the residuals
eta = bartlett(all_resids,taper,mv_correction);