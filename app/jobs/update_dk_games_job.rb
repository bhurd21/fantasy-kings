require 'net/http'
require 'uri'
require 'json'

class UpdateDkGamesJob < ApplicationJob
  queue_as :default

  API_KEY = "a2db116fab50bf0df3e4c6cba830c772".freeze
  BASE_URL = "https://api.the-odds-api.com/v4/sports".freeze
  SPORTS = {
    'nfl' => 'americanfootball_nfl',
    'ncaaf' => 'americanfootball_ncaaf',
    'ncaab' => 'basketball_ncaab'
  }.freeze

  def perform
    Rails.logger.info "Starting DK games update job"
    
    begin
      all_games = fetch_and_process_odds
      import_games(all_games)
      Rails.logger.info "DK games update job completed successfully"
    rescue => e
      Rails.logger.error "DK games update job failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise e
    end
  end

  private

  def fetch_and_process_odds
    all_games = []
    
    SPORTS.each do |sport_key, sport_api|
      Rails.logger.info "Fetching #{sport_key.upcase} odds..."
      
      odds_data = fetch_sport_odds(sport_api)
      if odds_data.any?
        flattened_games = flatten_odds(odds_data, sport_key)
        all_games.concat(flattened_games)
        Rails.logger.info "Processed #{flattened_games.size} #{sport_key.upcase} games with DraftKings data"
      end
    end
    
    Rails.logger.info "Total games processed: #{all_games.size}"
    all_games
  end

  def fetch_sport_odds(sport)
    uri = URI("#{BASE_URL}/#{sport}/odds")
    params = {
      api_key: API_KEY,
      regions: 'us',
      markets: 'h2h,spreads,totals',
      oddsFormat: 'american',
      dateFormat: 'iso'
    }
    uri.query = URI.encode_www_form(params)

    # Make HTTP request
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    # Use strict SSL verification in production, relaxed in development/test
    http.verify_mode = Rails.env.production? ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE
    
    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    
    unless response.code == '200'
      Rails.logger.error "Failed to get #{sport} odds: #{response.code}"
      return []
    end

    odds_data = JSON.parse(response.body)
    
    # Save odds snapshot to file
    save_odds_snapshot(response.body, sport)
    
    remaining_requests = response['x-requests-remaining']
    Rails.logger.info "Retrieved #{odds_data.size} events, #{remaining_requests || 'N/A'} requests remaining"
    
    odds_data
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse odds API response: #{e.message}"
    []
  rescue => e
    Rails.logger.error "Error fetching odds for #{sport}: #{e.message}"
    []
  end

  def flatten_odds(odds_data, sport)
    flattened = []
    
    odds_data.each do |game|
      dk_data = get_draftkings_data(game)
      next unless dk_data

      home_team = game['home_team']
      away_team = game['away_team']
      market_data = extract_market_data(dk_data['markets'] || [], home_team, away_team)

      flat_game = {
        'id' => game['id'],
        'sport' => sport,
        'commence_time' => game['commence_time'],
        'home_team' => home_team,
        'away_team' => away_team,
        'bookmaker_last_update' => dk_data['last_update']
      }.merge(market_data)

      flattened << flat_game
    end
    
    flattened
  end

  def get_draftkings_data(game)
    bookmakers = game['bookmakers'] || []
    bookmakers.find { |bm| bm['key'] == 'draftkings' }
  end

  def extract_market_data(markets, home_team, away_team)
    data = {
      'home_moneyline' => nil, 'away_moneyline' => nil,
      'home_spread_point' => nil, 'home_spread_price' => nil,
      'away_spread_point' => nil, 'away_spread_price' => nil,
      'total_point' => nil, 'over_price' => nil, 'under_price' => nil
    }

    markets.each do |market|
      key = market['key']
      outcomes = market['outcomes'] || []
      
      outcomes.each do |outcome|
        name = outcome['name']
        price = outcome['price']
        point = outcome['point']

        case key
        when 'h2h'
          if name == home_team
            data['home_moneyline'] = price
          elsif name == away_team
            data['away_moneyline'] = price
          end
        when 'spreads'
          if name == home_team
            data['home_spread_point'] = point
            data['home_spread_price'] = price
          elsif name == away_team
            data['away_spread_point'] = point
            data['away_spread_price'] = price
          end
        when 'totals'
          if name == 'Over'
            data['total_point'] = point
            data['over_price'] = price
          elsif name == 'Under'
            data['under_price'] = price
          end
        end
      end
    end

    data
  end

  def import_games(games_data)
    Rails.logger.info "Importing #{games_data.size} games"
    
    imported_count = 0
    updated_count = 0
    failed_count = 0
    
    games_data.each do |game_data|
      begin
        external_id = game_data['id']
        unless external_id.present?
          Rails.logger.warn "Skipping game with missing external_id"
          failed_count += 1
          next
        end

        # Parse sport
        sport = parse_sport(game_data['sport'])
        unless sport
          Rails.logger.warn "Skipping game with unknown sport: #{game_data['sport']}"
          failed_count += 1
          next
        end

        # Parse times
        commence_time = parse_time(game_data['commence_time'])
        bookmaker_last_update = parse_time(game_data['bookmaker_last_update'])

        attrs = build_game_attributes(game_data, external_id, sport, commence_time, bookmaker_last_update)

        if upsert_game(external_id, attrs)
          game = DkGame.find_by(external_id: external_id)
          if game.created_at == game.updated_at
            imported_count += 1
          else
            updated_count += 1
          end
        else
          failed_count += 1
        end

      rescue => e
        Rails.logger.error "Failed to process game #{external_id}: #{e.message}"
        failed_count += 1
      end
    end

    Rails.logger.info "Import completed: #{imported_count} created, #{updated_count} updated, #{failed_count} failed"
  end

  def parse_sport(sport_value)
    case sport_value&.downcase
    when 'nfl' then 'nfl'
    when 'ncaaf' then 'ncaaf'
    when 'ncaab' then 'ncaab'
    else nil
    end
  end

  def parse_time(time_string)
    return nil unless time_string.present?
    Time.parse(time_string)
  rescue ArgumentError
    nil
  end

  def build_game_attributes(game_data, external_id, sport, commence_time, bookmaker_last_update)
    {
      external_id: external_id,
      sport: sport,
      commence_time: commence_time,
      home_team: game_data['home_team'],
      away_team: game_data['away_team'],
      bookmaker_last_update: bookmaker_last_update,
      home_moneyline: parse_integer(game_data['home_moneyline']),
      away_moneyline: parse_integer(game_data['away_moneyline']),
      home_spread_point: parse_float(game_data['home_spread_point']),
      home_spread_price: parse_integer(game_data['home_spread_price']),
      away_spread_point: parse_float(game_data['away_spread_point']),
      away_spread_price: parse_integer(game_data['away_spread_price']),
      total_point: parse_float(game_data['total_point']),
      over_price: parse_integer(game_data['over_price']),
      under_price: parse_integer(game_data['under_price'])
    }
  end

  def upsert_game(external_id, attrs)
    game = DkGame.find_by(external_id: external_id)
    if game
      game.update!(attrs.except(:external_id))
    else
      DkGame.create!(attrs)
    end
    true
  rescue => e
    Rails.logger.error "Failed to save game #{external_id}: #{e.message}"
    false
  end

  def parse_integer(value)
    return nil if value.nil? || value.to_s.empty?
    value.to_i
  end

  def parse_float(value)
    return nil if value.nil? || value.to_s.empty?
    value.to_f
  end

  def save_odds_snapshot(json_response, sport)
    timestamp = Time.current.strftime("%m-%d-%Y-%I-%M-%p")
    filename = "odds-snapshot-#{sport}-#{timestamp}.json"
    filepath = Rails.root.join('db', 'odds-history', filename)
    
    File.write(filepath, json_response)
    Rails.logger.info "Saved odds snapshot to #{filepath}"
  rescue => e
    Rails.logger.error "Failed to save odds snapshot: #{e.message}"
  end
end
