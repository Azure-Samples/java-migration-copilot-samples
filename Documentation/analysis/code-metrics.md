# Code Metrics

**Analysis Date:** December 2024  
**Method:** Static analysis

## File Count Summary

| Project | Java Files | C# Files | Total |
|---------|-----------|----------|-------|
| mi-sql-public-demo | 1 | 0 | 1 |
| asset-manager | 26 | 0 | 26 |
| todo-web-api | 6 | 0 | 6 |
| rabbitmq-sender | 2 | 0 | 2 |
| jakarta-ee | 9 | 0 | 9 |
| ContosoUniversity | 0 | ~35 | ~35 |
| Malshinon | 0 | ~10 | ~10 |
| **Total** | **45** | **42** | **87** |

## Lines of Code (Estimated)

- **Java:** ~8,000-10,000 LOC
- **C#:** ~7,000-9,000 LOC
- **Total:** ~15,000-19,000 LOC

## Complexity Estimates

### asset-manager
- **Classes:** 26
- **Interfaces:** 3 (StorageService, FileProcessor, +repositories)
- **Complexity:** Medium-High

### ContosoUniversity  
- **Classes:** ~35
- **Controllers:** 7
- **Entities:** 7
- **Complexity:** High (relationships, concurrency)

## Quality Indicators

- **Modern patterns:** Repository, Service Layer, MVC
- **Dependency Injection:** Yes (Spring, limited in ASP.NET MVC)
- **Test Coverage:** Unknown (requires runtime analysis)

**Related:** [Complexity Analysis](complexity-analysis.md), [Technical Debt](../technical-debt/summary.md)
