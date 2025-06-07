import pandas as pd
import os

def clean_jamestown_csv():
    """
    Clean up the generated Jamestown CSV file by removing header rows and invalid entries.
    """
    
    input_file = os.path.join('assets', 'JAMESTOWN_DUTIES_STRUCTURED.csv')
    output_file = os.path.join('assets', 'JAMESTOWN_DUTIES_CLEAN.csv')
    
    try:
        # Read the CSV
        df = pd.read_csv(input_file)
        
        # Filter out rows with invalid duty numbers (should be numeric)
        def is_valid_duty(duty_val):
            if pd.isna(duty_val):
                return False
            duty_str = str(duty_val).strip()
            # Check if it's a number (valid duty)
            try:
                int(duty_str)
                return True
            except ValueError:
                return False
        
        # Filter the dataframe
        cleaned_df = df[df['duty'].apply(is_valid_duty)]
        
        # Also filter out any rows where shift contains non-duty information
        def is_valid_shift(shift_val):
            if pd.isna(shift_val):
                return False
            shift_str = str(shift_val).strip()
            return shift_str.startswith('811/') and not any(word in shift_str.lower() for word in ['jamestown', 'roster', 'duty no:', 'hour contracts'])
        
        cleaned_df = cleaned_df[cleaned_df['shift'].apply(is_valid_shift)]
        
        # Sort by duty number for better organization
        cleaned_df['duty_int'] = cleaned_df['duty'].astype(int)
        cleaned_df = cleaned_df.sort_values('duty_int')
        cleaned_df = cleaned_df.drop('duty_int', axis=1)
        
        # Save the cleaned CSV
        cleaned_df.to_csv(output_file, index=False)
        
        print(f"Cleaned CSV created: {output_file}")
        print(f"Original rows: {len(df)}")
        print(f"Cleaned rows: {len(cleaned_df)}")
        print(f"Removed {len(df) - len(cleaned_df)} invalid rows")
        
        # Show first few rows
        print("\nFirst 5 rows of cleaned data:")
        print(cleaned_df.head())
        
        return True
        
    except Exception as e:
        print(f"Error cleaning CSV: {e}")
        return False

if __name__ == "__main__":
    clean_jamestown_csv() 