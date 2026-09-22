require "uri"

module CloudinaryActiontext
  class R2Presign
    TTL_SECONDS = 300
    class InvalidUrl < StandardError; end

    def initialize(blob:, service:, endpoint: ENV.fetch("R2_ENDPOINT"), bucket: ENV.fetch("R2_BUCKET"))
      @blob, @service, @endpoint, @bucket = blob, service, URI(endpoint), bucket
    end

    def url
      generated = service.url(blob.key, expires_in: TTL_SECONDS, disposition: :inline, content_type: blob.content_type, filename: blob.filename)
      validate!(generated)
      generated
    end

    private

    attr_reader :blob, :service, :endpoint, :bucket

    def validate!(value)
      uri = URI(value)
      query = URI.decode_www_form(uri.query.to_s).to_h
      valid = uri.scheme == "https" &&
        uri.port == endpoint.port &&
        uri.userinfo.nil? &&
        uri.fragment.nil? &&
        canonical_location?(uri) &&
        sigv4_query?(query)
      raise InvalidUrl, "R2 presign did not match the configured blob authority" unless valid
    rescue URI::InvalidURIError
      raise InvalidUrl, "R2 presign did not match the configured blob authority"
    end

    def canonical_location?(uri)
      key = URI::DEFAULT_PARSER.escape(blob.key)
      path_style = uri.host == endpoint.host && uri.path == "/#{bucket}/#{key}"
      virtual_hosted = uri.host == "#{bucket}.#{endpoint.host}" && uri.path == "/#{key}"

      path_style || virtual_hosted
    end

    def sigv4_query?(query)
      required = %w[
        X-Amz-Algorithm
        X-Amz-Credential
        X-Amz-Date
        X-Amz-Expires
        X-Amz-SignedHeaders
        X-Amz-Signature
      ]

      query["X-Amz-Algorithm"] == "AWS4-HMAC-SHA256" &&
        required.all? { |key| query[key].present? } &&
        query["X-Amz-Expires"].to_i.between?(1, TTL_SECONDS)
    end
  end
end
