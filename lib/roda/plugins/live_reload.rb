# frozen_string_literal: true
require "listen"

module Roda::RodaPlugins # :nodoc:
  # The live_reload plugin provides a chunked-body endpoint and injects a
  # long-polling JavaScript function just before the closing body tag.
  #
  #   plugin :live_reload
  #
  #   route do |r|
  #     r.live_reload
  #   end
  #
  # = Plugin Options
  #
  # The following plugin options are supported:
  #
  # :watch :: Array of folders to watch. Defaults to +assets+, +views+
  #
  module LiveReload
    module ResponseMethods # :nodoc:
      INJECT = <<~EOM # :nodoc:
      <script>
        (function reconnect() {
          var xhr = new XMLHttpRequest();

          xhr.open("GET", "/_live_reload", true);

          xhr.onprogress = function(e) {
            /* Try to prevent memory leak */
            if (e.loaded > 1000) {
              window.location.reload();
            }
          };

          xhr.onload = function(e) {
            window.location.reload();
          };

          xhr.onerror = function() {
            console.log("Reconnecting after error");
            setTimeout(reconnect, 1000);
          };

          window.addEventListener("beforeunload", function(e) {
            xhr.abort();
          }, true);

          xhr.send();
        })();
      </script>
      EOM

      def finish # :nodoc:
        status, headers, content = super

        content = content.map do |chunk|
          if chunk.include?("</head>")
            chunk.sub("</head>", INJECT + "</head>")
          else
            chunk
          end
        end

        headers["Content-Length"] = content.reduce(0) { |memo, chunk| memo + chunk.bytesize }.to_s

        [status, headers, content]
      end
    end

    module RequestMethods
      # Setup the live reload endpoint
      def live_reload(opts = {}, &block)
        on("_live_reload") do
          logger.info "Live Reload listener attached" if logger
          reader, writer = IO.pipe

          LiveReload.synchronize do
            LiveReload.listeners.push(writer)
          end

          # I wish Rack would provide a shutdown indicator
          trap(:INT) { exit }

          scope.stream(loop: true) do |out|
            if IO.select([reader], nil, nil, 1)
              out.close
            else
              out << 0
            end
          end

          LiveReload.synchronize do
            LiveReload.listeners.delete(writer)
          end
        end
      end
    end

    def self.mutex # :nodoc:
      @mutex ||= Mutex.new
    end

    def self.synchronize # :nodoc:
      mutex.synchronize { yield }
    end

    def self.listeners # :nodoc:
      @listeners ||= []
    end

    def self.load_dependencies(app, opts = {}) # :nodoc:
      app.plugin :streaming
    end

    def self.configure(app, opts = {}) # :nodoc:
      watch = opts.delete(:watch) || ["assets", "views"]

      puts "Watching #{watch} for changes"

      listener = Listen.to(*watch) do |modified, added, removed|
        puts "Changes", modified, added, removed

        LiveReload.listeners.each do |writer|
          begin
            writer << 1
          rescue Errno::EPIPE
            LiveReload.synchronize do
              LiveReload.listeners.delete(writer)
            end
          end
        end
      end

      listener.start
    end
  end

  register_plugin :live_reload, LiveReload
end
