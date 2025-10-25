require 'csv'

namespace :betting_history do
  desc "Import betting history from CSV file"
  task :import, [:file_path] => :environment do |t, args|
    file_path = args[:file_path] || Rails.root.join('db', 'betting_history_import.csv')
    
    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      puts "Usage: rake betting_history:import[path/to/file.csv]"
      puts "Or place file at: db/betting_history_import.csv"
      exit
    end
    
    imported_count = 0
    skipped_count = 0
    error_count = 0
    
    # Store emails without users for later reporting
    emails_without_users = Set.new
    
    CSV.foreach(file_path, headers: true, header_converters: :symbol) do |row|
      begin
        email = row[:email]&.strip&.downcase
        
        # Skip if no email
        unless email
          puts "Skipping row - no email provided"
          skipped_count += 1
          next
        end
        
        # Try to find user by email
        user = User.find_by(email: email)
        
        unless user
          emails_without_users.add(email)
          skipped_count += 1
          next
        end
        
        # Parse the data
        timestamp = parse_timestamp(row[:timestamp])
        week_nfl = row[:week_nfl]&.to_i
        bet_description = row[:bet_description]&.strip
        line = parse_line(row[:line])
        total_stake = row[:total_stake]&.to_f || 0
        result = parse_result(row[:result])
        return_amount = row[:return]&.to_f || 0
        
        # Validate required fields
        unless timestamp && week_nfl && bet_description && total_stake > 0
          puts "Skipping row for #{email} - missing required fields"
          error_count += 1
          next
        end
        
        # Create the betting history record
        betting_history = user.betting_histories.build(
          bet_description: bet_description,
          line_value: line,
          total_stake: total_stake,
          result: result,
          return_amount: return_amount,
          nfl_week: week_nfl,
          created_at: timestamp,
          updated_at: timestamp,
          # Note: dk_game_id will be nil - these are legacy bets
          # bet_type will default based on description or can be inferred
          bet_type: infer_bet_type(bet_description)
        )
        
        if betting_history.save
          imported_count += 1
        else
          puts "Error saving bet for #{email}: #{betting_history.errors.full_messages.join(', ')}"
          error_count += 1
        end
        
      rescue => e
        puts "Error processing row: #{e.message}"
        puts row.inspect
        error_count += 1
      end
    end
    
    # Summary report
    puts "\n" + "="*60
    puts "IMPORT SUMMARY"
    puts "="*60
    puts "Successfully imported: #{imported_count} records"
    puts "Skipped (no matching user): #{skipped_count} records"
    puts "Errors: #{error_count} records"
    
    if emails_without_users.any?
      puts "\n" + "-"*60
      puts "EMAILS WITHOUT MATCHING USERS (#{emails_without_users.size}):"
      puts "-"*60
      emails_without_users.sort.each do |email|
        puts "  - #{email}"
      end
      puts "\nThese users need to sign up before their data can be imported."
      puts "Save this CSV file and re-run the import after they register."
    end
    
    puts "="*60
  end
  
  # Helper methods
  def parse_timestamp(timestamp_str)
    return Time.current unless timestamp_str
    
    # Try various timestamp formats
    [
      '%Y-%m-%d %H:%M:%S',
      '%m/%d/%Y %H:%M:%S',
      '%Y-%m-%d %H:%M:%S %Z',
      '%Y-%m-%d',
      '%m/%d/%Y'
    ].each do |format|
      begin
        return Time.strptime(timestamp_str, format)
      rescue ArgumentError
        next
      end
    end
    
    # Fallback to Time.parse
    Time.parse(timestamp_str) rescue Time.current
  end
  
  def parse_line(line_str)
    return nil unless line_str
    
    # Handle various line formats
    line_str = line_str.to_s.strip
    
    # Remove common prefixes/suffixes
    line_str = line_str.gsub(/[^\d\-\+\.]/, '')
    
    # Convert to integer (will handle negative numbers)
    line_str.to_i
  end
  
  def parse_result(result_str)
    return 'pending' unless result_str
    
    result_str = result_str.to_s.strip.downcase
    
    case result_str
    when 'Win', 'won', 'w'
      'win'
    when 'Loss', 'lost', 'lose', 'l'
      'loss'
    when 'Push', 'tie', 't'
      'push'
    else
      'pending'
    end
  end
  
  def infer_bet_type(description)
    return 'other' unless description
    
    desc = description.downcase
    
    if desc.include?('spread') || desc.match?(/[+-]\d+\.?\d*/)
      'spread'
    elsif desc.include?('over') || desc.include?('under') || desc.include?('vs')
      'total'
    elsif desc.include?('moneyline') || desc.include?('winner') || desc.include?('ml')
      'moneyline'
    else
      'other'
    end
  end
end
