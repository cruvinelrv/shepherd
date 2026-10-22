import '../../domain/entities/microfrontend_project_entity.dart';

/// Data model representing a microfrontend configuration entry in `.shepherd/microfrontends.yaml`.
class MicrofrontendProjectModel extends MicrofrontendProjectEntity {
  const MicrofrontendProjectModel({
    required super.name,
    super.path,
    super.description,
  });

  factory MicrofrontendProjectModel.fromMap(Map<String, dynamic> map) {
    return MicrofrontendProjectModel(
      name: map['name']?.toString() ?? '',
      path: map['path']?.toString(),
      description: map['description']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (path != null && path!.isNotEmpty) 'path': path,
        if (description != null && description!.isNotEmpty)
          'description': description,
      };
}
