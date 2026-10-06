# bootstrap

## Overview

Public first steps for installing tools of [InfiniteSolution](https://www.infinitesolution.cz/)
whose code lives in private repositories. A script here holds no code of the tool and no
secret: it asks for an access token, downloads the real install script from the private
repository with it, and runs it.

## LeadSonar

In PowerShell on Windows, paste this one line and press Enter:

```powershell
irm https://raw.githubusercontent.com/InfiniteSolutionCZ/bootstrap/main/leadsonar/install.ps1 | iex
```

It asks for the GitHub token you were given - ask Zdenek when you do not
have one. Then it runs `scripts/install.ps1` of the private repository
`InfiniteSolutionCZ/leadsonar`, which installs Portunix, Git, Python, uv and LeadSonar.

What happens to the token:

- It is read without echo and never written to a file, the command line or the
  PowerShell history
- The install script stores it with the Git credential helper (Windows Credential
  Manager) **for `https://github.com/InfiniteSolutionCZ/leadsonar.git` only**, so later
  updates of LeadSonar work without a sign-in; other repositories and pushes do not see
  it
- When it expires, run the line above again with a new token - it replaces the stored one

Developers who already work with the LeadSonar repository do not need this: they clone it
and run `scripts/install.ps1` from the checkout.

## Maintenance

- `irm ... | iex` runs whatever is on `main` here on the user's computer: only the
  maintainers may push, and `main` is protected
- Keep the scripts ASCII - Windows PowerShell 5.1 reads a file without a BOM in the ANSI
  code page
- The real install logic belongs in the private repository, next to the code it installs;
  a script here only gets it there
