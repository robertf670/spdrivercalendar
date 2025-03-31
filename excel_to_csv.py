import pandas as pd
import os
import re

def excel_to_csv(excel_file, output_dir=None):
    """
    Convert Excel sheets to CSV files.
    
    Args:
        excel_file (str): Path to the Excel file
        output_dir (str, optional): Directory to save CSV files. If None, uses the same directory as the Excel file.
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
        # Convert sheet name to a format suitable for the CSV filename
        if "M-F" in sheet_name or "M-f" in sheet_name:
            csv_suffix = "MF"
        elif "SAT" in sheet_name.upper():
            csv_suffix = "Sat"
        elif "SUN" in sheet_name.upper():
            csv_suffix = "Sun"
        else:
            # Use sheet name if it doesn't match any known pattern
            csv_suffix = sheet_name.replace(" ", "_")
        
        # Skip sheets we don't want to process
        if "roster" in csv_suffix.lower():
            continue
        
        # Read the sheet
        df = pd.read_excel(excel, sheet_name)
        
        # Process the dataframe to extract the schedule information
        processed_df = process_sheet(df)
        
        if processed_df is not None and not processed_df.empty:
            # Create output CSV filename
            csv_filename = f"{base_name}{csv_suffix}.csv"
            csv_path = os.path.join(output_dir, csv_filename)
            
            # Save to CSV
            processed_df.to_csv(csv_path, index=False)
            print(f"Saved sheet '{sheet_name}' to {csv_path}")
        else:
            print(f"Skipping sheet '{sheet_name}' - no valid data found")

def process_sheet(df):
    """
    Process the dataframe to extract schedule information.
    
    Args:
        df (DataFrame): The raw dataframe read from Excel
    
    Returns:
        DataFrame: A processed dataframe ready for CSV output
    """
    # Create a new dataframe with the expected columns
    result_df = pd.DataFrame(columns=[
        'Duty', 'Reports', 'Departs', 'Location', 'Route', 'From', 'To', 'Arrival', 'Departure', 'Notes'
    ])
    
    # Find rows that contain actual schedule data
    duty_rows = []
    current_duty = None
    data_rows = []
    
    for i, row in df.iterrows():
        row_data = row.values
        
        # Convert row data to strings for easier matching
        row_str = [str(val).strip() if not pd.isna(val) else "" for val in row_data]
        row_text = " ".join(row_str).lower()
        
        # Skip header rows and empty rows
        if ("duty" in row_text and "reports" in row_text) or "route" in row_text:
            continue
        
        # Check if this is a duty row
        duty_match = None
        for val in row_str:
            if val and re.match(r'^(duty\s+)?[0-9]{3}$', val.lower()):
                duty_match = val
                break
                
        # If we found a duty number
        if duty_match:
            duty_num = re.search(r'[0-9]{3}', duty_match).group(0)
            reports_time = None
            departs_time = None
            
            # Look for Reports and Departs times
            for j, val in enumerate(row_str):
                if val.lower() == 'reports at' and j+1 < len(row_str):
                    reports_time = row_str[j+1]
                if val.lower() == 'departs garage' and j+1 < len(row_str):
                    departs_time = row_str[j+1]
            
            current_duty = {
                'Duty': duty_num,
                'Reports': reports_time,
                'Departs': departs_time
            }
            duty_rows.append(current_duty)
        
        # Check for location and route data
        elif current_duty and any(loc in row_text for loc in ['garage', 'charlestown', 'limekiln', 'psqe', 'psqw']):
            location = None
            route = None
            arrival = None
            departure = None
            from_loc = None
            to_loc = None
            notes = None
            
            # Extract values from the row
            for j, val in enumerate(row_str):
                val_lower = val.lower()
                
                # Look for routes
                if val_lower in ['spl', '9', '122', 'ghost']:
                    route = val
                
                # Look for locations
                elif any(loc in val_lower for loc in ['garage', 'charlestown', 'limekiln', 'psqe', 'psqw']):
                    location = val
                
                # Look for arrival/departure times
                elif re.match(r'^\d{1,2}:\d{2}(:\d{2})?$', val):
                    # Check if this is arrival or departure based on position
                    if pd.notna(row.iloc[j-1]) and 'arr' in str(row.iloc[j-1]).lower():
                        arrival = val
                    elif pd.notna(row.iloc[j-1]) and 'dep' in str(row.iloc[j-1]).lower():
                        departure = val
                    # If no label, assume it's departure if it's after a location
                    elif location and not departure:
                        departure = val
            
            # If "Finish Duty" is in the row, add a note
            if 'finish' in row_text and 'duty' in row_text:
                notes = 'Duty {} Finished Duty'.format(current_duty['Duty'])
            
            if location or route:
                data_rows.append({
                    'Duty': current_duty['Duty'],
                    'Reports': '' if any(d['Duty'] == current_duty['Duty'] for d in data_rows) else current_duty['Reports'],
                    'Departs': '' if any(d['Duty'] == current_duty['Duty'] for d in data_rows) else current_duty['Departs'],
                    'Location': location or '',
                    'Route': route or '',
                    'From': from_loc or '',
                    'To': to_loc or '',
                    'Arrival': arrival or '',
                    'Departure': departure or '',
                    'Notes': notes or ''
                })
    
    # If we found any data, create the result dataframe
    if data_rows:
        result_df = pd.DataFrame(data_rows)
        
        # Fill in missing values
        result_df.fillna('', inplace=True)
        
        return result_df
    
    return None

if __name__ == "__main__":
    # Set the path to the Excel file
    excel_file = "assets/Zone4Boards.xlsx"
    
    # Convert Excel to CSV
    excel_to_csv(excel_file)
    print("Conversion complete!") 