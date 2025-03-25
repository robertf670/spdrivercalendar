import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:spdrivercalendar/models/board_entry.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';

class BoardService {
  static Future<List<BoardEntry>> loadBoardEntries(String dutyNumber, DateTime date) async {
    // Check if it's a bank holiday
    final isBankHoliday = ShiftService.getBankHoliday(date, ShiftService.bankHolidays) != null;
    
    // Determine which CSV file to load based on the day of the week
    String fileName;
    if (isBankHoliday) {
      // Use Sunday board for bank holidays
      fileName = 'assets/Zone3BoardsSun.csv';
    } else if (date.weekday == DateTime.saturday) {
      fileName = 'assets/Zone3BoardsSat.csv';
    } else if (date.weekday == DateTime.sunday) {
      fileName = 'assets/Zone3BoardsSun.csv';
    } else {
      fileName = 'assets/Zone3BoardsMF.csv';
    }

    try {
      // Load the CSV file
      final String csvData = await rootBundle.loadString(fileName);
      
      // Parse the CSV data
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);
      
      // Skip the header row and convert remaining rows to BoardEntry objects
      List<BoardEntry> entries = csvTable
          .skip(1) // Skip header row
          .where((row) => row[0].toString() == dutyNumber) // Filter by duty number
          .map((row) => BoardEntry.fromCsvRow(row))
          .toList();

      return entries;
    } catch (e) {
      print('Error loading board entries: $e');
      return [];
    }
  }
} 