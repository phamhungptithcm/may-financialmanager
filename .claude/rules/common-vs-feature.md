# Common vs Feature-Specific Architecture Policy

All implementation MUST follow the Foundation-First
and Reuse-First principles.

## Component Classification

Every new component, service, utility, or abstraction
must be classified before implementation:

1. GLOBAL SHARED
   Reusable across unrelated features.

2. SHARED DOMAIN
   Reusable across features within the same domain.

3. FEATURE-SPECIFIC
   Owned by one feature and containing its business logic.

## Mandatory Rules

- Search existing implementations before creating new ones.
- Reuse shared components whenever appropriate.
- Never duplicate generic UI primitives or infrastructure.
- All UI must use the centralized design system.
- Never hardcode colors, typography, spacing, or animations.
- Keep domain-specific logic out of generic components.
- Feature-specific modules must not depend on each other's internals.
- Shared modules must never import feature-specific implementations.
- Prefer composition over inheritance.
- Avoid premature abstractions and overengineering.
- Promote components to shared only when genuine reuse exists.
- Changes to shared components must not break existing consumers.
- Shared components require appropriate automated tests.
- Any architectural exception must be documented.

## Before Writing Code

1. Identify the responsibility of the new implementation.
2. Search for existing reusable implementations.
3. Classify it as GLOBAL, SHARED DOMAIN, or FEATURE.
4. Verify dependency boundaries.
5. Reuse existing design tokens and contracts.
6. Implement and test.
7. Check for duplication and architectural drift.

## Inventory Reference

See [docs/architecture/COMMON_COMPONENT_INVENTORY.md](../../docs/architecture/COMMON_COMPONENT_INVENTORY.md) for the current shared component inventory.
