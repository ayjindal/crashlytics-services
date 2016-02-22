require 'spec_helper'
require 'webmock/rspec'

describe Service::Flock do
  
  it 'has a title' do
    expect(Service::Flock.title).to eq('Flock')
  end

  describe 'schema and display configuration' do
    subject { Service::Flock }

    it { is_expected.to include_string_field :webhook_url }
    it { is_expected.to include_page 'Webhook Information', [:webhook_url] }
  end

  let(:config) do
    {
      :webhook_url => 'https://api.flock.co/hooks/sendMessage/3216b6b0-79bc-419d-9d95-46a49d164936'
    }
  end

  def stub_http_post_request(expected_body)
    stub_request(:post, 'https://api.flock.co/hooks/sendMessage/3216b6b0-79bc-419d-9d95-46a49d164936')
      .with(:body => expected_body)
  end

  describe '#receive_verification' do
    let(:expected_body) do 
     {  
       :text => 'Successfully configured Flock service hook with Crashlytics'
     }
    end

    let(:service) { Service::Flock.new('verification', config) }

    it 'a 200 response as a success' do
      stub_http_post_request(expected_body).to_return(:status => 200)
      success, message = service.receive_verification(config, nil)
      expect(success).to be true 
      expect(message).to eq('Successfully verified Flock service hook')
    end

    it 'escalates a non-200 response as a failure' do
      stub_http_post_request(expected_body).to_return(:status => 400)
      success, message = service.receive_verification(config, nil)
      expect(success).to be false
      expect(message).to eq('Oops! Please check your Flock service hook configuration again.')
    end
  end

  describe '.extract_flock_message' do
    let(:payload) do
      {
        :title => 'foo title',
        :method => 'foo method',
        :impacted_devices_count => 1,
        :crashes_count => 1,
        :app => {
          :name => 'foo name'
        },
        :url => 'foo url'
      }
    end
    it 'displays a readable message from payload' do
      message = Service::Flock.extract_flock_message(payload)
      expect(message).to eq("foo name crashed at foo title\n"+
      "Method: foo method\n" + 
      "Number of crashes: 1\n" + 
      "Number of impacted devices: 1\n" + 
      "More information: foo url")
    end
  end

  describe '#receive_issue_impact_change' do
    let(:payload) do
      {
        :title => 'foo title',
        :method => 'foo method',
        :impacted_devices_count => 1,
        :crashes_count => 1,
        :app => {
          :name => 'foo name'
        },
        :url => 'foo url'
      }
    end

    
    let(:expected_body) do
      {
        :text => Service::Flock.extract_flock_message(payload)
      }
    end

    let(:service) { Service::Flock.new('issue_impact_change', config) }

    it 'a 200 reponse as success to post a message to Flock for issue impact change' do
      stub_http_post_request(expected_body).to_return(:status => 200)
      success, message = service.receive_issue_impact_change(config, payload)
      expect(success).to be true
      expect(message).to eq('Successfully posted issue impact change message to Flock')
    end

    it 'escalates a non-200 response as failure to post a message to Flock for issue impact change' do
      stub_http_post_request(expected_body).to_return(:status => 400)
      success, message = service.receive_issue_impact_change(config, payload)
      expect(success).to be false
      expect(message).to eq('Oops! Some problem occurred while posting issue impact change message to Flock')
    end
  end
end
