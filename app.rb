$: << File.expand_path(File.join('.', 'lib'))
require 'bundler/setup'
require 'sinatra'
require 'setup'
require 'environment'

before do
  # This needs to be set to allow the JSON to be had over XMLHttpRequest
  headers 'Access-Control-Allow-Origin' => '*'
end

get '/ajax/submit.json' do
  content_type(:json)
  redis = settings.redis
  email, url = params.values_at(:email, :url)
  User.limit(redis, email, 60) do
    key = Digest::SHA1.hexdigest([email, url, Time.now.to_s].join(':'))
    message = { email: email, url: url, key: key }
    redis.set(key, 'Working...')
    settings.async.extractor << message
    { :message => 'Submitted! Hang tight...', :id => key }.to_json
  end
end

get '/ajax/status/:id.json' do |id|
  content_type(:json)
  status = settings.redis.get(id)
  done = !status.match(/done|failed|limited/i).nil?
  { message: status, done: done }.to_json
end

get '/static/bookmarklet.js' do
  content_type(:js)
  settings.bookmarklet
end

get '/?' do
  haml(:index)
end

get '/kindle-email' do
  haml(:kindle_email, :layout => false)
end

get %r{/(firefox|safari|chrome|ie|ios)} do |page|
  haml(page.to_sym, :layout => false)
end

get %r{/(faq|bugs)} do |page|
  haml(page.to_sym)
end
