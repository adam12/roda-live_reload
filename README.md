# Roda Live Reload

A very primitive live-reload mechanism for Roda.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "roda-live_reload"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install roda-live_reload

## Usage

After enabling the plugin, simply call `r.live_reload` inside your routing tree. You'll
likely want to only enable it during development.


```ruby
class App < Roda
  development = ENV.fetch("RACK_ENV", "development") == "development"

  plugin :live_reload if development

  route do |r|
    r.live_reload if development

    r.root { "Root" }
  end
end
```

## Caveats

Live Reloading mechanism may not work with Webrick. Tested with Puma.

A new SIGINT trap is set per request, possibly bulldozing any previously set SIGINT.
This may not be an issue for most, but it's something to be aware of.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/adam12/roda-live_reload.

I love pull requests! If you fork this project and modify it, please ping me to see
if your changes can be incorporated back into this project.

That said, if your feature idea is nontrivial, you should probably open an issue to
[discuss it](http://www.igvita.com/2011/12/19/dont-push-your-pull-requests/)
before attempting a pull request.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
