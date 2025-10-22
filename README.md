# armadillo
**The purpose of this pipeline is to identify neural electrophysiologic features in Blackrock Neurotech EEG recordings that reliably classify cognitive behaviors. Classifier can be input to Elemem closed-loop stimulation experiments. Stimulation parameters ideal for classifier result reversal are explored.**

<p align="center">
  <img src="armadillo.png" alt="Armadillo" width="350"/>
</p>

**Armadillo:**
- The state animal of Texas.
- Thick-skinned like Rhinos and Hippos. 
- A Spanish adjective that endearingly describes something as well built. 
- In this repository, it stands for Associative Recognition Machine-learning Automatic Detection of Interfering Line-noise and Low-frequency Oscillations.


## Overview:
The main goal is to develop a reliable classifier of neural activity that could be implemented in a classifier-based closed-loop stimulation device aiming to revert classifier results. This Matlab-based pipeline provides tools to attain this goal, integrating Blackrock Neurotech EEG data and Elemem software.


## Features:
- **Data Curation**: Pipeline standardizes electrodes' anatomic location labels confirmed by neurologist into 250 well-sampled anatomic location groups (vs 150 and 400 from two previous automatic methods). This aids in exploring the relevance of anatomic location connectivity and individual activity to a cognitive process.
- **Data Restructuring**: Behavioral events files are restructured to simplify code that compares features of all possible combinations of behaviors or experimental conditions.
- **Line-noise and Artifact Handling**: Signal and power spectral density of sample EEG and events of interest are plotted to aid in the exclusion of noisy channels and artifactual events from analysis and classification. Visualization of sample signal can aid in diagnosis of hardware issues. Manual labeling of noise and artifact could aid in the development of classifiers that would automatically identify and exlude noisy channels and artifact.
- **Brain Plots and Timelapses**: Data and results are easily visualized with 3D plots of electrodes from different views of the brain. Time series of data or results are converted to animated GIFs.
- **Data Alignment**: Pipeline ensures millisecond precision of alignment of behavioral data to EEG data, including new protocol for sync pulse delivery, improving reliability of results.


## Tech Stack:
- **Languages**: Matlab.


## Installation:
1) Download repository.
2) Edit paths for repository directory in all files.


## Usage:
1) Save Blackrock Neurotech or Nihon Kohden EEG recordings in folders with this format: /armadillo/subject_files/subject_code/yyyy-mm-dd_experiment-name/raw/recording.(ns3/EEG) .
2) Save corresponding behavioral events in .mat files in folders with this format: /armadillo/subject_files/subject_code/yyyy-mm-dd_experiment-name/behavioral/events.mat .
3) Execute update_subject.sh subject_code from command terminal.


## Future Improvements:
- Integrate behavioral features and electrophysiologic phase features into classifier.
- Add more classification methods to pipeline and Elemem codebase (SVM, neural networks).
- Develop classifier for noisy channels and artifactual events.

## Example Alignment Corrections
Task computer time clock runs faster than 1000Hz samples of EEG recording, as shown by the negative slopes in the subplots of "EEG pulses - Event Pulses", which have been retimed relative to the first pulse of each set. This would be corrected by correlating EEG pulse times to event pulse times and inferring EEG offsets. Nevertheless, there could be glitches in computer time that shift the time of a set of pulses. These pulses would previously be unmatched from the correlation, and thus the inferred EEG offset would be inaccurate. In the present method computer time is corrected to account for these errors. This is verified by getting the ratios of the differences between pulses of one set and the differences of matched pulses of a different set and making sure the ratios remain between 0.9975 and 1.0025.

<p align="center">
  <img src="/plots/alignment/SC001_AR_session_0_6-mismatch.png" alt="Alignment1" width="1080"/>
</p>
<p align="center">
  <img src="/plots/alignment/SC001_AR_session_0_7-corrected.png" alt="Alignment2" width="1080"/>
</p>
<p align="center">
  <img src="/plots/alignment/SC002_AR_session_0_6-mismatch.png" alt="Alignment3" width="1080"/>
</p>
<p align="center">
  <img src="/plots/alignment/SC002_AR_session_0_7-corrected.png" alt="Alignment4" width="1080"/>
</p>

Below, an example where no such errors occurred, and where the correlation inference errors were minimal.
<p align="center">
  <img src="/plots/alignment/SC003_AR_session_1_6-mismatch.png" alt="Alignment5" width="1080"/>
</p>
<p align="center">
  <img src="/plots/alignment/SC003_AR_session_1_7-corrected.png" alt="Alignment6" width="1080"/>
</p>

Below, the corrected offset (y-axis) for all sessions (x-axis).
<p align="center">
  <img src="/plots/alignment/corrected_offset.jpg" alt="Alignment1" width="1080"/>
</p>

New sync pulse delivery method developed so that this method could be applied automatically.
