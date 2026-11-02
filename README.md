# OpenID Federation Trust Mark Requirements 1.0

This repository contains the "OpenID Federation Trust Mark Requirements" specification, an extension to OpenID Federation 1.1. It defines the `trust_mark_requirements` claim, which lets a Trust Anchor or an Intermediate Entity declare which Trust Marks the subject of a Trust Chain must hold for the chain to be valid, and adds that check as a normative step of Trust Chain validation.

## Builds

The latest editors' draft can be viewed at
[https://eduperottoni.github.io/trust-mark-requirements/main.html](https://eduperottoni.github.io/trust-mark-requirements/main.html)

Branches can be viewed at
https://eduperottoni.github.io/trust-mark-requirements/{BRANCH-NAME}.html

## Build the HTML

```bash
docker run -v `pwd`:/data danielfett/markdown2rfc openid-federation-trust-mark-requirements-1_0.md
```

or simply `make`.

## Contact

For further information and to get involved, please read [CONTRIBUTING.md](CONTRIBUTING.md), open an issue, or write to the OpenID Connect Working Group list (openid-specs-ab@lists.openid.net).
