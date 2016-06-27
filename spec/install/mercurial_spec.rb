# frozen_string_literal: true
require "spec_helper"

describe "installs" do
  it "a simple repo" do
    build_hg "foo-hg"

    install_gemfile <<-G
      source 'file://#{gem_repo1}'

      source "#{lib_path("foo-hg-1.0")}", :type => "mercurial" do
        gem "foo-hg"
      end
    G
    expect(out).to include("Bundle complete!")

    should_be_installed "foo-hg 1.0"
  end
end
