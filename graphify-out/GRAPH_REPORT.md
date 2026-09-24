# Graph Report - GoDelivery-lb-app  (2026-09-24)

## Corpus Check
- 113 files · ~68,698 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 51 file(s) not represented in the graph (top: .xcconfig 8, (none) 7, .xml 7)

## Summary
- 1562 nodes · 1967 edges · 90 communities (77 shown, 13 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 26 edges (avg confidence: 0.88)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `c82c36e4`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Win32Window
- providers.dart
- api_service.dart
- admin_dashboard.dart
- app_tokens.dart
- admin_models.dart
- orders_screens.dart
- create_order_screen.dart
- GeneratedPluginRegistrant.swift
- my_application.cc
- app_theme.dart
- responsive_layout_test.dart
- specialized_screens.dart
- app_components.dart
- StatelessWidget
- marketplace_screen.dart
- app_router.dart
- order.dart
- finance.dart
- login_screen.dart
- user.dart
- app_shell.dart
- Native Platform Interoperability
- payment.dart
- collection.dart
- main.dart
- manifest.json
- flutter-debugging/SKILL.md
- State
- List
- Repository Guidelines
- build
- city.dart
- dart-collect-coverage/SKILL.md
- package:flutter/material.dart
- OrderProvider
- MerchantProvider
- DriverProvider
- GoDelivery Flutter → backend API map
- MainActivity.kt
- Modern Dart Syntax (Dart 3.0 - 3.12+)
- GoDeliveryContext
- c_users_bilal_github_godelivery_lb_app_ios_runner_generatedpluginregistrant_h
- ApiException
- LaunchImage.imageset/README.md
- Implementing Routing and Deep Linking
- flutter-add-widget-preview/SKILL.md
- String?
- flutter-apply-architecture-best-practices/SKILL.md
- flutter-setup-localization/SKILL.md
- flutter-add-widget-test/SKILL.md
- flutter-add-integration-test/SKILL.md
- flutter-implement-json-serialization/SKILL.md
- main
- flutter-fix-layout-issues/SKILL.md
- Dart Testing Suite
- Building Dart CLI Applications
- dart-migrate-to-checks-package/SKILL.md
- Flutter Web with WebAssembly (Wasm-GC)
- utils.cpp
- Resolving Package Conflicts
- dart-use-pattern-matching/SKILL.md
- flutter-ui/SKILL.md
- flutter-config/SKILL.md
- string
- Changelog Writing & Auditing
- dart-fix-runtime-errors/SKILL.md
- flutter-build-responsive-layout/SKILL.md
- flutter-dio/SKILL.md
- flutter-testing/SKILL.md
- github-actions/SKILL.md
- dart-generate-test-mocks/SKILL.md
- dart-run-static-analysis/SKILL.md
- flutter-bloc-forms/SKILL.md
- flutter-firebase/SKILL.md
- AI Engineering with Genkit Dart
- flutter-isar/SKILL.md
- flutter-use-http-package/SKILL.md
- flutter-bloc/SKILL.md
- Automated Git Commits
- Algorithms & Logic
- Memory Management
- Execution Targets
- flutter-security/SKILL.md
- flutter-code-gen/SKILL.md
- c_users_yasse_documents_github_godelivery_lb_app_ios_runner_generatedpluginregistrant_h

## God Nodes (most connected - your core abstractions)
1. `AuthProvider` - 28 edges
2. `Win32Window` - 24 edges
3. `OrderProvider` - 13 edges
4. `MessageHandler` - 12 edges
5. `AdminProvider` - 11 edges
6. `main()` - 11 edges
7. `FlutterWindow` - 10 edges
8. `Create` - 10 edges
9. `WndProc` - 10 edges
10. `MessageHandler` - 9 edges

## Surprising Connections (you probably didn't know these)
- `Read Git History` --references--> `main()`  [INFERRED]
  .agents/skills/changelog-writing/SKILL.md → linux/runner/main.cc
- `2. Branching` --references--> `main()`  [INFERRED]
  .agents/skills/git-commit/SKILL.md → linux/runner/main.cc
- `PR Requirements` --references--> `main()`  [INFERRED]
  .agents/skills/github-actions/SKILL.md → linux/runner/main.cc
- `Project Setup & Architecture` --references--> `main()`  [INFERRED]
  .agents/skills/dart-build-cli-app/SKILL.md → linux/runner/main.cc
- `Workflow: Generating Mocks and Validating Tests` --references--> `main()`  [INFERRED]
  .agents/skills/dart-generate-test-mocks/SKILL.md → linux/runner/main.cc

## Import Cycles
- None detected.

## Communities (90 total, 13 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.05
Nodes (59): dwmapi, FlutterViewController, generated_plugin_registrant, optional, RECT, unique_ptr, DartProject, HWND (+51 more)

### Community 1 - "providers.dart"
Cohesion: 0.04
Nodes (49): AnalyticsOverview? get, AuthStatus get, DriverBalance? get, FinanceOverview? get, _analytics, AuthStatus, _balance, _balanceError (+41 more)

### Community 2 - "api_service.dart"
Cohesion: 0.04
Nodes (51): int?, ApiService, baseUrl, createOrder, _dateOnly, _decodeBody, _errorMessage, getAnalytics (+43 more)

### Community 3 - "admin_dashboard.dart"
Cohesion: 0.04
Nodes (51): int get, activeDrivers, cancelled, collected, color, count, createState, DashboardInsights (+43 more)

### Community 4 - "app_tokens.dart"
Cohesion: 0.04
Nodes (50): ColorScheme get, amber, AppBreakpoints, AppColors, AppRadius, AppShadows, AppSpacing, blue (+42 more)

### Community 5 - "admin_models.dart"
Cohesion: 0.09
Nodes (22): accountType, activeDrivers, AnalyticsOverview, balance, driver, drivers, DriverSummary, FinanceOverview (+14 more)

### Community 6 - "orders_screens.dart"
Cohesion: 0.06
Nodes (35): ConfirmDeliveredDialog, controller, createState, CustomerDetailCard, DesktopOrderRow, dispose, ExpressBadge, _filtered (+27 more)

### Community 7 - "create_order_screen.dart"
Cohesion: 0.04
Nodes (46): amountValidator, build, child, _cities, createState, CustomerFormSection, _deliveryChargeController, DeliveryOptionsSection (+38 more)

### Community 8 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (32): Any, Cocoa, connectivity_plus, file_selector_macos, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate (+24 more)

### Community 9 - "my_application.cc"
Cohesion: 0.06
Nodes (33): connectivity_plus_windows_plugin, file_selector_plugin, file_selector_windows, FlPluginRegistry, flutter_linux, FlView, GApplication, gboolean (+25 more)

### Community 10 - "app_theme.dart"
Cohesion: 0.06
Nodes (31): app_tokens.dart, accentColor, AppTheme, backgroundColor, cardColor, darkTheme, dividerColor, errorColor (+23 more)

### Community 11 - "responsive_layout_test.dart"
Cohesion: 0.06
Nodes (39): dart:async, dart:convert, dart:ui, GridView, DriverCollectionPage, package:flutter_test/flutter_test.dart, package:godelivery_lb_app/core/routing/app_router.dart, package:godelivery_lb_app/core/theme/app_theme.dart (+31 more)

### Community 12 - "specialized_screens.dart"
Cohesion: 0.05
Nodes (37): AccountPlanBadge, accountType, balance, balanceError, collection, CollectionCard, collections, CollectionsList (+29 more)

### Community 13 - "app_components.dart"
Cohesion: 0.04
Nodes (45): EdgeInsetsGeometry?, action, actions, AppContent, AppEmptyState, AppErrorState, AppInfoRow, AppLoadingState (+37 more)

### Community 14 - "StatelessWidget"
Cohesion: 0.05
Nodes (51): AccountAvatar, AccountTypeBadge, AdminAnalyticsPage, AdminDriversPage, AdminFinancePage, AdminLocationsPage, AdminPeoplePage, AdminPersonCard (+43 more)

### Community 15 - "marketplace_screen.dart"
Cohesion: 0.06
Nodes (31): Color?, build, category, CategoryCard, color, compact, FeaturedStores, HeroMiniBadge (+23 more)

### Community 16 - "app_router.dart"
Cohesion: 0.06
Nodes (30): actionLabel, adminHomePath, AppRouter, authLoadingPath, AuthLoadingScreen, build, _canAccess, driverHomePath (+22 more)

### Community 17 - "order.dart"
Cohesion: 0.07
Nodes (28): double get, city, createdAt, customerFirstName, customerLastName, customerPhone, deliveryCharge, district (+20 more)

### Community 18 - "finance.dart"
Cohesion: 0.07
Nodes (28): accountType, balance, createdAt, deliveryCharge, DriverBalance, entitled, feeTotal, firstName (+20 more)

### Community 19 - "login_screen.dart"
Cohesion: 0.07
Nodes (29): FormState, GlobalKey, BrandOrb, build, createState, dispose, _formKey, icon (+21 more)

### Community 20 - "user.dart"
Cohesion: 0.08
Nodes (25): bool get, double?, accountType, deliveryCharges, deliveryFee, email, firstName, fromJson (+17 more)

### Community 21 - "app_shell.dart"
Cohesion: 0.06
Nodes (37): godelivery_logo.dart, IconData, AuthProvider, DashboardContent, _login, build, OrdersHeader, build (+29 more)

### Community 22 - "Native Platform Interoperability"
Cohesion: 0.08
Nodes (22): 1. MethodChannels (One-shot), 2. EventChannels (Streams), 3. Type Safety with Pigeon, 4. Platform-Specific Directory Structure, 5. Swift Package Manager (SPM) Defaults, 6. Platform View Overhaul, 7. Federated Plugins, Dart Standard (+14 more)

### Community 23 - "payment.dart"
Cohesion: 0.11
Nodes (18): finance.dart, admin, amount, createdAt, data, fromJson, id, isAdvance (+10 more)

### Community 24 - "collection.dart"
Cohesion: 0.11
Nodes (17): DateTime, admin, amount, createdAt, data, deliveryFee, DriverCollection, driverId (+9 more)

### Community 25 - "main.dart"
Cohesion: 0.12
Nodes (16): ../admin/admin_dashboard.dart, core/routing/app_router.dart, core/theme/app_theme.dart, authProvider, build, initFlutter, main, MyApp (+8 more)

### Community 26 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 27 - "flutter-debugging/SKILL.md"
Cohesion: 0.09
Nodes (21): Automated Resolution Workflow, Debugging Strategies, Error Boundaries, Flutter DevTools, Logging, Memory Management, Null Safety Error Patterns, Performance Profiling (+13 more)

### Community 28 - "State"
Cohesion: 0.23
Nodes (12): AdminSectionScreen, _AdminSectionScreenState, OrderDetailScreen, _OrderDetailScreenState, OrdersScreen, _OrdersScreenState, DriverCollectionsScreen, _DriverCollectionsScreenState (+4 more)

### Community 29 - "List"
Cohesion: 0.22
Nodes (8): city.dart, cities, District, fromJson, id, nameAr, nameEn, List

### Community 30 - "Repository Guidelines"
Cohesion: 0.25
Nodes (7): Build, Test, and Development Commands, Coding Style & Naming Conventions, Commit & Pull Request Guidelines, Project Structure & Module Organization, Repository Guidelines, Security & Configuration, Testing Guidelines

### Community 31 - "build"
Cohesion: 0.67
Nodes (3): build, Route /home/admin/drivers, Route /home/orders

### Community 32 - "city.dart"
Cohesion: 0.29
Nodes (6): City, districtId, fromJson, id, nameAr, nameEn

### Community 33 - "dart-collect-coverage/SKILL.md"
Cohesion: 0.10
Nodes (20): 1. Run Tests with VM Service, 2. Collect Raw Coverage, 3. Format to LCOV, Automated Collection, CI Integration, Contents, Coverage Ignore Directives, Coverage Targets (from AGENTS.md) (+12 more)

### Community 34 - "package:flutter/material.dart"
Cohesion: 0.15
Nodes (11): ../core/theme/app_tokens.dart, build, DriverDashboard, build, MerchantDashboard, build, GoDeliveryLogo, height (+3 more)

### Community 35 - "OrderProvider"
Cohesion: 0.20
Nodes (12): AdminProvider, OrderProvider, AdminDashboard, _AdminDashboardState, _refresh, _load, CreateOrderScreen, _CreateOrderScreenState (+4 more)

### Community 36 - "MerchantProvider"
Cohesion: 0.40
Nodes (5): ChangeNotifier, MerchantProvider, initState, MerchantBalanceScreen, _MerchantBalanceScreenState

### Community 37 - "DriverProvider"
Cohesion: 0.40
Nodes (5): DriverProvider, _changeStatus, DriverOrdersScreen, _DriverOrdersScreenState, _load

### Community 38 - "GoDelivery Flutter → backend API map"
Cohesion: 0.50
Nodes (3): Authorization and current backend gaps, Compact order status contract, GoDelivery Flutter → backend API map

### Community 40 - "Modern Dart Syntax (Dart 3.0 - 3.12+)"
Cohesion: 0.10
Nodes (18): Contents, Extension Types, Modern Dart Syntax (Dart 3.0 - 3.12+), Primary Constructors, Private Named Parameters, Records and Pattern Matching, Rules & Patterns, Syntactic Best Practices (+10 more)

### Community 48 - "Implementing Routing and Deep Linking"
Cohesion: 0.11
Nodes (17): 1. Scaffold the Application, 2. Configure the Router, Contents, Core Concepts, Examples, High-Fidelity Shell Widget Implementation, If configuring for Android:, If configuring for iOS: (+9 more)

### Community 49 - "flutter-add-widget-preview/SKILL.md"
Cohesion: 0.12
Nodes (16): Basic Preview, Command Line, Contents, Custom Annotations, Examples, Extending Preview, Feedback Loop, Handling Limitations (+8 more)

### Community 52 - "flutter-apply-architecture-best-practices/SKILL.md"
Cohesion: 0.12
Nodes (16): Clean Architecture, Coding Guidelines & Maintenance, Dart 3 Language Features, Data Flow, Data Model Rules, Directory Structure, Documentation, Error Handling (+8 more)

### Community 53 - "flutter-setup-localization/SKILL.md"
Cohesion: 0.12
Nodes (16): 1. Add Dependencies, 1. Simple Placeholders, 2. Enable Code Generation, 2. Plurals, 3. Create Configuration File, 3. Selection, 4. Configure Application Entry Point, ARB File Structure and Rules (+8 more)

### Community 54 - "flutter-add-widget-test/SKILL.md"
Cohesion: 0.12
Nodes (15): Common Pitfalls, Contents, Core APIs, Enter Text and Validate Form, Examples, Finder Patterns, Interaction Patterns, Minimal Widget Test (+7 more)

### Community 55 - "flutter-add-integration-test/SKILL.md"
Cohesion: 0.13
Nodes (14): CI/CD Integration, Common Pitfalls, Contents, Examples, GitHub Actions Workflow, Multi-Screen Navigation Flow, Performance Profiling, Performance Profiling Driver (+6 more)

### Community 56 - "flutter-implement-json-serialization/SKILL.md"
Cohesion: 0.13
Nodes (14): Background Parsing, Contents, Core Guidelines, Dart 3 Pattern Matching in fromJson, Examples, List Parsing with Type Safety, Manual vs Code-Gen Decision, Nested Objects (+6 more)

### Community 57 - "main"
Cohesion: 0.15
Nodes (11): Project Setup & Architecture, Workflow: Generating Mocks and Validating Tests, 1. Preparation, 2. PR Quality & Metadata, 3. Generate PR Description, 3. Generate PR Title, 4. Labeling & Assignment, 5. Execution (+3 more)

### Community 58 - "flutter-fix-layout-issues/SKILL.md"
Cohesion: 0.14
Nodes (13): Constraint Model, Contents, Decision Tree, Error Signature Catalog, Examples, Expanded vs Flexible vs SizedBox, Fixing ParentData Misuse, Fixing RenderFlex Overflow (Text in Row) (+5 more)

### Community 59 - "Dart Testing Suite"
Cohesion: 0.15
Nodes (12): Contents, Dart Testing Suite, Mocking Dependencies, mockito Setup (Code-Gen), mocktail Setup (Recommended), mocktail vs mockito Decision, Registering Fallback Values, Task Progress (+4 more)

### Community 60 - "Building Dart CLI Applications"
Cohesion: 0.15
Nodes (12): Argument Parsing & Command Routing, Building Dart CLI Applications, Compilation & Distribution, Contents, Example: CommandRunner Implementation, Example: Integration Testing with Subprocesses, Examples, Execution & Error Handling (+4 more)

### Community 61 - "dart-migrate-to-checks-package/SKILL.md"
Cohesion: 0.15
Nodes (12): 1. Futures, 2. Streams, Advanced Asynchronous Assertions, Assertion Mapping and Syntax Guidelines, Chaining Multiple Checks, Contents, Dependency Management, Examples (+4 more)

### Community 62 - "Flutter Web with WebAssembly (Wasm-GC)"
Cohesion: 0.15
Nodes (12): 1. No `dart:io`, 2. Isolate/Threading limitations, 3. Font and Asset Loading, Compilation & Deployment, Contents, Debugging WebAssembly, Example: Invoking a JS API, Flutter Web with WebAssembly (Wasm-GC) (+4 more)

### Community 63 - "utils.cpp"
Cohesion: 0.19
Nodes (12): flutter_windows, _In_, _In_opt_, io, iostream, stdio, wWinMain(), string (+4 more)

### Community 64 - "Resolving Package Conflicts"
Cohesion: 0.17
Nodes (11): Contents, Dart Tooling & Package Workflows, Git LFS Support, Migrating Tests to package:checks, Resolving Package Conflicts, Static Analysis Resolution, Surgical Lockfile Removal, Temporary Overrides (Last Resort) (+3 more)

### Community 65 - "dart-use-pattern-matching/SKILL.md"
Cohesion: 0.17
Nodes (11): Contents, Core Pattern Syntaxes, Examples, Exhaustive Sealed Class Matching, JSON Validation and Parsing, Pattern Selection Strategy, Record Destructuring and Swapping, Switch Expressions (+3 more)

### Community 66 - "flutter-ui/SKILL.md"
Cohesion: 0.17
Nodes (11): 1. Performance & Rendering, 2. Design Tokens (Theming), 3. Reusable Components, 4. Widget & Interaction Patterns, 5. Adaptive & Responsive Design and Common Fixes, 6. Responsive Layout Patterns, 7. UI States & Accessibility, Adaptive Layout Pattern (+3 more)

### Community 67 - "flutter-config/SKILL.md"
Cohesion: 0.18
Nodes (10): Android, Build Commands, Config JSON Structure, Entry Point Pattern, Environment Configuration, Firebase Per-Flavor, Flavor Architecture, iOS (+2 more)

### Community 68 - "string"
Cohesion: 0.27
Nodes (7): dart_project, flutter_view_controller, functional, memory, string, vector, windows

### Community 69 - "Changelog Writing & Auditing"
Cohesion: 0.20
Nodes (9): Bad Entry (Raw commit dump / AI-jargon), Changelog Writing & Auditing, Checklist, Core Rules, Examples, Good Entry (Keep a Changelog standard), Read Git History, Standard Categories (+1 more)

### Community 70 - "dart-fix-runtime-errors/SKILL.md"
Cohesion: 0.20
Nodes (9): Contents, Correcting Dynamic List Assignments, Error and Exception Handling, Examples, Method Overrides and Covariants, Null Safety and Variable Initialization, Safely Managing Late Initializations, Type System and Soundness (+1 more)

### Community 71 - "flutter-build-responsive-layout/SKILL.md"
Cohesion: 0.20
Nodes (9): Adaptive Layout with Breakpoints, Constraining Width on Wide Screens, Contents, Device and Orientation Behaviors, Examples, Space Measurement Guidelines, Widget Sizing and Constraints, Workflow: Constructing an Adaptive Layout (+1 more)

### Community 72 - "flutter-dio/SKILL.md"
Cohesion: 0.20
Nodes (9): Alternative: http Package, Basic http Patterns, Dio Interceptors, Dio vs http, Networking with Dio, Performance, Repository Pattern, Retry & Resilience (+1 more)

### Community 73 - "flutter-testing/SKILL.md"
Cohesion: 0.20
Nodes (9): Common Test Errors, Golden Variant Testing, Interaction Contract Testing, Pattern-Based Testing, Running Tests (Quick Reference), State Matrix Testing, Test Naming & Structure, Test Types Overview (+1 more)

### Community 74 - "github-actions/SKILL.md"
Cohesion: 0.20
Nodes (9): Caching Strategy, Code Signing, GitHub Actions Pipeline, PR Requirements, Release Checklist, Stage 1: Quality Gate, Stage 2: Build, Stage 3: Deploy (on main merge only) (+1 more)

### Community 75 - "dart-generate-test-mocks/SKILL.md"
Cohesion: 0.22
Nodes (8): Complete Mocked Test Suit (Mockito), Contents, Examples, Generating Mock Files, Managing Dev Dependencies, Mock Framework Selection, Structuring Code for Testability, Stubbing and Verification Best Practices

### Community 76 - "dart-run-static-analysis/SKILL.md"
Cohesion: 0.22
Nodes (8): Analysis Configuration, Comprehensive `analysis_options.yaml` Template, Contents, Diagnostic Suppression Rules, Examples, Inline Suppression Techniques, Workflow: Applying Automated Code Fixes, Workflow: Running Static Analysis

### Community 77 - "flutter-bloc-forms/SKILL.md"
Cohesion: 0.22
Nodes (8): Common Form Patterns, Controller Lifecycle, Form Architecture with BLoC, Form Events, Form State, Form Submission, Input Widgets, Validation Patterns

### Community 78 - "flutter-firebase/SKILL.md"
Cohesion: 0.22
Nodes (8): Analytics, Authentication, Crashlytics, Firebase Setup, Firestore, Push Notifications (FCM), Remote Config, Security Rules

### Community 79 - "AI Engineering with Genkit Dart"
Cohesion: 0.25
Nodes (7): AI Engineering with Genkit Dart, Best Practices, Contents, Creating Custom Tools, Defining Prompts & Models, Orchestrating Flows, Project Setup

### Community 80 - "flutter-isar/SKILL.md"
Cohesion: 0.25
Nodes (7): Isar Database, Migrations, Offline-First Patterns, Reactive Queries, Repository Pattern for Local Data, Schema Design, Secure Storage

### Community 81 - "flutter-use-http-package/SKILL.md"
Cohesion: 0.25
Nodes (7): Background Parsing, Complete Network Client and Isolate Parser, Configuration and Permissions, Contents, Examples, Request Execution and Response Handling, Workflow: Executing Network Operations

### Community 82 - "flutter-bloc/SKILL.md"
Cohesion: 0.29
Nodes (6): BLoC Pattern, BLoC Widget Usage, Dependency Injection, Navigation & Routing, Task Progress, Workflow: Implementing State Management

### Community 83 - "Automated Git Commits"
Cohesion: 0.29
Nodes (6): 1. Analyze Changes, 2. Branching, 3. Atomic Commits, 3. Generate Commit Message, 4. Execution Flow, Automated Git Commits

### Community 84 - "Algorithms & Logic"
Cohesion: 0.33
Nodes (5): Algorithms & Logic, Business Logic Organization, Complexity Analysis, Logic Patterns, Search & Sort

### Community 85 - "Memory Management"
Cohesion: 0.33
Nodes (5): Garbage Collection (GC) Pressure, Large Data Handling, Memory Management, Mobile Specifics, Resource Lifecycle

### Community 86 - "Execution Targets"
Cohesion: 0.40
Nodes (5): Chrome (Web), Execution Targets, Firebase Test Lab (Android), Headless Web, Local Device (Android/iOS)

## Knowledge Gaps
- **927 isolated node(s):** `AppRouter`, `authLoadingPath`, `adminHomePath`, `driverHomePath`, `merchantHomePath` (+922 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 1060 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `main()` connect `main` to `Changelog Writing & Auditing`, `my_application.cc`, `github-actions/SKILL.md`, `Automated Git Commits`, `flutter-add-integration-test/SKILL.md`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **Why does `my_application_new()` connect `my_application.cc` to `main`?**
  _High betweenness centrality (0.070) - this node is a cross-community bridge._
- **Why does `Win32Window` connect `Win32Window` to `string`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **What connects `AppRouter`, `authLoadingPath`, `adminHomePath` to the rest of the system?**
  _927 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05407925407925408 - nodes in this community are weakly interconnected._
- **Should `providers.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `api_service.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._