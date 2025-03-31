import csv
import os

def update_csv_file(filepath):
    # Read the CSV file
    rows = []
    with open(filepath, 'r', newline='') as csvfile:
        reader = csv.reader(csvfile)
        rows = list(reader)
    
    # Update route numbers (9.0 -> 9, 122.0 -> 122)
    for i in range(len(rows)):
        if i > 0:  # Skip header row
            if len(rows[i]) > 4:  # Make sure we have enough columns
                if rows[i][4] == '9.0':
                    rows[i][4] = '9'
                elif rows[i][4] == '122.0':
                    rows[i][4] = '122'
    
    # Write the updated data back to the CSV file
    with open(filepath, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(rows)
    
    print(f"Updated {filepath}")

# Update all Zone4 CSV files
files_to_update = [
    'assets/Zone4BoardsMF.csv',
    'assets/Zone4BoardsSat.csv',
    'assets/Zone4BoardsSun.csv'
]

for file in files_to_update:
    if os.path.exists(file):
        update_csv_file(file)
    else:
        print(f"File not found: {file}") 