// MIT License

// Copyright (c) 2018

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as ImageUtil;

import '../helper/identify.dart';
import '../helper/rotatescale.dart';
import '../helper/helper.dart';
import 'result_page.dart';

class CropPage extends StatefulWidget {
  CropPage({Key key, this.image, this.imageInfo}) : super(key: key);
  final ui.Image image;
  final ImageInfo imageInfo;
  @override
  _CropPageState createState() => new _CropPageState();
}

class _CropPageState extends State<CropPage>
    with SingleTickerProviderStateMixin {
  GlobalKey globalKey = new GlobalKey();
  ui.Image corpImg;
  String maskDirection = "center";
  double opacity = 0.5;
  double maskTop = 60.0;
  double maskLeft = 40.0;
  double maskWidth = 0.0;
  double maskHeight = 0.0;
  double dragStartX = 0.0;
  double dragStartY = 0.0;
  double imgDragStartX = 0.0;
  double imgDragStartY = 0.0;
  double imgWidth = 0.0;
  double imgHeight = 0.0;
  double oldScale = 1.0;
  double _scale = 1.0;
  double oldRotate = 0.0;

  double rotate = 0.0;
  Offset topLeft = new Offset(40.0, 60.0);
  Matrix4 matrix = new Matrix4.identity();
  GlobalKey imgKey = new GlobalKey();
  AnimationController _controller; // scan animate
  Identify _identify;
  @override
  void initState() {
    super.initState();
    _identify = new Identify();
    _controller =
        new AnimationController(duration: new Duration(seconds: 3), vsync: this)
          ..addListener(() {
            this.setState(() {});
          });
  }

  Future<ImageUtil.Image> copyCrop(ImageUtil.Image image, int corpX, int corpY,
      int corpWidth, int corpHeight) async {
    return new Future(
        () => ImageUtil.copyCrop(image, corpX, corpY, corpWidth, corpHeight));
  }

  Future<Uint8List> _cropImg() async {
    RenderRepaintBoundary boundary =
        globalKey.currentContext.findRenderObject();
    double pixelRatio = 1.5;
    ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    ImageUtil.Image uImage = ImageUtil.decodePng(pngBytes);
    int corpX = (maskLeft * pixelRatio).toInt();
    int corpY = (maskTop * pixelRatio).toInt();
    int corpWidth = (maskWidth * pixelRatio).toInt();
    int corpHeight = (maskHeight * pixelRatio).toInt();
    print(uImage.width.toString() +
        " " +
        uImage.height.toString() +
        " " +
        corpX.toString() +
        " " +
        corpY.toString() +
        " " +
        corpWidth.toString() +
        " " +
        corpHeight.toString());
    var nImage = await copyCrop(uImage, corpX, corpY, corpWidth, corpHeight);
    return ImageUtil.encodePng(nImage);
  }

  Future<void> _capturePng(bool ml) async {
    List<int> byteList = await _cropImg();
    await _identify.writeImg(byteList);
    var codec = await ui.instantiateImageCodec(byteList);
    var frame = await codec.getNextFrame();

    String txt = '';
    if (ml)
      txt = await _identify.tessText();
    else
      txt = await _identify.readText();
    print(txt);

    //重置
    _controller.reset();
    _controller.stop();

    Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => new ResultPage(
                ocrContent: txt, image: frame.image)));
  }

  void doCapturePng(bool _ml) async {
    _controller.repeat();
    _capturePng(_ml);
  }

  void onPanStart(DragStartDetails dragInfo) {
    dragStartX = dragInfo.globalPosition.dx;
    dragStartY = dragInfo.globalPosition.dy;
  }

  void onMaskPanStart(DragStartDetails dragInfo) {
    dragStartX = dragInfo.globalPosition.dx;
    dragStartY = dragInfo.globalPosition.dy;
    double margin = 20.0;
    //点击位置离跟左边点在10以内
    if ((dragStartX - maskLeft).abs() < margin &&
        dragStartY > (maskTop + margin) &&
        dragStartY < (maskTop + maskHeight - margin)) {
      maskDirection = "left";
    } else if ((dragStartY - maskTop).abs() < margin &&
        dragStartX > (maskLeft + margin) &&
        dragStartX < (maskLeft + maskWidth - margin)) {
      maskDirection = "top";
    } else if ((dragStartX - (maskLeft + maskWidth)).abs() < margin &&
        dragStartY > (maskTop + margin) &&
        dragStartY < (maskTop + maskHeight - margin)) {
      maskDirection = "right";
    } else if ((dragStartY - (maskTop + maskHeight)).abs() < margin &&
        dragStartX > (maskLeft + margin) &&
        dragStartX < (maskLeft + maskWidth - margin)) {
      maskDirection = "bottom";
    } else {
      maskDirection = "center";
    }
    //print(maskDirection+" " +dragStartX.toString()+" "+maskLeft.toString()+" "+(dragStartX -maskLeft).abs().toString());
  }

  void onPanEnd(DragEndDetails details) {
    dragStartX = 0.0;
    dragStartY = 0.0;
  }

  void onScaleStart(ScaleRotateStartDetails details) {
    imgDragStartX = details.focalPoint.dx;
    imgDragStartY = details.focalPoint.dy;
    rotate = 0.0;
  }

  void onScaleUpdate(ScaleRotateUpdateDetails details) {
    // double degrees = details.rotation * (180 / math.pi);
    if (details.scale == 1 && details.rotation == 0) {
      double moveX = (details.focalPoint.dx - imgDragStartX);
      double moveY = (details.focalPoint.dy - imgDragStartY);
      imgDragStartX = imgDragStartX + moveX;
      imgDragStartY = imgDragStartY + moveY;
      double dx = (topLeft.dx + moveX);
      double dy = (topLeft.dy + moveY);
      Offset offset = new Offset(dx, dy);

      setState(() {
        topLeft = offset;
      });
    } else {
      doRotateAndZoom(details.rotation, details.scale);
    }
  }

  void doRotateAndZoom(double rt, double scale) {
    rotate = rt;
    var matrix1 = new Matrix4.identity()..rotateZ(oldRotate + rotate);
    var diffScale = scale - _scale;
    oldScale = oldScale + diffScale;
    // if(diffScale>0.05 || diffScale<0.05){
    matrix1 = new Matrix4.identity()
      ..rotateZ(oldRotate + rotate)
      ..scale(oldScale);
    //}
    setState(() {
      matrix = matrix1;
    });
    _scale = scale;
  }

  void onScaleEnd(ScaleRotateEndDetails details) {
    imgDragStartX = 0.0;
    imgDragStartY = 0.0;
    oldRotate = oldRotate + rotate;
    rotate = 0.0;
    _scale = 1.0;
  }

  void onPanUpdate(String btn, DragUpdateDetails dragInfo) {
    //重新计算move
    //重新计算move
    double moveX = (dragInfo.globalPosition.dx - dragStartX);
    double moveY = (dragInfo.globalPosition.dy - dragStartY);

    dragStartX = dragStartX + moveX;
    dragStartY = dragStartY + moveY;

    double _maskHeight = maskHeight;
    double _maskWidth = maskWidth;
    double _maskTop = maskTop;
    double _maskLeft = maskLeft;
    //topleft,都变化了
    if (btn == "topleft") {
      _maskHeight = maskHeight - moveY;
      _maskWidth = maskWidth - moveX;
      _maskTop = maskTop + moveY;
      _maskLeft = maskLeft + moveX;
    }

    //topright，left不变
    if (btn == "topright") {
      _maskWidth = maskWidth + moveX;
      _maskHeight = maskHeight - moveY;
      _maskTop = maskTop + moveY;
    }

    //bottomLeft
    if (btn == "bottomleft") {
      _maskWidth = maskWidth - moveX;
      _maskLeft = maskLeft + moveX;
      _maskHeight = maskHeight + moveY;
      //_maskTop = maskTop+ moveY;
    }

    //bottomRight
    if (btn == "bottomright") {
      _maskWidth = maskWidth + moveX;
      _maskHeight = maskHeight + moveY;
    }
    if (btn == "left") {
      _maskWidth = maskWidth - moveX;
      _maskLeft = maskLeft + moveX;
    }

    if (btn == "top") {
      _maskHeight = maskHeight - moveY;
      _maskTop = maskTop + moveY;
    }
    if (btn == "bottom") {
      _maskHeight = maskHeight + moveY;
    }
    if (btn == "right") {
      _maskWidth = maskWidth + moveX;
    }

    //center
    if (btn == "center") {
      _maskLeft = maskLeft + moveX;
      _maskTop = maskTop + moveY;
    }

    //debugPrint("undate x:"+dragInfo.globalPosition.dx.toString()+" y:"+dragInfo.globalPosition.dy.toString()+" move:"+moveX.toString()+" maskWidth:" +maskWidth.toString());
    setState(() {
      maskWidth = _maskWidth;
      maskHeight = _maskHeight;
      maskTop = _maskTop;
      maskLeft = _maskLeft;
    });
  }

  Widget buildLoading() {
    return new Center(
        child: new Text(
      "Loading",
      style: new TextStyle(color: Colors.white),
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var size = MediaQuery.of(context).size;
    //手机宽高比
    var devW = size.width - 40 * 2;
    var devH = size.height - 2 * 60;
    var devWh = devW / devH;
    var imgWh = widget.imageInfo.image.width / widget.imageInfo.image.height;
    if (devWh < imgWh) {
      //如果机器宽高比比图片高，那么按照宽度适配
      imgWidth = devW;
      imgHeight = widget.imageInfo.image.height *
          (imgWidth / widget.imageInfo.image.width);
    } else {
      //否则按照高度适配
      imgHeight = devH;
      imgWidth = widget.imageInfo.image.width *
          (imgHeight / widget.imageInfo.image.height);
    }
    maskWidth = imgWidth;
    maskHeight = imgHeight;
    //print("====== imgHeight:"+imgHeight.toString()+"  imgWidth:"+imgWidth.toString());
  }

  Widget _buildImage(BuildContext context) {
    if (corpImg != null) {
      return new RawImage(
        image: corpImg,
        scale: 1.0,
      );
    }

    return new Stack(
      children: <Widget>[
        new RawGestureDetector(
          gestures: <Type, GestureRecognizerFactory>{
            ScaleRotateGestureRecognizer:
                new GestureRecognizerFactoryWithHandlers<
                    ScaleRotateGestureRecognizer>(
              () => new ScaleRotateGestureRecognizer(),
              (ScaleRotateGestureRecognizer instance) {
                instance
                  ..onStart = onScaleStart
                  ..onUpdate = onScaleUpdate
                  ..onEnd = onScaleEnd;
              },
            ),
          },
          child: new RepaintBoundary(
            key: globalKey,
            child: new Container(
              margin: const EdgeInsets.only(
                  left: 0.0, top: 0.0, right: 0.0, bottom: 0.0),
              padding: const EdgeInsets.only(
                  left: 0.0, top: 0.0, right: 0.0, bottom: 0.0),
              color: Colors.black,
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: new CustomSingleChildLayout(
                delegate:
                    new ImagePositionDelegate(imgWidth, imgHeight, topLeft),
                child: Transform(
                  child: new RawImage(
                    image: widget.image,
                    scale: widget.imageInfo.scale,
                  ),
                  alignment: FractionalOffset.center,
                  transform: matrix,
                ),
              ),
            ),
          ),
        ),
        new Positioned(
            left: 0.0,
            top: 0.0,
            width: MediaQuery.of(context).size.width,
            height: maskTop,
            child: new IgnorePointer(
                child: new Opacity(
              opacity: opacity,
              child: new Container(
                color: Colors.black,
              ),
            ))),
        new Positioned(
            left: 0.0,
            top: maskTop,
            width: this.maskLeft,
            height: this.maskHeight,
            child: new IgnorePointer(
                child: new Opacity(
              opacity: opacity,
              child: new Container(color: Colors.black),
            ))),
        new Positioned(
            right: 0.0,
            top: maskTop,
            width: (MediaQuery.of(context).size.width -
                this.maskWidth -
                this.maskLeft),
            height: this.maskHeight,
            child: new IgnorePointer(
                child: new Opacity(
              opacity: opacity,
              child: new Container(color: Colors.black),
            ))),
        new Positioned(
            left: 0.0,
            top: this.maskTop + this.maskHeight,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height -
                (this.maskTop + this.maskHeight),
            child: new IgnorePointer(
                child: new Opacity(
              opacity: opacity,
              child: new Container(color: Colors.black),
            ))),
        new Positioned(
            left: this.maskLeft,
            top: this.maskTop,
            width: this.maskWidth,
            height: this.maskHeight,
            child: new GestureDetector(
                child: new Container(
                  color: Colors.transparent,
                  child: new CustomPaint(
                    painter: new GridPainter(),
                  ),
                ),
                onPanStart: onMaskPanStart,
                onPanUpdate: (dragInfo) {
                  this.onPanUpdate(maskDirection, dragInfo);
                },
                onPanEnd: onPanEnd)),
        new Positioned(
            //scan
            left: this.maskLeft,
            top: this.maskTop,
            width: this.maskWidth,
            height: this.maskHeight * _controller.value,
            child: new Opacity(
              opacity: 0.5,
              child: new Container(color: Colors.blue),
            )),
        new Positioned(
          top: maskTop - 2,
          left: this.maskLeft - 2,
          child: new GestureDetector(
              child: new Image.asset("assets/topLeft.png"),
              onPanStart: onPanStart,
              onPanUpdate: (dragInfo) {
                this.onPanUpdate("topleft", dragInfo);
              },
              onPanEnd: onPanEnd),
        ),
        new Positioned(
          top: maskTop - 2,
          right: (MediaQuery.of(context).size.width -
              this.maskWidth -
              this.maskLeft -
              2),
          child: new GestureDetector(
              child: new Image.asset("assets/topRight.png"),
              onPanStart: onPanStart,
              onPanUpdate: (dragInfo) {
                this.onPanUpdate("topright", dragInfo);
              },
              onPanEnd: onPanEnd),
        ),
        new Positioned(
          top: this.maskTop + this.maskHeight - 12.0,
          left: this.maskLeft - 2,
          child: new GestureDetector(
              child: new Image.asset("assets/bottomLeft.png"),
              onPanStart: onPanStart,
              onPanUpdate: (dragInfo) {
                this.onPanUpdate("bottomleft", dragInfo);
              },
              onPanEnd: onPanEnd),
        ),
        new Positioned(
          top: this.maskTop + this.maskHeight - 12.0,
          right: (MediaQuery.of(context).size.width -
              this.maskWidth -
              this.maskLeft -
              2),
          child: new GestureDetector(
            child: new Image.asset("assets/bottomRight.png"),
            onPanStart: onPanStart,
            onPanUpdate: (dragInfo) {
              this.onPanUpdate("bottomright", dragInfo);
            },
            onPanEnd: onPanEnd,
          ),
        ),
        new Positioned(
          bottom: 10.0,
          height: 40.0,
          width: 40.0,
          left: (20.0),
          child: new RaisedButton(
              onPressed: () => Navigator.pop(context, ""),
              padding: EdgeInsets.all(10.0),
              splashColor: Colors.white,
              shape: new RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40.0))),
              child: new Icon(Icons.arrow_back_ios,
                  size: 20.0, color: Colors.blueAccent)),
        ),
        new Positioned(
          bottom: 10.0,
          height: 40.0,
          width: 40.0,
          left: (MediaQuery.of(context).size.width / 2 - 20.0),
          child: new RaisedButton(
              onPressed: () => doCapturePng(false),
              padding: EdgeInsets.all(10.0),
              splashColor: Colors.white,
              shape: new RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40.0))),
              child: new Icon(Icons.translate, size: 20.0, color: Colors.blueAccent)),
        ),
        new Positioned(
          bottom: 10.0,
          height: 40.0,
          width: 40.0,
          right: 20.0,
          child: new RaisedButton(
              onPressed: () => doCapturePng(true),
              padding: EdgeInsets.all(10.0),
              splashColor: Colors.white,
              shape: new RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40.0))),
              child: new Icon(Icons.check, size: 20.0, color: Colors.blueAccent)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
          child: new Container(
              child: new Column(children: [
        new Expanded(child: new Center(child: _buildImage(context))),
        //_buildButtons()
      ]))), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
