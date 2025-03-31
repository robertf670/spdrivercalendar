import pandas as pd
import os

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
        if "M-F" in sheet_name.upper() or "M-f" in sheet_name.upper() or "MONDAY" in sheet_name.upper():
            csv_suffix = "MF"
        elif "SAT" in sheet_name.upper() or "SATURDAY" in sheet_name.upper():
            csv_suffix = "Sat"
        elif "SUN" in sheet_name.upper() or "SUNDAY" in sheet_name.upper():
            csv_suffix = "Sun"
        else:
            # Skip sheets we don't want to process
            if "roster" in sheet_name.lower() or "summary" in sheet_name.lower():
                print(f"Skipping sheet '{sheet_name}' - not a schedule sheet")
                continue
            # Use sheet name if it doesn't match any known pattern
            csv_suffix = sheet_name.replace(" ", "_")
        
        # Read the sheet
        df = pd.read_excel(excel, sheet_name)
        
        # Create output CSV filename
        csv_filename = f"{base_name}{csv_suffix}.csv"
        csv_path = os.path.join(output_dir, csv_filename)
        
        # Save to CSV
        df.to_csv(csv_path, index=False)
        print(f"Saved sheet '{sheet_name}' to {csv_path}")

if __name__ == "__main__":
    # Set the path to the Excel file
    excel_file = "assets/Zone4Boards.xlsx"
    
    # Convert Excel to CSV
    excel_to_csv(excel_file)
    print("Conversion complete!") 