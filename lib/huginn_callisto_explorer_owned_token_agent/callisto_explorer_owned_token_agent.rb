module Agents
  class CallistoExplorerOwnedTokenAgent < Agent
    include FormConfigurable
    can_dry_run!
    no_bulk_receive!
    default_schedule '1h'

    description do
      <<-MD
      The Callisto Explorer agent fetches new owned token by address and creates event .

      `address` is the wallet address wanted.

      `debug` is used for verbose mode.

      The `changes only` option causes the Agent to report an event only when the status changes. If set to false, an event will be created for every check.  If set to true, an event will only be created when the status changes (like if your site goes from 200 to 500).

      `expected_receive_period_in_days` is used to determine if the Agent is working. Set it to the maximum number of days
      that you anticipate passing without this Agent receiving an incoming Event.
      MD
    end

    event_description <<-MD
      Events look like this:
        {
          "balance": "13641540356782800000000",
          "contractAddress": "0x1eaa43544daa399b87eecfcc6fa579d5ea4a6187",
          "decimals": "18",
          "name": "Callisto Enterprise",
          "symbol": "CLOE",
          "type": "ERC-20"
        }
    MD

    def default_options
      {
        'debug' => 'false',
        'changes_only' => 'true',
        'expected_receive_period_in_days' => '2',
        'wallet' => ''
      }
    end

    form_configurable :changes_only, type: :boolean
    form_configurable :debug, type: :boolean
    form_configurable :wallet, type: :string
    form_configurable :expected_receive_period_in_days, type: :string
    def validate_options
      if options.has_key?('debug') && boolify(options['debug']).nil?
        errors.add(:base, "if provided, debug must be true or false")
      end

      unless options['wallet'].present?
        errors.add(:base, "wallet is a required field")
      end

      unless options['expected_receive_period_in_days'].present? && options['expected_receive_period_in_days'].to_i > 0
        errors.add(:base, "Please provide 'expected_receive_period_in_days' to indicate how many days can pass before this Agent is considered to be not working")
      end
    end

    def working?
      event_created_within?(options['expected_receive_period_in_days']) && !recent_error_logs?
    end

    def check
      fetch
    end

    private

    def fetch
      uri = URI.parse("https://explorer.callisto.network/api?module=account&action=tokenlist&address=0x6811164c90Cdd153E337B513064dB69C1540BE1b")
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"
      
      req_options = {
        use_ssl: uri.scheme == "https",
      }
      
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end
    
      log "fetch event request status : #{response.code}"
    
      payload = JSON.parse(response.body)

      if interpolated['debug'] == 'true'
        log payload
      end

      if interpolated['changes_only'] == 'true' && !payload.empty?
        if payload.to_s != memory['last_status']
          if payload
            if "#{memory['last_status']}" == ''
              payload['result'].each do |event|
                if interpolated['debug'] == 'true'
                  log event
                end
                create_event payload: event
              end
            else
              last_status = memory['last_status'].gsub("=>", ": ").gsub(":nil,", ": null,")
              last_status = JSON.parse(last_status)
              payload['result'].each do |token|
                found = false
                if interpolated['debug'] == 'true'
                  log "found is #{found}!"
                  log token
                end
                last_status['result'].each do |tokenbis|
                  if token == tokenbis
                    found = true
                  end
                  if interpolated['debug'] == 'true'
                    log "found is #{found}!"
                  end
                end
                if found == false
                  if interpolated['debug'] == 'true'
                    log "found is #{found}! so token created"
                    log token
                  end
                  create_token payload: token
                end
              end
            end
          end
          memory['last_status'] = payload.to_s
        end
      else
        if !payload.empty?
          create_token payload: payload['result']
          if payload.to_s != memory['last_status']
            memory['last_status'] = payload.to_s
          end
        end
      end
    end    
  end
end
