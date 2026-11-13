# Video-Based Heart Rate Estimation via RGB Color Modulation

This project implements a video-based heart rate estimation system using RGB color modulation (remote photoplethysmography – rPPG).
The approach extracts subtle color variations from facial skin regions in video recordings and processes them to estimate heart rate without physical contact.

This is an academic project focused on signal processing and non-contact physiological monitoring.

## What it does

- Reads RGB video data
- Detects the face and 68 facial landmarks (dlib) and builds forehead, nose and cheek skin regions
- Extracts the mean RGB signal of those regions for every frame
- Applies the POS (Plane-Orthogonal-to-Skin) projection and a 0.8–2.5 Hz band-pass filter
- Detects pulse peaks to estimate heart rate (HR) and heart-rate variability (SDNN, RMSSD)
- Compares the results against ground-truth PPG / HR signals

## Repository structure

| Path                        | Content                                                                                  |
| --------------------------- | ---------------------------------------------------------------------------------------- |
| `src/pos_subject1.m`        | Main script: video of subject 1, with PPG/HR ground truth and error metrics              |
| `src/pos_camera_subject6.m` | Same pipeline for subject 6 (own camera recording, HR-only ground truth)                 |
| `data/ground_truth/`        | Ground-truth files (`ground_truth*.txt`)                                                 |
| `data/videos/`              | Input videos (not stored in the repository, see its README)                              |
| `models/`                   | dlib landmark model (not stored in the repository, see its README)                       |
| `third_party/dlib-matlab/`  | MATLAB wrapper around dlib providing the `detector` function                             |
| `archive/`                  | Earlier versions kept for reference, including the originally submitted `main_entrega.m` |
| `report.pdf`                | Project report describing the methodology and results                                    |

## Requirements

- MATLAB R2019a or newer
- Image Processing Toolbox and Signal Processing Toolbox
- The `detector` MEX file (dlib wrapper) for your platform, built from `third_party/dlib-matlab/detector.cpp` if the prebuilt binary does not load
- `shape_predictor_68_face_landmarks.dat`, downloadable from <http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2> and placed in `models/`
- Video recordings with visible facial skin regions, adequate lighting and minimal motion for best results

## Run

1. Place the videos in `data/videos/` (e.g. `subject_1.avi`) and the landmark model in `models/`.
2. Open MATLAB and run `src/pos_subject1.m` (or `src/pos_camera_subject6.m`).
   Paths are resolved relative to the project, so the current folder does not matter.

## Outputs

- Estimated heart rate over time, compared with the ground truth
- Intermediate signals (raw POS signal, filtered pulse signal, detected peaks)
- HR error (mean and standard deviation) and SDNN / RMSSD errors

## Notes & limitations

- This is a prototype for educational and research purposes.
- Performance is sensitive to motion, lighting conditions, and video quality.
- The method assumes visible, stable skin regions.
- The frame rate is fixed at 30 fps (`fs = 30`) in the scripts.
- Results are not intended for medical or clinical use.

## Context

Academic project developed for coursework in Principles of Biosignals and Biomedical Imaging at Instituto Superior Técnico (IST), Lisbon.

## Credits

Face detection and alignment use a dlib MATLAB wrapper (`third_party/dlib-matlab/`) and dlib's 68-point shape predictor.
