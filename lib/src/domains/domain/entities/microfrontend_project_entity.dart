/// Entity representing a registered microfrontend in the Shepherd ecosystem.
class MicrofrontendProjectEntity {
  final String name;
  final String? path;
  final String? description;

  const MicrofrontendProjectEntity({
    required this.name,
    this.path,
    this.description,
  });
}
