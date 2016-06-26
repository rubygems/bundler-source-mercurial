# frozen_string_literal: true
require "spec_helper"

describe "installs", :focused do
  it "a simple repo" do
    build_hg "foo-hg"

    install_gemfile <<-G
      plugin "bundler-source-mercurial", :git => "#{root}"

      source "#{lib_path("foo-hg-1.0")}", :type => "mercurial" do
        gem "foo-hg"
      end
    G
    expect(out).to include("Bundle complete!")

    should_be_installed "foo-hg 1.0"
  end
end
