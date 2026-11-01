/// reSandang Pure Backend Architecture Layer
/// Mengacu pada api-contracts.md dan architecture.md
library;

// Core errors, services & models
export 'core/errors/app_failure.dart';
export 'core/errors/error_mapper.dart';
export 'core/services/supabase_client_provider.dart';
export 'core/models/app_role.dart';
export 'core/models/user_access.dart';
export 'core/env.dart';

// Auth domain
export 'features/auth/models/app_profile.dart';
export 'features/auth/models/organization_membership.dart';
export 'features/auth/services/auth_service.dart';
export 'features/auth/data/auth_repository.dart';

// Needs domain
export 'features/needs/models/need.dart';
export 'features/needs/models/need_item_model.dart';
export 'features/needs/services/needs_service.dart';
export 'features/needs/data/needs_repository.dart';

// Donations domain
export 'features/donations/models/donation_model.dart';
export 'features/donations/services/donations_service.dart';
export 'features/donations/data/donations_repository.dart';

// Logistics & Inventory domain
export 'features/logistics/models/logistics_task_model.dart';
export 'features/logistics/models/inventory_batch.dart';
export 'features/logistics/services/logistics_service.dart';

// Admin, Emergency & Tracking domain
export 'features/admin/services/admin_service.dart';
