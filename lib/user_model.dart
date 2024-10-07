// user_model.dart

import 'dart:convert';

class PrivacySettings {
  final bool mobile;
  final bool officeName;
  final bool dpurl;
  final bool instagramUsername;
  final bool youtubeChannel;
  final bool githubUsername;
  final bool telegramUsername;
  final bool website;

  // **New Privacy Fields**
  final bool gender;
  final bool taluk;
  final bool districtName;
  final bool stateName;

  PrivacySettings({
    required this.mobile,
    required this.officeName,
    required this.dpurl,
    required this.instagramUsername,
    required this.youtubeChannel,
    required this.githubUsername,
    required this.telegramUsername,
    required this.website,
    required this.gender,
    required this.taluk,
    required this.districtName,
    required this.stateName,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      mobile: json['mobile'] ?? false,
      officeName: json['officeName'] ?? false,
      dpurl: json['dpurl'] ?? false,
      instagramUsername: json['instagramUsername'] ?? false,
      youtubeChannel: json['youtubeChannel'] ?? false,
      githubUsername: json['githubUsername'] ?? false,
      telegramUsername: json['telegramUsername'] ?? false,
      website: json['website'] ?? false,
      gender: json['gender'] ?? false,
      taluk: json['taluk'] ?? false,
      districtName: json['districtName'] ?? false,
      stateName: json['stateName'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile,
      'officeName': officeName,
      'dpurl': dpurl,
      'instagramUsername': instagramUsername,
      'youtubeChannel': youtubeChannel,
      'githubUsername': githubUsername,
      'telegramUsername': telegramUsername,
      'website': website,
      'gender': gender,
      'taluk': taluk,
      'districtName': districtName,
      'stateName': stateName,
    };
  }

  // Method to create a copy with updated fields
  PrivacySettings copyWith({
    bool? mobile,
    bool? officeName,
    bool? dpurl,
    bool? instagramUsername,
    bool? youtubeChannel,
    bool? githubUsername,
    bool? telegramUsername,
    bool? website,
    bool? gender,
    bool? taluk,
    bool? districtName,
    bool? stateName,
  }) {
    return PrivacySettings(
      mobile: mobile ?? this.mobile,
      officeName: officeName ?? this.officeName,
      dpurl: dpurl ?? this.dpurl,
      instagramUsername: instagramUsername ?? this.instagramUsername,
      youtubeChannel: youtubeChannel ?? this.youtubeChannel,
      githubUsername: githubUsername ?? this.githubUsername,
      telegramUsername: telegramUsername ?? this.telegramUsername,
      website: website ?? this.website,
      gender: gender ?? this.gender,
      taluk: taluk ?? this.taluk,
      districtName: districtName ?? this.districtName,
      stateName: stateName ?? this.stateName,
    );
  }
}

class User {
  final String id;
  final String name;
  final String mobile;
  final String dpUrl;
  final String gender;
  final String officeName;
  final String taluk;
  final String districtName;
  final String stateName;
  final int matchScore;
  final bool isPremium;
  final PrivacySettings privacy;

  // **New Social Media and Website URL Fields**
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? githubUrl;
  final String? telegramUrl;
  final String? websiteUrl;

  User({
    required this.id,
    required this.name,
    required this.mobile,
    required this.dpUrl,
    required this.gender,
    required this.officeName,
    required this.taluk,
    required this.districtName,
    required this.stateName,
    required this.matchScore,
    required this.isPremium,
    required this.privacy,
    this.instagramUrl,
    this.youtubeUrl,
    this.githubUrl,
    this.telegramUrl,
    this.websiteUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'No Name',
      mobile: json['mobile'] ?? 'No Mobile',
      dpUrl: json['dpurl'] ?? '',
      gender: json['gender'] ?? 'Not Specified',
      officeName: json['officeName'] ?? 'N/A',
      taluk: json['taluk'] ?? 'N/A',
      districtName: json['districtName'] ?? 'N/A',
      stateName: json['stateName'] ?? 'N/A',
      matchScore: json['matchScore'] ?? 0,
      isPremium: json['isPremium'] ?? false,
      privacy: PrivacySettings.fromJson(json['privacy'] ?? {}),
      instagramUrl: json['instagramUrl'],
      youtubeUrl: json['youtubeUrl'],
      githubUrl: json['githubUrl'],
      telegramUrl: json['telegramUrl'],
      websiteUrl: json['websiteUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'mobile': mobile,
      'dpurl': dpUrl,
      'gender': gender,
      'officeName': officeName,
      'taluk': taluk,
      'districtName': districtName,
      'stateName': stateName,
      'matchScore': matchScore,
      'isPremium': isPremium,
      'privacy': privacy.toJson(),
      'instagramUrl': instagramUrl,
      'youtubeUrl': youtubeUrl,
      'githubUrl': githubUrl,
      'telegramUrl': telegramUrl,
      'websiteUrl': websiteUrl,
    };
  }
}
