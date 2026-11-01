%%%
title = "OpenID Federation Trust Mark Requirements 1.0 - draft 00"
abbrev = "oidfed-trust-mark-requirements"
ipr = "none"
workgroup = "OpenID Connect Working Group"
keyword = ["security", "openid", "federation", "trust mark"]

[seriesInfo]
name = "Internet-Draft"
value = "openid-federation-trust-mark-requirements-1_0"
status = "standard"

[[author]]
initials = "E. D."
surname = "Perottoni"
fullname = "Eduardo Dani Perottoni"
organization = "Universidade Federal de Santa Catarina (UFSC)"
    [author.address]
    email = "edu.perottoni@gmail.com"
%%%

.# Abstract

This specification lets a Trust Anchor or an Intermediate Entity declare, on the Entity Statements it issues , which Trust Marks the subject of a Trust Chain MUST hold for the chain to be valid. Trust Mark requirements are expressed per Entity Type and are enforced as a normative step of Trust Chain validation. This specification extends [@!OpenID.Federation] without changing any existing processing rule.

{mainmatter}

# Introduction

OpenID Federation defines a way to build a Trust Chain that proves its subject is hierarchically part of the federation. It also proves the subject meets some requirements regarding its metadata, its Entity ID domain name, its depth on the hierarchy and its Entity Type, all of them defined by the superior entities using metadata\_policy and constraints. It does not prove that the subject meets specific conditions the federation attaches to its entities. Those conditions are typically conveyed by Trust Marks, whose semantics are deliberately left to each federation. A Trust Mark is a statement of conformance to requirements "as determined by an accreditation authority" (Section 1.2 of [@!OpenID.Federation]).

What the base specification does not define is how a federation states, in a machine-verifiable way, that a Trust Mark is mandatory:

- Trust Chain validation (Section 10.2 of [@!OpenID.Federation]) checks claims, timestamps, the `iss`/`sub` linkage and signatures, then resolves metadata and enforces `constraints`. No step involves Trust Marks.
- Trust Mark validation (Section 7.3 of [@!OpenID.Federation]) is a separate procedure on a Trust Mark instance.
- Section 17.5 of [@!OpenID.Federation], under Implementation Considerations, notes only that a federation MAY have a policy on which Trust Marks SHOULD be used, and that an Entity MAY use unrecognized Trust Marks at its own discretion.

The result is that the requirement lives in out-of-band policy documents. Two resolvers configured with the same Trust Anchor can reach different conclusions about the same Entity.

The gap matters most in an inter-federation context. When a federation Trust Anchor A is subordinated to an inter-federation Trust Anchor B, every Leaf of A obtains a valid Trust Chain to B. The chain proves the Leaf is subordinate of B and A and does not prove the Leaf is in accordance with some requirement of B possibly expressed using a Trust Mark.

# Requirements Notation and Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "NOT RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in BCP 14 [@!RFC2119] [@!RFC8174] when, and only when, they appear in all capitals.

This specification uses the terms Entity, Entity Configuration, Subordinate Statement, Trust Anchor, Intermediate Entity, Leaf Entity, Trust Chain, Entity Type, Trust Mark, Trust Mark type identifier, Trust Mark Issuer and Resolved Metadata as defined in [@!OpenID.Federation]. It defines the following terms:

- **Trust Mark Requirement**: a statement, made by a Trust Anchor or an Intermediate Entity, that the subject of a Trust Chain MUST hold Trust Marks satisfying a given expression for a given Entity Type.
- **Clause**: a non-empty set of Trust Mark type identifiers, satisfied when the subject holds a valid Trust Mark of at least one of them.
- **Requirement Expression**: a set of Clauses for one Entity Type, satisfied when every Clause is satisfied.
- **Gate Phase**: the evaluation of requirements declared in the Trust Anchor's Entity Configuration, before Federation Entity Discovery proceeds to the subject.
- **Chain Phase**: the evaluation of the combined requirements of the whole Trust Chain, after its statements have been validated and before metadata policy is applied.

# Use Cases

Each use case below is one a federation operator expresses today as an out-of-band policy and cannot enforce through the Trust Chain.

1. **Inter-federation opt-in.** An inter-federation Trust Anchor subordinates national federations as Intermediates. Only Entities that opted in carry the inter-federation's membership Trust Mark. The inter-federation requires that Trust Mark, so non-participating Entities of a national federation cannot form a valid chain to it.
2. **Security baseline.** A federation requires every OpenID Provider and Relying Party to hold a security incident response Trust Mark (for example, a SIRTFI-equivalent).
3. **Entity-type-specific categories.** A federation requires Relying Parties to hold one of several attribute-release categories (for example, Research and Scholarship or Code of Conduct) while imposing nothing on OpenID Providers.
4. **Branch-specific tightening.** An Intermediate adds requirements for its own Subordinates (for example, a national accreditation Trust Mark) without affecting other branches of the federation.

In all four, the requirement depends on the Trust Anchor the chain ends in. The same Leaf may satisfy its national federation and fail the inter-federation, which is the intended outcome.

# The trust\_mark\_requirements Claim {#claim}

Requirements are carried in a new Entity Statement Claim, `trust_mark_requirements`, whose value is a JSON object:

- Each member name is an Entity Type Identifier (Section 5.1 of [@!OpenID.Federation]).
- Each member value is a Requirement Expression: a non-empty JSON array of Clauses.
- Each Clause is a non-empty JSON array of Trust Mark type identifiers (strings).

The Requirement Expression is read in conjunctive normal form. The outer array is a conjunction (AND), each inner array is a disjunction (OR). The following example requires every Relying Party to hold a SIRTFI-equivalent Trust Mark AND either a Research and Scholarship or a Code of Conduct Trust Mark, and every OpenID Provider to hold the SIRTFI-equivalent Trust Mark:

```json
"trust_mark_requirements": {
  "openid_relying_party": [
    ["https://refeds.example.org/tm/sirtfi"],
    ["https://refeds.example.org/tm/research-and-scholarship",
     "https://refeds.example.org/tm/code-of-conduct"]
  ],
  "openid_provider": [
    ["https://refeds.example.org/tm/sirtfi"]
  ]
}
```

Rules:

- A Requirement Expression applies to the subject of the Trust Chain only if the subject's Entity Configuration declares that Entity Type in its `metadata` Claim. A subject with several Entity Types MUST satisfy the expression for each of them.
- Duplicate Trust Mark type identifiers within a Clause, and duplicate Clauses within an expression, have no effect.
- An empty object, an empty expression array or an empty Clause MUST be treated as a syntax error, and the Entity Statement carrying it MUST be rejected.

The Trust Mark type identifiers above are placeholders. Real identifiers are defined by the federation or by the Trust Mark Owner.

# Declaring Requirements

The Claim MAY appear in both Entity Configurations and Subordinate Statements.

| Location | Allowed entities | Applies to | Checked in |
| --- | --- | --- | --- |
| Trust Anchor's Entity Configuration | Trust Anchors only | Every Trust Chain ending in that Trust Anchor | Gate Phase and Chain Phase |
| Subordinate Statement | Trust Anchors and Intermediates | The subject of the statement and all its Subordinates | Chain Phase |

## In the Trust Anchor's Entity Configuration

A Trust Anchor MAY include `trust_mark_requirements` in its Entity Configuration. As with `trust_mark_issuers` (Section 3.1.2 of [@!OpenID.Federation]), the Claim MUST be ignored if present in the Entity Configuration of an Entity that is not acting as the Trust Anchor of the chain being validated. Because the Trust Anchor's Entity Configuration is obtained and trusted before discovery begins, these requirements can be checked against the subject before any Superior is fetched (Section 7.1).

## In Subordinate Statements

A Trust Anchor or Intermediate MAY include `trust_mark_requirements` in a Subordinate Statement. Like `metadata_policy` and `constraints` (Section 3.1.3 of [@!OpenID.Federation]), it applies to the subject of the statement and to all Entities Subordinate to it.

## Criticality

An issuer of an Entity Statement carrying `trust_mark_requirements` MUST list `trust_mark_requirements` in the `crit` Claim of that statement (Section 13.4 of [@!OpenID.Federation]). A resolver that does not implement this specification then rejects the statement (Section 3.2, step 13, of [@!OpenID.Federation]) instead of silently accepting a chain the issuer meant to restrict. This specification is therefore fail-closed for non-implementing resolvers.

# Combining Requirements Along a Trust Chain

The combined requirement of a Trust Chain is the union of all Clauses declared for each Entity Type, collected from the Trust Anchor's Entity Configuration and from every Subordinate Statement in the chain.

Formally, if R(s, t) is the set of Clauses that statement s declares for Entity Type t, the combined expression for t is the union of R(s, t) over all statements s in the chain. Because a set of Clauses is read as their conjunction, the union is the conjunction of every declared expression.

This combination inherits the principles of metadata policy (Section 6.1.1 of [@!OpenID.Federation]):

- **Hierarchy.** A Subordinate can only add Clauses. No statement can remove or relax a Clause declared by a Superior.
- **Equal opportunity.** Every Superior in the chain contributes on the same basis.
- **Specificity.** Requirements are bound to an Entity Type and do not interact across types.
- **Determinism.** Union is commutative and associative, so the combined expression does not depend on the order in which statements are processed.

Unlike metadata policy, combination cannot produce a conflict: every combined expression is well-formed. A combined expression can still be unsatisfiable in practice, for example when no Trust Mark Issuer is authorized for a required type (Section 7.3). That case invalidates the chain rather than producing a policy error.

# Enforcement During Trust Chain Resolution

Trust Mark Requirements are enforced in two phases: a Gate Phase that rejects a subject before discovery when the Trust Anchor's own requirements fail, and a Chain Phase that checks the combined requirements once the chain is assembled.

~~~ ascii-art
+-------------------------------+
| Validate the subject's        |
| Entity Configuration          |
+-------------------------------+
                |
                v
+-------------------------------+       +---------------------+
| Gate Phase: Trust Anchor      |  no   | Skip this Trust     |
| requirements met?             |------>| Anchor (no Superior |
+-------------------------------+       | fetched)            |
                | yes                   +---------------------+
                v
+-------------------------------+
| Fetch and validate the chain  |
| (Section 10.2)                |
+-------------------------------+
                |
                v
+-------------------------------+       +---------------------+
| Chain Phase: combined         |  no   | Chain invalid; try  |
| requirements met?             |------>| another chain       |
+-------------------------------+       | (Section 10.3)      |
                | yes                   +---------------------+
                v
+-------------------------------+
| Resolve metadata and enforce  |
| constraints                   |
+-------------------------------+
~~~
Figure: Two-phase enforcement of Trust Mark Requirements

The Gate Phase uses only the Trust Anchor's own requirements, so it runs before any Superior is fetched. The Chain Phase adds every requirement declared along the chain.

## Gate Phase

After obtaining and validating the subject's Entity Configuration, and before following its `authority_hints`, a resolver SHOULD, for each Trust Anchor it is configured with, evaluate the `trust_mark_requirements` of that Trust Anchor's Entity Configuration against the subject. If the evaluation fails, the resolver MUST NOT attempt to build a Trust Chain from the subject to that Trust Anchor.

The Gate Phase is an optimization and a denial-of-service control: it avoids fetching Superiors for a subject that cannot qualify. Skipping it never changes the outcome, because the Chain Phase re-evaluates the same requirements.

## Chain Phase

This specification adds the following step to Trust Chain validation (Section 10.2 of [@!OpenID.Federation]), after the statements of the chain have been validated and before metadata is resolved:

1. Collect `trust_mark_requirements` from the Trust Anchor's Entity Configuration and from every Subordinate Statement in the chain.
2. Combine them per Entity Type as described in Section 6.
3. Evaluate the combined expression for each Entity Type of the subject (Section 7.3).
4. If any Clause is not satisfied, the Trust Chain MUST be considered invalid.

Requirements in a Subordinate Statement are only known once that statement has been fetched and its signature validated. They MUST NOT be evaluated from an unvalidated statement.

## Evaluating a Clause

A Clause is satisfied when the subject's Entity Configuration contains, in its `trust_marks` Claim, at least one Trust Mark that:

1. has a `trust_mark_type` listed in the Clause;
2. is valid according to Section 7.3 of [@!OpenID.Federation], including its `sub` matching the subject, `iat`, `exp`, signature and, when applicable, delegation;
3. was issued by an Entity listed for that `trust_mark_type` in the `trust_mark_issuers` Claim of the Trust Anchor that ends the chain, or the list for that type is empty, which per Section 3.1.2 of [@!OpenID.Federation] means anyone may issue it.

If the Trust Anchor's `trust_mark_issuers` does not list a required `trust_mark_type`, no Trust Mark can satisfy it and the chain is invalid. A Trust Anchor SHOULD therefore list every type it or its Subordinates require. Trust Marks that an Entity accepts at its own discretion under Section 17.5 of [@!OpenID.Federation] MUST NOT be used to satisfy a requirement.

## Static and Dynamic Validation

Static validation is the procedure of Section 7.3 of [@!OpenID.Federation] applied to the Trust Mark JWT. It requires the Trust Mark Issuer's key, which in turn requires trust in the issuer.

- When the issuer is the Trust Anchor itself (for example, an inter-federation membership Trust Mark), its key is already configured and the check is purely static.
- When the issuer is another Entity, the resolver MUST first establish trust in the issuer as defined in Section 7.3 of [@!OpenID.Federation], that is, through a Trust Chain from the issuer to a Trust Anchor the resolver trusts, which need not be the Trust Anchor of the subject's chain. The issuer MUST still be authorized for that `trust_mark_type` in the `trust_mark_issuers` of the subject's Trust Anchor (Section 7.3, item 3). Resolvers SHOULD cache the issuer's Trust Chain, since one issuer serves many subjects.

Trust Marks required in a Trust Anchor's Entity Configuration SHOULD be issued by the Trust Anchor or by an issuer whose trust can be established without resolving the subject's chain, so that the Gate Phase stays static.

A resolver MAY additionally query the issuer's Trust Mark Status endpoint (Section 8.4 of [@!OpenID.Federation]). A federation MAY require it for specific types; how a federation states that is out of scope of this draft (Appendix C).

## Expiration

The expiration time of a Trust Chain (Section 10.4 of [@!OpenID.Federation]) becomes the minimum of the `exp` values of its Entity Statements AND of the `exp` values of the Trust Marks used to satisfy its requirements. When several Trust Marks could satisfy the same Clause, a resolver SHOULD pick the one with the latest `exp`.

## Multiple Trust Chains

A chain that fails its requirements is invalid, not an error of the subject. A resolver MAY try other chains (Section 10.3 of [@!OpenID.Federation]), including chains to other Trust Anchors, each evaluated against its own requirements.

## Resolve Endpoint

A resolver exposing a `federation_resolve_endpoint` (Section 8.3 of [@!OpenID.Federation]) that implements this specification MUST apply both phases before returning a response, and MUST NOT return Resolved Metadata for a chain whose requirements are not satisfied.

# Relationship to Other Mechanisms

This specification adds one dimension, sufficiency, alongside mechanisms that each answer a different question.

| Mechanism | Question it answers | Declared by |
| --- | --- | --- |
| `trust_mark_issuers`, `trust_mark_owners` (Section 3.1.2 of [@!OpenID.Federation]) | Who may issue a Trust Mark of a given type (authenticity) | Trust Anchor |
| `trust_mark_requirements` (this specification) | Which Trust Marks the subject must hold (sufficiency) | Trust Anchor, Intermediates |
| `constraints` (Section 6.2 of [@!OpenID.Federation]) | Where the subject may sit in the hierarchy and which Entity Types it may have | Trust Anchor, Intermediates |
| `metadata_policy` (Section 6.1 of [@!OpenID.Federation]) | What the subject's protocol metadata may contain | Trust Anchor, Intermediates |
| `trust_mark_types_required` [@OpenID.Federation.WellKnownBinding] | Which Trust Marks a counterparty must hold for a given role | The Entity itself |

\[AQUI ACHO QUE TEMOS QUE TIRAR O WK BINDING\]

Notes:

- **Authenticity and sufficiency are orthogonal.** A requirement is only satisfied by a Trust Mark that also passes the authenticity check of the chain's Trust Anchor (Section 7.3, item 3).
- **`allowed_entity_types`** restricts which roles a Subordinate may declare; a Trust Mark Requirement adds an accreditation for a role the subject already declares.
- **Counterparty requirements** in the Well-Known Binding draft are complementary. Together, federation-level, branch-level and relationship-level requirements cover three distinct scopes.
- **Discovery and filtering** of Entities by Trust Mark remain consumer-side functions, served by the Trust Marked Entities Listing endpoint (Section 8.5 of [@!OpenID.Federation]) and by the Entity Collection endpoint [@OpenID.Federation.EntityCollection].

# Security and Privacy Considerations

## Downgrade by Non-Implementing Resolvers

Without criticality, a resolver unaware of this Claim would ignore it and accept chains the federation meant to reject. Section 5.3 makes the Claim critical, so such resolvers reject the statement instead. Federations deploying this specification should expect non-implementing resolvers to fail closed during the transition.

## Removal of Requirements

Requirements are carried in signed Entity Statements, so they cannot be removed in transit. A compromised Intermediate can add requirements for its branch but cannot relax those of its Superiors (Section 6). A compromised Trust Anchor controls the whole federation regardless of this specification.

## Trust Mark Replay

A Trust Mark copied into another Entity's Entity Configuration fails validation, because its `sub` must match the Entity whose configuration contains it (Section 7.3 of [@!OpenID.Federation]).

## Freshness

Static validation does not detect a Trust Mark revoked before its `exp`. Federations that need prompt revocation should issue short-lived Trust Marks or require the Trust Mark Status endpoint. Section 7.5 bounds chain lifetime by the Trust Marks used.

## Denial of Service

The Gate Phase rejects unqualified subjects before any Superior is fetched. Resolvers should cache issuer trust (Section 7.4) and bound the number of Trust Marks evaluated per subject.

## Privacy

This specification introduces no new data about End-Users. Trust Marks and requirements are already public in Entity Statements. The privacy considerations of the Trust Mark Status endpoint (Section 19.2 of [@!OpenID.Federation]) apply when it is used.

# IANA Considerations

This specification requests registration of the following Claim in the IANA "JSON Web Token Claims" registry [@IANA.JWT.Claims] established by [@!RFC7519]:

- Claim Name: `trust_mark_requirements`
- Claim Description: Trust Marks that the subject of a Trust Chain is required to hold, per Entity Type
- Change Controller: OpenID Foundation Artifact Binding/Connect Working Group – openid-specs-ab@lists.openid.net
- Specification Document(s): Section 4 of this specification

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

<reference anchor="OpenID.Federation.EntityCollection" target="https://openid.net/specs/openid-federation-entity-collection-1_0.html">
    <front>
        <title>OpenID Federation Entity Collection Endpoint 1.0</title>
        <author fullname="Gabriel Zachmann"><organization>Karlsruhe Institute of Technology</organization></author>
        <date year="2026"/>
    </front>
</reference>

<reference anchor="OpenID.Federation.WellKnownBinding" target="https://dickhardt.github.io/well-known-binding/main.html">
    <front>
        <title>OpenID Federation Well-Known Binding</title>
        <author fullname="Dick Hardt"><organization/></author>
        <date month="September" year="2026"/>
    </front>
</reference>

<reference anchor="SPID-CIE-OIDC" target="https://docs.italia.it/italia/spid/spid-cie-oidc-docs/it/versione-corrente/trust_marks.html">
    <front>
        <title>SPID/CIE OpenID Connect Federation: Technical Rules (Trust Marks; Trust Negotiation)</title>
        <author><organization>Agenzia per l'Italia Digitale (AgID)</organization></author>
        <date year="2023"/>
    </front>
</reference>

<reference anchor="IANA.JWT.Claims" target="https://www.iana.org/assignments/jwt">
    <front>
        <title>JSON Web Token Claims</title>
        <author><organization>IANA</organization></author>
        <date/>
    </front>
</reference>

# Example: Inter-Federation Opt-In

This non-normative example models an inter-federation (in the role eduGAIN plays) that subordinates a national federation (in the role CAFe plays). Only opted-in Entities of the national federation hold the inter-federation membership Trust Mark. All identifiers are placeholders.

## Inter-federation Trust Anchor Entity Configuration

The Trust Anchor issues its own membership Trust Mark and requires it of every OpenID Provider and Relying Party.

```json
{
  "iss": "https://ta.interfed.example.org",
  "sub": "https://ta.interfed.example.org",
  "iat": 1790000000,
  "exp": 1790086400,
  "jwks": {"keys": ["..."]},
  "metadata": {"federation_entity": {
    "federation_fetch_endpoint": "https://ta.interfed.example.org/fetch",
    "federation_list_endpoint": "https://ta.interfed.example.org/list"}},
  "trust_mark_issuers": {
    "https://ta.interfed.example.org/tm/member": ["https://ta.interfed.example.org"],
    "https://refeds.example.org/tm/sirtfi": ["https://tmi.refeds.example.org"]
  },
  "trust_mark_requirements": {
    "openid_provider": [["https://ta.interfed.example.org/tm/member"]],
    "openid_relying_party": [["https://ta.interfed.example.org/tm/member"]]
  },
  "crit": ["trust_mark_requirements"]
}
```

## Subordinate Statement About the National Federation

The inter-federation additionally requires the SIRTFI-equivalent Trust Mark for Entities reached through this national federation. Its issuer is not the Trust Anchor, so validating it requires trust in that issuer (Section 7.4); this is why it sits in a Subordinate Statement, checked in the Chain Phase, rather than in the Gate Phase.

```json
{
  "iss": "https://ta.interfed.example.org",
  "sub": "https://ta.national.example.org",
  "iat": 1790000000,
  "exp": 1790086400,
  "jwks": {"keys": ["..."]},
  "trust_mark_requirements": {
    "openid_provider": [["https://refeds.example.org/tm/sirtfi"]],
    "openid_relying_party": [["https://refeds.example.org/tm/sirtfi"]]
  },
  "crit": ["trust_mark_requirements"]
}
```

## Leaf Entity Configuration

An opted-in Relying Party of the national federation:

```json
{
  "iss": "https://rp.university.example.org",
  "sub": "https://rp.university.example.org",
  "iat": 1790000000,
  "exp": 1790086400,
  "jwks": {"keys": ["..."]},
  "authority_hints": ["https://ta.national.example.org"],
  "metadata": {"openid_relying_party": {"redirect_uris": ["https://rp.university.example.org/cb"]}},
  "trust_marks": [
    {"trust_mark_type": "https://ta.interfed.example.org/tm/member", "trust_mark": "eyJ..."},
    {"trust_mark_type": "https://refeds.example.org/tm/sirtfi", "trust_mark": "eyJ..."}
  ]
}
```

## Outcomes

The combined requirement for a Relying Party resolved to the inter-federation is: member AND SIRTFI.

| Relying Party holds | To the national Trust Anchor | To the inter-federation Trust Anchor |
| --- | --- | --- |
| member + SIRTFI | Valid | Valid |
| SIRTFI only (not opted in) | Valid | Rejected in the Gate Phase (member missing) |
| member only | Valid | Rejected in the Chain Phase (SIRTFI required by A.2) |
| neither | Valid | Rejected in the Gate Phase |

The national Trust Anchor declares no requirements in this example, so every row is valid there. The same Leaf is admitted or rejected depending on the Trust Anchor its chain ends in.

\[BEGIN OPTIONAL\]

# Comparison with Existing Practice

This non-normative appendix places the mechanism next to how SAML federations and the Italian OpenID Federation profile meet the same need. The difference is where the requirement is enforced.

|  | SAML inter-federation (eduGAIN) | SPID/CIE OpenID Federation profile | This specification |
| --- | --- | --- | --- |
| Where the requirement is stated | Federation policy documents | The technical rules of the profile | `trust_mark_requirements` in the Trust Chain |
| Who enforces it | The operator, when building the metadata aggregate | Each OpenID Provider, before resolving the Relying Party's chain | Every resolver, during Trust Chain validation |
| Membership signal | Inclusion in the aggregate; registration information | Recognizable Trust Mark for the Entity's profile | Required Trust Mark, Gate Phase |
| Category and certification signals | `EntityAttributes` (entity categories, assurance certifications) | Trust Marks per profile | Trust Marks, combined per Entity Type |
| Machine-readable requirement | No | No | Yes |

In SAML, enforcement was centralized: an Entity that did not meet the requirements was absent from the aggregate. OpenID Federation resolves trust bottom-up at each relying party, so that implicit filter no longer exists, and the requirement has to travel with the chain.

The SPID/CIE profile already treats Trust Marks as the first filter of trust and rejects Relying Parties without a recognizable Trust Mark before resolving their chain. This specification turns that profile-specific rule into one any federation can declare.

\[END OPTIONAL\]

# Open Issues

These are left open for working group discussion.

1. **Name.** `trust_mark_requirements` as a top-level Claim, or a new parameter inside `constraints` (Section 6.2 of [@!OpenID.Federation])? A constraint would reuse existing placement rules but cannot appear in the Trust Anchor's Entity Configuration, which the Gate Phase relies on.
2. **Wildcard Entity Type.** Should a reserved member name (for example, `*`) apply a Requirement Expression to every Entity Type, to avoid repeating a baseline?
3. **Negation.** Is there a use case for "MUST NOT hold" (for example, a deprecated category)? It would break monotonic combination (Section 6); 
4. **Mandatory status checks.** Should the expression be able to mark a type as requiring a Trust Mark Status endpoint check (Section 7.4)?

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

* Initial version: `trust_mark_requirements` Claim, Gate and Chain Phases,
  inter-federation opt-in example.
