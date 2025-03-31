import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:spdrivercalendar/models/board_entry.dart';
import 'package:spdrivercalendar/features/calendar/services/shift_service.dart';

class BoardService {
  static Future<List<BoardEntry>> loadBoardEntries(String dutyNumber, DateTime date, {String? zone}) async {
    // Check if it's a bank holiday
    final isBankHoliday = ShiftService.getBankHoliday(date, ShiftService.bankHolidays) != null;
    
    // Determine which CSV file to load based on the day of the week and zone
    String fileName;
    
    // Handle Zone 4 boards
    if (zone == 'Zone4') {
      if (date.weekday == DateTime.saturday) {
        fileName = 'assets/Zone4BoardsSat.csv';
      } else {
        // For now, we only support Zone 4 Saturday boards
        // In the future, we can add support for other days
        return [];
      }
    } 
    // Default to Zone 3 boards
    else {
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
    }

    try {
      // Load the CSV file
      final String csvData = await rootBundle.loadString(fileName);
      
      // Parse the CSV data
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);
      
      List<BoardEntry> entries;
      
      // Process entries differently based on zone
      if (zone == 'Zone4') {
        // For Zone 4, filter out descriptive rows and normalize the data
        entries = _processZone4Entries(csvTable, dutyNumber);
      } else {
        // Standard processing for Zone 3
        entries = csvTable
            .skip(1) // Skip header row
            .where((row) => row[0].toString() == dutyNumber) // Filter by duty number
            .map((row) => BoardEntry.fromCsvRow(row))
            .toList();
      }

      return entries;
    } catch (e) {
      print('Error loading board entries: $e');
      return [];
    }
  }
  
  static List<BoardEntry> _processZone4Entries(List<List<dynamic>> csvTable, String dutyNumber) {
    // Filter rows for the specified duty
    final dutyRows = csvTable
        .skip(1) // Skip header row
        .where((row) => row[0].toString() == dutyNumber)
        .toList();
    
    List<BoardEntry> processedEntries = [];
    
    // Filter out descriptive rows and the final 'Finished Duty' marker row
    List<List<dynamic>> relevantRows = dutyRows.where((row) {
      // Condition 1: Exclude 'Reports at' rows
      bool isReportRow = row.length > 3 && row[3].toString().contains('Reports at');

      // Condition 2: Exclude the specific 'Finished Duty' marker row
      // Checks for empty location, 'nan' route, and 'Finished Duty' note.
      bool isFinishedMarker = row.length > 9 &&
                             row[3].toString().isEmpty &&
                             row[4].toString() == 'nan' &&
                             row[9] != null &&
                             row[9].toString().trim().contains('Finished Duty');

      // Condition 3: Exclude 'Takes Bus...' rows (redundant and have bad notes)
      bool isTakesBusRow = row.length > 3 && row[3].toString().contains('Takes Bus');

      // Condition 4: Exclude descriptive rows with 'ROUTE' in column 4
      bool isRouteDescRow = row.length > 4 && row[4].toString().startsWith('ROUTE');

      // Keep the row ONLY if it meets none of the exclusion criteria
      return !isReportRow && !isFinishedMarker && !isTakesBusRow && !isRouteDescRow;
    }).toList();
    
    // Process each row
    for (int i = 0; i < relevantRows.length; i++) {
      final row = relevantRows[i];
      
      // Skip the "Finished Duty" row - it will be handled specially
      if (row.length > 9 && row[9]?.toString()?.contains('Finished Duty') == true &&
          row[3].toString().isEmpty) {
        continue;
      }
      
      // Special handling for "Departs garage" - first entry
      if (row[3].toString() == 'Departs garage' && row[4].toString() == 'SPL') {
        // This is the first entry - departure from garage
        String nextLocation = "Unknown";
        // Try to get the next actual location
        if (i + 1 < relevantRows.length) {
          nextLocation = relevantRows[i + 1][3].toString();
        }
        
        processedEntries.add(BoardEntry(
          duty: dutyNumber,
          departs: row[2]?.toString(), // Use the direct departs time
          location: 'Garage',
          route: 'SPL',
          from: 'Garage',
          to: nextLocation,
        ));
      }
      
      // Handle 'Takes up at' entries (start of second half)
      else if (row[3].toString().contains('Takes up at')) {
        // Extract time and location from the string (e.g., "Takes up at 12:15 PSQW")
        String text = row[3].toString();
        RegExpMatch? match = RegExp(r'(\d{1,2}:\d{2})\s+(\w+)$').firstMatch(text);
        String takeOverTime = match?.group(1) ?? ''; // e.g., "12:15"
        String takeOverLocation = match?.group(2) ?? ''; // e.g., "PSQW"

        if (takeOverTime.isNotEmpty && takeOverLocation.isNotEmpty) {
          processedEntries.add(BoardEntry(
            duty: dutyNumber,
            location: takeOverLocation,
            route: 'TakeOver', // Special route type
            departs: takeOverTime, // Use departs to show start time
            notes: 'Start of Second Half',
          ));
        }
        // If parsing fails, we just skip this row for now
      }
      
      // Handle route entries (not garage departure, not PSQ, not special entries)
      else if (row[4].toString() != 'nan' && 
              row[4].toString() != 'SPL' && 
              !row[3].toString().contains('PSQ') &&
              row[3].toString() != 'Takes up at' &&
              !row[3].toString().contains('Takes Bus')) {
        
        String location = row[3].toString();
        String route = row[4].toString();
        String departureTime = row[8]?.toString() ?? "";
        
        // Look ahead to find the destination (next row's location)
        String destination = "Unknown";
        if (i + 1 < relevantRows.length) {
          // If next row has the same route, use its location as destination
          if (relevantRows[i + 1][4].toString() == route) {
            destination = relevantRows[i + 1][3].toString();
          }
          // If next row is a PSQ, use that as destination
          else if (relevantRows[i + 1][3].toString().contains('PSQ')) {
            destination = relevantRows[i + 1][3].toString();
          }
        }
        
        // Add entry for this location with its departure time
        processedEntries.add(BoardEntry(
          duty: dutyNumber,
          location: location,
          route: route,
          from: location,
          to: destination,
          departure: departureTime,
          notes: row[9]?.toString(),
        ));
      }
      
      // Handle PSQ entries (terminus entries)
      else if (row[3].toString().contains('PSQW') || row[3].toString().contains('PSQE')) {
        String psqLocation = row[3].toString();
        String? departureOrArrivalTime = row[8]?.toString() ?? row[7]?.toString(); // Use departure if available, else arrival

        // Check if this PSQ entry marks the START of the first trip after a TakeOver
        if (i > 0 && relevantRows[i - 1][3].toString().contains('Takes up at')) {
          // Find the next actual stop to determine route and destination
          String nextStopLocation = 'Unknown';
          String route = 'Unknown';
          for (int j = i + 1; j < relevantRows.length; j++) {
            var nextStopRow = relevantRows[j];
            String nextLoc = nextStopRow.length > 3 ? nextStopRow[3].toString() : '';
            String nextRoute = nextStopRow.length > 4 ? nextStopRow[4].toString() : 'nan';
            if (!nextLoc.contains('PSQ') && !nextLoc.contains('Takes') && nextRoute != 'nan' && nextRoute != 'SPL') {
              nextStopLocation = nextLoc;
              route = nextRoute;
              break;
            }
          }

          // Create the BoardEntry for the first trip
          processedEntries.add(BoardEntry(
            duty: dutyNumber,
            location: psqLocation, // Starting location (e.g., PSQW)
            route: route,          // Route number (e.g., 122)
            from: psqLocation,     // From location
            to: nextStopLocation, // Destination (e.g., Ashington)
            departure: departureOrArrivalTime, // Departure time (e.g., 12:15:00)
          ));
        } 
        // Standard handling for other PSQ entries (Handover or Final Finish)
        else {
          String? arrivalTime = row[7]?.toString(); // Use arrival time for these cases

          // Check if it's the final finish
          bool isLastEntry = i == relevantRows.length - 1;
          bool hasFinishDutyRow = dutyRows.any((r) => r.length > 9 && r[9] != null && r[9].toString().trim().contains('Finished Duty'));

          if (isLastEntry && hasFinishDutyRow) {
            // Final Finish sequence: Create a single Finish entry at the PSQ location
            String finishNote = 'Duty Finished'; // Default note
            var finishRow = dutyRows.firstWhere(
              (r) => r.length > 9 && r[9] != null && r[9].toString().trim().contains('Finished Duty'),
              orElse: () => [], 
            );
            if (finishRow.isNotEmpty) {
              finishNote = finishRow[9].toString().trim();
            }
            
            // Add the actual Finish entry at the PSQ
            processedEntries.add(BoardEntry(
              duty: dutyNumber,
              location: psqLocation, // e.g. PSQW
              route: 'Finish',
              arrival: arrivalTime, // Use the actual arrival time from the CSV row
              notes: finishNote,
            ));
          } else {
            // Mid-duty PSQ arrival implies start of handover
            processedEntries.add(BoardEntry(
              duty: dutyNumber,
              location: psqLocation, 
              route: 'Handover', 
              arrival: arrivalTime, 
              notes: 'End of First Half', 
            ));
          }
        }
      }
    }
    
    return processedEntries;
  }
  
  // Helper method to find the previous actual location
  static String _findPreviousLocation(List<List<dynamic>> rows, int currentIndex) {
    for (int i = currentIndex - 1; i >= 0; i--) {
      if (rows[i][4].toString() != 'nan' && 
          rows[i][4].toString() != 'SPL' && 
          !rows[i][3].toString().contains('Takes') &&
          !rows[i][3].toString().contains('PSQ')) {
        return rows[i][3].toString();
      }
    }
    return "Unknown";
  }
  
  static String? _calculateArrivalAtGarage(String? arrivalAtPSQ) {
    if (arrivalAtPSQ == null) return null;
    
    // Parse the arrival time at PSQ
    List<String> timeParts = arrivalAtPSQ.split(':');
    if (timeParts.length < 2) return null;
    
    // Add 30 minutes for travel to garage
    int hours = int.tryParse(timeParts[0]) ?? 0;
    int minutes = (int.tryParse(timeParts[1]) ?? 0) + 30;
    
    // Handle minute overflow
    if (minutes >= 60) {
      hours += minutes ~/ 60;
      minutes = minutes % 60;
    }
    
    // Format the time
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00';
  }
} 