require "assembly/version"

require 'json'
require "ostruct"

require "faraday"
require "faraday_middleware"

require 'assembly/faraday_middleware/assembly_oauth2'
require 'assembly/util'
require 'assembly/config'
require 'assembly/client'
require 'assembly/actions/read'
require 'assembly/actions/list'
require 'assembly/actions/create'
require 'assembly/actions/update'
require 'assembly/actions/delete'
require 'assembly/model'
require 'assembly/api_model'
require 'assembly/resource'
require 'assembly/models/aspect'
require 'assembly/models/assessment'
require 'assembly/models/attendance'
require 'assembly/models/exclusion'
require 'assembly/models/facet'
require 'assembly/models/year_group'
require 'assembly/models/list'
require 'assembly/models/result'
require 'assembly/models/academic_year'
require 'assembly/models/assessment_point'
require 'assembly/models/calendar_event'
require 'assembly/models/contact'
require 'assembly/models/grade'
require 'assembly/models/grade_set'
require 'assembly/models/group'
require 'assembly/models/registration_group'
require 'assembly/models/school_detail'
require 'assembly/models/staff_member'
require 'assembly/models/student'
require 'assembly/models/subject'
require 'assembly/models/teaching_group'

module Assembly
  @config = Config.new

  class << self
    attr_accessor :config

    def configure(options=nil)
      @config.merge(options) if options.is_a?(Hash)
      yield(config) if block_given?
    end

    # nil - standard client
    # Config object - new client with config
    # Hash - new client with config extended by hash
    def client(options=nil)
      @client ||= Client.new
      return @client if options.nil?
      return options if options.is_a?(Client)
      client_config = options.is_a?(Config) ? options : @config.copy_with_overrides(options)
      Client.new(client_config)
    end
  end
end
