# ArrowHead

An inspector-focused iPhone camera app. A marker is visible in the live camera preview and is permanently composited into the saved photo when the shutter is pressed.

## MVP controls

- Left button: choose Arrow, Dot, Circle, Oval, or Square.
- Center button: capture and save to the `Inspection Photos` album.
- Right button: turn the marker on or off.
- Drag the marker to position it. Pinch to resize and rotate with two fingers.

## Run on iPhone

1. Open `ArrowHead.xcodeproj` in the full Xcode app.
2. Select the `ArrowHead` target and choose your Apple Development Team under Signing & Capabilities.
3. Connect an iPhone, select it as the run destination, and press Run.
4. Allow Camera and Photos access on first launch.

The project targets iOS 17. A physical iPhone test is required because the simulator cannot validate the real camera capture path.
