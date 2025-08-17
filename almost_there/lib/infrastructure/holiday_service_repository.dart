import '../domain/policy/holiday_policy.dart';
import '../data/services/holiday_service.dart';

/// Implementation of HolidayRepository that wraps the existing HolidayService
class HolidayServiceRepository implements HolidayRepository {
  final HolidayService _holidayService;
  
  HolidayServiceRepository(this._holidayService);
  
  @override
  Future<bool> isHoliday(DateTime date) async {
    return await _holidayService.isHoliday(date);
  }
  
  @override
  Future<void> loadHolidaysForYear(int year) async {
    await _holidayService.loadHolidaysForYear(year);
  }
  
  @override
  String get policyInfo => _holidayService.holidayCalendarInfo;
}