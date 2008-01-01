# Adds easy defaults to writing Atom feeds with the Builder template engine (this does not work on ERb or any other
# template languages).
module AtomFeedHelper
  # Available Options:
  #
  #   :root_url - Adds a <link rel="alternate" type="text/html" ... /> tag for the feed.
  #   :url - Adds a <link rel="self" type="application/atom+xml" ... /> tag for the feed.
  #
  def atom_feed(options = {}, &block)
    xml = options[:xml] || eval("xml", block.binding)
    xml.instruct!

    xml.feed "xml:lang" => "en-US", "xmlns" => 'http://www.w3.org/2005/Atom' do
      xml.id("tag:#{request.host},#{Time.now.utc.year}:#{request.request_uri.split(".")[0].gsub("/", "")}")
      
      if options[:root_url] || respond_to?(:root_url)
        xml.link(:rel => 'alternate', :type => 'text/html', :href => options[:root_url] || root_url)
      end

      if options[:url]
        xml.link(:rel => 'self', :type => 'application/atom+xml', :href => options[:url])
      end

      yield AtomFeedBuilder.new(xml, self)
    end
  end


  protected
    class AtomFeedBuilder
      def initialize(xml, view)
        @xml, @view = xml, view
      end

      # Available Options:
      #
      #   :url - Adds a <link rel="alternate" type="text/html" ... /> tag for the given record.
      #   :published - Uses the given field to set the <published> tag value.  Defaults to #created_at.
      def entry(record, options = {})
        published = record.created_at if record.respond_to?(:created_at)

        @xml.entry do
          @xml.id("tag:#{@view.request.host_with_port},#{(published || Time.now.utc).year}:#{record.class}#{record.id}")
          @xml.published(published.xmlschema) if published
          @xml.updated(record.updated_at.xmlschema) if record.respond_to?(:updated_at)

          yield @xml

          @xml.link(:rel => 'alternate', :type => 'text/html', :href => options[:url] || @view.polymorphic_url(record))
        end
      end

      private
        def method_missing(method, *arguments, &block)
          @xml.__send__(method, *arguments, &block)
        end
    end
end