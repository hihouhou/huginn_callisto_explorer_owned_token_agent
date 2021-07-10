require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::CallistoExplorerOwnedTokenAgent do
  before(:each) do
    @valid_options = Agents::CallistoExplorerOwnedTokenAgent.new.default_options
    @checker = Agents::CallistoExplorerOwnedTokenAgent.new(:name => "CallistoExplorerOwnedTokenAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
