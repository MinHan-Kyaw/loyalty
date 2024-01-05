import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermission {
  Future<PermissionStatus> cameraPermission(BuildContext context) async {
    if (Platform.isIOS) {
      PermissionStatus permission = await Permission.camera.status;
      if (permission == PermissionStatus.permanentlyDenied) {
        await showDialog(
          context: context,
          builder: (_context) => AlertDialog(
            title: Text("Camera Permission"),
            content: Text(
                "Camera permission should be granted to use this feature, would you like to go to app settings to give camera permission?"),
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
        PermissionStatus permissionStatus = await Permission.camera.request();
        return permissionStatus;
      } else if (permission != PermissionStatus.granted) {
        PermissionStatus permissionStatus = await Permission.camera.request();
        return permissionStatus;
      } else {
        return permission;
      }
    } else {
      PermissionStatus permission = await Permission.camera.status;
      if (permission == PermissionStatus.permanentlyDenied ||
          permission == PermissionStatus.denied) {
        await showDialog(
          context: context,
          builder: (_context) => AlertDialog(
            title: Text("Camera Permission"),
            content: Text(
                "Camera permission should be granted to use this feature, would you like to go to app settings to give camera permission?"),
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
        PermissionStatus permissionStatus = await Permission.camera.request();
        return permissionStatus;
      } else if (permission != PermissionStatus.granted) {
        PermissionStatus permissionStatus = await Permission.camera.request();
        return permissionStatus;
      } else {
        return permission;
      }
    }
  }
}
