# Graph Report - GoDelivery-lb-app  (2026-09-20)

## Corpus Check
- 61 files · ~30,417 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 51 file(s) not represented in the graph (top: .xcconfig 8, (none) 7, .xml 7)

## Summary
- 734 nodes · 985 edges · 38 communities (29 shown, 9 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 17 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `54aea1b1`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- Win32Window
- GeneratedPluginRegistrant.swift
- my_application.cc
- orders_screens.dart
- app_router.dart
- admin_dashboard.dart
- api_service.dart
- order.dart
- app_theme.dart
- providers.dart
- create_order_screen.dart
- StatelessWidget
- utils.cpp
- login_screen.dart
- user.dart
- main.dart
- marketplace_screen.dart
- admin_section_screen.dart
- specialized_screens.dart
- backend_contract_models_test.dart
- package:flutter/material.dart
- manifest.json
- payment.dart
- admin_models.dart
- auth_routing_test.dart
- Repository Guidelines
- GoDelivery Flutter → backend API map
- city.dart
- MainActivity.kt
- build
- c_users_yasse_documents_github_godelivery_lb_app_ios_runner_generatedpluginregistrant_h
- String?
- LaunchImage.imageset/README.md

## God Nodes (most connected - your core abstractions)
1. `Win32Window` - 24 edges
2. `OrderProvider` - 18 edges
3. `AuthProvider` - 17 edges
4. `AdminProvider` - 12 edges
5. `MessageHandler` - 12 edges
6. `DriverProvider` - 10 edges
7. `FlutterWindow` - 10 edges
8. `Create` - 10 edges
9. `WndProc` - 10 edges
10. `MerchantProvider` - 9 edges

## Surprising Connections (you probably didn't know these)
- `_login` --references--> `AuthProvider`  [EXTRACTED]
  lib/screens/auth/login_screen.dart → lib/providers/providers.dart
- `_handleCreateOrder` --references--> `OrderProvider`  [EXTRACTED]
  lib/screens/orders/create_order_screen.dart → lib/providers/providers.dart
- `initState` --references--> `OrderProvider`  [EXTRACTED]
  lib/screens/orders/orders_screens.dart → lib/providers/providers.dart
- `_loadOrders` --references--> `OrderProvider`  [EXTRACTED]
  lib/screens/orders/orders_screens.dart → lib/providers/providers.dart
- `_showUpdateStatusDialog` --references--> `OrderProvider`  [EXTRACTED]
  lib/screens/orders/orders_screens.dart → lib/providers/providers.dart

## Import Cycles
- None detected.

## Communities (38 total, 9 thin omitted)

### Community 0 - "Win32Window"
Cohesion: 0.05
Nodes (59): dwmapi, FlutterViewController, generated_plugin_registrant, optional, RECT, unique_ptr, DartProject, HWND (+51 more)

### Community 1 - "GeneratedPluginRegistrant.swift"
Cohesion: 0.05
Nodes (32): Any, Cocoa, connectivity_plus, file_selector_macos, Flutter, FlutterAppDelegate, FlutterImplicitEngineBridge, FlutterImplicitEngineDelegate (+24 more)

### Community 2 - "my_application.cc"
Cohesion: 0.06
Nodes (35): connectivity_plus_windows_plugin, file_selector_plugin, file_selector_windows, FlPluginRegistry, flutter_linux, FlView, GApplication, gboolean (+27 more)

### Community 3 - "orders_screens.dart"
Cohesion: 0.06
Nodes (33): class, build, _buildCustomerCard, _buildEmptyState, _buildErrorState, _buildExpressBadge, _buildInfoLine, _buildInfoRow (+25 more)

### Community 4 - "app_router.dart"
Cohesion: 0.10
Nodes (19): adminHomePath, AppRouter, authLoadingPath, build, _canAccess, driverHomePath, homeForUser, merchantHomePath (+11 more)

### Community 5 - "admin_dashboard.dart"
Cohesion: 0.05
Nodes (41): build, _buildDrawer, _buildEmptyOrders, _buildErrorState, _buildHeader, _buildQuickActions, _buildRecentOrders, _buildStatistics (+33 more)

### Community 6 - "api_service.dart"
Cohesion: 0.05
Nodes (41): ApiService, baseUrl, createOrder, _dateOnly, _decodeBody, _errorMessage, getAnalytics, getCities (+33 more)

### Community 7 - "order.dart"
Cohesion: 0.07
Nodes (28): double get, city, createdAt, customerFirstName, customerLastName, customerPhone, deliveryCharge, district (+20 more)

### Community 8 - "app_theme.dart"
Cohesion: 0.07
Nodes (27): accentColor, AppTheme, backgroundColor, cardColor, dividerColor, errorColor, infoColor, primaryColor (+19 more)

### Community 9 - "providers.dart"
Cohesion: 0.04
Nodes (45): AnalyticsOverview? get, AuthStatus get, FinanceOverview? get, _analytics, AuthStatus, _balance, _collections, createOrder (+37 more)

### Community 10 - "create_order_screen.dart"
Cohesion: 0.07
Nodes (29): build, _buildSectionTitle, _cities, createState, _deliveryChargeController, dispose, _districts, _firstNameController (+21 more)

### Community 11 - "StatelessWidget"
Cohesion: 0.15
Nodes (13): AuthLoadingScreen, ErrorScreen, ForgotPasswordScreen, OnboardingScreen, RegisterScreen, _ActionCard, _DrawerItem, _OrderTile (+5 more)

### Community 12 - "utils.cpp"
Cohesion: 0.12
Nodes (19): dart_project, flutter_view_controller, flutter_windows, functional, _In_, _In_opt_, io, iostream (+11 more)

### Community 13 - "login_screen.dart"
Cohesion: 0.18
Nodes (10): Color, FormState, createState, dispose, _formKey, _login, _obscurePassword, _passwordController (+2 more)

### Community 14 - "user.dart"
Cohesion: 0.08
Nodes (24): bool get, double?, accountType, deliveryCharges, deliveryFee, email, firstName, fromJson (+16 more)

### Community 15 - "main.dart"
Cohesion: 0.17
Nodes (11): core/routing/app_router.dart, ../core/theme/app_theme.dart, authProvider, build, initFlutter, main, MyApp, restoreSession (+3 more)

### Community 16 - "marketplace_screen.dart"
Cohesion: 0.12
Nodes (16): IconData, build, _Category, icon, MarketplaceScreen, name, onSeeAll, price (+8 more)

### Community 17 - "admin_section_screen.dart"
Cohesion: 0.11
Nodes (18): AdminSection, _analytics, _balanceSection, build, createState, _drivers, _finance, initState (+10 more)

### Community 18 - "specialized_screens.dart"
Cohesion: 0.06
Nodes (58): ChangeNotifier, AdminProvider, AuthProvider, DriverProvider, MerchantProvider, OrderProvider, AdminDashboard, _AdminDashboardState (+50 more)

### Community 19 - "backend_contract_models_test.dart"
Cohesion: 0.33
Nodes (5): package:flutter_test/flutter_test.dart, package:godelivery_lb_app/models/admin_models.dart, package:godelivery_lb_app/models/district.dart, package:godelivery_lb_app/models/order.dart, main

### Community 21 - "package:flutter/material.dart"
Cohesion: 0.29
Nodes (5): build, DriverDashboard, build, MerchantDashboard, package:flutter/material.dart

### Community 22 - "manifest.json"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 23 - "payment.dart"
Cohesion: 0.08
Nodes (23): DateTime, amount, createdAt, deliveryFee, DriverCollection, driverId, driverName, fromJson (+15 more)

### Community 24 - "admin_models.dart"
Cohesion: 0.06
Nodes (30): city.dart, accountType, activeDrivers, AnalyticsOverview, balance, driver, drivers, DriverSummary (+22 more)

### Community 25 - "auth_routing_test.dart"
Cohesion: 0.20
Nodes (9): dart:convert, dart:ui, package:godelivery_lb_app/core/routing/app_router.dart, package:godelivery_lb_app/main.dart, package:godelivery_lb_app/providers/providers.dart, package:shared_preferences/shared_preferences.dart, main, restoreUser (+1 more)

### Community 26 - "Repository Guidelines"
Cohesion: 0.25
Nodes (7): Build, Test, and Development Commands, Coding Style & Naming Conventions, Commit & Pull Request Guidelines, Project Structure & Module Organization, Repository Guidelines, Security & Configuration, Testing Guidelines

### Community 27 - "GoDelivery Flutter → backend API map"
Cohesion: 0.50
Nodes (3): Authorization and current backend gaps, Compact order status contract, GoDelivery Flutter → backend API map

### Community 28 - "city.dart"
Cohesion: 0.29
Nodes (6): City, districtId, fromJson, id, nameAr, nameEn

### Community 30 - "build"
Cohesion: 0.50
Nodes (4): build, Route /, Route /forgot-password, Route /register

## Knowledge Gaps
- **385 isolated node(s):** `AppRouter`, `authLoadingPath`, `adminHomePath`, `driverHomePath`, `merchantHomePath` (+380 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 487 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **9 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Win32Window` connect `Win32Window` to `utils.cpp`?**
  _High betweenness centrality (0.098) - this node is a cross-community bridge._
- **Why does `AuthProvider` connect `specialized_screens.dart` to `admin_dashboard.dart`, `providers.dart`, `create_order_screen.dart`, `login_screen.dart`, `main.dart`?**
  _High betweenness centrality (0.036) - this node is a cross-community bridge._
- **Why does `Order` connect `order.dart` to `providers.dart`, `admin_dashboard.dart`?**
  _High betweenness centrality (0.034) - this node is a cross-community bridge._
- **What connects `AppRouter`, `authLoadingPath`, `adminHomePath` to the rest of the system?**
  _385 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Win32Window` be split into smaller, more focused modules?**
  _Cohesion score 0.05407925407925408 - nodes in this community are weakly interconnected._
- **Should `GeneratedPluginRegistrant.swift` be split into smaller, more focused modules?**
  _Cohesion score 0.05217391304347826 - nodes in this community are weakly interconnected._
- **Should `my_application.cc` be split into smaller, more focused modules?**
  _Cohesion score 0.056910569105691054 - nodes in this community are weakly interconnected._