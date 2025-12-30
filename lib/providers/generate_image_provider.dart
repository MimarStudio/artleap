import 'dart:io';
import 'dart:typed_data';
import 'package:Artleap.ai/domain/api_models/image_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Artleap.ai/domain/api_models/generate_high_q_model.dart';
import 'package:Artleap.ai/domain/api_services/api_response.dart';
import 'package:Artleap.ai/domain/base_repo/base_repo.dart';
import 'package:uuid/uuid.dart';
import '../domain/api_models/models_list_model.dart';
import '../shared/constants/app_static_data.dart';
import '../shared/constants/user_data.dart';
import '../shared/utilities/pickers.dart';
import '../domain/api_models/text_to_image_model.dart' as txtToImg;
import '../domain/api_models/Image_to_Image_model.dart' as ImgToImg;

final generateImageProvider = ChangeNotifierProvider<GenerateImageProvider>(
    (ref) => GenerateImageProvider(ref));

enum ImagePrivacy {
  public('Public', 'Visible to everyone', Icons.public_rounded),
  private('Private', 'Only visible to you', Icons.lock_rounded);

  final String title;
  final String description;
  final IconData icon;

  const ImagePrivacy(this.title, this.description, this.icon);
}

class GenerateImageProvider extends ChangeNotifier with BaseRepo {
  final TextEditingController _promptTextController = TextEditingController();
  TextEditingController get promptTextController => _promptTextController;
  final List<Images?> _generatedImage = [];
  List<Images?> get generatedImage => _generatedImage;
  GenerateHighQualityImageModel? _generatedHighQualityImage;
  GenerateHighQualityImageModel? get generatedHighQualityImage =>
      _generatedHighQualityImage;

  bool _isGenerateImageLoading = false;
  bool get isGenerateImageLoading => _isGenerateImageLoading;
  bool _isImageReferenceLoading = false;
  bool get isImageReferenceLoading => _isImageReferenceLoading;

  ModelsListModel? _selectedModelName;
  ModelsListModel? get selectedModeldata => _selectedModelName;
  int? _selectedItem = 1;
  int? get selectedImageNumber => _selectedItem;
  final List<int> _dropdownItems = [1, 2, 3, 4];
  List<int> get imageNumber => _dropdownItems;

  var uuid = const Uuid().v1();
  final List<Images?> _generatedTextToImageData = [];
  List<Images?> get generatedTextToImageData => _generatedTextToImageData;
  List<Uint8List> listOfImagesBytes = [];
  List<File> images = [];

  String? _selectedStyle;
  String? get selectedStyle => _selectedStyle;

  bool _containsSexualWords = false;
  bool get containsSexualWords => _containsSexualWords;

  String? _aspectRatio = "classic_4_3";
  String? get aspectRatio => _aspectRatio;

  ImagePrivacy _selectedPrivacy = ImagePrivacy.public;
  ImagePrivacy get selectedPrivacy => _selectedPrivacy;

  set aspectRatio(String? value) {
    _aspectRatio = value;
    notifyListeners();
  }

  void clearPrompt() {
    promptTextController.clear();
    _containsSexualWords = false;
  }

  set selectedStyle(String? value) {
    _selectedStyle = value;
    notifyListeners();
  }

  final Ref reference;

  GenerateImageProvider(this.reference) {
    if (freePikStyles.isNotEmpty) {
      _selectedStyle = freePikStyles[0]['title'];
    }
  }
  set selectedImageNumber(int? value) {
    _selectedItem = value;
    notifyListeners();
  }

  set selectedModeldata(ModelsListModel? value) {
    _selectedModelName = value;
    notifyListeners();
  }

  setGenerateImageLoader(bool value) {
    _isGenerateImageLoading = value;
    notifyListeners();
  }

  setImageRefLoader(bool value) {
    _isImageReferenceLoading = value;
    notifyListeners();
  }

  clearVarData() {
    _selectedModelName = null;
    _selectedItem = null;
    notifyListeners();
  }

  clearImagesList() {
    images = [];
    notifyListeners();
  }

  void clearGeneratedData() {
    _generatedImage.clear();
    _generatedTextToImageData.clear();
    _generatedHighQualityImage = null;
    _promptTextController.clear();
    images.clear();
    listOfImagesBytes.clear();
    notifyListeners();
  }

  set selectedPrivacy(ImagePrivacy value) {
    _selectedPrivacy = value;
    notifyListeners();
  }

  String? dataUrl;
  Future<bool> generateTextToImage() async {
    try {
      setGenerateImageLoader(true);

      Map<String, dynamic> mapdata = {
        "prompt": _promptTextController.text,
        "userId": UserData.ins.userId,
        "username": UserData.ins.userName,
        "creatorEmail": UserData.ins.userEmail,
        "presetStyle": _selectedStyle,
        "num_images": _selectedItem,
        "aspectRatio": _aspectRatio,
        "generationType": 'prompt',
        "privacy": _selectedPrivacy.name,
      };

      ApiResponse generateImageRes = await freePikRepo.generateImage(mapdata);
      if (generateImageRes.status == Status.completed) {
        var generatedData = generateImageRes.data as txtToImg.TextToImageModel;
        _generatedTextToImageData.addAll(generatedData.images);
        setGenerateImageLoader(false);
        notifyListeners();
        return true;
      } else {
        setGenerateImageLoader(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Image generation error: $e');
      setGenerateImageLoader(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> generateLeonardoTxt2Image() async {
    print("Generate type TextToImage 1");
    try {
      setGenerateImageLoader(true);

      Map<String, dynamic> mapdata = {
        "prompt": _promptTextController.text,
        "userId": UserData.ins.userId,
        "username": UserData.ins.userName,
        "creatorEmail": UserData.ins.userEmail,
        "num_images": _selectedItem,
        "generationType": 'prompt',
        "privacy": _selectedPrivacy.name,
      };

      ApiResponse generateImageRes = await leonardoTxt2ImgRepo.generateLeonardoImage(mapdata);
      if (generateImageRes.status == Status.completed) {
        var generatedData = generateImageRes.data as txtToImg.TextToImageModel;
        _generatedTextToImageData.addAll(generatedData.images);
        setGenerateImageLoader(false);
        notifyListeners();
        return true;
      } else {
        setGenerateImageLoader(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Image generation error: $e');
      setGenerateImageLoader(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> pickImage() async {
    try {
      String? imagePath = await Pickers.ins.pickImage();

      if (imagePath == null) {
        return;
      }

      File imageData = File(imagePath);
      images = [imageData];
      _selectedStyle = textToImageStyles.firstWhere(
            (style) => style['title'] == 'ANIME',
        orElse: () => textToImageStyles[0],
      )['title'];

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> generateImgToImg() async {
    try {
      setGenerateImageLoader(true);
      notifyListeners();
      final Map<String, dynamic> data = {
        "prompt": promptTextController.text,
        "userId": UserData.ins.userId,
        "username": UserData.ins.userName,
        "creatorEmail": UserData.ins.userEmail,
        "presetStyle": selectedStyle,
        "num_images": selectedImageNumber,
        "generationType": 'image',
        "privacy": _selectedPrivacy.name,
      };

      final ApiResponse generateImageRes = await generateImgToImgRepo.generateImgToImg(data, images);
      if (generateImageRes.status == Status.completed) {
        final generatedData = generateImageRes.data as ImgToImg.ImageToImageModel;
        _generatedImage.addAll(generatedData.images);

        selectedStyle = freePikStyles[0]['title'];
        images = [];
        return true;
      } else {
        images = [];
        return false;
      }
    } catch (e) {
      debugPrint('Image generation error: $e');
      return false;
    } finally {
      setGenerateImageLoader(false);
      notifyListeners();
    }
  }

  bool isValidUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      return uri.isAbsolute &&
          (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'));
    } catch (e) {
      return false;
    }
  }

  void checkSexualWords(String input) {
    final lowerInput = input.toLowerCase();
    final matchedWords = <String>[];

    for (final word in sexualWordsList) {
      final pattern = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
      if (pattern.hasMatch(lowerInput)) {
        matchedWords.add(word);
      }
    }
    if (matchedWords.isNotEmpty) {
      print('Matched sexual words: $matchedWords');
    } else {
      // print('No sexual words found.');
    }
    _containsSexualWords = matchedWords.isNotEmpty;
    notifyListeners();
  }

}
