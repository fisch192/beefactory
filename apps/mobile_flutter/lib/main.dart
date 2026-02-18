import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/connectivity_service.dart';
import 'data/local/database.dart';
import 'data/local/daos/sites_dao.dart';
import 'data/local/daos/hives_dao.dart';
import 'data/local/daos/events_dao.dart';
import 'data/local/daos/tasks_dao.dart';
import 'data/remote/api_client.dart';
import 'data/remote/auth_api.dart';
import 'data/remote/community_api.dart';
import 'data/remote/sites_api.dart';
import 'data/remote/hives_api.dart';
import 'data/remote/events_api.dart';
import 'data/remote/tasks_api.dart';
import 'data/sync/sync_engine.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/site_repository.dart';
import 'domain/repositories/hive_repository.dart';
import 'presentation/app.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/community_provider.dart';
import 'presentation/providers/sites_provider.dart';
import 'presentation/providers/sync_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core services
  final prefs = await SharedPreferences.getInstance();
  final database = AppDatabase();
  final connectivity = ConnectivityService();
  await connectivity.initialize();

  // DAOs
  final sitesDao = SitesDao(database);
  final hivesDao = HivesDao(database);
  final eventsDao = EventsDao(database);
  final tasksDao = TasksDao(database);

  // API layer
  final apiClient = ApiClient(prefs: prefs);
  final authApi = AuthApi(apiClient);
  final sitesApi = SitesApi(apiClient);
  final hivesApi = HivesApi(apiClient);
  final eventsApi = EventsApi(apiClient);
  final tasksApi = TasksApi(apiClient);
  final communityApi = CommunityApi(apiClient);

  // Repositories
  final authRepository = AuthRepositoryImpl(
    authApi: authApi,
    apiClient: apiClient,
    prefs: prefs,
  );
  final siteRepository = SiteRepositoryImpl(
    sitesDao: sitesDao,
    hivesDao: hivesDao,
  );
  final hiveRepository = HiveRepositoryImpl(hivesDao: hivesDao);

  // Sync engine
  final syncEngine = SyncEngine(
    sitesDao: sitesDao,
    hivesDao: hivesDao,
    eventsDao: eventsDao,
    tasksDao: tasksDao,
    sitesApi: sitesApi,
    hivesApi: hivesApi,
    eventsApi: eventsApi,
    tasksApi: tasksApi,
    connectivity: connectivity,
    prefs: prefs,
  );

  runApp(
    MultiProvider(
      providers: [
        // Database and DAOs
        Provider<AppDatabase>.value(value: database),
        Provider<SitesDao>.value(value: sitesDao),
        Provider<HivesDao>.value(value: hivesDao),
        Provider<EventsDao>.value(value: eventsDao),
        Provider<TasksDao>.value(value: tasksDao),

        // API clients
        Provider<ApiClient>.value(value: apiClient),
        Provider<EventsApi>.value(value: eventsApi),
        Provider<TasksApi>.value(value: tasksApi),
        Provider<CommunityApi>.value(value: communityApi),

        // Repositories
        Provider<AuthRepository>.value(value: authRepository),
        Provider<SiteRepository>.value(value: siteRepository),
        Provider<HiveRepository>.value(value: hiveRepository),

        // Connectivity
        Provider<ConnectivityService>.value(value: connectivity),

        // Localization
        ChangeNotifierProvider<AppLocalizations>(
          create: (_) => AppLocalizations(prefs),
        ),

        // State providers
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository),
        ),
        ChangeNotifierProvider<SitesProvider>(
          create: (_) => SitesProvider(siteRepository),
        ),
        ChangeNotifierProvider<SyncProvider>(
          create: (_) => SyncProvider(
            syncEngine: syncEngine,
            connectivity: connectivity,
          ),
        ),
        ChangeNotifierProvider<CommunityProvider>(
          create: (_) => CommunityProvider(
            communityApi: communityApi,
            eventsApi: eventsApi,
            tasksApi: tasksApi,
          ),
        ),
      ],
      child: const BeeApp(),
    ),
  );
}
