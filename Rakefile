#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Victorykit::Application.load_tasks

task :default => ['jslint', 'spec:smoke'] #remember, these are *appended* to the existing default tasks

namespace :spec do
  task :all => ['spec', 'spec:smoke']
end
