require 'spec_helper'

describe Capistrano::Docker::Compose do
  it 'has a version number' do
    expect(Capistrano::Docker::Compose::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(true)
  end
end
