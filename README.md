# SneakersToolbox

Various helpers and convenience classes/modules/methods to help simplify working with Sneakers and get around common issues

## Components

### LostDbConnectionHandler

Sometimes ActiveRecord can lose connection and not be aware of it (thus not re-connecting). It can happen for example when connecting through a QuotaGuard tunnel. This results in `ActiveRecord::StatementInvalid` exception being thrown. `SneakersToolbox::LostDbConnectionHandler` uses this fact to clear all connections, forcing them to be reestablished. You can use this functionality with:

```ruby
  def work(*args)
    payload, *extra = args
    payload = JSON.parse(payload) unless payload.class == Hash
    SneakersToolbox::LostDbConnectionHandler.with_connection { process_message(payload, *extra) }
  rescue => error
    Honeybadger.notify(error, context: payload)
    raise error
  end
```
