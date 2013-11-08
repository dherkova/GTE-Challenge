# MATLAB
Set of MATLAB scripts to help with the challenge

## External dependencies
External MATLAB files are already included for ease of use. See their
respective pages for more details:

1. [YAMLMatlab](https://code.google.com/p/yamlmatlab/)
2. [parse_pv_pairs](http://www.mathworks.com/matlabcentral/fileexchange/9082-parsepvpairs)
3. [sshist](http://www.mathworks.com/matlabcentral/fileexchange/24913-histogram-binwidth-optimization)

## Usage
Remember to add the external dependencies to your path:

        path(path,'/yourPathToGTE-Challenge/MATLAB/external');
        path(path,'/yourPathToGTE-Challenge/MATLAB/external/YAMLMatlab');

The MATLAB scripts rely heavily on the following structures:

* **network**
  * **network.RS** adjacency matrix (usually sparse). Element RS(i,j) stores
    the weight of the connection from i to j.
  * **network.X** vector containing the X position of the nodes.
  * **network.Y** vector containing the Y position of the nodes.

* **firings**
  * **firings.T** vector containing the times of spike events.
  * **firings.N** vector containing the nodes associated to the spike
    events.

## Included Scripts
Every script is fully documented, look inside the file.

### spikeTimesToFluorescence
Converts a vector with spike times to a fluorescence signal.

### YAMLToNetwork
Converts a YAML network structure to a MATLAB one.

### nestToFirings
Cconverts nest output files (indices and times) to a MATLAB firings structure.

### firingsToFluorescence
Converts a MATLAB firings structure to a fluorescence signal.

### plotFluorescenceHistogram
Plots the Fluorescence Histogram.

## History

### November 8, 2013

Adding more scripts.

### November 7, 2013

First version. Adding some scripts and readme file.

