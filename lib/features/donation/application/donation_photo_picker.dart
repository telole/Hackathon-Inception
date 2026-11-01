import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'donation_models.dart';

abstract interface class DonationPhotoPicker {
  Future<PickedDonationPhoto?> pick();
}

class ImagePickerDonationPhotoPicker implements DonationPhotoPicker {
  ImagePickerDonationPhotoPicker();

  final ImagePicker _picker = ImagePicker();

  @override
  Future<PickedDonationPhoto?> pick() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 65,
      maxWidth: 1200,
    );
    if (file == null) return null;
    return PickedDonationPhoto(
      name: file.name,
      bytes: await file.readAsBytes(),
    );
  }
}

final donationPhotoPickerProvider = Provider<DonationPhotoPicker>(
  (ref) => ImagePickerDonationPhotoPicker(),
);
