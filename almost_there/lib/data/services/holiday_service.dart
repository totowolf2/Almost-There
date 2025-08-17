import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';

class HolidayService {
  static const List<String> _holidayKeywords = [
    'holiday',
    'holidays', 
    'วันหยุด',
    'วัน หยุด',
    'Thai',
    'Thailand',
    'ไทย'
  ];
  
  final DeviceCalendarPlugin _deviceCalendar = DeviceCalendarPlugin();
  List<DateTime> _cachedHolidays = [];
  int _currentCachedYear = 0;
  Calendar? _selectedHolidayCalendar;
  
  static final HolidayService _instance = HolidayService._internal();
  factory HolidayService() => _instance;
  HolidayService._internal();

  /// Request calendar permission
  Future<bool> requestCalendarPermission() async {
    // Check current permission status first
    final status = await Permission.calendarFullAccess.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      // Request permission
      final requestResult = await Permission.calendarFullAccess.request();
      return requestResult.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // User has permanently denied permission, need to open settings
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  /// Find holiday calendars on the device
  Future<List<Calendar>> findHolidayCalendars() async {
    try {
      final permissionsGranted = await _deviceCalendar.hasPermissions();
      if (!permissionsGranted.isSuccess || !permissionsGranted.data!) {
        final requestResult = await _deviceCalendar.requestPermissions();
        if (!requestResult.isSuccess || !requestResult.data!) {
          throw Exception('Calendar permissions not granted');
        }
      }

      final calendarsResult = await _deviceCalendar.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        return [];
      }

      final holidayCalendars = calendarsResult.data!
          .where((calendar) => _isHolidayCalendar(calendar.name ?? ''))
          .toList();

      return holidayCalendars;
    } catch (e) {
      // Error finding holiday calendars
      return [];
    }
  }

  /// Check if calendar name contains holiday keywords
  bool _isHolidayCalendar(String calendarName) {
    final lowerName = calendarName.toLowerCase();
    return _holidayKeywords.any((keyword) => 
        lowerName.contains(keyword.toLowerCase()));
  }

  /// Set the selected holiday calendar
  void setHolidayCalendar(Calendar calendar) {
    _selectedHolidayCalendar = calendar;
    _clearCache(); // Clear cache when changing calendar
  }

  /// Get currently selected holiday calendar
  Calendar? get selectedHolidayCalendar => _selectedHolidayCalendar;

  /// Load holidays for the current year and cache them
  Future<void> loadHolidaysForYear(int year) async {
    if (_selectedHolidayCalendar == null) {
      final calendars = await findHolidayCalendars();
      if (calendars.isNotEmpty) {
        _selectedHolidayCalendar = calendars.first;
      } else {
        // No holiday calendars found
        return;
      }
    }

    if (year == _currentCachedYear && _cachedHolidays.isNotEmpty) {
      return; // Already cached for this year
    }

    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);

      final eventsResult = await _deviceCalendar.retrieveEvents(
        _selectedHolidayCalendar!.id,
        RetrieveEventsParams(
          startDate: startDate,
          endDate: endDate,
        ),
      );

      if (eventsResult.isSuccess && eventsResult.data != null) {
        _cachedHolidays = eventsResult.data!
            .where((event) => event.allDay == true) // Only all-day events
            .map((event) => event.start!)
            .map((dateTime) => DateTime(dateTime.year, dateTime.month, dateTime.day))
            .toSet() // Remove duplicates
            .toList();
        
        _currentCachedYear = year;
        
        // Debug: Loaded holidays successfully
      } else {
        // Error: Failed to load holidays
      }
    } catch (e) {
      // Error loading holidays
    }
  }

  /// Check if a specific date is a holiday
  Future<bool> isHoliday(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Load holidays for the year if not cached
    if (date.year != _currentCachedYear) {
      await loadHolidaysForYear(date.year);
    }
    
    return _cachedHolidays.contains(dateOnly);
  }

  /// Get all cached holidays for the current year
  List<DateTime> get cachedHolidays => List.unmodifiable(_cachedHolidays);

  /// Check if holidays are loaded for a specific year
  bool isYearCached(int year) => year == _currentCachedYear && _cachedHolidays.isNotEmpty;

  /// Clear cached holidays
  void _clearCache() {
    _cachedHolidays.clear();
    _currentCachedYear = 0;
  }

  /// Update cache for new year if needed
  Future<void> updateCacheIfNeeded() async {
    final currentYear = DateTime.now().year;
    if (currentYear != _currentCachedYear) {
      await loadHolidaysForYear(currentYear);
    }
  }

  /// Get holiday calendar info for display
  String get holidayCalendarInfo {
    if (_selectedHolidayCalendar == null) {
      return 'ไม่พบปฏิทินวันหยุด';
    }
    return 'ปฏิทิน: ${_selectedHolidayCalendar!.name} (${_cachedHolidays.length} วันหยุดในปี $_currentCachedYear)';
  }
}