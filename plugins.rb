# frozen_string_literal: true
require "bundler/source/mercurial"

Bundler::Plugin::API.source "mercurial", Bundler::Source::Mercurial
