# frozen_string_literal: true
require "listen"

module Roda::RodaPlugins
  module LiveReload
    module ResponseMethods
      INJECT = <<~EOM
      <script>
        (function reconnect() {
          var xhr = new XMLHttpRequest();

          xhr.open("GET", "/_live_reload", true);

          xhr.onprogress = function() {
            window.location.reload();
          };

          xhr.onerror = function() {
            console.log("Reconnecting after error");
            setTimeout(reconnect, 1000);
          };

          xhr.onabort = function() {
            console.log("Reconnecting after abort");
            setTimeout(reconnect, 1000);
          };

          xhr.send();
        })();
      </script>
      EOM

      def finish
        status, headers, content = super

        content = content.map do |chunk|
          if chunk.include?("</body>")
            chunk.sub("</body>", INJECT + "</body>")
          else
            chunk
          end
        end

        headers["Content-Length"] = content.reduce(0) { |memo, chunk| memo + chunk.size }.to_s

        [status, headers, content]
      end
    end

    module RequestMethods
      def live_reload(opts = {}, &block)
        on("_live_reload") do
          reader, writer = IO.pipe

          LiveReload.synchronize do
            LiveReload.listeners.push(writer)
          end

          scope.stream(loop: true) do |out|
            out << reader.gets
          end
        end
      end
    end

    def self.mutex
      @mutex ||= Mutex.new
    end

    def self.synchronize
      mutex.synchronize { yield }
    end

    def self.listeners
      @listeners ||= []
    end

    def self.load_dependencies(app, opts = {})
      app.plugin :streaming
    end

    def self.configure(app, opts = {})
      listener = Listen.to("assets", "views") do |modified, added, removed|
        puts "Changes", modified, added, removed

        LiveReload.listeners.each do |writer|
          writer.puts "Changes"
        end
      end

      listener.start
    end
  end

  register_plugin :live_reload, LiveReload
end
