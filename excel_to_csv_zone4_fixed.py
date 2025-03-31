import pandas as pd
import os
import re
import numpy as np
from datetime import datetime, time

def excel_to_csv_zone4(excel_file, output_dir=None):
    """
    Convert Zone4 Excel sheets to CSV files in the Zone3 format.
    
    Args:
        excel_file (str): Path to the Excel file
        output_dir (str, optional): Directory to save CSV files. If None, uses same directory as Excel file.
    """
    # Get base filename without extension
    base_name = os.path.splitext(os.path.basename(excel_file))[0]
    
    # Set output directory
    if output_dir is None:
        output_dir = os.path.dirname(excel_file)
    
    # Create output directory if it doesn't exist
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    print(f"Reading Excel file: {excel_file}")
    
    # Read all sheets
    excel = pd.ExcelFile(excel_file)
    sheet_names = excel.sheet_names
    
    print(f"Found sheets: {sheet_names}")
    
    for sheet_name in sheet_names:
        # Skip non-schedule sheets
        if "roster" in sheet_name.lower() or "summary" in sheet_name.lower():
            print(f"Skipping sheet '{sheet_name}' - not a schedule sheet")
            continue
            
        # Convert sheet name to a format suitable for the CSV filename
        if "M-F" in sheet_name.upper() or "M-f" in sheet_name.upper() or "MONDAY" in sheet_name.upper():
            csv_suffix = "MF"
        elif "SAT" in sheet_name.upper() or "SATURDAY" in sheet_name.upper():
            csv_suffix = "Sat"
        elif "SUN" in sheet_name.upper() or "SUNDAY" in sheet_name.upper():
            csv_suffix = "Sun"
        else:
            # Use sheet name if it doesn't match any known pattern
            csv_suffix = sheet_name.replace(" ", "_")
        
        # Read the sheet
        print(f"Reading sheet '{sheet_name}'...")
        df = pd.read_excel(excel, sheet_name)
        
        # Process the sheet to extract duty information
        print(f"Processing sheet '{sheet_name}'...")
        processed_data = extract_duty_data_by_board(df)
        
        if processed_data:
            # Create a dataframe from the processed data
            output_df = pd.DataFrame(processed_data, columns=[
                'Duty', 'Reports', 'Departs', 'Location', 'Route', 'From', 'To', 'Arrival', 'Departure', 'Notes'
            ])
            
            # Create output CSV filename
            csv_filename = f"{base_name}{csv_suffix}.csv"
            csv_path = os.path.join(output_dir, csv_filename)
            
            # Save to CSV
            output_df.to_csv(csv_path, index=False)
            print(f"Saved sheet '{sheet_name}' to {csv_path}")
        else:
            print(f"No duty data found in sheet '{sheet_name}'")

def extract_duty_data_by_board(df):
    """
    Extract duty data from the Zone4 Excel sheet using a better approach that follows
    the running board structure.
    
    Args:
        df (DataFrame): The raw dataframe from Excel
    
    Returns:
        list: List of dictionaries with duty data in Zone3 format
    """
    # Initialize result list
    result = []
    
    # Replace NaN with empty strings
    df = df.fillna('')
    
    # Convert all cells to strings
    for col in df.columns:
        df[col] = df[col].astype(str)
    
    # First, identify running board sections
    running_board_rows = []
    for idx, row in df.iterrows():
        row_text = ' '.join([str(x).strip() for x in row.values]).lower()
        if 'running board' in row_text:
            running_board_rows.append(idx)
    
    if not running_board_rows:
        # If no running board sections found, process the whole sheet
        running_board_rows = [0]
        running_board_rows.append(len(df))
    else:
        # Add the end of the dataframe as the last boundary
        running_board_rows.append(len(df))
    
    # Process each running board section
    for i in range(len(running_board_rows) - 1):
        start_row = running_board_rows[i]
        end_row = running_board_rows[i+1]
        
        # Process this section
        section_data = process_running_board_section(df.iloc[start_row:end_row])
        if section_data:
            result.extend(section_data)
    
    # Sort the results by duty number
    result.sort(key=lambda x: int(x['Duty']))
    
    return result

def process_running_board_section(section_df):
    """
    Process a single running board section from the Excel sheet.
    
    Args:
        section_df (DataFrame): A section of the Excel sheet containing one running board
    
    Returns:
        list: List of dictionaries with duty data
    """
    # Initialize result
    result = []
    
    # Map of main locations to standardize naming
    location_map = {
        'phibsboro garage': 'Garage',
        'garage': 'Garage',
        'charlestown': 'Charlestown',
        'limekiln': 'Limekiln',
        'psqe': 'PSQE',
        'psqw': 'PSQW'
    }
    
    # Find the columns with Route and Place
    route_col = None
    place_col = None
    arr_col = None
    dep_col = None
    
    # Find the header row
    header_row = None
    for idx, row in section_df.iterrows():
        row_text = ' '.join([str(x).strip().lower() for x in row.values])
        if 'route' in row_text and 'place' in row_text:
            header_row = idx
            break
    
    if header_row is None:
        return []
    
    # Identify columns based on header row
    header = section_df.iloc[header_row - section_df.index[0]]
    for col_idx, val in enumerate(header):
        val_lower = str(val).strip().lower()
        if val_lower == 'route':
            route_col = col_idx
        elif val_lower == 'place':
            place_col = col_idx
        elif 'arr' in val_lower:
            arr_col = col_idx
        elif 'dep' in val_lower:
            dep_col = col_idx
    
    if place_col is None:
        return []
    
    # Initialize variables for tracking duty context
    current_duty = None
    reports_time = None
    duties_data = {}
    
    # Process each row after the header
    for idx in range(header_row + 1, len(section_df) + section_df.index[0]):
        if idx >= len(section_df) + section_df.index[0]:
            break
        
        row = section_df.iloc[idx - section_df.index[0]]
        row_text = ' '.join([str(x).strip() for x in row.values]).lower()
        
        # Skip empty rows
        if not row_text.strip():
            continue
        
        # Check for duty information
        duty_match = re.search(r'duty\s+(\d{3})', row_text)
        if duty_match:
            current_duty = duty_match.group(1)
            
            # Extract reports time
            reports_match = re.search(r'reports at\s+(\d{2}:\d{2})', row_text)
            if reports_match:
                reports_time = reports_match.group(1)
            
            # Initialize this duty in the dictionary if needed
            if current_duty not in duties_data:
                duties_data[current_duty] = {
                    'entries': [],
                    'reports': reports_time
                }
            continue
        
        # If we're not currently tracking a duty, skip this row
        if not current_duty:
            continue
        
        # Extract information from the row
        route = ''
        location = ''
        arrival = ''
        departure = ''
        notes = ''
        
        # Get location
        if place_col < len(row):
            place_val = str(row.iloc[place_col]).strip()
            if place_val:
                location = place_val
                # Standardize location name
                location_lower = location.lower()
                for key, mapped_loc in location_map.items():
                    if key in location_lower:
                        location = mapped_loc
                        break
        
        # Get route
        if route_col is not None and route_col < len(row):
            route_val = str(row.iloc[route_col]).strip()
            if route_val and route_val.upper() in ['SPL', '9', '122', 'GHOST']:
                route = route_val.upper()
        
        # Get arrival time
        if arr_col is not None and arr_col < len(row):
            arr_val = str(row.iloc[arr_col]).strip()
            if re.match(r'^\d{1,2}:\d{2}(:\d{2})?$', arr_val):
                arrival = arr_val
        
        # Get departure time
        if dep_col is not None and dep_col < len(row):
            dep_val = str(row.iloc[dep_col]).strip()
            if re.match(r'^\d{1,2}:\d{2}(:\d{2})?$', dep_val):
                departure = dep_val
        
        # Check for "Departs Garage" text which indicates a depart time
        departs_time = ''
        if 'departs garage' in row_text:
            for val in row:
                val_str = str(val).strip()
                if re.match(r'^\d{1,2}:\d{2}(:\d{2})?$', val_str):
                    departs_time = val_str
                    break
        
        # Check for "Finish Duty" text
        if 'finish' in row_text and 'duty' in row_text:
            notes = f"Duty {current_duty} Finished Duty"
        
        # Check for "Takes up" notes
        takes_up_match = re.search(r'takes up.*?(bus \d+|at \w+ \d{2}:\d{2})', row_text)
        if takes_up_match:
            takes_up_text = takes_up_match.group(0)
            if notes:
                notes = f"{notes}; {takes_up_text}"
            else:
                notes = takes_up_text
        
        # Only add the row if we have useful information
        if location or route or arrival or departure:
            entry = {
                'location': location,
                'route': route,
                'arrival': arrival,
                'departure': departure,
                'departs_time': departs_time,
                'notes': notes
            }
            duties_data[current_duty]['entries'].append(entry)
    
    # Convert the duty data to the final format
    for duty_num, duty_info in sorted(duties_data.items(), key=lambda x: int(x[0])):
        entries = duty_info['entries']
        reports_time = duty_info['reports']
        
        if not entries:
            continue
        
        # Add each entry to the result
        for i, entry in enumerate(entries):
            location = entry['location']
            
            # Determine From and To fields
            from_loc = ''
            to_loc = ''
            if i > 0 and entries[i-1]['location']:
                from_loc = entries[i-1]['location']
                to_loc = location
            
            result_entry = {
                'Duty': duty_num,
                'Reports': reports_time if i == 0 else '',
                'Departs': entry['departs_time'] if location == 'Garage' and entry['departs_time'] else '',
                'Location': location,
                'Route': entry['route'],
                'From': from_loc,
                'To': to_loc,
                'Arrival': entry['arrival'],
                'Departure': entry['departure'],
                'Notes': entry['notes']
            }
            
            result.append(result_entry)
    
    return result

if __name__ == "__main__":
    # Set the path to the Excel file
    excel_file = "assets/Zone4Boards.xlsx"
    
    # Convert Excel to CSV
    excel_to_csv_zone4(excel_file)
    print("Conversion complete!") 