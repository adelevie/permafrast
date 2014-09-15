#!/usr/bin/env ruby 
# app.rb
require 'sinatra'
require 'sinatra/base'
require './environments'
require 'curb'
require 'json'
require 'fastcase'
require 'sinatra/activerecord'
require 'sinatra/contrib/all'
require 'redcarpet'
require 'github/markup'
require 'pry'

if settings.development?
  require 'dotenv'
  Dotenv.load
end

# Autoload everything in models and use cases folder
["models", "use_cases"].each do |target|
  Dir[File.dirname(__FILE__) + "/#{target}/**/*.rb"].each do |file| 
    puts "including #{file}"
    require file
  end
end

configure :production do
  host = ENV['HOST'] || 'permafrast.herokuapp.com'
  
  set :host, host
  set :force_ssl, true
end

before(/.*/) do
  if request.url.match(/.json$/)
    request.accept.unshift('application/json')
    request.path_info = request.path_info.gsub(/.json$/,'')
  end
end

class App < Sinatra::Base
  register Sinatra::Contrib
  register Sinatra::ActiveRecordExtension

  get '/' do
    file = 'readme.md'
    @homepage ||= GitHub::Markup.render(file, File.read(file))
  end

  get '/:vol/:reporter/:page' do
    data = Cacher.new(
      volume: params["vol"],
      reporter: params["reporter"],
      page: params["page"]
    ).cache!

    respond_to do |f|
      f.json do
        [data].to_json(only:[
          :volume,
          :reporter,
          :page,
          :url,
          :full_citation
        ])
      end

      f.html do
        erb :app, :locals => {"out"=>data}
      end
    end
  end

  get '/:vol/:reporter/:page/redirect' do
    data = Cacher.new(
      volume: params["vol"],
      reporter: params["reporter"],
      page: params["page"]
    ).cache!

    redirect data.url
  end

  run! if app_file == $0
end