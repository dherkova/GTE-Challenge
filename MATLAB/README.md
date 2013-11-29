# MATLAB
Set of MATLAB scripts to help with the challenge

## External dependencies
External MATLAB files are already included for ease of use. See their
respective pages for more details:

1. [YAMLMatlab](https://code.google.com/p/yamlmatlab/)
2. [parse_pv_pairs](http://www.mathworks.com/matlabcentral/fileexchange/9082-parsepvpairs)
3. [sshist](http://www.mathworks.com/matlabcentral/fileexchange/24913-histogram-binwidth-optimization)
4. [colormap utilities](http://www.mathworks.es/matlabcentral/fileexchange/24371-colormap-and-colorbar-utilities-sep-2009)

If you want to visualize the networks you are better off using
[Gephi](http://www.gephi.org) and using the provided `networkToGEXF`
function to transform the provided networks to GEXF format. Seriouslly,
use it. It's free and it's easy. Just load the GEXF file and play!

## Notes
Remember to add the external dependencies to your path:

        path(path,'/yourPathToGTE-Challenge/MATLAB/external');
        path(path,'/yourPathToGTE-Challenge/MATLAB/external/YAMLMatlab');
        path(path,'cm_and_cb_utilities');
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

## Installation and mini-tutorial
1. Download the zip within the [GTE-Challenge repository] (https://github.com/dherkova/GTE-Challenge/archive/master.zip)
2. Load the file called `reconstruction.m` located in the MATLAB folder.
3. Change the folders in the first cell to match yours.
4. Run it cell by cell to understand what is going on. The PDF
   calculation can be quite slow (currently 3min for 50 nodes in a
   modern PC, and it scales ~O(N^2). To obtain good reconstruction speeds
   one should use the C code from the [te-causality package] (https://github.com/olavolav/te-causality).

## HOWTO for the Challenge
1. Load the script `challengeGeneration.m`. This script creates the
   files that will be used by the challenge participants based on the
   NEST and network files provided by Olav.
2. Load the script `challengeVisualization.m`. This script loads
   fluorescence and network data and uses the available plotting scripts
   to visualize the dynamics.
3. Load the script `challengeExample.m`. This script is an example of a
   Challenge submission, it uses only the files generated in the
   previous script and produces a matrix with scores as output.
4. Load the script `challengeValidation.m`. This script compares the
   scoring matrix with the true topology through the ROC curve. The AUC
   and the TPR at 10% are the main observables to be checke in the
   challenge. (AUC = 1 perfect reconstruction, 0.5 completely random).

## Included Scripts

### reconstruction
Main script. Loads a NEST file and performs all the necessary steps to
obtain the reconstruction.

### challengeGeneration
This script generates the data for the challenge (fluorescence and network structure). Note: The network and spike data have been created a priori.

### challengeVisualization
Loads fluorescence and network data and plots it using different options
and views.

### challengeExample
Example of a challenge submission. Loads the provided fluorescence file
and performs the reconstruction (based on GTE). As output it generates a
scoring matrix to be validated against the true network.

### challengeValidation
Example of a challenge validation. Compares the provided scores matrix
wtih the true topology using the ROC curve.

## Included Functions

### YAMLToNetwork
Converts a YAML network structure to a MATLAB one.

### nestToFirings
Converts NEST output files (indices and times) to a MATLAB firings structure.

### firingsToFluorescence
Converts a MATLAB firings structure to a fluorescence signal.

### spikeTimesToFluorescence
Converts a vector with spike times to a fluorescence signal.

### plotFluorescenceHistogram
Plots the Fluorescence Histogram.

### discretizeFluorescenceSignal
Discretizes the fluorescence signal.

### calculateJointPDFforGTE
Calculates the joint PDF required for the Generalized Transfer Entropy
computation. 

### calculateGTEfromJointPDF 
Calculates Generalized Transfer Entropy from the joint PDF previously
obtained.

### calculateROC 
Calculates the ROC by comparing the GTE scores with the real network.

### networkToGEXF
Converts a MATLAB network structure into a GEXF file so it can be read with GEPHI

### visualizeFluorescenceTimeSeries
Plots in the current figure the fluorescence time series. See the options for a detailed usage.

### visualizePair
Plots the time series of a pair of neurons I and J and tells you the I->J and J->I connetion weights.

### visualizeFluorescenceMovie
Creates a movie from the fluorescence data similar to the one obtained in the experiments


## History

### November 29, 2013
Added visualization scripts and a GEXF network converter.

### November 14, 2013
Fixed the main bug in GTE calculation, now it works as expected.

### November 12, 2013
Added independent scripts for: challenge generation, the challenge
itself and validation.

### November 11, 2013
Added the remaining scripts. Now there is enough to go from NEST
input to the reconstruction.

### November 8, 2013
Adding more scripts.

### November 7, 2013
First version. Adding some scripts and readme file.

