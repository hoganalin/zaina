import 'package:freezed_annotation/freezed_annotation.dart';

part 'interest.freezed.dart';
part 'interest.g.dart';

enum InterestCategory {
  @JsonValue('active')
  active,
  @JsonValue('static')
  staticCategory,
}

@freezed
class Interest with _$Interest {
  const factory Interest({
    required String id,
    required String slug,
    required String name,
    required InterestCategory category,
  }) = _Interest;

  factory Interest.fromJson(Map<String, dynamic> json) =>
      _$InterestFromJson(json);
}
