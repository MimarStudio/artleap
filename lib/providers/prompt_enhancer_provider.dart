import 'package:Artleap.ai/shared/route_export.dart';
import 'package:Artleap.ai/domain/api_services/api_response.dart';
import 'package:Artleap.ai/domain/api_models/prompt_enhancer_model.dart';
import 'package:Artleap.ai/domain/base_repo/base_repo.dart';

final promptEnhancerProvider = ChangeNotifierProvider<PromptEnhancerProvider>(
      (ref) => PromptEnhancerProvider(),
);

class PromptEnhancerProvider extends ChangeNotifier with BaseRepo {
  bool _isLoading = false;
  String? _enhancedPrompt;
  String? _errorMessage;
  String _originalPrompt = '';
  bool _isEnhancedMode = false;

  bool get isLoading => _isLoading;
  String? get enhancedPrompt => _enhancedPrompt;
  String? get errorMessage => _errorMessage;
  String get originalPrompt => _originalPrompt;
  bool get isEnhancedMode => _isEnhancedMode;

  String get currentPrompt {
    return _isEnhancedMode && _enhancedPrompt != null
        ? _enhancedPrompt!
        : _originalPrompt;
  }

  void resetEnhancer() {
    _isEnhancedMode = false;
    _originalPrompt = '';
  }

  bool get hasEnhancedPrompt => _enhancedPrompt != null;

  Future<void> enhancePrompt(String prompt) async {
    if (prompt.trim().isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    _originalPrompt = prompt;
    notifyListeners();

    try {
      final response = await promptEnhancerRepo.enhancePrompt(
        prompt,
        enableLocalPersistence: false,
      );

      if (response.status == Status.completed) {
        final enhancedModel = response.data as PromptEnhancerModel;

        if (enhancedModel.success) {
          _isLoading = false;
          _enhancedPrompt = enhancedModel.enhanced;
          _isEnhancedMode = true;
          _errorMessage = null;
          notifyListeners();
        } else {
          _isLoading = false;
          _errorMessage = enhancedModel.message ?? 'Failed to enhance prompt';
          notifyListeners();
        }
      } else {
        _isLoading = false;
        _errorMessage = response.message ?? 'An error occurred';
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Network error: ${e.toString()}';
      notifyListeners();
    }
  }

  void revertToOriginal() {
    _isEnhancedMode = false;
    _enhancedPrompt = null;
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _enhancedPrompt = null;
    _errorMessage = null;
    _isEnhancedMode = false;
    notifyListeners();
  }

  void setOriginalPrompt(String prompt) {
    if (!_isEnhancedMode) {
      _originalPrompt = prompt;
    }
  }
}