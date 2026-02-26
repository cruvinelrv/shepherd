# Shepherd CLI Example

This directory contains a showcase of the Shepherd ecosystem. Shepherd uses a centralized configuration folder (hidden as `.shepherd` in real projects, but displayed here as `shepherd` for visibility) to manage domains, teams, and automation.

## Showcase Highlights

- **`shepherd/`**: The heart of the configuration.
  - `project.yaml`: Project identity and setup mode.
  - `domains.yaml`: Business domains (DDD).
  - `environments.yaml`: Branch mapping for CI/CD.
  - `feature_toggles.yaml`: Feature flags management.
  - `shepherd_activity.yaml`: Rich User Story and Task tracking.
  - `maestro/flows/`: Centralized destination for automated test flows.

## Try it out!

Check out `shepherd_example.dart` to see how to use the Shepherd core classes programmatically.
