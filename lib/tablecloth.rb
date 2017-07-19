require 'sinatra/base'
require 'tilt/erubis'
require 'json'
require 'yaml'
require 'octokit'
require 'dotenv'
require 'mongoid'

Mongoid.load!(File.join File.expand_path(__dir__), '..', 'mongoid.yml')

Dotenv.load

require_relative 'tablecloth/helpers'
require_relative 'tablecloth/repo'

module Tablecloth
  class App < Sinatra::Base
    helpers do
      include Tablecloth::Helpers
    end
    
    before do
      @client ||= Octokit::Client.new(:access_token => ENV['GITHUB_ACCESS_TOKEN'])
    end
    
    post '/trigger' do
      @payload = JSON.parse(params['payload'])
            
      case request.env['HTTP_X_GITHUB_EVENT']
      when "pull_request"
        if @payload["action"] == "opened"
          name = @payload["pull_request"]['base']['repo']['full_name']
          sha = @payload["pull_request"]['head']['sha']
          repo = Repo.find_or_create_by(slug: name)
          repo.sha = sha
          repo.save
          trigger_status(name, sha, 'pending', 'Tablecloth is waiting for your coverage report')
        end
      end
    end
    
    post '/coverage/:username/:slug' do
      @result = JSON.parse(params[:result][:covered_percent])
      slug = [params[:username], params[:slug]].join('/')
      # Get coverage from DB (Redis or whatever)
      repo = Repo.find_by(slug: slug)
      coverage = repo.coverage.to_f
      # Check coverage percentage change
      if coverage == 0.0
        trigger_status(repo.slug, repo.sha, 'success', "Coverage is #{@result}%")
      elsif @result >= coverage
        change = @result - coverage
        trigger_status(repo.slug, repo.sha, 'success', "Coverage increased by #{change}% to #{@result}%")
      else
        change = coverage - @result
        trigger_status(repo.slug, repo.sha, 'failure', "Coverage decreased by #{change}% to #{@result}%")
      end
    end

    # start the server if ruby file executed directly
    run! if app_file == $0

    not_found do
      status 404
      @title = '404'
      erb :oops
    end
  end
end
