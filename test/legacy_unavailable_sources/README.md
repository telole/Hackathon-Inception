# Inherited tests with unavailable source modules

These tests were already present on main at 842c1b7, but their imported production files were absent from that commit. They are preserved here with `.dart.disabled` so the runnable suite targets code that actually exists. No assertions were changed to make these pass.

The integrated frontend is covered by the widget, repository-contract, pagination, registration and live Realtime tests in test/. Re-enable an archived test after restoring its original API or porting its assertions to the replacement implementation.

- test\legacy_unavailable_sources\core_workflow_http_test.dart.disabled: missing features/auth/presentation/auth_state_notifier.dart, features/donation/services/donation_editor_service.dart, features/operations/services/workflow_service.dart
- test\legacy_unavailable_sources\features\needs\presentation\needs_notifier_test.dart.disabled: missing features/needs/presentation/needs_notifier.dart
- test\legacy_unavailable_sources\features\logistics\presentation\partner_allocation_notifier_test.dart.disabled: missing features/logistics/presentation/partner_allocation_notifier.dart
- test\legacy_unavailable_sources\features\logistics\presentation\volunteer_task_notifier_test.dart.disabled: missing features/donation/models/donation.dart, features/logistics/presentation/volunteer_task_notifier.dart
- test\legacy_unavailable_sources\features\donation\models\donation_models_test.dart.disabled: missing features/donation/models/donation.dart
- test\legacy_unavailable_sources\features\donation\presentation\donation_notifier_test.dart.disabled: missing features/donation/models/donation.dart, features/donation/presentation/donation_notifier.dart, features/donation/services/donation_service.dart
- test\legacy_unavailable_sources\features\donation\services\donation_service_test.dart.disabled: missing features/donation/services/donation_service.dart
- test\legacy_unavailable_sources\features\disaster\models\disaster_models_test.dart.disabled: missing features/disaster/models/emergency_stock_match.dart, features/disaster/models/incident.dart
- test\legacy_unavailable_sources\features\disaster\presentation\disaster_notifier_test.dart.disabled: missing features/disaster/models/emergency_stock_match.dart, features/disaster/models/incident.dart, features/disaster/presentation/disaster_notifier.dart, features/disaster/services/disaster_service.dart
- test\legacy_unavailable_sources\features\disaster\services\disaster_service_test.dart.disabled: missing features/disaster/services/disaster_service.dart
- test\legacy_unavailable_sources\features\collection_points\models\collection_point_test.dart.disabled: missing features/collection_points/models/collection_point.dart
- test\legacy_unavailable_sources\features\auth\presentation\auth_state_notifier_test.dart.disabled: missing features/auth/presentation/auth_state_notifier.dart

The query group from logistics_service_test.dart is also archived: its fetch* methods are absent from the inherited LogisticsService. The existing RPC command tests remain active. The replacement SupabaseOperationsRepository read paths are covered by operations_contract_test.dart.
