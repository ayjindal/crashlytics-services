class Service::Flock < Service::Base
  title 'Flock'

  string :webhook_url, :placeholder => 'Incoming Webhook URL',
                 :label => 'Flock Incoming Webhook URL. <br />' \
                   'To create an incoming webhook, go to your Flock admin panel and switch to \"Webhooks\" tab'

  page 'Webhook Information', [ :webhook_url ]

  def receive_verification(config, _)
    success = [true,  'Successfully verified Flock service hook']
    failure = [false, 'Oops! Please check your Flock service hook configuration again.']
    message = 'Successfully configured Flock service hook with Crashlytics'
    response = post_to_flock(config[:webhook_url], message)
    if successful_response?(response)
      success
    else
      failure
    end
  end

  def receive_issue_impact_change(config, payload)
    success = [true,  'Successfully posted issue impact change message to Flock']
    failure = [false, 'Oops! Some problem occurred while posting issue impact change message to Flock']
    message = Service::Flock.extract_flock_message(payload)
    response = post_to_flock(config[:webhook_url], message)
    if successful_response?(response)
      success
    else
      failure
    end
  end

  def self.extract_flock_message(payload)
  	message = "#{payload[:app][:name]} crashed at #{payload[:title]}\n"+
  	  "Method: #{payload[:method]}\n" + 
  	  "Number of crashes: #{payload[:crashes_count]}\n" + 
  	  "Number of impacted devices: #{payload[:impacted_devices_count]}\n" + 
  	  "More information: #{payload[:url]}"
  end

  def post_to_flock(webhook_url, message)
    body = {:text => message}
    response = http_post(webhook_url) do |request|
      request.body = body
    end
  end
end

