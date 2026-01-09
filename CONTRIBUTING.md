# Contributing to Shepherd

First off, thank you for considering contributing to Shepherd! It's people like you that make Shepherd such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by the Shepherd Code of Conduct. By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How Can I Contribute?

### Reporting Bugs

- **Ensure the bug was not already reported** by searching on GitHub under [Issues](https://github.com/cruvinelrv/shepherd/issues).
- If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/cruvinelrv/shepherd/issues/new). Be sure to include a **title and clear description**, as much relevant information as possible, and a **code sample** or an **executable test case** demonstrating the expected behavior that is not occurring.

### Suggesting Enhancements

- Open a new issue with a clear title and detailed description of the suggested enhancement.
- Explain why this enhancement would be useful to most Shepherd users.

### Pull Requests

1.  **Fork** the repo on GitHub.
2.  **Clone** the project to your own machine.
3.  **Create a branch** for your work.
    - Use `feature/` for new features (e.g., `feature/add-new-command`).
    - Use `fix/` for bug fixes (e.g., `fix/update-checker`).
    - Use `docs/` for documentation changes.
4.  **Commit changes** to your branch.
5.  **Push** your work back to your fork.
6.  Submit a **Pull Request** so that we can review your changes.

## Development Setup

1.  Ensure you have Dart SDK installed (`>=3.0.0 <4.0.0`).
2.  Clone the repository.
3.  Run `dart pub get` to install dependencies.
4.  Run `dart test` to ensure all tests pass.

## Coding Standards

Shepherd usually follows the standard Dart style guide, but with specific architectural rules.

### Architecture (DDD & Clean Architecture)

We follow a strict **Domain-Driven Design (DDD)** approach with **Clean Architecture**.

-   **Domain Layer** (`lib/src/<feature>/domain`):
    -   Pure Dart code. No external dependencies (no Flutter, no HTTP implementation, etc.).
    -   Contains **Entities**, **Value Objects**, **Use Cases**, and **Repository Interfaces**.
    -   **Naming Convention**: Entities must have the suffix `Entity` (e.g., `UserEntity`).
-   **Data Layer** (`lib/src/<feature>/data`):
    -   Implements Domain interfaces.
    -   Contains **Models**, **Datasources**, and **Repository Implementations**.
    -   **Naming Convention**: Models must have the suffix `Model` (e.g., `UserModel`).
    -   Models should extend or implement Entities and handle JSON serialization/deserialization.
-   **Presentation/CLI Layer**:
    -   Commands and Menus.

### Lints

We use the [`lints`](https://pub.dev/packages/lints) package. Run `dart analyze` to check for linting errors before pushing.

### Commit Messages

We follow the **Conventional Commits** specification.

-   `feat`: A new feature
-   `fix`: A bug fix
-   `docs`: Documentation only changes
-   `style`: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
-   `refactor`: A code change that neither fixes a bug nor adds a feature
-   `perf`: A code change that improves performance
-   `test`: Adding missing tests or correcting existing tests
-   `chore`: Changes to the build process or auxiliary tools and libraries such as documentation generation

Example: `feat: add new shepherd clean command`
