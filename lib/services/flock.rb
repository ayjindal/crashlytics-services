class Service::Flock < Service::Base
  title 'Flock'

  string :url, :placeholder => 'Flock Webhook URL',
                 :label => 'Go to the <a href="https://apps.flock.co/crashlytics">Flock App Store</a> and install the Crashlytics app. <br />' \
                    'Generate the Flock Webhook URL and paste it below:'

  def receive_verification
    message = 'Successfully configured Flock service hook with Crashlytics'
    payload = { :event => 'verification', :payload_type => 'none' }
    response = post_to_flock(message, payload)
    if response.success?
      log('verification successful')
    else
      display_error "#{self.class.title} verification failed - #{error_response_details(response)}"
    end
  end

  def receive_issue_impact_change(payload)
    message = extract_flock_message(payload)
    response = post_to_flock(message, payload)
    if response.success?
      log('issue_impact_change successful')
    else
      display_error "#{self.class.title} issue impact change failed - #{error_response_details(response)}"
    end
  end

  def extract_flock_message(payload)
    "#{payload[:app][:name]} crashed at #{payload[:title]}\n" +
    "Method: #{payload[:method]}\n" +
    "Number of crashes: #{payload[:crashes_count]}\n" +
    "Number of impacted devices: #{payload[:impacted_devices_count]}\n" +
    "More information: #{payload[:url]}"
  end

  def post_to_flock(message, payload)
    url = config[:url]
    if (url.start_with?('https://apps.flock')) 
      body = payload
    elsif (url.start_with?('https://api.flock'))
      body = { :text => message }
    end  
    http_post(url) do |request|
      request.headers['Content-Type'] = 'application/json'
      request.body = body.to_json
    end
  end
end

