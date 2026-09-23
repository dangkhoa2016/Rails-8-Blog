require "digest"

module CloudinaryActiontext
  class Identity
    PREFIX = "d7-actiontext".freeze

    def self.public_id_for(blob)
      digest = Digest::SHA256.hexdigest([ blob.id, blob.key, blob.checksum ].join("\0"))
      "#{PREFIX}/#{digest}"
    end
  end
end
