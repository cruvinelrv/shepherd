/// Entity representing an active terminal shell session state in Shepherd CLI.
class ShellSessionEntity {
  final String projectName;
  final String? userName;
  final String? userEmail;
  final String? environment;
  final String? aiProvider;
  final String? aiModel;
  final bool isAuthenticated;

  const ShellSessionEntity({
    required this.projectName,
    this.userName,
    this.userEmail,
    this.environment,
    this.aiProvider,
    this.aiModel,
    this.isAuthenticated = false,
  });

  bool get hasAiConfigured =>
      aiProvider != null &&
      aiProvider!.isNotEmpty &&
      aiModel != null &&
      aiModel!.isNotEmpty;
}
