# Super-heterodyne Receiver & DSB-SC AM Communication System Simulation

## Overview

This project simulates a **Super-heterodyne receiver** for a **DSB-SC AM communication system** using MATLAB. The system processes multiple audio signals, modulates them using AM, performs **Frequency Division Multiplexing (FDM)**, and then recovers the selected station using RF, Mixer, IF, and Baseband stages. Experiments on RF filtering and LO frequency offset are also included.

## Features

- Converts stereo audio signals to mono and pads them for uniform length.
- Interpolates signals to prevent aliasing during high-frequency modulation.
- Implements DSB-SC AM modulation with carrier frequencies spaced 30 kHz apart.
- Combines multiple channels using FDM.
- Receiver stages: RF band-pass filter, Mixer with Local Oscillator, IF filtering, Baseband detection.
- Experiments:
  - Bypassing the RF filter
  - LO frequency offsets (0.1 kHz and 1 kHz)
- Plots spectra for each stage and plays back recovered audio signals.

## Project Structure

```
Superheterodyne-AM-Receiver/
├── audio/                  # Input WAV files
├── figures/                # Generated figures
├── src/                    # MATLAB code
│   └── superheterodyne_AM.m
├── report/                 # Report file
├── README.md
└── .gitignore
```

## Requirements

- MATLAB R2019b or later (for `designfilt`, `filtfilt`, and `audioread` functions)
- Five WAV audio files in the `audio/` folder

## How to Run

1. Open MATLAB.
2. Set your current folder to the project root.
3. Navigate to the `src/` folder.
4. Run the main script:

```matlab
superheterodyne_AM
```

5. Listen to the recovered audio signals and observe the plotted spectra.

## Output

- Spectrum plots for all stages: Baseband, AM Modulated, FDM, RF, Mixer, IF, and Recovered.
- Playback of recovered audio signals at different stages and experimental conditions.
- Bandwidth information printed in the MATLAB Command Window.

## Experiments

- **No RF Filter:** Demonstrates the effects of image frequency interference.
- **LO Offset:** Demonstrates the effects of LO frequency mismatches (0.1 kHz and 1 kHz) on audio quality.

## Author

- Mohaned Waleed Hosny
- Contact: mohaned.waleed.hosny@gmail.com
