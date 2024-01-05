import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PhotoViewer extends StatefulWidget {
  final images;
  final type;
  final index;
  PhotoViewer({this.images, this.type, this.index});
  @override
  _PhotoViewerState createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  PageController _pageController;
  bool firstTimeChanged = false;
  _downloadImage(String url) async {
    String fileName = DateFormat('yyyyMMddHHmmssms').format(DateTime.now());
    var response = await Dio()
        .get(url, options: Options(responseType: ResponseType.bytes));
    final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(response.data),
        quality: 100,
        name: fileName);
    debugPrint("result>>> $result");
    if (result["isSuccess"] == true) {
      _showSnackBar("Saved Successfully.");
    } else {
      _showSnackBar("Can't Save.");
    }
  }

  _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: new Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  goAction(imgurl) {
    final action = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 1.5,
                color: Colors.white,
              ),
              color: Colors.grey[300],
            ),
            child: Icon(
              Icons.file_download,
              color: Colors.black54,
              size: 20,
            ),
          ),
          title: Text(
            'Save',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
            _downloadImage(imgurl);
          },
        ),
      ],
    );
    showModalBottomSheet(
      context: context,
      builder: (context) => action,
      backgroundColor: Colors.white,
    );
  }

  onPageChanged(int index) {
    setState(() {
      firstTimeChanged = true;
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.index != null) {
      _pageController = PageController(initialPage: widget.index);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        body: widget.type == "gallery"
            ? Container(
                child: PhotoViewGallery.builder(
                pageController: _pageController,
                scrollPhysics: const BouncingScrollPhysics(),
                onPageChanged: onPageChanged,
                builder: (BuildContext context, int index) {
                  return PhotoViewGalleryPageOptions.customChild(
                    child: GestureDetector(
                      onLongPress: () {
                        goAction(widget.images[index]);
                      },
                      child: Container(
                          child: PhotoView(
                        imageProvider: CachedNetworkImageProvider(
                          widget.images[index],
                        ),
                      )),
                    ),
                    initialScale: PhotoViewComputedScale.contained * 0.8,
                    heroAttributes:
                        PhotoViewHeroAttributes(tag: widget.images[index]),
                  );
                },
                itemCount: widget.images.length,
                loadingBuilder: (context, event) => Center(
                  child: Container(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      value: event == null
                          ? 0
                          : event.cumulativeBytesLoaded /
                              event.expectedTotalBytes,
                    ),
                  ),
                ),
              ))
            : GestureDetector(
                onLongPress: () {
                  goAction(widget.images);
                },
                child: Container(
                    child: PhotoView(
                  imageProvider: CachedNetworkImageProvider(
                    widget.images,
                  ),
                )),
              ));
  }
}
