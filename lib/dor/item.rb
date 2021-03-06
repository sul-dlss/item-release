require 'retries'

module Dor::Release
  class Item
    attr_accessor :druid, :fetcher

    def initialize(params = {})
      # Takes a druid, either as a string or as a Druid object.
      @druid = params[:druid]
      skip_heartbeat = params[:skip_heartbeat] || false
      @fetcher = DorFetcher::Client.new(service_url: Dor::Config.release.fetcher_root, skip_heartbeat: skip_heartbeat)
    end

    def object
      @object ||= Dor.find(@druid)
    end

    def members
      # rubocop:disable Style/UnneededCondition
      # See https://github.com/rubocop-hq/rubocop/issues/6668
      if @members

        @members # return cached instance variable

      else # if members have not been fetched and cached for this object yet, fetch them

        with_retries(max_tries: Dor::Config.release.max_tries, base_sleep_seconds: Dor::Config.release.base_sleep_seconds, max_sleep_seconds: Dor::Config.release.max_sleep_seconds) do |_attempt|
          @members = @fetcher.get_collection(@druid) # cache members in an instance variable
        end

      end
      # rubocop:enable Style/UnneededCondition
    end

    def item_members
      members['items'] || []
    end

    def sub_collections
      unless @sub_collections
        @sub_collections = []
        @sub_collections += members['sets'] if members['sets']
        @sub_collections += members['collections'] if members['collections']
        @sub_collections.delete_if { |collection| collection['druid'] == druid } # if this is a collection, do not include yourself in the sub-collection list
      end
      @sub_collections
    end

    def object_type
      unless @obj_type
        obj_type = object.identityMetadata.objectType
        @obj_type = (obj_type.nil? ? 'unknown' : obj_type.first)
      end
      @obj_type.downcase.strip
    end

    def republish_needed?
      # TODO: implement logic here, presumably by calling a method on dor-services-gem
      false

      # LyberCore::Log.debug "republishing metadata for #{@druid}"
    end

    def is_item?
      object_type.downcase  == 'item'
    end

    def is_collection?
      object_type.downcase  == 'collection'
    end

    def is_set?
      object_type.downcase  == 'set'
    end

    def is_apo?
      object_type.downcase == 'adminpolicy'
    end

    def update_marc_record
      with_retries(max_tries: Dor::Config.release.max_tries, base_sleep_seconds: Dor::Config.release.base_sleep_seconds, max_sleep_seconds: Dor::Config.release.max_sleep_seconds) do |_attempt|
        url = "#{Dor::Config.dor.service_root}/objects/#{@druid}/update_marc_record"
        response = RestClient.post url, {}
        response.code
      end
    end

    def self.add_workflow_for_collection(druid)
      create_workflow(druid)
    end

    def self.add_workflow_for_item(druid)
      create_workflow(druid)
    end

    def self.create_workflow(druid)
      LyberCore::Log.debug "...adding workflow #{Dor::Config.release.workflow_name} for #{druid}"

      # initiate workflow by making workflow service call
      with_retries(max_tries: Dor::Config.release.max_tries, base_sleep_seconds: Dor::Config.release.base_sleep_seconds, max_sleep_seconds: Dor::Config.release.max_sleep_seconds) do |_attempt|
        Dor::Config.workflow.client.create_workflow(Dor::WorkflowObject.initial_repo(Dor::Config.release.workflow_name), druid, Dor::Config.release.workflow_name, Dor::WorkflowObject.initial_workflow(Dor::Config.release.workflow_name), {})
      end
    end
  end # class Item
end # module
