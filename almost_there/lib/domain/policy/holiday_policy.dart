/// Interface for holiday checking policy
abstract class HolidayPolicy {
  /// Check if the given date is a working day (not a holiday)
  Future<bool> isWorkingDay(DateTime date);
  
  /// Check if the given date is a holiday
  Future<bool> isHoliday(DateTime date);
  
  /// Get current policy state for debugging
  String get policyState;
}

/// Implementation of holiday policy using device calendar
class CalendarHolidayPolicy implements HolidayPolicy {
  final HolidayRepository _repository;
  
  CalendarHolidayPolicy(this._repository);
  
  @override
  Future<bool> isWorkingDay(DateTime date) async {
    return !(await isHoliday(date));
  }
  
  @override
  Future<bool> isHoliday(DateTime date) async {
    try {
      return await _repository.isHoliday(date);
    } catch (e) {
      // On error, assume it's a working day to avoid blocking alarms
      return false;
    }
  }
  
  @override
  String get policyState => _repository.policyInfo;
}

/// Repository interface for holiday data access
abstract class HolidayRepository {
  Future<bool> isHoliday(DateTime date);
  Future<void> loadHolidaysForYear(int year);
  String get policyInfo;
}