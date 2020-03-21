# flutter-OCR
*(Optical Character Recognition)*

app using firebase ml-kit[https://firebase.google.com/docs/ml-kit/android/recognize-text]
and [tesseract](https://pub.dev/packages/tesseract_ocr) to OCR

## Getting Started

Download your language [trained data](https://github.com/tesseract-ocr/tessdata) and put it in assets folder

Then, create your own [firebase project](https://console.firebase.google.com/) and Sync with Gradle

run `flutter pub get` , Enjoy it on your android device 😎


## Known Issue
- crash when tesseract model scan
- firebase ml kit latin chars weird 😢

## Todo
- [ ] fix tesseract mode and push better chinese traineddata

## Reference
[flutter_ocr](https://github.com/luyongfugx/flutter_ocr)