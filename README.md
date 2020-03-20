# OCR

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# flutter-ml-OCR (Optical Character Recognition)

app using firebase ml-kit and [tesseract](https://pub.dev/packages/tesseract_ocr) to OCR

## Getting Started

Download [trained data](https://github.com/tesseract-ocr/tessdata) and put it in assets folder 
run `flutter pub get` , and test it on your android device

## Known Issue
- cannot switch to tesseract mode
- firebase ml kit latin chars weird 😢

## Todo
- [ ] fix tesseract mode and push chinese traineddata

## Reference
[flutter_ocr](https://github.com/luyongfugx/flutter_ocr)