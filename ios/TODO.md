# FitTwin iOS App Development TODO

## Phase 1: Research & Technology Selection
- [x] Research body measurement technologies (computer vision, ML models)
- [x] Research iOS camera frameworks (AVFoundation, ARKit)
- [x] Research pose estimation libraries (MediaPipe, Vision, CoreML)
- [x] Research accuracy testing methodologies
- [x] Document technology stack decisions

**Decision**: Use MediaPipe Pose Landmarker (33 landmarks, proven accuracy, real-time processing)

## Phase 2: Camera Implementation
- [ ] Implement full-screen front camera preview with AVFoundation
- [ ] Add camera permission handling
- [ ] Implement photo capture functionality
- [ ] Test camera on actual iPhone device

## Phase 3: Computer Vision & Body Detection
- [ ] Integrate pose estimation framework
- [ ] Implement body segmentation
- [ ] Add AR overlay for user guidance
- [ ] Validate body detection accuracy

## Phase 4: Measurement Extraction
- [ ] Research measurement algorithms
- [ ] Implement measurement calculation from pose landmarks
- [ ] Add validation and error handling
- [ ] Test measurement accuracy

## Phase 5: Backend Integration
- [ ] Research backend API endpoints
- [ ] Implement API client
- [ ] Add data persistence (save measurements to backend)
- [ ] Test end-to-end data flow

## Phase 6: User Experience Enhancements
- [ ] Add phone angle detection
- [ ] Implement audio narration
- [ ] Add clothing guidance
- [ ] Implement countdown timers

## Phase 7: Testing & Validation
- [ ] Create test data collection framework
- [ ] Implement accuracy testing
- [ ] Document test results
- [ ] Fix identified issues

## Phase 8: Deployment
- [ ] Final testing on iPhone
- [ ] Push to GitHub
- [ ] Create documentation
- [ ] Prepare for TestFlight distribution
