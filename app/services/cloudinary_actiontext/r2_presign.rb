require "uri"

module CloudinaryActiontext
  class R2Presign
    TTL_SECONDS = 300
    class InvalidUrl < StandardError; end

    def initialize(blob:, service:, endpoint: ENV.fetch("R2_ENDPOINT"), bucket: ENV.fetch("R2_BUCKET"))
      @blob, @service, @endpoint, @bucket = blob, service, URI(endpoint), bucket
    end

    def url
      generated = service.url(blob.key, expires_in: TTL_SECONDS, disposition: :inline, content_type: blob.content_type)
      validate!(generated)
      generated
    end

    private

    attr_reader :blob, :service, :endpoint, :bucket

    def validate!(value)
      uri = URI(value)
      expected_path = "/#{bucket}/#{URI::DEFAULT_PARSER.escape(blob.key)}"
      query = URI.decode_www_form(uri.query.to_s).to_h
      valid = uri.scheme == "https" && uri.host == endpoint.host && uri.port == 443 && uri.userinfo.nil? && uri.fragment.nil? && uri.path == expected_path && query.key?("X-Amz-Algorithm") && query.key?("X-Amz-Signature")
      raise InvalidUrl, "R2 presign did not match the configured blob authority" unless valid
    rescue URI::InvalidURIError
      raise InvalidUrl, "R2 presign did not match the configured blob authority"
    end
  end
end
