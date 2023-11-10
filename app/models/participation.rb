require_relative '../../lib/participation/neighboring_region_participation.rb'

class Participation < ApplicationRecord
  include CountableStatistics

  #
  # each region which participates in a contest must have
  # a participation object
  #

  scope :in_competition, -> { where status: Participation.statuses[:accepted] }
  scope :in_progress, -> { where "participations.starts_at < ? AND participations.last_submission_accepted_at > ?", Time.now, Time.now }

  scope :ordered_by_observations_count, -> { order observations_count: :desc }
  scope :base_region_participations, -> { where base_participation_id: nil }
  scope :neighboring_region_participations, -> { where.not(base_participation_id: nil) }

  belongs_to :user, optional: true
  belongs_to :region
  belongs_to :contest
  has_and_belongs_to_many :data_sources
  has_and_belongs_to_many :observations
  has_many :neighboring_region_participations, class_name: 'Participation', foreign_key: 'base_participation_id', dependent: :delete_all

  after_save :set_start_and_end_times

  # after_save :update_neighboring_region_participation

  enum status: [:submitted, :accepted, :refused, :removed_by_admin, :removed_by_region] 

  def set_start_and_end_times
    #
    # contest model start and end datetimes are not utc- they refer to the time in the local time of each region. 
    # the actual start and end are those datetimes in the timezone of the region, in utc.
    #

    offset = region.timezone_offset_mins.nil? ? 0 : (region.timezone_offset_mins.abs*60)
    if region.timezone_offset_mins<0
      update_column :starts_at, (contest.starts_at + offset)
      update_column :ends_at, (contest.ends_at + offset)
      update_column :last_submission_accepted_at, (contest.last_submission_accepted_at + offset)
    else
      update_column :starts_at, (contest.starts_at - offset)
      update_column :ends_at, (contest.ends_at - offset)
      update_column :last_submission_accepted_at, (contest.last_submission_accepted_at - offset)
    end       

    Rails.logger.info "\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> timings debug"
    Rails.logger.info "contest starts at #{contest.starts_at.strftime '%Y/%m/%d %H:%M'} in each region"
    Rails.logger.info "region timezone difference #{region.timezone_offset_mins} minutes = #{region.timezone_offset_mins/60} hours"
    Rails.logger.info "offset in seconds = #{offset}"
    Rails.logger.info "participation starts at #{starts_at}"
    Rails.logger.info "\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> timings debug"

    contest.set_utc_start_and_end_times
  end

  def is_active?
    return last_submission_accepted_at.present? && last_submission_accepted_at >= Time.now.utc
  end


  ### Return participation specific data
  def format_data(params:)

    ### Region specific data
    region_hash = RegionSerializer.new(region).serializable_hash[:data][:attributes]
    region_scores = region.get_region_scores
    region_hash.merge!(region_scores)

    ## Participation data i.e. Region's data related to given contest
    participation_hash = ParticipationSerializer.new(self, {params: { include_top_species:params[:include_top_species],
       include_top_people:params[:include_top_people] }}).serializable_hash[:data][:attributes]

    region_hash.merge!(participation_hash)

    ## Include the recent sightings data only if recent_sightings query param value is 'true'
    if params[:include_recent_sightings] == true
      result = Observation.get_search_results region.id, contest.id, '', params[:nstart], params[:nend], params[:category]
      observations = result[:observations]
      recent_sightings = Hash.new([])
      recent_sightings[:recent_sightings] = observations.map { |obs|
          ObservationSerializer.new(obs).serializable_hash[:data][:attributes]
      }
      region_hash.merge!(recent_sightings)
    end

    return region_hash
  end


  # Add or update neighboring regions' participations
  def update_neighboring_region_participation
    return if base_participation_id.present?

    neighboring_regions = region.neighboring_regions

    # Create or update locality
    neighboring_regions.each do |nr|
      existing_nr_participation = nr.participations&.where(base_participation_id: id).first
      nr_participation = NeighboringRegionParticipation.new(self, nr.id, existing_nr_participation)
      nr_participation = nr_participation.get_participation()
      nr_participation.save
    end
  end

  rails_admin do
    list do
      scopes [:base_region_participations]
      field :id
      field :region          
      field :contest
      field :status
      field :data_sources
      field :created_at     
    end
    edit do
      field :region
      field :contest
      field :status
      field :data_sources
      # field :data_sources do
      #   associated_collection_scope do
      #     participation = bindings[:object]
      #     Proc.new { |scope|
      #       scope = scope.where.not(name: 'gbif')
      #     }
      #   end
      # end
    end
    show do
      field :id
      field :region
      field :contest
      field :status
      field :data_sources
      field :created_at     
    end    
  end

end
