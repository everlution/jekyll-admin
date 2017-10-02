module JekyllAdmin
  # Abstract module to be included in Convertible and Document to provide
  # additional, URL-specific functionality without duplicating logic
  module URLable

    # Absolute URL to the HTTP(S) rendered/served representation of this resource
    def http_url
      return if is_a?(Jekyll::Collection) || is_a?(JekyllAdmin::DataFile)
      return if is_a?(Jekyll::Document) && !collection.write?
      @http_url ||= Addressable::URI.new(
        :scheme => scheme, :host => host, :port => port,
        :path => path_with_base(JekyllAdmin.site.config["baseurl"], url)
      ).normalize.to_s
    end

    # Absolute URL to the API representation of this resource
    def api_url
      @api_url ||= Addressable::URI.new(
        :scheme => scheme, :host => host, :port => port,
        :path => path_with_base("/_api", resource_path)
      ).normalize.to_s
    end

    def entries_url
      return unless is_a?(Jekyll::Collection)
      "#{api_url}/entries"
    end

    private

    # URL path relative to `_api/` to retreive the given resource via the API
    # Note: we can't use a case statement here, because === doesn't like includes
    def resource_path
      if is_a?(Jekyll::Document)
        "/collections/#{relative_path.sub(%r!\A_!, "")}"
      elsif is_a?(Jekyll::Collection)
        "/collections/#{label}"
      elsif is_a?(JekyllAdmin::DataFile)
        "/data/#{relative_path}"
      elsif is_a?(Jekyll::StaticFile)
        "/static_files/#{relative_path}"
      elsif is_a?(Jekyll::Page)
        "/pages/#{relative_path}"
      end
    end

    # URI.join doesn't like joining two relative paths, and File.join may join
    # with `\` rather than with `/` on windows
    def path_with_base(base, path)
      [base, path].join("/").squeeze("/")
    end

    def scheme
      JekyllAdmin.site.config["scheme"] || "http"
    end

    def host
      if JekyllAdmin.site.config["url"]
        Addressable::URI.parse(JekyllAdmin.site.config["url"]).host
      else
        JekyllAdmin.site.config["host"].sub("127.0.0.1", "localhost")
      end
    end

    def port
      if JekyllAdmin.site.config["url"]
        Addressable::URI.parse(JekyllAdmin.site.config["url"]).port
      else
        JekyllAdmin.site.config["port"]
      end
    end
  end
end
