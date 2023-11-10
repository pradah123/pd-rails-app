class RemoveDuplicates < ActiveRecord::Migration[7.0]
  def change

    contests_sql = 'with cte as (
        select
            id,
            row_number() over(partition by contest_id, observation_id order by id desc) as duplicate_count
          from contests_observations
        )
        delete from contests_observations
        where id in (select id from cte where duplicate_count > 1);'
    ActiveRecord::Base.connection.execute(contests_sql)

    participations_sql = 'with cte as (
        select
            id,
            row_number() over(partition by participation_id, observation_id order by id desc) as duplicate_count
          from observations_participations
        )
        delete from observations_participations
        where id in (select id from cte where duplicate_count > 1);'
    ActiveRecord::Base.connection.execute(participations_sql)

    regions_sql = 'with cte as (
        select
            id,
            row_number() over(partition by region_id, observation_id order by id desc) as duplicate_count
          from observations_regions
        )
        delete from observations_regions
        where id in (select id from cte where duplicate_count > 1);'
    ActiveRecord::Base.connection.execute(regions_sql)

    observations_sql = 'with cte as (
          select
              id,
              row_number() over(partition by unique_id order by id desc) as duplicate_count
            from observations
          )
          delete from observations
          where id in (select id from cte where duplicate_count > 1);'
    ActiveRecord::Base.connection.execute(observations_sql)

    add_index :contests_observations, [:contest_id, :observation_id],
               unique: true, name: 'contests_observations_ukey'
    add_index :observations_participations, [:participation_id, :observation_id],
               unique: true, name: 'observations_participations_ukey'
    add_index :observations_regions, [:region_id, :observation_id],
               unique: true, name: 'observations_regions_ukey'

    ## observations indexes
    add_index :observations, :search_text
    add_index :observations, :unique_id, unique: true

    ## Contests indexes
    add_index :contests, :title
    add_index :contests, :slug

    ## Regions indexes
    add_index :regions, :name
    add_index :regions, :slug

    ## Reset statistics
    Region.all.each        { |r| r.reset_statistics }
    Participation.all.each { |p| p.reset_statistics }
    Contest.all.each       { |c| c.reset_statistics }

   end
end
