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

## Example Timelapse
Using timelapse code, may visualize timeseries data (eg. event related potentials, normalized power values, t-statistics) in brain plots converted to GIFs. Input is a matrix; with every row being the time series associated to an electrode with MNI normalized coordinate data. Color maps are selected for the respective time series. Below is an example of a timelapse, which for every time point, displays color coded electrodes in one of the anatomical regions labeled by a neurologist.
<p align="center">
  <img src="/plots/timelapses/brain_region_all_tasks.gif" alt="Brain Region Timelapse" width="1080"/>
</p>

## Example Signal Check
Signal quality is an important matter in cognitive electrophysiology analyses. Previously, channels were excluded based on whether the signal exceeded a level of kurtosis or root median square, and subjects were excluded based on whether half of the available channels met exclusion criteria. In this project visualization tools are provided that would allow the user to visually identify noisy channels for hardware diagnostics and analysis exclusions. Power spectral densities and one second of sample signals of all active channels are plotted to easily identify channels with excessive line noise.

The three figures below show an example where noise affects signal almost exclusively from channels in hardware banks B (ch. 65-128) and C (ch. 129-192), potentially from improper connection or damage of the cables used for recording from these banks. In addition to fundamental frequency and harmonics of line noise (60Hz), one can also see noise present in multiples of 20Hz in raw signal.
<p align="center">
  <img src="/plots/signal_check/SC001_PSDs.png" alt="SignalCheck1" width="1080"/>
</p>
<p align="center">
  <img src="/plots/signal_check/SC001_signals_separate.png" alt="SignalCheck2" width="1080"/>
</p>
<p align="center">
  <img src="/plots/signal_check/SC001_signals_together.png" alt="SignalCheck3" width="1080"/>
</p>

The next example, shows line noise affecting signal mostly from bank A (ch. 1-64). The noise decreases in power with bipolar referencing in some cases. Nevertheless, one can also see subharmonic components of line noise at 30Hz. Previous methods would only filter out fundamental and harmonic frequencies. Nevertheless, the presence of subharmonic components (eg. 3.75, 7.5, 15, and 30Hz) may interfere with the interpretation of results of low frequency bands of interest theta (4-8Hz) and beta (12-30Hz); and filtering these bands is not an option.
<p align="center">
  <img src="/plots/signal_check/SC002_PSDs.png" alt="SignalCheck4" width="1080"/>
</p>
<p align="center">
  <img src="/plots/signal_check/SC002_signals_separate.png" alt="SignalCheck5" width="1080"/>
</p>
<p align="center">
  <img src="/plots/signal_check/SC002_signals_together.png" alt="SignalCheck6" width="1080"/>
</p>

The next example shows line noise only affect a portion of channels of some depth electrodes. The noise remains after bipolar referencing. One may attempt to filter the noise or exclude this set of channels.
<p align="center">
  <img src="/plots/signal_check/SC003_PSDs.png" alt="SignalCheck7" width="1080"/>
</p>
<p align="center">
  <img src="/plots/signal_check/SC003_signals_separate.png" alt="SignalCheck8" width="1080"/>
</p>
<p align="center">
  <img src="/plots/signal_check/SC003_signals_together.png" alt="SignalCheck9" width="1080"/>
</p>

The last example shows only a few channels with noise not exceeding the power of lower frequency components and mostly channels almost completely devoid of noise. 
<p align="center">
  <img src="/plots/signal_check/SC004_PSDs.png" alt="SignalCheck10" width="1080"/>
</p>
<p align="center">
  <img src="/plots/signal_check/SC004_signals_separate.png" alt="SignalCheck11" width="1080"/>
</p>
<p align="center">
  <img src="/plots/signal_check/SC004_signals_together.png" alt="SignalCheck12" width="1080"/>
</p>


## Example Alignment Corrections
Task computer time clock runs faster than 1000Hz samples of EEG recording, as shown by the negative slopes in the subplots of "EEG pulses - Event Pulses", which have been retimed relative to the first pulse of each set. This would be corrected by correlating EEG pulse times to event pulse times and inferring EEG offsets. Nevertheless, there could be glitches in computer time that shift the time of a set of pulses. These pulses would previously be unmatched from the correlation, and thus the inferred EEG offset would be inaccurate. In the present method computer time is corrected to account for these errors. This is verified by getting the ratios of the differences between pulses of one set and the differences of matched pulses of a different set and making sure the ratios remain between 0.9975 and 1.0025.

Below, two examples of where such errors occured; with differential ratios showing correctly matched pulses (top), and alignment before (middle) and after (bottom) correction.

<p align="center">
  <img src="/plots/alignment/SC001_AR_session_0_4-differentials-after.png" alt="PulseDifferentials1" width="1080"/>
</p>
<p align="center">
  <img src="/plots/alignment/SC001_AR_session_0_6-mismatch.png" alt="Alignment1" width="1080"/>
</p>
<p align="center">
  <img src="/plots/alignment/SC001_AR_session_0_7-corrected.png" alt="Alignment2" width="1080"/>
</p>


<p align="center">
  <img src="/plots/alignment/SC002_AR_session_0_4-differentials-after.png" alt="PulseDifferentials2" width="1080"/>
</p>
<p align="center">
  <img src="/plots/alignment/SC002_AR_session_0_6-mismatch.png" alt="Alignment3" width="1080"/>
</p>
<p align="center">
  <img src="/plots/alignment/SC002_AR_session_0_7-corrected.png" alt="Alignment4" width="1080"/>
</p>

Below, an example where no such errors occurred, and where the correlation inference errors were negligible.
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

New sync pulse delivery method developed so that this alignment method could be applied automatically.
