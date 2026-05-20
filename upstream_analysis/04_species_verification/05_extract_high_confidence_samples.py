import pandas as pd

# Read the CSV file and skip the processing log lines
df = pd.read_csv('staph_verification_results_fixed_v2.csv', comment='[')

# Extract samples with HIGH_CONFIDENCE_SA and LIKELY_SA
target_samples = df[df['classification'].isin(['HIGH_CONFIDENCE_SA', 'LIKELY_SA'])]

# Calculate total samples and counts for each category
total_samples = len(df)
high_confidence_count = len(df[df['classification'] == 'HIGH_CONFIDENCE_SA'])
likely_count = len(df[df['classification'] == 'LIKELY_SA'])
target_count = len(target_samples)

# Calculate percentages
high_confidence_percentage = (high_confidence_count / total_samples) * 100
likely_percentage = (likely_count / total_samples) * 100
target_percentage = (target_count / total_samples) * 100

# Print results
print("=== SAMPLE DISTRIBUTION ANALYSIS ===")
print(f"Total samples: {total_samples}")
print("\n--- Individual Categories ---")
print(f"HIGH_CONFIDENCE_SA: {high_confidence_count} samples ({high_confidence_percentage:.2f}%)")
print(f"LIKELY_SA: {likely_count} samples ({likely_percentage:.2f}%)")
print(f"POSSIBLE_SA: {len(df[df['classification'] == 'POSSIBLE_SA'])} samples")
print(f"UNLIKELY_SA: {len(df[df['classification'] == 'UNLIKELY_SA'])} samples")

print("\n--- Target Samples for Analysis ---")
print(f"HIGH_CONFIDENCE_SA + LIKELY_SA: {target_count} samples ({target_percentage:.2f}%)")

print("\n--- Quality Distribution in Target Samples ---")
target_quality_counts = target_samples['quality'].value_counts()
for quality, count in target_quality_counts.items():
    percentage = (count / target_count) * 100
    print(f"{quality}: {count} samples ({percentage:.2f}%)")

# Save the filtered dataset
target_samples.to_csv('high_confidence_likely_samples.csv', index=False)
print(f"\nFiltered dataset saved to 'high_confidence_likely_samples.csv'")

# Display first few rows of the filtered data
print("\nFirst 5 samples in filtered dataset:")
print(target_samples[['sample', 'classification', 'quality', 'mapping_percentage']].head())
