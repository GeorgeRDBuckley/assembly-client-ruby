module Assembly
  class Client
    attr_reader :config

    def initialize(config=Assembly.config)
      @config           = config
      @on_token_refresh = nil
      build_api_adapter
    end

    def get(url, params={})
      if_modified_since = params.delete(:since)
      headers = {}
      headers.merge!({ 'IF_MODIFIED_SINCE': if_modified_since }) if if_modified_since

      response = @api.get(url, params, headers)
      ok       = check_errors(response)
      if ok
        response.body
      else
        get(url, params)
      end
    end

    def post(url, params={})
      response = @api.post url, params.to_json
      check_errors(response)
      response.body
    end

    def put(url, params={})
      response = @api.put url, params.to_json
      check_errors(response)
      response.body
    end

    def delete(url)
      response = @api.delete url
      check_errors(response)
      response.status == 200
    end

    def academic_years
      Assembly::AcademicYearResource.new(self)
    end

    def assessments
      Assembly::AssessmentResource.new(self)
    end

    def assessment_points
      Assembly::AssessmentPointResource.new(self)
    end

    def aspects
      Assembly::AspectResource.new(self)
    end

    def calendar_events
      Assembly::CalendarEventResource.new(self)
    end

    def contacts
      Assembly::ContactResource.new(self)
    end

    def grade_sets
      Assembly::GradeSetResource.new(self)
    end

    def groups
      Assembly::GroupResource.new(self)
    end

    def registration_groups
      Assembly::RegistrationGroupResource.new(self)
    end

    def results
      Assembly::ResultResource.new(self)
    end

    def school_details
      Assembly::SchoolDetailResource.new(self)
    end

    def facets
      Assembly::FacetResource.new(self)
    end

    def staff_members
      Assembly::StaffMemberResource.new(self)
    end

    def students
      Assembly::StudentResource.new(self)
    end

    def subjects
      Assembly::SubjectResource.new(self)
    end

    def teaching_groups
      Assembly::TeachingGroupResource.new(self)
    end

    def attendances
      Assembly::AttendanceResource.new(self)
    end

    def exclusions
      Assembly::ExclusionResource.new(self)
    end

    def year_groups
      Assembly::YearGroupResource.new(self)
    end

    def on_token_refresh(&blk)
      @on_token_refresh = blk
    end

    def refresh_token!
      return false unless config.client_id && config.client_secret && config.refresh_token
      refresh_api = Faraday.new(:url => config.auth_host) do |faraday|
        faraday.request :url_encoded
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
      refresh_api.headers[:accept]        = "application/vnd.assembly+json; version=#{config.api_version}"
      refresh_api.headers[:authorization] = refresh_api.basic_auth(config.client_id, config.client_secret)

      response = refresh_api.post('/oauth/token', {
        grant_type:    'refresh_token',
        refresh_token: config.refresh_token
      })
      return false unless check_errors(response)
      config.token = response.body[:access_token]
      build_api_adapter
      @on_token_refresh.call(response.body) if @on_token_refresh
      true
    end

    private

    def check_errors(response)
      status = response.status.to_i
      case status
        when 401
          handle_unauthorized_response(response)
          return false
        when 404
          raise Assembly::NotFoundError.new(response)
        when 422
          raise Assembly::ValidationError.new(response)
        when 429
          raise Assembly::TooManyRequestsError.new(response)
        when 500
          raise Assembly::ServerError.new(response)
      end
      true
    end

    def handle_unauthorized_response(response)
      if response.body[:error] != 'invalid_token'
        raise Assembly::UnauthorizedError.new(response)
      end
      raise Assembly::UnauthorizedError.new(response) unless refresh_token!
    end

    def build_api_adapter
      @api = Faraday.new(:url => config.host) do |faraday|
        faraday.request :json
        faraday.request :assembly_oauth2, config.token
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
      @api.headers[:accept] = "application/vnd.assembly+json; version=#{config.api_version}"
    end
  end

  class ServerError < StandardError
    def initialize(response)
      @response = response
    end

    def status
      @response.status
    end

    def message
      body = @response.body
      if body && body.length > 0
        body[:message]
      else
        "No Error Message - Server response body was empty."
      end
    end

    def to_s
      "[#{status}] #{message}"
    end
  end

  class TooManyRequestsError < ServerError
  end

  class NotFoundError < ServerError
  end

  class UnauthorizedError < ServerError
  end

  class ValidationError < ServerError
    def errors
      @response.body[:errors]
    end

    def to_s
      "#{super} - #{errors.inspect}"
    end
  end
end

module FaradayMiddleware
  class ParseJson
    define_parser do |body|
      ::JSON.parse(body, symbolize_names: true) unless body.strip.empty?
    end
  end
end
