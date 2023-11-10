Rails.application.config.middleware.insert_before 0, Rack::Cors, debug: true do
  allowed_headers = %i(get post put patch delete options head)
  allow do
    origins 'https://www.guardiansofearth.io'
    resource '*', headers: :any, methods: allowed_headers
  end
  allow do
    origins 'http://localhost:3000'
    resource '*', headers: :any, methods: allowed_headers
  end
  allow do
    origins 'https://feature-realms-addition.d2cie1zmg2glds.amplifyapp.com'
    resource '*', headers: :any, methods: allowed_headers
  end
  allow do
    origins 'https://development.d2cie1zmg2glds.amplifyapp.com'
    resource '*', headers: :any, methods: allowed_headers
  end
  allow do
    origins '*'
    resource '*',
      headers: :any,
      methods: allowed_headers,
      credentials: false
  end
end
