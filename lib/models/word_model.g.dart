// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WordModel _$WordModelFromJson(Map<String, dynamic> json) => WordModel(
  kelime: json['kelime'] as String,
  harekeliKelime: json['harekeliKelime'] as String?,
  anlam: json['anlam'] as String?,
  koku: json['koku'] as String?,
  dilbilgiselOzellikler: json['dilbilgiselOzellikler'] as Map<String, dynamic>?,
  fiilCekimler: json['fiilCekimler'] as Map<String, dynamic>?,
  ornekCumleler: (json['ornekCumleler'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  eklenmeTarihi: (json['eklenmeTarihi'] as num?)?.toInt(),
  bulunduMu: json['bulunduMu'] as bool? ?? true,
);

Map<String, dynamic> _$WordModelToJson(WordModel instance) => <String, dynamic>{
  'kelime': instance.kelime,
  'harekeliKelime': instance.harekeliKelime,
  'anlam': instance.anlam,
  'koku': instance.koku,
  'dilbilgiselOzellikler': instance.dilbilgiselOzellikler,
  'fiilCekimler': instance.fiilCekimler,
  'ornekCumleler': instance.ornekCumleler,
  'eklenmeTarihi': instance.eklenmeTarihi,
  'bulunduMu': instance.bulunduMu,
};

Ornek _$OrnekFromJson(Map<String, dynamic> json) => Ornek(
  arapcaCumle: json['arapcaCumle'] as String,
  turkceCeviri: json['turkceCeviri'] as String,
);

Map<String, dynamic> _$OrnekToJson(Ornek instance) => <String, dynamic>{
  'arapcaCumle': instance.arapcaCumle,
  'turkceCeviri': instance.turkceCeviri,
};

FiilCekimi _$FiilCekimiFromJson(Map<String, dynamic> json) => FiilCekimi(
  mazi: json['mazi'] as String?,
  muzari: json['muzari'] as String?,
  mastar: json['mastar'] as String?,
  emir: json['emir'] as String?,
);

Map<String, dynamic> _$FiilCekimiToJson(FiilCekimi instance) =>
    <String, dynamic>{
      'mazi': instance.mazi,
      'muzari': instance.muzari,
      'mastar': instance.mastar,
      'emir': instance.emir,
    };

WordError _$WordErrorFromJson(Map<String, dynamic> json) => WordError(
  message: json['message'] as String,
  detail: json['detail'] as String?,
);

Map<String, dynamic> _$WordErrorToJson(WordError instance) => <String, dynamic>{
  'message': instance.message,
  'detail': instance.detail,
};
