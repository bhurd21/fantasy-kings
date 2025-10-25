namespace :dk_games do
  desc "Update DK games by fetching latest odds and importing them"
  task :update => :environment do
    puts "Starting DK games update..."
    UpdateDkGamesJob.perform_now
    puts "DK games update completed!"
  end

  desc "Queue a DK games update job to run in the background"
  task :queue_update => :environment do
    job = UpdateDkGamesJob.perform_later
    puts "Queued DK games update job with ID: #{job.job_id}"
  end
end
