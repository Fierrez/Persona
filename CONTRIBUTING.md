# Contributing to Secure Vault

Thank you for your interest in contributing! This document describes the process for contributing code, reporting issues, and proposing enhancements.

1. Fork the repository
2. Create a feature branch
   - Branch name: `feature/<short-description>` or `fix/<short-description>`
3. Keep changes small and focused
4. Write tests for new behavior where applicable
5. Run formatting and analyzer before submitting

Local setup

```bash
flutter pub get
flutter analyze
flutter test
dart format .
```

Commit message guidelines
- Use present-tense, short summary: `Add feature X`
- Optionally include a longer description in the body

Pull request checklist
- [ ] Follows repository coding style
- [ ] Includes tests for new behavior
- [ ] All tests pass locally
- [ ] Documentation updated if applicable

Code style
- Run `dart format .` before committing
- Follow effective Dart guidelines

Reporting issues
- Use the issue tracker for bugs and feature requests
- Provide reproduction steps, environment, and screenshots where helpful

Communication
- Be respectful and constructive
- If you plan to work on a larger feature, open an issue first to discuss design

Maintainers may request changes before merging. Contributors are encouraged to respond promptly.
