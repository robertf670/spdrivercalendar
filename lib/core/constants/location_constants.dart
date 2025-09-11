const Map<String, String> locationMappings = {
  // Base locations
  'GARAGE': 'Garage',
  'Garage': 'Garage',  // Added for training duties
  'Training School': 'Training School',  // Added for training duties
  'GAR': 'Garage',  // Added for Jamestown Road duties
  'PHIBPO': 'Garage',
  'PHIBPI': 'Garage',
  'PSQE': 'PSQE',
  'PSQW': 'PSQW',
  'ASTONQ': 'Aston Q',
  'BWALK': 'B Walk',
  'CONHILL #1619': 'Con Hill',
  'BSTONE #190': 'B Stone',
  
  // Route-specific locations
  '39A-ASTONQ': 'Aston Q',
  '39A-BWALK': 'B Walk',
  '39-BWALK': 'B Walk',
  '39-ASTONQ': 'Aston Q',
  'C1/C2-BWALK': 'B Walk',
  'C1/C2-ASTONQ': 'Aston Q',
  '1/C2-BWALK': 'B Walk',
  '1/C2-ASTONQ': 'Aston Q',
  
  // Additional route variations
  '39A': 'Route 39A',
  '39': 'Route 39',
  'C1/C2': 'Route C1/C2',
  '1/C2': 'Route 1/C2',
  '23': 'Route 23',
  '24': 'Route 24',
  
  // New location formats
  'PSQE-PQ': 'PSQE',
  'PSQW-PE': 'PSQW',
  'PSQW-PD': 'PSQW',
  
  // Additional variations
  'PQ': 'PSQE',
  'PE': 'PSQW',
  'PD': 'PSQW',
  
  // Full location codes with route numbers
  'PSQE-PQ(122)': 'PSQE',
  'PSQE-PQ(9)': 'PSQE',
  'PSQW-PE(9)': 'PSQW',
  'PSQW-PD(122)': 'PSQW',
  'PHIBPI(122)': 'Garage',
  'PHIBPO(122)': 'Garage',
  'PHIBPO(9)': 'Garage',
  
  // Special cases
  '=': 'Unknown Location'
};
