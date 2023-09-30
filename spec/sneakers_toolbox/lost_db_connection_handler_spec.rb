require_relative '../../lib/sneakers_toolbox'
require 'active_record'

RSpec.describe SneakersToolbox::LostDbConnectionHandler do
  it 'clears connections after lost connection' do
    ActiveRecord::Base.establish_connection({adapter: 'sqlite3', database: ':memory:'})
    ActiveRecord::Base.connection
    expect(ActiveRecord::Base.connection_pool.connections.count).to eq 1
    expect { described_class.with_connection { raise ActiveRecord::StatementInvalid } }.to raise_error(ActiveRecord::StatementInvalid)
    expect(ActiveRecord::Base.connection_pool.connections.count).to eq 0
  end
end
