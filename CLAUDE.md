# CLAUDE.md - Guide for AI coding agents


# >> Commands

- Build/test configuration: `home-manager --flake ~/dotfiles/home-manager build`
- Apply configuration: `home-manager --flake ~/dotfiles/home-manager switch`
- Format nix files: `nix fmt .`
- Run tests: `nix flake check`


# >> Code Style

## General
- **Simplicity** is the guiding principle
- One folder per application
- Loose coupling between applications
- Split config into multiple files where possible
- Comment liberally
- Prefer application defaults when reasonable


## Configuration File Format
- Start with a filename comment (e.g., `# theme.fish`, `# paths.fish`, `; plugins/format.fnl`)
- Always include 2 blank lines after the filename comment
- Section headers with `# >> Section name` format
- Each new section (after the first) should have 3 blank lines before it
- Include blank line after section headers before content
- Group related configuration together
- Use whitespace liberally to improve readability


## Nix
- Uses `nixfmt-rfc-style` for formatting
- Declarative configuration
- Use native config files for applications when possible
- Structure follows home-manager conventions


## File Organization
- Application-specific configs in their own directories
- Main configuration entry point: `~/dotfiles/home-manager/flake.nix`
- Platform: macOS (aarch64-darwin)


# >> Examples

## Format
When showing examples or options:
- Use markdown headers (##) to organize different approaches
- Bold the key concept or approach name
- Include brief explanation of why/when to use each option
- Show concrete code examples in fenced code blocks
- Use bullet points for pros/cons or key differences
- Keep examples focused and relevant to the question

## Good Example
When asked about different approaches:

**Option 1: Direct approach**
Brief explanation of when this makes sense
```nix
code example
```

**Option 2: Alternative approach**  
Different use case explanation
```nix
code example
```

**Recommendation:** Clear statement about which option fits best and why