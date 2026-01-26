# Video-Based Heart Rate Estimation via RGB Color Modulation

This project implements a video-based heart rate estimation system using RGB color modulation (remote photoplethysmography – rPPG).  
The approach extracts subtle color variations from facial skin regions in video recordings and processes them to estimate heart rate without physical contact.

This is an academic project focused on signal processing and non-contact physiological monitoring.

## What it does
- Reads RGB video data
- Extracts temporal color signals from skin regions
- Applies signal processing techniques for rPPG
- Estimates heart rate from color modulation
- Compares or analyses results across time windows

## Approach
The method is based on the principle that blood volume changes cause subtle variations in skin color, particularly in the green channel.  
These variations are amplified and processed using filtering and frequency-domain analysis to estimate heart rate.

## Repository Structure
- main_entrega.m        Main MATLAB script for video processing and heart rate estimation
- README.md             Project documentation
- report.pdf            Project report describing the methodology and results

## Requirements
- MATLAB
- Video recordings with visible facial skin regions
- Adequate lighting and minimal motion for best results

## Run
1) Open MATLAB.
2) Place the video file in the project directory (or update the path in the code).
3) Run the main script:

main_entrega

The script will process the video and output an estimated heart rate signal.

## Outputs
- Estimated heart rate over time
- Intermediate processed signals (depending on configuration)
- Plots illustrating signal extraction and frequency analysis

## Notes & limitations
- This is a prototype for educational and research purposes.
- Performance is sensitive to motion, lighting conditions, and video quality.
- The method assumes visible, stable skin regions.
- Results are not intended for medical or clinical use.

## Context
Academic project developed for coursework in biomedical signal processing.

