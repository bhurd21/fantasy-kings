namespace :prod_data do
  desc "Create a snapshot of production database"
  task :snapshot do
    system("bin/create_prod_snapshot")
  end

  desc "Sync development database with current production data"
  task :sync do
    system("bin/sync_dev_with_prod")
  end

  desc "List available production backups"
  task :list_backups do
    puts "📋 Available production backups:"
    Dir.glob("db/backups/*.sql").sort.reverse.each do |file|
      size_mb = File.size(file) / 1024.0 / 1024.0
      created = File.mtime(file).strftime("%Y-%m-%d %H:%M:%S")
      puts "  #{File.basename(file)} (#{size_mb.round(2)} MB) - #{created}"
    end
  end

  desc "Clean old backups (keep last 10)"
  task :cleanup do
    backups = Dir.glob("db/backups/*.sql").sort.reverse
    if backups.length > 10
      old_backups = backups[10..-1]
      puts "🧹 Cleaning up #{old_backups.length} old backups..."
      old_backups.each do |file|
        File.delete(file)
        puts "  Deleted: #{File.basename(file)}"
      end
      puts "✅ Cleanup complete"
    else
      puts "📁 No cleanup needed (#{backups.length} backups)"
    end
  end

  desc "Show production database stats"
  task :stats do
    puts "📊 Production database statistics:"
    stats_output = `bin/kamal app exec --quiet 'bin/rails runner "puts \\"Users: \#{User.count}\\"; puts \\"DK Games: \#{DkGame.count}\\"; puts \\"Betting Histories: \#{BettingHistory.count}\\""' 2>/dev/null`.lines.reject { |line|
      line.match?(/ERROR|Failed|exit status|docker stdout|docker stderr|App Host|^\s*$/)
    }.join.strip
    puts stats_output
  end
end
