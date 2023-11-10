class NeighboringRegionParticipation
  def initialize(base_participation, region_id, existing_participation = nil)
    @base_participation = base_participation
    @region_id = region_id
    @existing_participation = existing_participation
  end

  # get_participation() -> Participation
  def get_participation
    # NOTE: If participation does not exists, create new participation
    p = @existing_participation || Participation.new()
    p.base_participation_id = @base_participation.id
    p.region_id = @region_id
    p.contest = @base_participation.contest
    p.status = @base_participation.status
    p.data_sources = @base_participation.data_sources
    p.starts_at = @base_participation.starts_at
    p.ends_at = @base_participation.ends_at
    p.last_submission_accepted_at = @base_participation.last_submission_accepted_at

    return p    
  end
end
