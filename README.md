# Bundler::Source::Mercurial

This is a source plugin for Bundler that can be used to install gems from a mercurial repository.

**Note**: _The source plugins are not yet avaiable on Bundler master. To use this, you need to checkout from the working PR [bundler/bundler#4674](https://github.com/bundler/bundler/pull/4674)_

## Installation

## Usage

Until it is released to rubygems, add this line to your application's Gemfile:

```ruby
plugin 'bundler-source-mercurial', :git => https://github.com/bundler/bundler-source-mercurial
```

To declare gem that use mercurial, you have add the to a `source` block in your Gemfile with `:type => "mercurial"`

```ruby
source "uri://of/the/mercurial/repo", :type => "mercurial" do
    gem "foo-hg"
end
```

The plugins system for bundler is also in pre-release state. To activate the plugins system execute:

    $ bundle config plugins true

And then execute:

    $ bundle install

## Development

After checking out the repo, run `bin/setup` to install dependencies.

Since the source plugins are not yet merged, you need to have a local checkout of the PR. Then export the path of `lib` to env var `BUNDLE_LIB`.

Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bundler/bundler-source-mercurial. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

