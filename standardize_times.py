import pandas as pd
import os

def standardize_time(time_str):
    if pd.isna(time_str):
        return time_str
    # If the time already has seconds, return as is
    if ':' in time_str and time_str.count(':') == 2:
        return time_str
    # If the time has only hours and minutes, add seconds
    if ':' in time_str and time_str.count(':') == 1:
        return f"{time_str}:00"
    return time_str

def process_file(file_path):
    print(f"\nProcessing {file_path}...")
    try:
        # Read the CSV file
        df = pd.read_csv(file_path)
        print(f"Successfully read file with {len(df)} rows")
        
        # Standardize times in all time-related columns
        time_columns = ['Reports', 'Departs', 'Arrival', 'Departure']
        for col in time_columns:
            print(f"Processing column: {col}")
            df[col] = df[col].apply(standardize_time)
        
        # Save the standardized file
        df.to_csv(file_path, index=False)
        print(f"Successfully saved standardized file")
    except Exception as e:
        print(f"Error processing {file_path}: {str(e)}")

def main():
    # Process both Saturday and Sunday files
    files = ['assets/Zone3BoardsSat.csv', 'assets/Zone3BoardsSun.csv']
    for file in files:
        if os.path.exists(file):
            process_file(file)
        else:
            print(f"File not found: {file}")

if __name__ == "__main__":
    main() 