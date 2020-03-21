import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:translator/translator.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';

class Identify {
  Future<String> get localPath async {
    final dir = await getApplicationDocumentsDirectory();
    return ('${dir.path}/Pictures/tmp.jpg');
  }

  Future<void> writeImg(Uint8List byteList) async {
    var path = await localPath;
    File img = new File(path);
    img.writeAsBytesSync(byteList);
  } 
  Future<String> readText() async {
    var img = await localPath;
    FirebaseVisionImage ourImage = FirebaseVisionImage.fromFilePath(img);
    TextRecognizer recognizeText = FirebaseVision.instance.textRecognizer();
    VisionText readText = await recognizeText.processImage(ourImage);
    // return readText.text;
    GoogleTranslator translator = GoogleTranslator();
    return translator.translate(readText.text, to: 'zh-tw');
  }

  Future<String> tessText() async {
    var img = await localPath;
    String extract = await TesseractOcr.extractText(img, language: "chi_tra");
    return extract;
  }
}
