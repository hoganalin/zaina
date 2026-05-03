import 'package:freezed_annotation/freezed_annotation.dart';

part 'companion.freezed.dart';
part 'companion.g.dart';

@freezed
class Companion with _$Companion {
  const factory Companion({
    required String id,
    required String nickname,
    String? username,
    String? city,
    String? country,
    String? avatarUrl,
    String? bio,
    @Default(false) bool isVerified,
    @Default(false) bool sharedCity,
    @Default(0) int sharedInterestCount,
  }) = _Companion;

  factory Companion.fromJson(Map<String, dynamic> json) =>
      _$CompanionFromJson(json);
}
