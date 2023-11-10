module JobStatus
    def self.job_is_running?(exclude: )
        #{#{ pass exclude array}}
        return true if JobStatus.observations_fetch_job_is_running? && (exclude != 'observations_fetch_job')
        return true if JobStatus.observations_create_job_is_running? && (exclude != 'observations_create_job')
        return true if JobStatus.observations_gbif_fetch_job_is_running? && exclude != 'observations_gbif_fetch_job'
        return true if JobStatus.observations_gbif_delete_job_is_running? && exclude != 'observations_gbif_delete_job'

        return false
    end
    def self.observations_fetch_job_is_running?
        job = Delayed::Job.where(failed_at: nil).find_by_queue("observations_#{Rails.env}_queue_observations_fetch")
        if job.present?
            return true
        end
        return false
    end

    def self.observations_create_job_is_running?
        job = Delayed::Job.where(failed_at: nil).find_by_queue("observations_#{Rails.env}_queue_observations_create")
        if job.present?
            return true
        end
        return false
    end

    def self.observations_gbif_fetch_job_is_running?
        job = Delayed::Job.where(failed_at: nil).find_by_queue("observations_#{Rails.env}_queue_gbif_observations_fetch")
        if job.present?
            return true
        end
        return false
    end

    def self.observations_gbif_delete_job_is_running?
        job = Delayed::Job.where(failed_at: nil).find_by_queue("observations_#{Rails.env}_queue_gbif_observations_delete")
        if job.present?
            return true
        end
        return false
    end
end
