%%%
title = "OpenID Federation Trust Mark Requirements 1.0 - draft 00"
abbrev = "openid-federation-trust-mark-requirements"
ipr = "none"
workgroup = "OpenID Connect Working Group"
keyword = ["security", "openid", "federation", "trust mark"]

[seriesInfo]
name = "Internet-Draft"
value = "openid-federation-trust-mark-requirements"
status = "standard"

[[author]]
initials = "E."
surname = "Perottoni"
fullname = "Eduardo Perottoni"
organization = "UFSC"
    [author.address]
    email = "edu.perottoni@gmail.com"

[[author]]
initials = "F."
surname = "Schardong"
fullname = "Frederico Schardong"
organization = "UFSC"
    [author.address]
    email = "frederico.schardong@ufsc.br"

[[author]]
initials = "R."
surname = "Custódio"
fullname = "Ricardo Custódio"
organization = "UFSC"
    [author.address]
    email = "ricardo.custodio@ufsc.br"

%%%

.# Abstract

This specification acts as an extension to [@!OpenID.Federation]. It defines the `trust_mark_requirements` Claim, which lets a Trust Anchor or an Intermediate Entity declare, in the Entity Statements it issues, which Trust Marks the subject of a Trust Chain MUST hold for the chain to be valid. Trust Mark requirements are expressed per Entity Type and are enforced as an additional step of Trust Chain validation, without changing any existing step.

{mainmatter}

# Introduction {#introduction}

OpenID Federation defines a way to build a Trust Chain that proves its subject is hierarchically part of the federation. It also proves the subject meets some requirements regarding its metadata, its Entity ID domain name, its depth on the hierarchy and its Entity Type, all of them defined by the superior entities using `metadata_policy` and `constraints`. It does not prove that the subject meets specific conditions the federation attaches to its entities. Those conditions are typically conveyed by Trust Marks (Section 1.2 of [@!OpenID.Federation]), whose semantics are deliberately left to definition by each federation implementation.

What the base specification does not define is how a federation states, in a machine-verifiable way, that a Trust Mark is mandatory. Trust Mark validation (Section 7.3 of [@!OpenID.Federation]) is a separate procedure on a Trust Mark instance. Section 17.5 of [@!OpenID.Federation] notes that a federation MAY have a policy on which Trust Marks SHOULD be used, and that an Entity MAY use unrecognized Trust Marks at its own discretion.

The result is that the requirement lives in out-of-band policy documents. Two resolvers configured with the same Trust Anchor can reach different conclusions about the same Entity depending whether they implement the policy or not.

## Requirements Notation and Conventions {#requirements-notation-and-conventions}

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 [@!RFC2119] [@!RFC8174] when, and only when, they appear in all capitals, as shown here.

# Terminology {#terminology}

This specification uses the terms "Entity", "Entity Configuration", "Subordinate Statement", "Trust Anchor", "Intermediate Entity", "Leaf Entity", "Superior Entity", "Subordinate Entity", "Trust Chain", "Entity Type", "Entity Type Identifier", "Federation Entity Discovery", "Trust Mark", "Trust Mark type identifier", "Trust Mark Issuer", "Trust Mark Owner", and "Resolved Metadata" as defined in [@!OpenID.Federation].

# Use Cases {#use-cases}

Each use case below is one a federation operator expresses today as an out-of-band policy and cannot enforce through the Trust Chain.

1. **Federation of federations.** Federation A is a federation of federations. Its Trust Anchor subordinates the Trust Anchor of a member Federation B as an Intermediate. Every Entity of B can then build a valid Trust Chain to A, but participation in A is decided per Entity, for example by agreeing to A's policies. A issues a membership Trust Mark only to the Entities of B that opted in and requires that Trust Mark. Entities of B that did not opt in keep valid Trust Chains to B, but cannot form one to A.
2. **Security baseline.** A federation requires every OpenID Provider and Relying Party to hold a Trust Mark attesting conformance to a baseline set of security practices defined by the federation.
3. **Entity-type-specific categories.** A federation requires Relying Parties to hold a Trust Mark from at least one of several categories defined by the federation, while imposing nothing on OpenID Providers.
4. **Branch-specific tightening.** An Intermediate requires its own Subordinates to hold additional Trust Marks defined for its branch, without affecting other branches of the federation.

# The `trust_mark_requirements` Claim {#claim}

This specification defines the following Entity Statement Claim:

- **trust_mark_requirements**: (OPTIONAL) JSON object declaring the Trust Marks that the subject of a Trust Chain is required to hold. Each member name is an Entity Type Identifier (Section 5.1 of [@!OpenID.Federation]). Each member value is the requirement for that Entity Type, expressed as defined in (#requirement-syntax).

## Declaring Requirements {#declaring-requirements}

The Claim MAY appear in both Entity Configurations and Subordinate Statements.

A Trust Anchor MAY include `trust_mark_requirements` in its Entity Configuration, in which case the requirements apply to every Trust Chain ending in that Trust Anchor. As with `trust_mark_issuers` (Section 3.1.2 of [@!OpenID.Federation]), the Claim MUST be ignored if present in the Entity Configuration of an Entity that is not acting as the Trust Anchor of the chain being validated. Because the Trust Anchor's Entity Configuration is obtained and trusted before discovery begins, these requirements can be checked against the subject before any Superior is fetched, as described in (#early-evaluation-of-trust-anchor-requirements).

A Trust Anchor or Intermediate MAY include `trust_mark_requirements` in a Subordinate Statement. Like `metadata_policy` and `constraints` (Section 3.1.3 of [@!OpenID.Federation]), it applies to the subject of the statement and to all Entities Subordinate to it.

An issuer of an Entity Statement carrying `trust_mark_requirements` MUST list `trust_mark_requirements` in the `crit` Claim of that statement (Section 13.4 of [@!OpenID.Federation]). A resolver that does not implement this specification then rejects the statement (Section 3.2, step 13, of [@!OpenID.Federation]) instead of silently accepting a chain the issuer meant to restrict. This specification is therefore fail-closed for non-implementing resolvers.

## Claim Syntax {#requirement-syntax}

The value of each member of the `trust_mark_requirements` object MUST take one of the following forms:

- A string, which is a Trust Mark type identifier. It is satisfied when the subject holds a valid Trust Mark of that type, as defined in (#evaluating-a-trust-mark-type-identifier).
- A JSON object whose only member is `all_of`, with a non-empty JSON array as its value. Each element of the array takes one of the forms in this list. It is satisfied when every element is satisfied.
- A JSON object whose only member is `one_of`, with a non-empty JSON array as its value. Each element of the array takes one of the forms in this list. It is satisfied when at least one element is satisfied.

The `all_of` and `one_of` operators MAY be nested to express any combination of Trust Mark type identifiers. Their semantics mirror two metadata policy operators of [@!OpenID.Federation]. The operator `all_of` corresponds to `superset_of` (Section 6.1.3.1.6 of [@!OpenID.Federation]), which requires a metadata parameter to contain every value it lists, and `one_of` corresponds to the operator of the same name (Section 6.1.3.1.4 of [@!OpenID.Federation]), which accepts any one of the values it lists. Here the listed values are themselves Trust Mark requirements: `all_of` is satisfied when every one of them is satisfied, and `one_of` when at least one of them is satisfied.

The following is a non-normative example of a `trust_mark_requirements` Claim value. It requires every Relying Party to hold a SIRTFI-equivalent Trust Mark and either a Research and Scholarship or a Code of Conduct Trust Mark, and every OpenID Provider to hold the SIRTFI-equivalent Trust Mark:

```json
{
  "openid_relying_party": {
    "all_of": [
      "https://refeds.example.org/tm/sirtfi",
      {
        "one_of": [
          "https://refeds.example.org/tm/research-and-scholarship",
          "https://refeds.example.org/tm/code-of-conduct"
        ]
      }
    ]
  },
  "openid_provider": "https://refeds.example.org/tm/sirtfi"
}
```

The Trust Mark type identifiers above are placeholders. Real identifiers are defined by the federation or by the Trust Mark Owner.

The following rules apply:

- The requirement for an Entity Type applies to the subject of the Trust Chain only if the subject's Entity Configuration declares that Entity Type in its `metadata` Claim. A subject with several Entity Types MUST satisfy the requirement for each of them.
- An empty `trust_mark_requirements` object, an empty `all_of` or `one_of` array, and a JSON object with any member other than exactly one of `all_of` or `one_of` MUST be treated as syntax errors, and the Entity Statement carrying them MUST be rejected.

# Combining Requirements Along a Trust Chain {#combining-requirements}

For each Entity Type, the combined requirement of a Trust Chain is an `all_of` of every requirement declared for that Entity Type in the Trust Anchor's Entity Configuration and in every Subordinate Statement in the chain.

For example, if the Trust Anchor requires `"https://ta.example.org/tm/member"` for Relying Parties, and an Intermediate requires `{"one_of": ["https://refeds.example.org/tm/research-and-scholarship", "https://refeds.example.org/tm/code-of-conduct"]}` for the same Entity Type, the combined requirement for a Relying Party under that Intermediate is:

```json
{
  "all_of": [
    "https://ta.example.org/tm/member",
    {
      "one_of": [
        "https://refeds.example.org/tm/research-and-scholarship",
        "https://refeds.example.org/tm/code-of-conduct"
      ]
    }
  ]
}
```

This combination inherits the principles of metadata policy (Section 6.1.1 of [@!OpenID.Federation]):

- **Hierarchy.** A Subordinate can only add requirements. No statement can remove or relax a requirement declared by a Superior.
- **Equal opportunity.** Every Superior in the chain contributes on the same basis.
- **Specificity.** Requirements are bound to an Entity Type and do not interact across types.
- **Determinism.** The result of `all_of` does not depend on the order of its members, so the combined requirement does not depend on the order in which statements are processed.

Unlike metadata policy, combination cannot produce a conflict: every combined requirement is well-formed. A combined requirement can still be unsatisfiable in practice, for example when no Trust Mark Issuer is authorized for a required type (see (#evaluating-a-trust-mark-type-identifier)). That case invalidates the chain rather than producing a policy error.

# Enforcement During Trust Chain Validation {#enforcement}

This specification adds the following step to Trust Chain validation (Section 10.2 of [@!OpenID.Federation]), after the statements of the chain have been validated and before metadata is resolved:

1. Collect `trust_mark_requirements` from the Trust Anchor's Entity Configuration and from every Subordinate Statement in the chain.
2. Combine them per Entity Type as described in (#combining-requirements).
3. Evaluate the combined requirement for each Entity Type of the subject, as defined in (#requirement-syntax).
4. If the combined requirement for any Entity Type of the subject is not satisfied, the Trust Chain MUST be considered invalid.

Requirements in a Subordinate Statement are only known once that statement has been fetched and its signature validated. They MUST NOT be evaluated from an unvalidated statement.

A resolver MAY evaluate the requirements declared in a Trust Anchor's Entity Configuration before building the Trust Chain, as described in (#early-evaluation-of-trust-anchor-requirements). Doing so never changes the outcome, because the step above evaluates the same requirements again.

## Evaluating a Trust Mark Type Identifier {#evaluating-a-trust-mark-type-identifier}

A Trust Mark type identifier in a requirement is satisfied when the subject's Entity Configuration contains, in its `trust_marks` Claim, at least one Trust Mark that:

1. has that `trust_mark_type`;
2. is valid according to Section 7.3 of [@!OpenID.Federation], including its `sub` matching the subject, `iat`, `exp`, signature and, when applicable, delegation;
3. was issued by an Entity listed for that `trust_mark_type` in the `trust_mark_issuers` Claim of the Trust Anchor that ends the chain, or the list for that type is empty, which per Section 3.1.2 of [@!OpenID.Federation] means anyone may issue it.

If the Trust Anchor's `trust_mark_issuers` does not list a required `trust_mark_type`, no Trust Mark can satisfy it and the chain is invalid. A Trust Anchor SHOULD therefore list every type it or its Subordinates require. Trust Marks that an Entity accepts at its own discretion under Section 17.5 of [@!OpenID.Federation] MUST NOT be used to satisfy a requirement.

## Static and Dynamic Validation {#static-and-dynamic-validation}

Static validation is the procedure of Section 7.3 of [@!OpenID.Federation] applied to the Trust Mark JWT. It requires the Trust Mark Issuer's key, which in turn requires trust in the issuer. When the issuer is the Trust Anchor itself and its key is already configured, the check is purely static. When the issuer is another Entity, the resolver MUST first establish trust in the issuer as defined in Section 7.3 of [@!OpenID.Federation], that is, through a Trust Chain from the issuer to a Trust Anchor the resolver trusts, which need not be the Trust Anchor of the subject's chain. The issuer MUST still be authorized for that `trust_mark_type` in the `trust_mark_issuers` of the subject's Trust Anchor (item 3 of (#evaluating-a-trust-mark-type-identifier)).

A resolver MAY additionally query the issuer's Trust Mark Status endpoint (Section 8.4 of [@!OpenID.Federation]). A federation MAY require it for specific types; how a federation states that is out of scope of this specification.

## Expiration {#expiration}

The expiration time of a Trust Chain (Section 10.4 of [@!OpenID.Federation]) becomes the minimum of the `exp` values of its Entity Statements and of the `exp` values of the Trust Marks used to satisfy its requirements.

## Multiple Trust Chains {#multiple-trust-chains}

A chain that fails its requirements is invalid, not an error of the subject. A resolver MAY try other chains (Section 10.3 of [@!OpenID.Federation]), including chains to other Trust Anchors, each evaluated against its own requirements.

## Resolve Endpoint {#resolve-endpoint}

A resolver exposing a `federation_resolve_endpoint` (Section 8.3 of [@!OpenID.Federation]) that implements this specification MUST perform the step defined in this section before returning a response, and MUST NOT return Resolved Metadata for a chain whose requirements are not satisfied.

# Implementation Considerations {#implementation-considerations}

## Early Evaluation of Trust Anchor Requirements {#early-evaluation-of-trust-anchor-requirements}

The requirements declared in a Trust Anchor's Entity Configuration apply to every Trust Chain ending in that Trust Anchor, and that Entity Configuration is available to the resolver before discovery begins. A resolver can therefore evaluate them against the subject right after obtaining and validating the subject's Entity Configuration, before following its `authority_hints`. If they are not satisfied, every Trust Chain from the subject to that Trust Anchor would be invalid, and the resolver can skip building one. This avoids fetching Superiors for a subject that cannot qualify, and lets a resolver configured with several Trust Anchors discard those whose requirements the subject does not meet.

## Caching Trust Mark Issuer Trust Chains {#caching-trust-mark-issuer-trust-chains}

Establishing trust in a Trust Mark Issuer (see (#static-and-dynamic-validation)) requires resolving a Trust Chain for that issuer. Since one issuer typically serves many subjects, resolvers SHOULD cache the issuer's Trust Chain, within its expiration time (Section 10.4 of [@!OpenID.Federation]).

## Selecting Among Equivalent Trust Marks {#selecting-among-equivalent-trust-marks}

When several Trust Marks held by the subject could satisfy the same Trust Mark type identifier, a resolver SHOULD use the one with the latest `exp`, since the Trust Marks used bound the expiration time of the Trust Chain (see (#expiration)).

## Bounding Evaluation Cost {#bounding-evaluation-cost}

Resolvers SHOULD bound the number of Trust Marks they evaluate per subject, and MAY stop evaluating an `all_of` as soon as one of its members is unsatisfied, or a `one_of` as soon as one of its members is satisfied.

# Security Considerations {#security-considerations}

In addition to the considerations below, the security considerations of [@!OpenID.Federation] apply to this specification.

## Downgrade by Non-Implementing Resolvers {#downgrade-by-non-implementing-resolvers}

Without criticality, a resolver unaware of this Claim would ignore it and accept chains the federation meant to reject. (#declaring-requirements) makes the Claim critical, so such resolvers reject the statement instead. Federations deploying this specification should expect non-implementing resolvers to fail closed during the transition.

## Trust Mark Replay {#trust-mark-replay}

A Trust Mark copied into another Entity's Entity Configuration fails validation, because its `sub` must match the Entity whose configuration contains it (Section 7.3 of [@!OpenID.Federation]).

## Freshness {#freshness}

Static validation does not detect a Trust Mark revoked before its `exp`. Federations that need prompt revocation should issue short-lived Trust Marks or require the Trust Mark Status endpoint. (#expiration) bounds chain lifetime by the Trust Marks used.

## Denial of Service {#denial-of-service}

Evaluating a Trust Anchor's requirements early (see (#early-evaluation-of-trust-anchor-requirements)) rejects unqualified subjects before any Superior is fetched. The measures in (#caching-trust-mark-issuer-trust-chains) and (#bounding-evaluation-cost) further limit the work an attacker can induce.

# IANA Considerations {#iana-considerations}

This specification requests registration of the following Claim in the IANA "JSON Web Token Claims" registry [@IANA.JWT.Claims] established by [@!RFC7519]:

- Claim Name: `trust_mark_requirements`
- Claim Description: Trust Marks that the subject of a Trust Chain is required to hold, per Entity Type
- Change Controller: OpenID Foundation Artifact Binding/Connect Working Group – openid-specs-ab@lists.openid.net
- Specification Document(s): (#claim) of this specification

{backmatter}

<reference anchor="OpenID.Federation" target="https://openid.net/specs/openid-federation-1_1.html">
    <front>
        <title>OpenID Federation 1.1</title>
        <author fullname="R. Hedberg, Ed."><organization>independent</organization></author>
        <author fullname="Michael B. Jones"><organization>Self-Issued Consulting</organization></author>
        <author fullname="Giuseppe De Marco"><organization>independent</organization></author>
        <author fullname="A. Solberg"><organization>Sikt</organization></author>
        <author fullname="John Bradley"><organization>Yubico</organization></author>
        <author fullname="Vladimir Dzhuvinov"><organization>Connect2id</organization></author>
        <date day="5" month="May" year="2026"/>
    </front>
</reference>

<reference anchor="OpenID.Federation-1.0" target="https://openid.net/specs/openid-federation-1_0.html">
    <front>
        <title>OpenID Federation 1.0</title>
        <author fullname="R. Hedberg, Ed."><organization>independent</organization></author>
        <author fullname="Michael B. Jones"><organization>Self-Issued Consulting</organization></author>
        <author fullname="A. Solberg"><organization>Sikt</organization></author>
        <author fullname="John Bradley"><organization>Yubico</organization></author>
        <author fullname="Giuseppe De Marco"><organization>independent</organization></author>
        <author fullname="Vladimir Dzhuvinov"><organization>Connect2id</organization></author>
        <date day="17" month="February" year="2026"/>
    </front>
</reference>

<reference anchor="IANA.JWT.Claims" target="https://www.iana.org/assignments/jwt">
    <front>
        <title>JSON Web Token Claims</title>
        <author><organization>IANA</organization></author>
        <date/>
    </front>
</reference>

# Example: Inter-Federation Opt-In {#example-inter-federation-opt-in}

This appendix models an inter-federation (in the role eduGAIN plays) that subordinates a national federation. Only opted-in Entities of the national federation hold the inter-federation membership Trust Mark. All identifiers and keys are placeholders.

## Inter-federation Trust Anchor Entity Configuration {#example-trust-anchor-entity-configuration}

The following is a non-normative example of the Entity Configuration payload of the inter-federation Trust Anchor. It issues its own membership Trust Mark and requires it of every OpenID Provider and Relying Party:

```json
{
  "iss": "https://ta.edugain.example.org",
  "sub": "https://ta.edugain.example.org",
  "iat": 1790000000,
  "exp": 1790086400,
  "jwks": {
    "keys": [
      {
        "kty": "RSA",
        "kid": "edugain-key1",
        "use": "sig",
        "n": "n4EPtAOCc9AlkeQHPzHStgAbgs7bTZLwUBZdR8_KuKPEHLd4rHVTeT",
        "e": "AQAB"
      }
    ]
  },
  "metadata": {
    "federation_entity": {
      "federation_fetch_endpoint": "https://ta.edugain.example.org/fetch",
      "federation_list_endpoint": "https://ta.edugain.example.org/list"
    }
  },
  "trust_mark_issuers": {
    "https://ta.edugain.example.org/tm/member": [
      "https://ta.edugain.example.org"
    ],
    "https://refeds.example.org/tm/sirtfi": [
      "https://tmi.refeds.example.org"
    ]
  },
  "trust_mark_requirements": {
    "openid_provider": "https://ta.edugain.example.org/tm/member",
    "openid_relying_party": "https://ta.edugain.example.org/tm/member"
  },
  "crit": [
    "trust_mark_requirements"
  ]
}
```

## Subordinate Statement About the National Federation {#example-subordinate-statement}

The inter-federation additionally requires the SIRTFI-equivalent Trust Mark, but only for Entities reached through this national federation, so it declares the requirement in its Subordinate Statement about that federation rather than in its own Entity Configuration. Its issuer is not the Trust Anchor, so validating it requires trust in that issuer (see (#static-and-dynamic-validation)).

The following is a non-normative example of the Subordinate Statement payload issued by the inter-federation Trust Anchor about the national federation Trust Anchor:

```json
{
  "iss": "https://ta.edugain.example.org",
  "sub": "https://ta.national.example.org",
  "iat": 1790000000,
  "exp": 1790086400,
  "jwks": {
    "keys": [
      {
        "kty": "RSA",
        "kid": "national-key1",
        "use": "sig",
        "n": "pnXBOusEANuug6ewezb9J_XqdsgyHQj9cbNNpG5EvmP2I8vLQEBOy3",
        "e": "AQAB"
      }
    ]
  },
  "trust_mark_requirements": {
    "openid_provider": "https://refeds.example.org/tm/sirtfi",
    "openid_relying_party": "https://refeds.example.org/tm/sirtfi"
  },
  "crit": [
    "trust_mark_requirements"
  ]
}
```

## Leaf Entity Configuration {#example-leaf-entity-configuration}

The following is a non-normative example of the Entity Configuration payload of an opted-in Relying Party of the national federation:

```json
{
  "iss": "https://rp.university.example.org",
  "sub": "https://rp.university.example.org",
  "iat": 1790000000,
  "exp": 1790086400,
  "jwks": {
    "keys": [
      {
        "kty": "RSA",
        "kid": "rp-key1",
        "use": "sig",
        "n": "0vx7agoebGcQSuuPiLJXZptN9nndrQmbXEps2aiAFbWhM78LhWx4cb",
        "e": "AQAB"
      }
    ]
  },
  "authority_hints": [
    "https://ta.national.example.org"
  ],
  "metadata": {
    "openid_relying_party": {
      "redirect_uris": [
        "https://rp.university.example.org/cb"
      ]
    }
  },
  "trust_marks": [
    {
      "trust_mark_type": "https://ta.edugain.example.org/tm/member",
      "trust_mark": "eyJhbGciOiJSUzI1NiIsInR5cCI6InRydXN0LW1hcmsrand0In0..."
    },
    {
      "trust_mark_type": "https://refeds.example.org/tm/sirtfi",
      "trust_mark": "eyJhbGciOiJSUzI1NiIsInR5cCI6InRydXN0LW1hcmsrand0In0..."
    }
  ]
}
```

## Outcomes {#example-outcomes}

The combined requirement for a Relying Party resolved to the inter-federation is `{"all_of": ["https://ta.edugain.example.org/tm/member", "https://refeds.example.org/tm/sirtfi"]}`: the Relying Party needs both the membership and the SIRTFI-equivalent Trust Marks.

The following table shows, for each combination of Trust Marks held by the Relying Party, whether its Trust Chain to each Trust Anchor is valid.

| Relying Party holds | To the national Trust Anchor | To the inter-federation Trust Anchor |
| --- | --- | --- |
| member + SIRTFI | Valid | Valid |
| SIRTFI only (not opted in) | Valid | Invalid (member missing) |
| member only | Valid | Invalid (SIRTFI, required by the Subordinate Statement, missing) |
| neither | Valid | Invalid (member and SIRTFI missing) |
Table: Trust Chain Validity per Combination of Trust Marks Held by the Relying Party

The national Trust Anchor declares no requirements in this example, so every row is valid there. The same Leaf is admitted or rejected depending on the Trust Anchor its chain ends in.

# Notices

Copyright (c) 2026 The OpenID Foundation.

The OpenID Foundation (OIDF) grants to any Contributor, developer,
implementer, or other interested party a non-exclusive, royalty free,
worldwide copyright license to reproduce, prepare derivative works from,
distribute, perform and display, this Implementers Draft, Final
Specification, or Final Specification Incorporating Errata Corrections
solely for the purposes of (i) developing specifications,
and (ii) implementing Implementers Drafts, Final Specifications,
and Final Specification Incorporating Errata Corrections based
on such documents, provided that attribution be made to the OIDF as the
source of the material, but that such attribution does not indicate an
endorsement by the OIDF.

The technology described in this specification was made available
from contributions from various sources, including members of the OpenID
Foundation and others. Although the OpenID Foundation has taken steps to
help ensure that the technology is available for distribution, it takes
no position regarding the validity or scope of any intellectual property
or other rights that might be claimed to pertain to the implementation
or use of the technology described in this specification or the extent
to which any license under such rights might or might not be available;
neither does it represent that it has made any independent effort to
identify any such rights. The OpenID Foundation and the contributors to
this specification make no (and hereby expressly disclaim any)
warranties (express, implied, or otherwise), including implied
warranties of merchantability, non-infringement, fitness for a
particular purpose, or title, related to this specification, and the
entire risk as to implementing this specification is assumed by the
implementer. The OpenID Intellectual Property Rights policy
(found at openid.net) requires
contributors to offer a patent promise not to assert certain patent
claims against other contributors and against implementers.
OpenID invites any interested party to bring to its attention any
copyrights, patents, patent applications, or other proprietary rights
that may cover technology that may be required to practice this
specification.

# Acknowledgements

TBD.

# Document History

[[ To be removed from the final specification ]]

-00

* Initial version: `trust_mark_requirements` Claim, enforcement as a Trust Chain
  validation step, inter-federation opt-in example.
