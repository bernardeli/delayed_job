require 'mongoid'

module Delayed
  module Backend
    module Mongoid
      # A job object that is persisted to the database.
      # Contains the work object as a YAML field.
      class Job < DelayedJob
        # include ::Mongoid::Document
        include Delayed::Backend::Base

        before_save :set_default_run_at

        def self.ready_to_run worker_name, max_run_time
          # where(['(run_at <= ? AND (locked_at IS NULL OR locked_at < ?) OR locked_by = ?) AND failed_at IS NULL', db_time_now, db_time_now - max_run_time, worker_name])
          where("function() {(return this.run_at <= #{db_time_now} && (this.locked_at < #{db_time_now - max_run_time}) || this.locked_by = '#{worker_name}') && !this.failed_at")
          # run_at = where(:run_at.lte => db_time_now).and(:locked_at.lt => db_time_now - max_run_time)
          # locked_by = where(:locked_by => worker_name).and(:failed_at => nil)
          # run_at | locked_by
        end

        def self.worker_priority
          return where(:priority.gte => Worker.min_priority) if Worker.min_priority
          return where(:priority.lte => Worker.max_priority) if Worker.max_priority
          where(:priority.gte => 0)
        end
        
        # scope :by_priority, order('priority ASC, run_at ASC')
        def self.by_priority 
          ascending(:priority).ascending(:run_at)
        end

        def self.before_fork
          # mongoid is cool!
        end

        def self.after_fork
          # mongoid is cool!
        end

        # When a worker is exiting, make sure we don't have any locked jobs.
        def self.clear_locks!(worker_name)
          # update_all("locked_by = null, locked_at = null", ["locked_by = ?", worker_name]) 
          update_all(:locked_by => nil, :locked_at => nil, :locked_by => worker_name)          
        end

        # Find a few candidate jobs to run (in case some immediately get locked by others).
        def self.find_available(worker_name, limit = 5, max_run_time = Worker.max_run_time)
          # scope = scope.scoped(:priority.gte => Worker.min_priority) if Worker.min_priority
          # scope = scope.scoped(:priority.lte => Worker.max_priority) if Worker.max_priority
          ready_to_run(worker_name, max_run_time).worker_priority.by_priority.all(:limit => limit)                    
        end

        # Lock this job for this worker.
        # Returns true if we have the lock, false otherwise.
        def lock_exclusively!(max_run_time, worker)
          now = self.class.db_time_now
          affected_rows = if locked_by != worker
            # We don't own this job so we will update the locked_by name and the locked_at
            # self.class.update_all(["locked_at = ?, locked_by = ?", now, worker], ["id = ? and (locked_at is null or locked_at < ?) and (run_at <= ?)", id, (now - max_run_time.to_i), now])
            self.class.where(:id => id).and(:locked_at.lt => now - max_run_time.to_i).and(:run_at.lte => now).update_all(:locked_at => now, :locked_by => worker).
          else
            # We already own this job, this may happen if the job queue crashes.
            # Simply resume and update the locked_at
            self.class.where(:id => id).and(:locked_by => worker).update_all(:locked_at => now)
          end
          if affected_rows == 1
            self.locked_at = now
            self.locked_by = worker
            self.locked_at_will_change!
            self.locked_by_will_change!
            return true
          else
            return false
          end
        end

        # Get the current time (GMT or local depending on DB)
        # Note: This does not ping the DB to get the time, so all your clients
        # must have syncronized clocks.
        def self.db_time_now
          if Time.zone
            Time.zone.now
          # elsif ::ActiveRecord::Base.default_timezone == :utc
          #   Time.now.utc
          else
            Time.now
          end
        end

      end
    end
  end
end
