# frozen_string_literal: true
require "spec_helper"

describe Bundler::Source::Mercurial do
  Mercurial = Bundler::Source::Mercurial

  before(:all) do
    Mercurial.include Bundler::Plugin::API::Source
  end

  subject(:source) { Mercurial.new(opts) }

  let(:opts) { {"uri" => "uri://to/test", "type" => "mercurial"} }

  it "has a version number" do
    expect(Bundler::Source::Mercurial::VERSION).not_to be nil
  end

  it "default ref is 'default'" do
    expect(source.ref).to eq("default")
  end

  describe "options to lock" do

    subject(:lock_options) { source.options_to_lock }

    let(:revision) { "b0a710addeadbeef70ffee" }

    before do
      allow(source).to receive(:revision).and_return(revision)
    end

    it "returns revision and ref" do
      expect(lock_options).
        to eq("revision" => revision, "ref" => "default")
    end

    context "with branch" do
      let(:opts) { super().merge("branch" => "foo-fix") }

      it "locks the branch as ref" do
        expect(lock_options).
          to eq("revision" => revision, "ref" => "foo-fix")
      end
    end

    context "with tag" do
      let(:opts) { super().merge("tag" => "v1.2.3") }

      it "locks the tag as ref" do
        expect(lock_options).
          to eq("revision" => revision, "ref" => "v1.2.3")
      end
    end
  end

  describe "#unlock!" do
    it "refreshes the revision" do
      expect(source).to receive(:latest_revision).once

      source.unlock!
    end
  end

  describe "comparision methods" do
    subject(:second) { Mercurial.new(opts) }

    context "different revision" do
      before do
        allow(source).to receive(:revision).and_return("first_ref")
        allow(second).to receive(:revision).and_return("second_ref")
      end

      it "== returns equal" do
        expect(source == second).to be true
      end

      it "eql? returns equal" do
        expect(source.eql?(second)).to be true
      end

      it "returns equal hash" do
        expect(source.hash).to eq(second.hash)
      end
    end
  end
end
