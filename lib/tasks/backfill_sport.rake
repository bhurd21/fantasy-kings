require 'csv'

namespace :backfill do
  desc "Backfill sport data from CSV file"
  task sport: :environment do
    csv_file = Rails.root.join('db', 'data_updates', 'betting_history_sport_backfill.csv')

    unless File.exist?(csv_file)
      puts "Error: #{csv_file} not found!"
      puts "Please ensure the CSV file exists in the project root."
      exit 1
    end

    updated_count = 0
    skipped_count = 0
    error_count = 0

    puts "Starting sport backfill from #{csv_file}..."

    CSV.foreach(csv_file, headers: true) do |row|
      id = row['id'].to_i
      is_nfl_value = row['is_nfl']&.strip&.upcase

      # Skip if is_nfl column is empty
      if is_nfl_value.blank?
        skipped_count += 1
        next
      end

      # Convert TRUE/FALSE string to boolean
      is_nfl = case is_nfl_value
      when 'TRUE', '1', 'YES'
        true
      when 'FALSE', '0', 'NO'
        false
      else
        puts "Warning: Invalid is_nfl value '#{is_nfl_value}' for ID #{id}, skipping"
        error_count += 1
        next
      end

      # Update the record
      begin
        betting_history = BettingHistory.find(id)
        betting_history.update_column(:is_nfl, is_nfl)
        updated_count += 1

        if updated_count % 50 == 0
          puts "Progress: #{updated_count} records updated..."
        end
      rescue ActiveRecord::RecordNotFound
        puts "Warning: BettingHistory with ID #{id} not found, skipping"
        error_count += 1
      rescue => e
        puts "Error updating ID #{id}: #{e.message}"
        error_count += 1
      end
    end

    puts "\n=== Backfill Complete ==="
    puts "Updated: #{updated_count} records"
    puts "Skipped (empty): #{skipped_count} records"
    puts "Errors: #{error_count} records"
    puts "========================="
  end
end
