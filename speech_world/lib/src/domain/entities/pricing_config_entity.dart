import 'package:equatable/equatable.dart';

class PricingConfigEntity extends Equatable {
  final String id;
  final int textTranslateCost; // за 1000 символов
  final int liveSpeechToSpeechCostPerSec; // за секунду
  final int imageAnalysisCostPerImage; // за 1 изображение

  const PricingConfigEntity({
    required this.id,
    required this.textTranslateCost,
    required this.liveSpeechToSpeechCostPerSec,
    required this.imageAnalysisCostPerImage,
  });

  PricingConfigEntity copyWith({
    String? id,
    int? textTranslateCost,
    int? liveSpeechToSpeechCostPerSec,
    int? imageAnalysisCostPerImage,
  }) {
    return PricingConfigEntity(
      id: id ?? this.id,
      textTranslateCost: textTranslateCost ?? this.textTranslateCost,
      liveSpeechToSpeechCostPerSec:
          liveSpeechToSpeechCostPerSec ?? this.liveSpeechToSpeechCostPerSec,
      imageAnalysisCostPerImage:
          imageAnalysisCostPerImage ?? this.imageAnalysisCostPerImage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        textTranslateCost,
        liveSpeechToSpeechCostPerSec,
        imageAnalysisCostPerImage,
      ];

  /// Преобразование из Map (для Firestore)
  factory PricingConfigEntity.fromMap(Map<String, dynamic> map, String docId) {
    return PricingConfigEntity(
      id: docId,
      textTranslateCost: map['text_translate_cost'] ?? 1,
      liveSpeechToSpeechCostPerSec: map['live_speech_to_speech_cost_per_sec'] ?? 2,
      imageAnalysisCostPerImage: map['image_analysis_cost_per_image'] ?? 10,
    );
  }

  /// Преобразование в Map (для Firestore)
  Map<String, dynamic> toMap() {
    return {
      'text_translate_cost': textTranslateCost,
      'live_speech_to_speech_cost_per_sec': liveSpeechToSpeechCostPerSec,
      'image_analysis_cost_per_image': imageAnalysisCostPerImage,
    };
  }
}