# Runivedo - Univedo Ruby Binding 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'runivedo'
```

## Usage

```ruby
connection = Runivedo.new(host: "univedo://hostname.com/bucket",
                          user: "username",
                          password: "secret",
                          uts: IO.read("univedo.uts"))
connection.execute("SELECT f1, f2 FROM tbl WHERE name = 'foo'") do |row|
  puts "f1: #{row[0]}, f2: #{row[1]}"
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
