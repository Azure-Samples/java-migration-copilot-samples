# Complexity Analysis

**Analysis Date:** December 2024

## Project Complexity Rankings

| Project | Complexity | Factors |
|---------|------------|---------|
| ContosoUniversity | HIGH | Complex relationships, concurrency, legacy platform |
| asset-manager | MEDIUM-HIGH | Multi-module, async messaging, cloud integration |
| jakarta-ee | HIGH | Hybrid architecture, legacy build |
| todo-web-api | LOW | Simple CRUD, clean design |
| mi-sql-public-demo | LOW | Single class, simple demo |
| Malshinon | MEDIUM | Factory pattern, data processing |

## Cyclomatic Complexity (Estimated)

### Controllers
- **ContosoUniversity Controllers:** Medium (8-15 per method)
- **asset-manager Controllers:** Low-Medium (5-10 per method)
- **todo-web-api Controllers:** Low (3-6 per method)

### Service Layer
- **Business Logic Methods:** Medium (6-12)
- **Data Access Methods:** Low (2-5)

## Maintainability Index

- **High (80-100):** todo-web-api, mi-sql-public-demo
- **Medium (50-79):** asset-manager, Malshinon
- **Low (<50):** jakarta-ee (hybrid architecture), ContosoUniversity (legacy platform)

## Recommendations

1. Refactor high-complexity methods
2. Add unit tests for complex logic
3. Simplify jakarta-ee hybrid architecture
4. Implement repository pattern in ContosoUniversity

**Related:** [Code Metrics](code-metrics.md), [Maintenance Burden](../technical-debt/maintenance-burden.md)
