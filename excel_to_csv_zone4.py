import pandas as pd
import os
import re
import numpy as np

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
        df = pd.read_excel(excel, sheet_name)
        
        # Process the sheet to extract duty information
        print(f"Processing sheet '{sheet_name}'...")
        processed_data = extract_duty_data(df)
        
        if processed_data:
            # Create a dataframe from the processed data
            output_df = pd.DataFrame(processed_data, columns=[
                'Duty', 'Reports', 'Departs', 'Location', 'Route', 'From', 'To', 'Arrival', 'Departure', 'Notes'
            ])
            
            # Sort the data by duty number
            output_df['Duty_Num'] = output_df['Duty'].astype(int)
            output_df = output_df.sort_values('Duty_Num')
            output_df = output_df.drop('Duty_Num', axis=1)
            
            # Create output CSV filename
            csv_filename = f"{base_name}{csv_suffix}.csv"
            csv_path = os.path.join(output_dir, csv_filename)
            
            # Save to CSV
            output_df.to_csv(csv_path, index=False)
            print(f"Saved sheet '{sheet_name}' to {csv_path}")
        else:
            print(f"No duty data found in sheet '{sheet_name}'")

def extract_duty_data(df):
    """
    Extract duty data from the Zone4 Excel sheet.
    
    Args:
        df (DataFrame): The raw dataframe from Excel
    
    Returns:
        list: List of dictionaries with duty data in Zone3 format
    """
    # Initialize result list
    result = []
    # Dictionary to hold duty data by duty number
    duty_data = {}
    
    # Replace NaN with empty strings
    df = df.fillna('')
    
    # Extract duty sections
    current_duty = None
    current_bus = None
    is_reading_duty = False
    report_time = ''
    
    for idx, row in df.iterrows():
        row_text = ' '.join([str(x).strip() for x in row.values]).lower()
        
        # Check if this row contains a duty number
        duty_match = re.search(r'duty\s+(\d{3})', row_text)
        if duty_match:
            duty_num = duty_match.group(1)
            
            # Extract report time if present
            report_match = re.search(r'reports at\s+(\d{2}:\d{2})', row_text)
            report_time = report_match.group(1) if report_match else ''
            
            # New duty found, set current duty
            current_duty = duty_num
            is_reading_duty = True
            
            # Initialize this duty in our dict if not already there
            if current_duty not in duty_data:
                duty_data[current_duty] = []
            
            # Look for bus number
            bus_match = re.search(r'bus\s+(\d+)', row_text)
            if bus_match:
                current_bus = bus_match.group(1)
            
            continue
        
        # Skip if not currently reading a duty
        if not is_reading_duty or not current_duty:
            continue
        
        # Check if this is a route/location row
        # Look for key locations in Zone4: Garage, Charlestown, Limekiln, PSQE, PSQW
        route = None
        location = None
        arrival = None
        departure = None
        from_loc = ''
        to_loc = ''
        notes = ''
        
        # Extract route
        for val in row.values:
            val_str = str(val).strip()
            if val_str in ['SPL', '9', '122', 'Ghost']:
                route = val_str
                break
        
        # Extract location
        for val in row.values:
            val_str = str(val).strip()
            if val_str in ['Garage', 'Charlestown', 'Limekiln', 'PSQE', 'PSQW', 'Phibsboro Garage']:
                location = val_str
                break
        
        # Extract times
        for col_idx, val in enumerate(row.values):
            val_str = str(val).strip()
            
            # Skip non-time values
            if not re.match(r'^\d{1,2}:\d{2}(:\d{2})?$', val_str):
                continue
            
            # Look for preceding column headers to determine if arrival or departure
            for i in range(max(0, col_idx-3), col_idx+1):
                if i < len(row.values) and str(row.iloc[i]).strip().lower() == 'arr':
                    arrival = val_str
                    break
                elif i < len(row.values) and str(row.iloc[i]).strip().lower() == 'dep':
                    departure = val_str
                    break
            
            # If we couldn't determine explicitly, guess based on position
            if not arrival and not departure and location:
                # Likely a departure time if after location
                departure = val_str
        
        # Check for "Finish Duty" text
        if 'finish' in row_text and 'duty' in row_text:
            notes = f"Duty {current_duty} Finished Duty"
            is_reading_duty = False
        
        # Add row if we have route or location
        if route or location:
            # Create entry with the format matching Zone3
            entry = {
                'Duty': current_duty,
                'Reports': report_time,  # Will update Reports field later
                'Departs': '',  # Extract departs time if available
                'Location': location if location else '',
                'Route': route if route else '',
                'From': from_loc,
                'To': to_loc,
                'Arrival': arrival if arrival else '',
                'Departure': departure if departure else '',
                'Notes': notes
            }
            
            # Extract departs time from "Departs Garage" text
            departs_match = re.search(r'departs garage.*?(\d{2}:\d{2}(:\d{2})?)', row_text)
            if departs_match:
                entry['Departs'] = departs_match.group(1)
            
            # Extract "Takes up" notes
            takes_up_match = re.search(r'takes up.*?(bus \d+|at \w+ \d{2}:\d{2})', row_text)
            if takes_up_match:
                notes_text = takes_up_match.group(0)
                if notes and notes_text:
                    entry['Notes'] = f"{notes}; {notes_text}"
                elif notes_text:
                    entry['Notes'] = notes_text
            
            # Add the entry to this duty's data list
            duty_data[current_duty].append(entry)
            
            # End duty if we saw "Finish Duty"
            if 'finish' in row_text:
                is_reading_duty = False
    
    # Combine all duty data into final result, with proper Reports field
    for duty_num, entries in sorted(duty_data.items(), key=lambda x: int(x[0])):
        if entries:
            # Keep report time only for the first entry of each duty
            first_entry = True
            for entry in entries:
                if not first_entry:
                    entry['Reports'] = ''
                first_entry = False
                result.append(entry)
    
    return result

if __name__ == "__main__":
    # Set the path to the Excel file
    excel_file = "assets/Zone4Boards.xlsx"
    
    # Convert Excel to CSV
    excel_to_csv_zone4(excel_file)
    print("Conversion complete!") 