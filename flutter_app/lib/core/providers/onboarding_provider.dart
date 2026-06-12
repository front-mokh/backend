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

  void updateCreatorInfo({
    String? firstName,
    String? lastName,
    String? nickname,
    String? bio,
    String? profilePicture,
    String? phone,
  }) {
    var changed = false;

    if (firstName != null && firstName != this.firstName) {
      this.firstName = firstName;
      changed = true;
    }
    if (lastName != null && lastName != this.lastName) {
      this.lastName = lastName;
      changed = true;
    }
    if (nickname != null && nickname != this.nickname) {
      this.nickname = nickname;
      changed = true;
    }
    if (bio != null && bio != this.bio) {
      this.bio = bio;
      changed = true;
    }
    if (profilePicture != null && profilePicture != this.profilePicture) {
      this.profilePicture = profilePicture;
      changed = true;
    }
    if (phone != null && phone != this.phone) {
      this.phone = phone;
      changed = true;
    }

    if (changed) notifyListeners();
  }

  void updateBrandInfo({
    String? brandName,
    String? phone,
    String? location,
    String? website,
    String? description,
    String? logo,
  }) {
    var changed = false;

    if (brandName != null && brandName != this.brandName) {
      this.brandName = brandName;
      changed = true;
    }
    if (phone != null && phone != this.phone) {
      this.phone = phone;
      changed = true;
    }
    if (location != null && location != this.location) {
      this.location = location;
      changed = true;
    }
    if (website != null && website != this.website) {
      this.website = website;
      changed = true;
    }
    if (description != null && description != this.description) {
      this.description = description;
      changed = true;
    }
    if (logo != null && logo != this.logo) {
      this.logo = logo;
      changed = true;
    }

    if (changed) notifyListeners();
  }

  void setLinks(List<OnboardingSocialLink> links) {
    this.links = List.of(links);
    notifyListeners();
  }

  void setCategories(Iterable<int> categories) {
    this.categories = categories.toList();
    notifyListeners();
  }

  void setIndustries(Iterable<int> industries) {
    this.industries = industries.toList();
    notifyListeners();
  }

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
