
class FetchObservationOrgUsernameJob < ApplicationJob
  queue_as :queue_fetch_observation_org_username
  
  @@username_cache = {}

  def perform
    Contest.in_progress.each do |contest|
      contest.observations.from_observation_org.has_creator_id.without_creator_name.distinct.pluck(:creator_id).each do |creator_id|
        creator_name = nil
        if creator_id.blank?
          next
        end
        if @@username_cache[creator_id].blank?
          creator_name = Source::ObservationOrg::Repo.fetch_creator_name(creator_id)
          if creator_name.present?
            @@username_cache[creator_id] = creator_name
          else
            Delayed::Worker.logger.error "Could not fetch creator name for creator id: #{creator_id}"
          end
        end
        if creator_name.present?
          contest.observations.from_observation_org.without_creator_name.where(
            creator_id: creator_id
          ).update_all(
            creator_name: creator_name, 
            updated_at: DateTime.now
          )
        end
      end
    end
  end
end
