import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class GalleryPermission {
  Future<PermissionStatus> galleryPermission(BuildContext context) async {
    if (Platform.isIOS) {
      PermissionStatus permission = await Permission.photos.status;
      if (permission == PermissionStatus.permanentlyDenied) {
        await showDialog(
          context: context,
          builder: (_context) => AlertDialog(
            title: Text("Photos Permission"),
            content: Text(
                "Photos permission should be granted to use this feature, would you like to go to app settings to give photos permission?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Color(0xFF2E86C1),
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Settings",
                  style: TextStyle(
                    color: Color(0xFF2E86C1),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
        PermissionStatus permissionStatus = await Permission.photos.request();
        return permissionStatus;
      } else if (permission != PermissionStatus.granted) {
        PermissionStatus permissionStatus = await Permission.photos.request();
        return permissionStatus;
      } else {
        return permission;
      }
    } else {
      PermissionStatus permission = await Permission.storage.status;
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.permanentlyDenied) {
        PermissionStatus permissionStatus = await Permission.storage.request();
        return permissionStatus;
      } else if (permission == PermissionStatus.permanentlyDenied) {
        await showDialog(
          context: context,
          builder: (_context) => AlertDialog(
            title: Text("Storage Permission"),
            content: Text(
                "Storage permission should be granted to use this feature, would you like to go to app settings to give storage permission?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Color(0xFF2E86C1),
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Settings",
                  style: TextStyle(
                    color: Color(0xFF2E86C1),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
        PermissionStatus permissionStatus = await Permission.storage.request();
        return permissionStatus;
      } else {
        return permission;
      }
    }
  }
}
