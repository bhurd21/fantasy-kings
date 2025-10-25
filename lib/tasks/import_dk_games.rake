namespace :dk_games do
  desc "Import DK games from a csv or json file. Supports CSV with headers matching the keys or JSON array of objects. Usage: rake dk_games:import[file_path]"
  task :import, [:file_path] => :environment do |_t, args|
    begin
      require 'csv'
    rescue LoadError
      puts "CSV library not available. Add gem 'csv' to your Gemfile and run bundle install"
      exit 1
    end

    file = args[:file_path]
    unless file && File.exist?(file)
      puts "Please provide a valid file path: rake dk_games:import[/path/to/file.csv]"
      next
    end

    ext = File.extname(file).downcase
    rows = []

    case ext
    when '.csv'
      CSV.foreach(file, headers: true) do |row|
        rows << row.to_h
      end
    when '.json'
      rows = JSON.parse(File.read(file))
    else
      puts "Unsupported file type: #{ext}. Use .csv or .json"
      next
    end

    rows.each do |r|
      # Normalize keys to strings
      data = r.transform_keys { |k| k.to_s.strip }

      # parse sport (string -> enum)
      sport = case data['sport']&.downcase
              when 'nfl' then 'nfl'
              when 'ncaaf' then 'ncaaf'
              else
                puts "Skipping row with unknown sport: #{data['sport']}"
                next
              end

      begin
        commence_time = data['commence_time'] ? Time.parse(data['commence_time']) : nil
        bookmaker_last_update = data['bookmaker_last_update'] ? Time.parse(data['bookmaker_last_update']) : nil
      rescue => e
        puts "Failed to parse time for row: #{e.message} - skipping"
        next
      end

      external_id = data['id']
      unless external_id.present?
        puts "Skipping row with missing external_id (id field)"
        next
      end

      attrs = {
        external_id: external_id,
        sport: sport,
        commence_time: commence_time,
        home_team: data['home_team'],
        away_team: data['away_team'],
        bookmaker_last_update: bookmaker_last_update,
        home_moneyline: (data['home_moneyline'] && !data['home_moneyline'].to_s.empty?) ? data['home_moneyline'].to_i : nil,
        away_moneyline: (data['away_moneyline'] && !data['away_moneyline'].to_s.empty?) ? data['away_moneyline'].to_i : nil,
        home_spread_point: (data['home_spread_point'] && !data['home_spread_point'].to_s.empty?) ? data['home_spread_point'].to_f : nil,
        home_spread_price: (data['home_spread_price'] && !data['home_spread_price'].to_s.empty?) ? data['home_spread_price'].to_i : nil,
        away_spread_point: (data['away_spread_point'] && !data['away_spread_point'].to_s.empty?) ? data['away_spread_point'].to_f : nil,
        away_spread_price: (data['away_spread_price'] && !data['away_spread_price'].to_s.empty?) ? data['away_spread_price'].to_i : nil,
        total_point: (data['total_point'] && !data['total_point'].to_s.empty?) ? data['total_point'].to_f : nil,
        over_price: (data['over_price'] && !data['over_price'].to_s.empty?) ? data['over_price'].to_i : nil,
        under_price: (data['under_price'] && !data['under_price'].to_s.empty?) ? data['under_price'].to_i : nil
      }

      game = DkGame.find_by(external_id: external_id)
      if game
        # Update existing record, preserving created_at
        game.update!(attrs.except(:external_id))
        puts "Updated game: #{external_id}"
      else
        # Create new record
        game = DkGame.create!(attrs)
        puts "Created game: #{external_id}"
      end
    end

    puts "Import complete. Processed #{rows.size} rows."
  end
end
