import '../orchestrator_integration.dart';
import 'debug_logger.dart';

/// Service that handles alarm events and delegates to orchestrator
class AlarmEventManager {
  
  /// Handle geofence entry event from platform
  static Future<void> handleGeofenceEntry(String alarmId) async {
    DebugLogger.debug('🌍 Geofence entry detected for alarm: $alarmId');
    
    // Delegate to orchestrator instead of handling directly
    await OrchestratorIntegration.onGeofenceEntered(alarmId);
    
    DebugLogger.debug('🌍 Geofence entry processed by orchestrator');
  }
  
  /// Handle geofence exit event from platform
  static Future<void> handleGeofenceExit(String alarmId) async {
    DebugLogger.debug('🌍 Geofence exit detected for alarm: $alarmId');
    
    // Delegate to orchestrator instead of handling directly
    await OrchestratorIntegration.onGeofenceExited(alarmId);
    
    DebugLogger.debug('🌍 Geofence exit processed by orchestrator');
  }
  
  /// Handle device boot event
  static Future<void> handleDeviceBoot() async {
    DebugLogger.debug('📱 Device boot detected, reconciling system state');
    
    await OrchestratorIntegration.onDeviceBoot();
    
    DebugLogger.debug('📱 Device boot reconciliation completed');
  }
  
  /// Handle permission changes
  static Future<void> handlePermissionChange() async {
    DebugLogger.debug('🔐 Permission change detected');
    
    await OrchestratorIntegration.onPermissionChanged();
    
    DebugLogger.debug('🔐 Permission change processed');
  }
}