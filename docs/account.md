# Account Information

```ruby
acc = client.account_info
puts "Login:        #{acc[:login]}"
puts "Balance:      #{acc[:balance]}"
puts "Equity:       #{acc[:equity]}"
puts "Free Margin:  #{acc[:free_margin]}"
puts "Margin Level: #{acc[:margin_level]}%"
puts "Leverage:     1:#{acc[:leverage]}"
```
