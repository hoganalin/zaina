import 'package:freezed_annotation/freezed_annotation.dart';

part 'self_view.freezed.dart';
part 'self_view.g.dart';

enum Gender {
  @JsonValue('male')
  male,
  @JsonValue('female')
  female,
  @JsonValue('non_binary')
  nonBinary,
}

@freezed
class SelfView with _$SelfView {
  const factory SelfView({
    required String id,
    required String nickname,
    String? username,
    Gender? gender,
    String? country,
    String? city,
    String? avatarUrl,
    String? bio,
    @Default(false) bool isVerified,
    @Default(false) bool onboardingCompleted,
    DateTime? createdAt,
  }) = _SelfView;

  factory SelfView.fromJson(Map<String, dynamic> json) =>
      _$SelfViewFromJson(json);
}
