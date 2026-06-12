import 'package:flutter/foundation.dart';

class OnboardingSocialLink {
  final String id;
  final String url;

  OnboardingSocialLink({required this.id, required this.url});
}

class OnboardingProvider extends ChangeNotifier {
  // Step 1: Creator personal info
  String firstName = '';
  String lastName = '';
  String nickname = '';
  String bio = '';
  String profilePicture = '';
  String phone = '';

  // Step 1: Brand info
  String brandName = '';
  String location = '';
  String website = '';
  String description = '';
  String logo = '';

  // Step 2: Social links (shared)
  List<OnboardingSocialLink> links = [];

  // Step 3: Categories / Industries
  List<int> categories = [];
  List<int> industries = [];

  int currentStep = 1;

  void updateStep(int step) {
    currentStep = step;
    notifyListeners();
  }

  void resetData() {
    firstName = '';
    lastName = '';
    nickname = '';
    bio = '';
    profilePicture = '';
    phone = '';
    brandName = '';
    location = '';
    website = '';
    description = '';
    logo = '';
    links = [];
    categories = [];
    industries = [];
    currentStep = 1;
    notifyListeners();
  }

  String? validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return 'Le numéro de téléphone est requis.';
    }
    final algPhoneRegex = RegExp(r'^0[567]\d{8}$');
    if (!algPhoneRegex.hasMatch(phone)) {
      return 'Le numéro de téléphone doit être un numéro algérien valide (10 chiffres, commençant par 05, 06 ou 07).';
    }
    return null;
  }

  String? validateBrandPhoneNumber(String phone) {
    if (phone.isEmpty) {
      return 'Le numéro de téléphone est requis.';
    }
    final phoneRegex = RegExp(r'^0\d{9}$');
    if (!phoneRegex.hasMatch(phone)) {
      return 'Le numéro de téléphone doit commencer par 0 et contenir 10 chiffres.';
    }
    return null;
  }
}
